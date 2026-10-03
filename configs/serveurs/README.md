# Serveurs Debian

Tous les serveurs sont des clones d'un modele Debian 13 minimal (`MC-DEB-TEMPLATE`).

## Preparation du modele (une seule fois)

Le modele est en NAT avec une redirection de port SSH (127.0.0.1:2222), pour y copier ces fichiers depuis l'hote :

```powershell
scp -P 2222 -r configs\serveurs\modele mcadmin@127.0.0.1:/tmp/
ssh -p 2222 mcadmin@127.0.0.1
```
```bash
cd /tmp/modele && sed -i 's/\r$//' *.sh nginx/*.conf
sudo bash install-modele.sh
sudo poweroff
```

## Specialisation d'un clone

Sur chaque clone, une seule commande fixe le nom, l'adresse, le certificat et la configuration nginx :

```bash
sudo mc-role relais    # 172.16.10.10 (patients) et .11 (medecins), zone DMZ relais
sudo mc-role app       # 172.16.20.10, zone SRV-APP
sudo mc-role demo      # 172.16.30.10, zone DEMO
sudo mc-role interne   # 10.10.20.10, zone serveurs
sudo mc-role admin     # 10.10.99.10, zone administration
```

## Chaines de traitement (ANSSI R6)

| Chaine | Entree publique | Relais (DMZ) | Destination |
|---|---|---|---|
| Patients | 192.36.253.11:443 | 172.16.10.10:443 | SRV-APP 172.16.20.10:8443, chemin `/` (le chemin `/pro` est refuse) |
| Medecins | 192.36.253.12:443 | 172.16.10.11:443 | SRV-APP 172.16.20.10:8443, chemin `/pro/` uniquement |

Les certificats et cles sont generes sur chaque serveur et ne sont jamais versionnes.
