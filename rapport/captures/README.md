# Captures d'écran

| Fichier | Contenu | Section du rapport |
|---|---|---|
| 01-virtualbox-vm-existantes.png | VM présentes avant le projet | Environnement de lab |
| 02-virtualbox-vm-mc-importees.png | Première importation de l'OVA (MC-FW-EXT, MC-Client-LAN) | Environnement de lab |
| 03-fw-ext-premiere-connexion.png | Première connexion à MC-FW-EXT (config usine, 10.0.0.254) | Mise en œuvre |
| 04-fw-ext-politique-pass-all.png | Politique temporaire (10) Pass all, nom MC-FW-EXT | Politique de filtrage (état provisoire) |
| 05-fw-ext-changement-mdp-admin.png | Remplacement du mot de passe admin par défaut | Sécurisation de l'administration |
| 06-fw-ext-interface-out.png | Interface out : External, 192.36.253.10/24 | Plan d'adressage |
| 07-fw-ext-interface-dmz-relais.png | Interface dmz_relais : Internal, 172.16.10.254/24 | Zones de sécurité |
| 08-fw-ext-interface-demo.png | Interface demo : Internal, 172.16.30.254/24 | Séparation production / démonstration |
| 09-fw-ext-erreur-chevauchement-bridge.png | Erreur : 10.0.0.254/8 du bridge chevauche 10.255.0.1/30 | Difficultés rencontrées |
| 10-client-ping-transit.png | Ping 10.255.0.1 depuis le client : 0 % de perte | Tests réalisés |
| 11-fw-ext-interfaces-mode-route.png | 4 interfaces adressées, bridge supprimé (mode routé) | Plan d'adressage |
| 12-fw-ext-passerelle-par-defaut.png | Passerelle par défaut gw_internet (192.36.253.1), routage statique | Routage (R19) |
| 13-client-pings-interfaces-fw-ext.png | Pings vers dmz_relais, demo, out : OK ; vers 192.36.253.1 : échec attendu (pas de NAT) | Tests réalisés |
| 14-fw-int-attribution-interfaces.png | pfSense : WAN=em0 (transit), LAN=em1, OPT1=em2, OPT2=em3, OPT3=em4 | Architecture / pare-feu interne |
| 15-fw-int-wan-lan-adresses.png | pfSense : WAN 10.255.0.2/30 sans passerelle, LAN 10.10.10.254/24 | Plan d'adressage / R19 |
| 16-fw-int-5-interfaces.png | pfSense : les 5 interfaces adressées (transit, LAN, SRV-APP, serveurs, admin) | Plan d'adressage |
| 17-fw-int-ping-transit-echec.png | Ping pfSense vers 10.255.0.1 : « No route to host » | Difficultés rencontrées |
| 18-fw-int-diagnostic-em0-sans-ipv4.png | Diagnostic : em0 sans adresse IPv4 malgré l'affichage du menu | Difficultés rencontrées |
| 19-fw-int-em0-ipv4-apres-reboot.png | Après redémarrage : em0 porte bien 10.255.0.2/30 | Difficultés rencontrées |
| 20-fw-int-ping-fw-ext-ok.png | Ping pfSense (10.255.0.2) vers MC-FW-EXT (10.255.0.1) : 3/3 | Tests réalisés |
| 21-fw-int-assistant-pfsense.png | Assistant pfSense : mot de passe par défaut signalé comme non sécurisé | Sécurisation de l'administration |
| 22-fw-int-wan-transit-sans-passerelle.png | TRANSIT en statique, passerelle None, blocage des réseaux privés désactivé | Routage (R19) / justification |
| 23-fw-int-5-interfaces-up.png | Les 5 interfaces du pare-feu interne actives avec leurs adresses | Zones de sécurité |
| 24-fw-int-passerelle-sans-defaut.png | Passerelle GW_FW_EXT déclarée, routes par défaut IPv4 et IPv6 sur None (R19) | Routage |
| 25-fw-int-routes-statiques.png | Les 4 routes statiques du pare-feu interne vers les zones derrière le pare-feu externe | Routage |
| 26-client-pings-bout-en-bout-echec.png | Client vers pfSense OK, vers Stormshield et DMZ : échec | Difficultés rencontrées |
| 27-fw-int-ping-source-transit-ok.png | Diagnostic A : ping pfSense source TRANSIT vers 10.255.0.1 : 3/3 | Méthode de diagnostic |
| 28-fw-int-ping-source-lan-echec.png | Diagnostic B : ping pfSense source LAN vers 10.255.0.1 : 0/3 | Méthode de diagnostic |
| 29-fw-ext-routes-objets-host-sans-masque.png | Routes créées avec des objets de type Host : colonne Address range sans masque | Difficultés rencontrées |
| 30-fw-ext-alarme-ip-spoofing.png | Alarme Stormshield « IP address spoofing (type=1) » sur transit, action Block | Protection anti-usurpation / journalisation |
| 31-fw-ext-objet-cree-en-host-par-erreur.png | Cause de la panne : formulaire Host, sans masque possible | Difficultés rencontrées |
| 32-fw-ext-objet-network-correct.png | Correction : objet de type Network, 10.10.10.0/24 | Difficultés rencontrées |
