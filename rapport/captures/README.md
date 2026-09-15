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
