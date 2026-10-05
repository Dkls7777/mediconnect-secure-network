# Portail MFA de l'espace medecins

Authentification a deux facteurs devant `/pro/` : mot de passe et code TOTP (RFC 6238, 6 chiffres, 30 secondes).

| Fichier | Role |
|---|---|
| `mc-mfa.py` | Service d'authentification (Python, bibliotheque standard uniquement) et outil d'administration |
| `mc-mfa.service` | Unite systemd, compte dedie `mcmfa`, systeme de fichiers en lecture seule |
| `relais-medecins.conf` | Reverse proxy nginx : `auth_request` avant tout acces a `/pro/` |
| `install-mfa.sh` | Installation sur le serveur relais |

## Choix de conception

- Base d'utilisateurs locale a la DMZ : le relais n'interroge aucun annuaire interne (ANSSI R10).
- Mots de passe stockes sous forme d'empreinte PBKDF2-SHA256 salee, jamais en clair.
- Session portee par un cookie signe (HMAC-SHA256), `Secure`, `HttpOnly`, `SameSite=Strict`, valable 15 minutes.
- Cinq echecs bloquent le couple identifiant et adresse pendant 5 minutes.
- Un code TOTP ne peut pas etre rejoue.
- Le meme message d'erreur est renvoye que l'identifiant existe ou non.
- Chaque tentative est journalisee dans `/var/log/mediconnect/mfa.log` (jamais le mot de passe ni le code).

## Utilisation

```bash
sudo bash install-mfa.sh
sudo mc-mfa adduser dr.dupont     # affiche le secret a saisir dans l'application d'authentification
sudo mc-mfa list
```

La commande `mc-mfa code <identifiant>` affiche le code courant : c'est une aide de maquette, a ne pas conserver en production.

Le secret TOTP, la cle de signature et le fichier des utilisateurs sont crees sur le serveur et ne sont jamais versionnes.

## Limites

- Service minimal ecrit pour la maquette : en production, un fournisseur d'identite eprouve (OpenID Connect) et des cles materielles FIDO2 seraient preferables.
- Les compteurs d'echecs sont en memoire et repartent a zero au redemarrage du service.
- Le TOTP depend de l'heure : le serveur relais doit etre a l'heure.
