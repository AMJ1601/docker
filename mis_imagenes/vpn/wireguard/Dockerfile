# Ultima versión de ubuntu
FROM ubuntu:latest

# Definimos variable para zona horaria
ENV TZ="Europe/Madrid"
# Ip que usamos para el servidor
ENV IP_SERVER=10.0.0.1/24
# Numero de clientes
ENV NUMBER_CLIENT=5
# DNS QUE USARÁ
ENV DNS=8.8.8.8
# Ip permitidas
ENV ALLOWED_IPS=0.0.0.0/0
# Metodo de conexión (ip | dominio)
ENV SERVER_ENDPOINT=

#Instalamos zona horaria con su configuración, wireguard con sus dependencias y limpiazos caché
RUN apt update && apt install curl tzdata wireguard iproute2 iptables net-tools -y && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata && apt clean

# Copiamos en el docker el script, le damos permisos y hacemos que se ejecute al iniciar el contenedor
COPY ./entrypoint.sh /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT ["/entrypoint"]

# docker build -t wireguard-server .
# docker run --rm -it --cap-add=NET_ADMIN --cap-add=SYS_MODULE --sysctl net.ipv4.conf.all.src_valid_mark=1 --sysctl net.ipv4.ip_forward=1 -v ./data:/etc/wireguard -p 51820:51820/udp wireguard

# NET_ADMIN es una capacidad del kernel Linux que permite realizar operaciones avanzadas de administración de red, como:
# Configurar interfaces de red.
# Modificar tablas de enrutamiento.
# Configurar firewalls (iptables/nftables).
# Establecer parámetros de red (sysctl).

# SYS_MODULE puede instalar el controlador de WireGuard por sí mismo

# net.ipv4.conf.all.src_valid_mark del kernel a 1.
# src_valid_mark controla si el kernel acepta paquetes con marcas (marks) específicas en el routing.
# Cuando se habilita (=1), permite que el sistema maneje paquetes marcados (útil en combinación con políticas de routing avanzadas o VPNs).

# --sysctl net.ipv4.ip_forward=1 habilita el reenvío de paquetes entre redes por ejemplo entre interfaces