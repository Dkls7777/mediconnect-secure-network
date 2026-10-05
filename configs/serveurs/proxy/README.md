# Relais sortant

Proxy web (Squid) des utilisateurs du siege, place en DMZ sur `MC-SRV-PROXY` (172.16.10.20, port 3128).

## Pourquoi

Le pare-feu interne n'a pas de route par defaut vers Internet (ANSSI R19). Un poste interne ne peut donc pas sortir directement. La navigation passe par ce relais, qui applique une politique et garde une trace.

## Chaine de traitement

| Etape | Source | Destination | Service |
|---|---|---|---|
| 1 | Poste du LAN 10.10.10.0/24 | Relais 172.16.10.20 | TCP 3128 |
| 2 | Relais | Internet | TCP 80 et 443, DNS |
| 3 | Pare-feu externe | Internet | Adresse source masquee par celle du pare-feu (R21) |

## Politique du relais

- Seul le LAN du siege peut l'utiliser.
- Seuls les ports 80 et 443 sont relayes ; la methode CONNECT n'est acceptee que vers 443.
- Une liste de domaines refuses (`mediconnect-interdits.txt`) illustre le filtrage.
- Chaque requete est journalisee dans `/var/log/squid/access.log`.
- L'adresse interne du poste et la version du relais ne sont pas transmises aux sites visites.

## Limites

- Le relais sortant partage la DMZ des relais entrants. Le guide recommande des chaines distinctes pour les flux entrants et sortants : en production, une DMZ dediee.
- Pas d'authentification des utilisateurs sur le relais, pas d'analyse antivirale ni de dechiffrement TLS.
