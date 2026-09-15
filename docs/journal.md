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
