#!/bin/bash
# MediConnect - installe le portail MFA sur le serveur relais (a lancer avec sudo, une seule fois)
set -e
cd "$(dirname "$0")"
[ "$(id -u)" = "0" ] || { echo "A lancer avec sudo"; exit 1; }
sed -i 's/\r$//' mc-mfa.py mc-mfa.service relais-medecins.conf
command -v python3 >/dev/null || { echo "ERREUR : python3 absent de ce serveur"; exit 1; }

id mcmfa >/dev/null 2>&1 || useradd --system --no-create-home --shell /usr/sbin/nologin mcmfa
install -m 755 mc-mfa.py /usr/local/sbin/mc-mfa
install -d -m 750 -o mcmfa -g mcmfa /etc/mediconnect/mfa /var/log/mediconnect
# Cle de signature des sessions : generee sur place, jamais versionnee
[ -f /etc/mediconnect/mfa/secret.key ] || head -c 32 /dev/urandom > /etc/mediconnect/mfa/secret.key
[ -f /etc/mediconnect/mfa/users.json ] || echo "{}" > /etc/mediconnect/mfa/users.json
chown mcmfa:mcmfa /etc/mediconnect/mfa/secret.key /etc/mediconnect/mfa/users.json
chmod 600 /etc/mediconnect/mfa/secret.key /etc/mediconnect/mfa/users.json

install -m 644 mc-mfa.service /etc/systemd/system/mc-mfa.service
systemctl daemon-reload
systemctl enable mc-mfa
systemctl restart mc-mfa

install -m 644 relais-medecins.conf /etc/nginx/sites-enabled/relais-medecins.conf
mkdir -p /opt/mediconnect/nginx && cp relais-medecins.conf /opt/mediconnect/nginx/
echo
systemctl is-active mc-mfa && echo "Service mc-mfa actif."
if nginx -t; then
  systemctl reload nginx 2>/dev/null || systemctl restart nginx || true
  echo "Configuration nginx valide et chargee."
else
  echo "ATTENTION : configuration nginx invalide, voir le message ci-dessus."
fi
echo "Etape suivante : sudo mc-mfa adduser dr.dupont"
