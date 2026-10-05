#!/bin/bash
# MediConnect - transforme un clone du modele en serveur d'une zone
# Usage : sudo mc-role relais | app | demo | interne | admin | proxy
set -e
ROLE="$1"
ALIAS=""
case "$ROLE" in
  relais)  HN=mc-srv-relais;  IP=172.16.10.10/24; GW=172.16.10.254; ALIAS=172.16.10.11/24; DNS=172.16.10.53 ;;
  app)     HN=mc-srv-app;     IP=172.16.20.10/24; GW=172.16.20.254; DNS=10.10.20.53 ;;
  demo)    HN=mc-srv-demo;    IP=172.16.30.10/24; GW=172.16.30.254; DNS=172.16.10.53 ;;
  interne) HN=mc-srv-interne; IP=10.10.20.10/24;  GW=10.10.20.254;  ALIAS="10.10.20.20/24 10.10.20.30/24 10.10.20.40/24"; DNS=10.10.20.53 ;;
  admin)   HN=mc-srv-admin;   IP=10.10.99.10/24;  GW=10.10.99.254;  DNS=10.10.20.53 ;;
  proxy)   HN=mc-srv-proxy;   IP=172.16.10.20/24; GW=172.16.10.254; DNS=9.9.9.9 ;;
  *) echo "Usage : sudo mc-role relais | app | demo | interne | admin | proxy"; exit 1 ;;
esac
[ "$(id -u)" = "0" ] || { echo "A lancer avec sudo"; exit 1; }
if [ "$ROLE" = "proxy" ] && ! command -v squid >/dev/null; then
  echo "ERREUR : squid absent. Installer d'abord : sudo apt-get install -y squid"; exit 1
fi

IF=$(ip -o link show | awk -F': ' '$2 != "lo" && $2 !~ /^docker/ {print $2; exit}')
echo "Role $ROLE : $HN, $IP sur $IF, passerelle $GW"

# Identite de la machine (un clone ne doit pas garder celle du modele)
hostnamectl set-hostname "$HN"
sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HN.mediconnect.lab $HN/" /etc/hosts
rm -f /etc/machine-id /var/lib/dbus/machine-id
systemd-machine-id-setup
rm -f /etc/ssh/ssh_host_*
ssh-keygen -A

# Reseau statique
cat > /etc/network/interfaces << NET
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto $IF
iface $IF inet static
    address $IP
    gateway $GW
NET
for A in $ALIAS; do echo "    up ip addr add $A dev $IF" >> /etc/network/interfaces; done
echo "nameserver $DNS" > /etc/resolv.conf

# Certificat auto-signe propre a ce serveur
mkdir -p /etc/nginx/tls
mkcert() { # $1 = nom de fichier, $2 = CN, $3 = SAN
  openssl req -x509 -newkey rsa:2048 -nodes -days 365 \
    -keyout /etc/nginx/tls/$1.key -out /etc/nginx/tls/$1.crt \
    -subj "/O=MediConnect/CN=$2" -addext "subjectAltName=$3" 2>/dev/null
  chmod 600 /etc/nginx/tls/$1.key
}

rm -f /etc/nginx/sites-enabled/*
case "$ROLE" in
  relais)
    mkcert patients www.mediconnect.lab "DNS:www.mediconnect.lab,IP:192.36.253.11,IP:172.16.10.10"
    mkcert medecins pro.mediconnect.lab "DNS:pro.mediconnect.lab,IP:192.36.253.12,IP:172.16.10.11"
    cp /opt/mediconnect/nginx/relais-patients.conf /opt/mediconnect/nginx/relais-medecins.conf /etc/nginx/sites-enabled/
    echo "net.ipv4.ip_nonlocal_bind=1" > /etc/sysctl.d/90-mediconnect.conf
    ;;
  app)
    mkcert app app.mediconnect.lab "DNS:app.mediconnect.lab,IP:172.16.20.10"
    mkdir -p /var/www/mediconnect && cp -r /opt/mediconnect/www/portail/. /var/www/mediconnect/
    chmod -R a+rX /var/www/mediconnect   # dossiers lisibles par nginx (www-data)
    cp /opt/mediconnect/nginx/app.conf /etc/nginx/sites-enabled/
    ;;
  demo)
    mkcert demo demo.mediconnect.lab "DNS:demo.mediconnect.lab,IP:172.16.30.10"
    mkdir -p /var/www/demo && cp -r /opt/mediconnect/www/demo/. /var/www/demo/
    chmod -R a+rX /var/www/demo
    cp /opt/mediconnect/nginx/demo.conf /etc/nginx/sites-enabled/
    ;;
  interne)
    # Un seul serveur porte les trois applications internes, une adresse par application
    mkcert interne interne.mediconnect.lab "DNS:interne.mediconnect.lab,IP:10.10.20.20,IP:10.10.20.30,IP:10.10.20.40"
    mkdir -p /var/www/interne && cp -r /opt/mediconnect/www/interne/. /var/www/interne/
    chmod -R a+rX /var/www/interne
    cp /opt/mediconnect/nginx/interne.conf /etc/nginx/sites-enabled/
    echo "net.ipv4.ip_nonlocal_bind=1" > /etc/sysctl.d/90-mediconnect.conf
    ;;
  proxy)
    # Relais sortant : Squid, configuration et liste de domaines refuses
    sed -i 's/\r$//' /opt/mediconnect/proxy/squid.conf /opt/mediconnect/proxy/mediconnect-interdits.txt
    install -m 644 /opt/mediconnect/proxy/squid.conf /etc/squid/squid.conf
    install -m 644 /opt/mediconnect/proxy/mediconnect-interdits.txt /etc/squid/mediconnect-interdits.txt
    echo "net.ipv4.ip_nonlocal_bind=1" > /etc/sysctl.d/90-mediconnect.conf
    squid -k parse 2>&1 | grep -iE "error|fatal|warning" || echo "Configuration Squid valide."
    systemctl enable squid
    ;;
esac

if ls /etc/nginx/sites-enabled/*.conf >/dev/null 2>&1; then
  sed -i 's/# server_tokens off;/server_tokens off;/' /etc/nginx/nginx.conf
  nginx -t || true   # le test peut echouer tant que les adresses de la zone ne sont pas actives
  systemctl enable nginx
fi

echo
echo "Termine. Eteindre (sudo poweroff), brancher la carte sur le bon reseau interne, puis redemarrer."
