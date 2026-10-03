#!/bin/bash
# MediConnect - preparation du serveur Debian modele (a lancer une seule fois, avec sudo)
set -e
cd "$(dirname "$0")"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx openssl curl tcpdump dnsutils rsyslog ca-certificates
apt-get install -y docker.io docker-compose || echo "ATTENTION : docker non installe (non bloquant pour l'instant)"
mkdir -p /opt/mediconnect
cp -r nginx www /opt/mediconnect/
chmod -R a+rX /opt/mediconnect
install -m 755 mc-role.sh /usr/local/sbin/mc-role
systemctl disable --now nginx
apt-get clean
echo
echo "Modele pret. Eteindre la VM (sudo poweroff), prendre un instantane, puis cloner."
