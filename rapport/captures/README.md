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
| 33-fw-ext-routes-retour-avec-masque.png | Routes retour corrigées : 4 réseaux en /24 via transit et gw_fw_int | Routage |
| 34-client-pings-bout-en-bout-ok.png | Test de bout en bout : le client du LAN joint le pfSense, le Stormshield, la DMZ et la DEMO (TTL 63 = un saut par le pfSense) | Tests réalisés |
| 35-debian-selection-logiciels-minimale.png | Serveur modèle Debian : installation minimale, sans bureau (réduction de la surface d'attaque) | Environnement de lab |
| 36-fw-int-regle-transit-rp-vers-app.png | pfSense, interface TRANSIT : seule règle autorisée, RP_DMZ vers SRV-APP en TCP 8443 | Politique de filtrage / protection de la DMZ |
| 37-portail-patients-via-reverse-proxy.png | Portail patients servi par SRV-APP à travers le reverse proxy de la DMZ (https://172.16.10.10) | Exposition sécurisée de la plateforme |
| 38-chaine-patients-refuse-espace-pro-403.png | La chaîne patients refuse l'espace professionnel (403) : séparation des chaînes, ANSSI R6 | Protection de la DMZ |
| 39-srv-app-droits-dossier-pro-corriges.png | Dossier pro en drwx------ (illisible par nginx) corrigé en drwxr-xr-x | Difficultés rencontrées |
| 40-espace-medecins-via-reverse-proxy.png | Espace professionnel servi par la chaîne médecins (https://172.16.10.11/pro/) | Accès authentifié des médecins |
| 41-fw-ext-nat-avant.png | Stormshield, onglet NAT avant publication : une seule règle d'usine désactivée | Exposition sécurisée de la plateforme |
| 42-fw-ext-nat-edition-regle.png | Fenêtre d'édition d'une règle de NAT (destination d'origine, destination translatée) | Exposition sécurisée de la plateforme |
| 43-fw-ext-nat-publication.png | Les deux règles de publication : pub_patients vers srv_rp_patients et pub_medecins vers srv_rp_medecins, HTTPS uniquement | Exposition sécurisée de la plateforme |
| 44-client-externe-pings-adresses-publiques.png | Client externe (192.36.253.100) : le pare-feu répond sur ses trois adresses publiques .10, .11, .12 | Tests réalisés |
| 45-admin-fw-ext-refusee-depuis-internet.png | Interface d'administration du Stormshield refusée depuis Internet (Forbidden) : ANSSI R16 | Administration sécurisée |
| 46-espace-medecins-depuis-internet.png | Espace professionnel atteint depuis Internet par l'adresse publique médecins (https://192.36.253.12/pro/) | Accès authentifié des médecins |
| 47-chaine-patients-internet-refuse-pro-403.png | Depuis Internet, la chaîne patients refuse l'espace professionnel (403) : séparation des chaînes, ANSSI R6 | Protection de la DMZ |
| 48-portail-patients-depuis-internet.png | Portail patients atteint depuis Internet par l'adresse publique patients (https://192.36.253.11) | Exposition sécurisée de la plateforme |
| 49-fw-ext-politique-filtrage-mediconnect.png | Politique MediConnect, première version : 5 règles d'autorisation et un blocage final journalisé | Politique de filtrage |
| 50-fw-ext-objet-port-app-8443.png | Création de l'objet port app_8443 (TCP 8443) | Politique de filtrage |
| 51-filtrage-ping-internet-sans-reponse.png | Depuis Internet, le ping des adresses publiques reste sans réponse (blocage silencieux, ANSSI R20) | Tests réalisés |
| 52-filtrage-portail-patients-toujours-ok.png | Le portail patients reste joignable après durcissement | Tests réalisés |
| 53-filtrage-espace-medecins-toujours-ok.png | L'espace médecins reste joignable après durcissement | Tests réalisés |
| 54-filtrage-admin-internet-sans-reponse.png | L'administration du pare-feu ne répond plus du tout depuis Internet (avant : Forbidden) | Administration sécurisée |
| 55-fw-ext-journal-blocages-regle-6.png | Journal : pings du pfSense vers sa passerelle bloqués par la règle finale, flux légitime oublié dans la matrice | Difficultés rencontrées / journalisation |
| 56-fw-ext-politique-filtrage-7-regles.png | Politique MediConnect avec la règle de supervision de passerelle ajoutée (7 règles) | Politique de filtrage |
| 57-fw-ext-journal-admin-autorisee-depuis-lan.png | Journal : connexion d'administration autorisée depuis 10.10.10.2 | Journalisation |
| 58-fw-ext-journal-blocage-ping-internet.png | Journal : ping de 192.36.253.100 vers pub_patients bloqué par la règle finale, interface out | Journalisation / tests réalisés |
| 59-fw-int-passerelle-online-apres-regle-supervision.png | pfSense : passerelle GW_FW_EXT Online après ajout de la règle de supervision | Routage |
| 60-demo-publiee-depuis-internet.png | État intermédiaire, publication retirée ensuite : la DEMO n'est accessible que par le VPN (voir journal du 03/10 soir). Utilisable seulement pour montrer la page | Zone DEMO |
| 61-demo-isolement-aucun-flux-sortant.png | Depuis le serveur DEMO : aucun accès à la DMZ, à l'application ni au réseau interne | Zone DEMO / protection de la DMZ |
| 62-fw-ext-politique-finale-8-regles.png | Politique MediConnect finale du pare-feu externe : 7 autorisations précises et un blocage final journalisé | Politique de filtrage |
| 63-fw-ext-nat-3-publications.png | État intermédiaire avec trois règles de NAT ; la publication de la démonstration a été retirée ensuite, à refaire avec deux règles | Exposition sécurisée de la plateforme |
| 64-fw-b-interfaces-mode-route.png | Pare-feu du site B en mode routé : out 192.36.253.20/24, lan_site_b 10.20.10.254/24 | Environnement de lab / site secondaire |
| 65-fw-b-route-par-defaut.png | Site B : passerelle par défaut gw_internet | Routage |
| 66-fw-b-tunnel-ipsec-cree.png | Site B : tunnel IPsec Network_lan_site_b vers net_serveurs_siege, correspondant Site_Siege, profil StrongEncryption | VPN IPsec site à site |
| 67-fw-b-politique-filtrage-site-b.png | Site B : politique MediConnect-B, 3 autorisations et un blocage final journalisé | Politique de filtrage |
| 68-fw-ext-politique-10-regles-avec-tunnel.png | Pare-feu externe : règles 8 et 9 n'acceptant le site B que via le tunnel IPsec | VPN IPsec site à site / politique de filtrage |
| 69-fw-int-regles-transit-site-b.png | pfSense, interface TRANSIT : site B autorisé vers la zone SERVEURS en HTTPS et en ping | VPN IPsec site à site |
| 70-site-b-ping-zone-serveurs-par-tunnel.png | Poste du site B : ping de la zone SERVEURS du siège à travers le tunnel (premier paquet perdu pendant la négociation) | Tests réalisés |
| 71-site-b-tunnel-refuse-lan-et-dmz.png | Poste du site B : le LAN du siège et la DMZ restent injoignables, le tunnel est limité à la zone SERVEURS | Tests réalisés / VPN IPsec site à site |
| 72-fw-ext-supervision-tunnel-ipsec-etabli.png | Supervision du tunnel : IKE established (AES-256, SHA-256, PFS groupe 28), SA IPsec installed (AES-256, HMAC-SHA256), octets échangés | VPN IPsec site à site |
| 73-fw-ext-politique-9-regles-sans-demo.png | Politique du pare-feu externe après retrait de la publication DEMO : 9 règles, dont 2 réservées au tunnel IPsec | Politique de filtrage |
| 74-site-b-crm-par-tunnel.png | Poste du site B : application CRM de la zone SERVEURS (https://10.10.20.20) affichée à travers le tunnel IPsec | VPN IPsec site à site / tests réalisés |
| 75-site-b-comptabilite-par-tunnel.png | Poste du site B : application de comptabilité (https://10.10.20.30) à travers le tunnel | VPN IPsec site à site |
| 76-site-b-support-par-tunnel.png | Poste du site B : application de support (https://10.10.20.40) à travers le tunnel | VPN IPsec site à site |
| 77-fw-ext-annuaire-utilisateurs-et-groupes.png | Annuaire mediconnect.lab du pare-feu externe : 4 utilisateurs de test et 4 groupes (commerciaux, comptabilite, support, administrateurs) | Accès distant / contrôle d'accès par identité |
| 78-fw-ext-service-vpn-ssl.png | Service VPN SSL du pare-feu externe : adresse publique 192.36.253.10, ressources vpn_ressources, pools UDP et TCP dans 10.60.0.0/24 | VPN SSL d'accès distant |
| 79-fw-ext-politique-authentification.png | Politique d'authentification : utilisateurs de mediconnect.lab autorisés à s'authentifier depuis l'interface out, méthode LDAP | VPN SSL d'accès distant |
| 80-fw-ext-droits-vpn-ssl-par-groupe.png | Droits d'accès détaillés : VPN SSL autorisé pour les quatre groupes, portail et IPsec bloqués | Contrôle d'accès par identité |
| 81-fw-ext-portail-authentification-out.png | Portail d'authentification associé à l'interface out, profil External, annuaire mediconnect.lab | VPN SSL d'accès distant |
| 82-fw-ext-politique-12-regles-haut.png | Politique finale du pare-feu externe, règles 1 à 7 en pleine largeur, sources, destinations et commentaires lisibles | Politique de filtrage (capture de référence) |
| 83-fw-ext-politique-12-regles-bas-groupes-vpn.png | Politique finale, règles 5 à 12 : tunnel IPsec, puis une règle par groupe d'utilisateurs via le VPN SSL, puis blocage final | Contrôle d'accès par identité (capture de référence) |
| 84-fw-int-regles-transit-avec-nomades.png | pfSense, interface TRANSIT : relais vers application, site B, puis nomades du VPN SSL vers la zone SERVEURS en HTTPS | Protection de la DMZ / VPN SSL d'accès distant |
| 85-portail-authentification-depuis-internet.png | Portail d'authentification du pare-feu externe atteint depuis Internet (https://192.36.253.10/auth) | VPN SSL d'accès distant |
| 86-fw-ext-journal-vpn-access-denied-by-uac.png | Journal VPN : connexion de lea.martin refusée, « Access denied by UAC » (droits d'accès) et « bad password », plus les événements du tunnel IPsec | Difficultés rencontrées / journalisation |
| 87-fw-ext-journal-tous-evenements-lea.png | Journal complet filtré sur lea : connexions au portail, flux OpenVPN UDP 1194 autorisés par règle implicite, refus d'authentification | Journalisation |
| 88-vpn-ssl-lea-commerciale-acces-crm.png | Nomade connectée en VPN SSL (lea.martin, groupe commerciaux, adresse 10.60.0.6) : le CRM s'affiche | VPN SSL d'accès distant / contrôle d'accès par identité |
| 89-vpn-ssl-lea-commerciale-acces-demo.png | Même session VPN : la zone DEMO s'affiche pour la commerciale (accessible uniquement par le VPN, jamais depuis Internet) | Zone DEMO / contrôle d'accès par identité |
| 90-fw-ext-supervision-tunnel-vpn-ssl-lea.png | Supervision des tunnels VPN SSL : lea.martin, annuaire mediconnect.lab, adresse VPN 10.60.0.6, adresse réelle 192.36.253.100, tunnel UDP | VPN SSL d'accès distant |
| 91-vpn-ssl-lea-comptabilite-refusee.png | Même session VPN : l'application de comptabilité (10.10.20.30) reste inaccessible à la commerciale | Contrôle d'accès par identité / tests réalisés |
| 92-fw-ext-droits-vpn-ssl-par-utilisateur.png | Droits d'accès détaillés : VPN SSL accordé utilisateur par utilisateur (les lignes de groupe ne sont pas prises en compte par cette version) | Contrôle d'accès par identité / difficultés rencontrées |
| 93-vpn-ssl-marc-comptable-acces-comptabilite.png | Nomade connecté en VPN SSL (marc.petit, groupe comptabilite) : l'application de comptabilité s'affiche | Contrôle d'accès par identité |
| 94-vpn-ssl-marc-crm-refuse.png | Même session : le CRM (10.10.20.20) est refusé au comptable | Contrôle d'accès par identité / tests réalisés |
| 95-vpn-ssl-marc-demo-refusee.png | Même session : la zone DEMO (172.16.30.10) est refusée au comptable | Contrôle d'accès par identité / zone DEMO |
| 96-fw-int-regles-admin-bastion.png | pfSense, interface ADMIN : le bastion (10.10.99.10) est seul autorisé vers l'administration des deux pare-feux (443) et le SSH des serveurs | Administration sécurisée (ANSSI R16) |
| 97-bastion-rebond-ssh-et-acces-admin.png | Rebond SSH sur le bastion puis accès à l'administration des deux pare-feux depuis le bastion (codes HTTP 200) | Administration sécurisée / tests réalisés |
| 98-fw-int-administre-depuis-le-bastion.png | pfSense administré par son adresse de la zone ADMIN (10.10.99.254) ; la session est vue comme admin@10.10.99.10, l'adresse du bastion | Administration sécurisée (ANSSI R16) |
| 99-fw-ext-journal-administration-depuis-bastion.png | Journal système du pare-feu externe : session d'administration ouverte depuis 10.10.99.10 (bastion), la précédente venait de 10.10.10.2 (poste du LAN) | Administration sécurisée / journalisation |
| 100-fw-ext-administration-reservee-au-bastion.png | Pare-feu externe : seul srv_bastion est autorisé à accéder aux pages d'administration ; protection contre la force brute active (3 essais) | Administration sécurisée (ANSSI R16) |
| 101-lan-administration-directe-refusee.png | Depuis un poste du LAN, sans passer par le bastion : aucune réponse des interfaces d'administration des deux pare-feux (code 000) | Administration sécurisée / tests réalisés |
| 102-fw-int-regles-lan-separation-administration.png | pfSense, interface LAN : seul le poste d'administration peut joindre le bastion en SSH ; zone ADMIN et administration des pare-feux interdites au LAN, journalisées | Administration sécurisée (ANSSI R16) |
