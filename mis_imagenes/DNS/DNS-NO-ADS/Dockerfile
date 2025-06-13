FROM ubuntu:latest

# Evitar instalaciones interactivas
ENV DEBIAN_FRONTEND=noninteractive

# Definimos variable para zona horaria
ENV TZ=Europe/Madrid

# Actualizamos repositorios, instalamos y limpiazmos cache
RUN apt update && apt install dnsmasq lighttpd iputils-ping curl tzdata -y && apt clean && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

# Copiamos la configuración al contenedor
COPY ./dnsmasq.conf /etc/dnsmasq.conf

COPY ./entrypoint.sh /entrypoint
RUN chmod +x /entrypoint
ENTRYPOINT ["/entrypoint"]