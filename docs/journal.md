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

**Reste à faire sur MC-FW-EXT**
- Objet `gw_internet` (192.36.253.1) et passerelle par défaut
- Pings vers les autres interfaces
- Instantané `FW-EXT-INTERFACES`
