#!/bin/bash

# Si no existen las claves del servicio las crea, aunque podrían estar en otra ruta
if [ ! -f /etc/wireguard/privatekey ] || [ ! -f /etc/wireguard/publickey ]; then
    umask 077
    wg genkey > /etc/wireguard/privatekey
    wg pubkey < /etc/wireguard/privatekey > /etc/wireguard/publickey
fi

# Si no existe el fichero con la configuración de la interfaz del servicio lo crea con los datos de las variables
if [ ! -f /etc/wireguard/wg0.conf ]; then
    echo -e "
[Interface]
PrivateKey = $(cat /etc/wireguard/privatekey)
Address = $IP_SERVER
ListenPort = 51820
PostUp = iptables -t nat -A POSTROUTING -o $(ip route show default | awk '{print $5}') -j MASQUERADE 
PostDown = iptables -t nat -D POSTROUTING -o $(ip route show default | awk '{print $5}') -j MASQUERADE
" > /etc/wireguard/wg0.conf
fi # ip route show default | awk '{print $5}' coge la interfaz de red por donde salen los paquetes predeterminadamente
# PostUp hace que todo lo que salga sea con la IP de la interfaz de red por donde salen los paquetes predeterminadamente
# PostDown lo quita

# Si no existe la carpeta client la crea (para guardar los clientes)
if [ ! -d /etc/wireguard/client ]; then
    mkdir /etc/wireguard/client
    chmod 700 $_
fi

# Si la variable esta vacía coge automaticamente la IP pública por el puerto predeterminado de wireguard
if [ -z $SERVER_ENDPOINT ]; then
    SERVER_ENDPOINT="$(curl ifconfig.me):51820"
fi

# Coge la mascara de la IP
mascara=$(echo $IP_SERVER | cut -d \/ -f 2)
# Calcula cuantos host puede haber como máximo
max_host=$(( 2**(32 - $mascara ) -3 ))

# Contador para el número de cliente (ver más adelante)
contador="$(ls -1 /etc/wireguard/client | wc -l)"
contador=$(($contador + 1))

# Separa la IP por octetos
primer_octeto=$(echo $IP_SERVER | sed 's/\./\n/g' | cut -d \/ -f 1 | head -1)
segundo_octeto=$(echo $IP_SERVER | sed 's/\./\n/g' | cut -d \/ -f 1 | head -2 | tail -1)
tercer_octeto=$(echo $IP_SERVER | sed 's/\./\n/g' | cut -d \/ -f 1 | head -3 | tail -1)
cuarto_octeto=$(echo $IP_SERVER | sed 's/\./\n/g' | cut -d \/ -f 1 | tail -1)

# Un bucle que completa los clientes que hay hasta los que quedan

while [ $(ls -1 /etc/wireguard/client | wc -l) -lt $NUMBER_CLIENT ]; do

    # Pequeño apaño para saber la IP del cliente
    IPC() {
        # Si existe el primer cliente
        if [ -d /etc/wireguard/client/peer1 ]; then
            # Cogemos el último cliente
            ULT_CLI=$(ls /etc/wireguard/client/ | sort -V | tail -1)
            # De ese cliente cogemos la IP
            ULT_IP=$(cat /etc/wireguard/client/$ULT_CLI/wg0.conf | grep "Address" | awk '{print $3}' | cut -d \/ -f 1)
            # Y la dividimos
            primer_octeto=$(echo $ULT_IP | sed 's/\./\n/g' | cut -d \/ -f 1 | head -1)
            segundo_octeto=$(echo $ULT_IP | sed 's/\./\n/g' | cut -d \/ -f 1 | head -2 | tail -1)
            tercer_octeto=$(echo $ULT_IP | sed 's/\./\n/g' | cut -d \/ -f 1 | head -3 | tail -1)
            cuarto_octeto=$(echo $ULT_IP | sed 's/\./\n/g' | cut -d \/ -f 1 | tail -1)
        fi

        # Sumamos 1 a la IP sea o no del primero cliente
        cuarto_octeto=$((cuarto_octeto + 1))
            if [ $cuarto_octeto -ge 255 ]; then
                cuarto_octeto=0
                tercer_octeto=$((tercer_octeto + 1))
                if [ $tercer_octeto -ge 255 ]; then
                    tercer_octeto=0
                    segundo_octeto=$((segundo_octeto + 1))
                    if [ $segundo_octeto -ge 255 ]; then
                        segundo_octeto=0
                        primer_octeto=$((primer_octeto + 1))
                    fi
                fi
            fi

    # Variable de la IP cliente
    CLIENT_IP="$primer_octeto.$segundo_octeto.$tercer_octeto.$cuarto_octeto/$mascara"
    }

    IPC
    
    # Creamos la carpeta de los clientes (el numero de cliente correspondiente, por eso el contador)
    mkdir -p /etc/wireguard/client/peer$contador
    umask 077
    
    # Generamos clave de los clientes
    wg genkey | tee /etc/wireguard/client/peer$contador/privatekey | wg pubkey > /etc/wireguard/client/peer$contador/publickey

    # Si los host maximos llega a 0 terminamos
    if [ $max_host -eq 0 ]; then
        echo "No se puede crear mas"
        exit 1
    fi
    
    # Configuracion de wg0 cliente
    echo -e "[Interface]
PrivateKey = $(cat /etc/wireguard/client/peer$contador/privatekey)
Address = $CLIENT_IP
DNS = $DNS

[Peer]
PublicKey = $(cat /etc/wireguard/publickey)
Endpoint = "$SERVER_ENDPOINT"
AllowedIPs = $ALLOWED_IPS
PersistentKeepalive = 25" > /etc/wireguard/client/peer$contador/wg0.conf
    
    # Añadirmos cliente a wg0 del servicio
    echo -e "
[Peer]
PublicKey = $(cat /etc/wireguard/client/peer$contador/publickey)
AllowedIPs = "$primer_octeto.$segundo_octeto.$tercer_octeto.$cuarto_octeto/32"
" >> /etc/wireguard/wg0.conf
    
    # Sumamos contador
    contador=$(($contador + 1))

    # Restamos host
    max_host=$(($max_host - 1))
done

# Levantamos interfaz
wg-quick up wg0

# Manten el contenedor en ejecucion
exec tail -f /dev/null