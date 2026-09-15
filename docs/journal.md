# Journal de bord

## 15/09/2026 : cadrage et socle VirtualBox

**Fait**
- Analyse du sujet et du guide ANSSI PA-066
- Choix d'architecture : Stormshield en externe (siège et site B), pfSense en interne (R13)
- Document de cadrage : besoins, zones, plan d'adressage, matrice des flux, planning
- Réseau NAT dédié `NatMediConnect` (192.36.253.0/24, sans DHCP)
- Deux réimportations de l'OVA CSNx v4.8 : `MC-FW-EXT`, `MC-Client-LAN`, `MC-FW-B`, `MC-Client-B`
- Clone intégral du pfSense : `MC-FW-INT`
- Branchement des cartes réseau sur les réseaux internes `mc_*` (5 cartes pour le pfSense)
- Instantané `PROJET-INIT` sur les 5 VM

**Choix notables**
- Les VM du cours (`CSNx-*`) restent intactes ; le projet utilise uniquement des VM `MC-*`.
- Réseau NAT séparé de celui du cours pour éviter le conflit d'adresse `.10`.

**Prochaine étape**
- MC-FW-EXT : passage en mode routé, adressage des 4 interfaces, route par défaut

## 15/09/2026 (suite) : MC-FW-EXT en mode routé

**Fait**
- Dépôt GitHub privé créé et premier push
- MC-FW-EXT : nom du pare-feu, mot de passe admin par défaut remplacé
- Politique (10) Pass all activée **temporairement** (diagnostic)
- Sortie du mode transparent : out 192.36.253.10/24 (External), dmz_relais 172.16.10.254/24, demo 172.16.30.254/24, transit 10.255.0.1/30 (Internal)
- Suppression de `new_bridge1`
- Test : ping du client (10.255.0.2, provisoire sur mc_transit) vers 10.255.0.1 : 3/3, 0 % de perte

**Difficultés**
- Erreur de chevauchement : l'adresse d'usine du bridge `10.0.0.254/8` couvre `10.255.0.1/30`. Résolu en supprimant le bridge vide avant l'APPLY.
- Commandes Linux lancées par erreur hors de la VM : elles se tapent dans le terminal du client, pas dans PowerShell.

- Objet `gw_internet` (192.36.253.1) défini comme passerelle par défaut (routage statique, R19)

**Tests (depuis 10.255.0.2)**

| Destination | Résultat | Interprétation |
|---|---|---|
| 10.255.0.1 (transit) | 3/3 | Lien transit OK |
| 172.16.10.254 (dmz_relais) | 3/3 | Interface active |
| 172.16.30.254 (demo) | 3/3 | Interface active |
| 192.36.253.10 (out) | 3/3 | Interface active |
| 192.36.253.1 (passerelle NAT) | 0/3 | Attendu : la source 10.255.0.2 n'est pas traduite, la passerelle VirtualBox ne sait pas lui répondre. À corriger avec une règle de NAT sortante. |

**Prochaine étape**
- Instantané `FW-EXT-INTERFACES`, puis configuration du pare-feu interne MC-FW-INT (pfSense)

## 15/09/2026 (suite) : MC-FW-INT (pfSense) adressé

**Fait**
- Instantané `FW-EXT-INTERFACES` sur MC-FW-EXT
- pfSense remis en configuration d'usine (option 4)
- Attribution des cartes par adresse MAC : WAN=em0 (transit), LAN=em1 (lan_siege), OPT1=em2 (srv_app), OPT2=em3 (serveurs), OPT3=em4 (admin)
- Adressage : 10.255.0.2/30, 10.10.10.254/24, 172.16.20.254/24, 10.10.20.254/24, 10.10.99.254/24
- **Aucune passerelle par défaut** sur le WAN du pare-feu interne (ANSSI R19, encadré « Attention »)
- MC-Client-LAN déplacé sur mc_lan_siege : 10.10.10.2/24, passerelle 10.10.10.254, DNS 10.10.20.53 (résolveur interne prévu, §2.4.6)

**Tests**

| Source | Destination | Résultat |
|---|---|---|
| Client 10.10.10.2 | pfSense LAN 10.10.10.254 | 3/3 |
| pfSense 10.255.0.2 | MC-FW-EXT 10.255.0.1 | 3/3 (après correction) |

**Difficultés**
- Le client occupait encore 10.255.0.2 sur le transit : conflit d'adresse évité en le déplaçant sur le LAN avant les tests.
- Ping pfSense vers 10.255.0.1 : « No route to host ». `ifconfig em0` montrait que l'adresse IPv4 du WAN n'était pas appliquée (reste du DHCP d'usine), alors que le menu console l'affichait. Corrigé par un redémarrage du pfSense. Leçon : le menu montre la configuration enregistrée, `ifconfig` montre l'état réel.
- Console pfSense en QWERTY : éviter les caractères spéciaux, utiliser le pavé numérique pour les adresses.

**Prochaine étape**
- Interface web du pfSense depuis le client (https://10.10.10.254), mot de passe admin, option « Block private networks » du WAN
- Routes statiques croisées entre les deux pare-feux, puis test de bout en bout client vers DMZ
