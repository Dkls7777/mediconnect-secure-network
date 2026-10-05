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

## 01/10/2026 : pfSense finalisé et routes croisées

**Fait**
- pfSense : assistant web, nom MC-FW-INT, domaine mediconnect.lab, mot de passe admin par défaut remplacé
- Interface WAN renommée TRANSIT : statique 10.255.0.2/30, passerelle None, « Block private networks » et « Block bogon networks » décochés (le transit est en adressage privé)
- Interfaces OPT activées et renommées : SRV_APP, SERVEURS, ADMIN
- Passerelle `GW_FW_EXT` (10.255.0.1) déclarée, **passerelles par défaut IPv4 et IPv6 sur None** (ANSSI R19) ; passerelles DHCP résiduelles supprimées
- 4 routes statiques sur le pfSense via GW_FW_EXT : 172.16.10.0/24 (DMZ), 172.16.30.0/24 (DEMO), 10.60.0.0/24 (VPN), 10.20.10.0/24 (site B)
- Stormshield : objet `gw_fw_int` (10.255.0.2) et routes retour vers net_lan_siege, net_serveurs, net_admin, net_srv_app via transit

**Difficulté principale : usurpation d'adresse détectée par le Stormshield**
- Symptôme : le client (10.10.10.2) joint le pfSense mais ni 10.255.0.1 ni la DMZ.
- Méthode : ping depuis le pfSense avec source TRANSIT (3/3) puis source LAN (0/3). La panne est donc sur le retour, côté Stormshield.
- Preuve : alarmes « IP address spoofing (type=1) », action Block, interface transit, aux heures exactes des pings.
- Cause : les objets `net_*` avaient été créés en type Host au lieu de Network. Les routes ne couvraient qu'une adresse (colonne Address range sans masque), donc le Stormshield considérait 10.10.10.0/24 comme illégitime derrière transit.
- Correction : suppression des routes et des objets, recréation en type Network avec masque /24.
- Leçon : sur Stormshield, une route statique vers un réseau interne sert aussi à déclarer ce réseau comme légitime derrière l'interface (anti-usurpation).

**Autre point**
- Pour administrer le Stormshield avant d'avoir les routes retour, le client a été branché provisoirement sur la DMZ (172.16.10.2). À terme, l'administration passera uniquement par la zone ADMIN (R16).

**À faire en premier la prochaine fois**
- Vérifier que les 4 routes affichent bien un masque /24, puis test de bout en bout depuis le LAN : ping 10.255.0.1, 172.16.10.254, 172.16.30.254

## 03/10/2026 : serveurs, reverse proxies et publication sur Internet

**Fait**
- Test de bout en bout validé depuis le LAN : pfSense, Stormshield, DMZ et DEMO joignables (TTL 63, un saut par le pfSense)
- Serveur modèle `MC-DEB-TEMPLATE` (Debian 13, installation minimale sans bureau), scripts `install-modele.sh` et `mc-role.sh`, instantané `MODELE-PRET`
- Trois clones liés de 512 Mo : `MC-SRV-RELAIS` (172.16.10.10 et .11), `MC-SRV-APP` (172.16.20.10), `MC-SRV-DEMO` (172.16.30.10)
- Deux reverse proxies nginx sur le relais, une adresse d'écoute par chaîne : patients (.10) et médecins (.11), tous deux en HTTPS vers SRV-APP:8443
- SRV-APP n'accepte que les deux relais (`allow` / `deny all`)
- pfSense : alias `RP_DMZ`, une seule règle sur TRANSIT (RP_DMZ vers 172.16.20.10 en TCP 8443, journalisée)
- Stormshield : adresses publiques 192.36.253.11 et .12 ajoutées sur `out`, objets `pub_patients`, `pub_medecins`, `srv_rp_patients`, `srv_rp_medecins`, deux règles de NAT de destination limitées à HTTPS et à l'interface `out`

**Tests**

| Source | Destination | Résultat attendu | Résultat |
|---|---|---|---|
| Client LAN 10.10.10.2 | https://172.16.10.10 | Portail patients | OK |
| Client LAN 10.10.10.2 | https://172.16.10.11/pro/ | Espace pro | OK |
| Client externe 192.36.253.100 | ping .10, .11, .12 | Réponse | 2/2 sur chaque adresse |
| Client externe | https://192.36.253.11 | Portail patients | OK |
| Client externe | https://192.36.253.12/pro/ | Espace pro | OK |
| Client externe | https://192.36.253.11/pro/ | Refus | 403 |
| Client externe | https://192.36.253.10/admin | Refus | Forbidden |

**Recommandations ANSSI illustrées**
- R2, R3, R13 : le flux traverse deux pare-feux de technologies différentes
- R6 : deux chaînes distinctes (adresse publique, relais et règle propres à chaque population), la chaîne patients refuse `/pro/`
- R7 : seul le relais initie un flux vers SRV-APP, sur un port unique
- R8 : rupture protocolaire, le relais termine le TLS et rouvre une session vers l'application
- R16 : l'administration du pare-feu externe n'est pas servie côté Internet

**Difficultés**
- `nginx -t` échouait sur le relais tant que la seconde adresse n'existait pas : test rendu non bloquant dans `mc-role.sh`
- 403 sur l'espace pro : dossier `/var/www/mediconnect/pro` en `drwx------` (droits hérités de la copie depuis Windows), corrigé par `chmod -R a+rX` et intégré aux scripts
- Mot de passe pfSense oublié : réinitialisé par la console (option 3), à rechanger

**Politique de filtrage du pare-feu externe (fin d'après-midi)**
- Politique (10) renommée `MediConnect`, copie de secours conservée dans (5) Pass all
- 8 règles, de la plus précise à la plus générale :

| N° | Source | Destination | Service | Action | Rôle |
|---|---|---|---|---|---|
| 1 | net_lan_siege, net_admin | Firewall_transit | https | pass | Administration (LAN provisoire, à terme zone ADMIN) |
| 2 | Any, interface out | pub_patients | https | pass | Portail patients |
| 3 | Any, interface out | pub_medecins | https | pass | Espace médecins |
| 4 | Any, interface out | pub_demo | https | pass | Environnement de démonstration |
| 5 | srv_rp_patients, srv_rp_medecins | srv_app | TCP 8443 | pass | Relais vers application (R7) |
| 6 | net_lan_siege, net_admin | Any | ICMP echo | pass | Diagnostic |
| 7 | gw_fw_int | Firewall_transit | ICMP echo | pass | Supervision de passerelle par le pfSense |
| 8 | Any | Any | Any | block, journalisé | Blocage silencieux (R20) |

- Les règles de filtrage visent l'adresse publique (`pub_*`) : sur Stormshield le filtrage est évalué avant le NAT
- Zone DEMO publiée sur une adresse dédiée 192.36.253.13 (objets `pub_demo`, `srv_demo`, règle de NAT et règle de filtrage propres)

**Tests après durcissement**

| Source | Test | Résultat |
|---|---|---|
| Client externe | https://192.36.253.11 et https://192.36.253.12/pro/ | OK |
| Client externe | ping 192.36.253.11 | 100 % de perte, tentative journalisée (règle de blocage, interface out) |
| Client externe | https://192.36.253.10/admin | Aucune réponse (avant : Forbidden) |
| Client externe | https://192.36.253.13 | Page de démonstration |
| Serveur DEMO | curl vers 172.16.10.10 et 172.16.20.10:8443, ping 10.10.10.254 | Délai dépassé, 100 % de perte |
| pfSense | État de la passerelle GW_FW_EXT | Online |

**Flux oublié révélé par les journaux**
- Après activation, un blocage toutes les demi-secondes en ICMP sur `transit` : le pfSense surveille sa passerelle par ping. Flux légitime absent de la matrice, ajouté par une règle dédiée (source `gw_fw_int` uniquement).
- Leçon : une politique restrictive associée à la journalisation fait apparaître les flux réels, la matrice se corrige à partir des journaux.

**Autres points**
- Journaux Stormshield anonymisés par défaut (protection des données personnelles) : accès complet à demander explicitement par l'administrateur
- Une seule session d'administration a le droit d'écriture à la fois (seconde session en lecture seule)

**Reste à faire**
- Sorties vers Internet (mises à jour des serveurs, navigation des utilisateurs) : à traiter par un relais sortant, pas par du routage direct (R19)
- Rechanger le mot de passe par défaut du pfSense

## 03/10/2026 (soir) : site B et tunnel IPsec

**Fait**
- MC-FW-B mis en service : nom, mot de passe d'usine remplacé, sortie du bridge d'usine, `out` 192.36.253.20/24 (externe), `lan_site_b` 10.20.10.254/24 (interne), passerelle par défaut `gw_internet`
- Tunnel IPsec site à site entre MC-FW-B (192.36.253.20) et MC-FW-EXT (192.36.253.10) : IKEv2, profil StrongEncryption, authentification par clé partagée
- Périmètre du tunnel volontairement réduit : LAN du site B (10.20.10.0/24) vers la seule zone SERVEURS du siège (10.10.20.0/24)
- Filtrage du site B, politique `MediConnect-B` : administration, HTTPS et ping vers la zone SERVEURS, blocage final journalisé
- Pare-feu externe : deux règles ajoutées avant le blocage final, source `net_lan_site_b` acceptée uniquement « via IPsec VPN tunnel »
- pfSense, interface TRANSIT : site B autorisé vers `SERVEURS subnets` en HTTPS (443) et en ICMP echo request, journalisé

**Tests**

| Source | Destination | Résultat |
|---|---|---|
| Poste site B 10.20.10.2 | 10.10.20.254 (zone SERVEURS) | 4/5, premier paquet perdu pendant la négociation du tunnel |

**Points à retenir**
- Le tunnel transporte, le filtrage autorise : trois équipements à ouvrir pour un seul flux (pare-feu du site B, pare-feu externe, pare-feu interne)
- Sur Stormshield, la restriction au tunnel se règle dans Source, onglet Advanced properties, champ Via (et non dans la liste des interfaces)
- La clé partagée n'est stockée nulle part dans le dépôt

**Limite à mentionner dans le rapport**
- Authentification par clé partagée, suffisante pour la maquette ; en production, authentification par certificats

**Tests négatifs**

| Source | Destination | Résultat |
|---|---|---|
| Poste site B | 10.10.10.254 (LAN du siège) | 100 % de perte |
| Poste site B | 172.16.10.10 (DMZ) | 100 % de perte |

**Correction d'un écart avec le cadrage : zone DEMO**
- L'après-midi, la zone DEMO a été publiée sur Internet (adresse 192.36.253.13). C'est un écart : le cadrage prévoit que la DEMO n'est accessible qu'aux commerciaux, à travers le VPN d'accès distant (flux 8 de la matrice). Le sujet ne demande pas de l'exposer à tout Internet.
- Décision : publication retirée (règle de NAT, règle de filtrage et adresse publique supprimées). La DEMO reste isolée et sera ouverte au seul groupe Commerciaux lors de la mise en place du VPN SSL.
- Les captures 60 et 63 montrent l'état intermédiaire et ne sont pas à utiliser telles quelles dans le rapport. La capture 61 (isolement de la DEMO) reste valable.

**Serveur interne et flux applicatif dans le tunnel**
- `MC-SRV-INTERNE` : clone lié du modèle, zone SERVEURS, une adresse par application (CRM 10.10.20.20, comptabilité .30, support .40), un bloc nginx HTTPS par adresse. Ce découpage permettra de filtrer par groupe d'utilisateurs.
- Supervision du tunnel sur le pare-feu externe : IKE established (AES-256, SHA-256, PFS groupe 28), SA IPsec installed (AES-256, HMAC-SHA256)
- Depuis le poste du site B, les trois applications s'affichent en HTTPS à travers le tunnel

**État en fin de séance**
- Pare-feu externe : 9 règles de filtrage (dont 2 réservées au tunnel), 2 règles de NAT
- VM du projet : MC-FW-EXT, MC-FW-INT, MC-FW-B, MC-SRV-RELAIS, MC-SRV-APP, MC-SRV-DEMO, MC-SRV-INTERNE, MC-Client-LAN, MC-Client-B

**À faire ensuite**
- VPN SSL d'accès distant, annuaire, droits par groupe (CRM et DEMO pour les commerciaux, comptabilité, support)
- Restreindre l'accès du site B si tous ses utilisateurs n'ont pas besoin des trois applications
- Refaire la capture de l'onglet NAT (2 règles) pour le rapport

## 04/10/2026 (nuit) : VPN SSL d'accès distant et droits par groupe

**Fait**
- Annuaire dédié aux accès distants sur le pare-feu externe (`mediconnect.lab`), distinct de l'annuaire interne (ANSSI R10) : 4 utilisateurs de test, 4 groupes (commerciaux, comptabilite, support, administrateurs)
- Service VPN SSL : adresse publique 192.36.253.10, ports TCP 443 et UDP 1194, ressources `vpn_ressources` (zone SERVEURS et serveur DEMO), adresses des nomades dans 10.60.0.0/24 (moitié UDP, moitié TCP)
- Authentification : portail associé à l'interface `out`, politique LDAP pour les utilisateurs de `mediconnect.lab`
- Droits d'accès : VPN SSL refusé par défaut, autorisé explicitement
- Filtrage par identité sur le pare-feu externe, source « via SSL VPN tunnel » :

| N° | Groupe | Destination | Service |
|---|---|---|---|
| 9 | commerciaux | srv_crm, srv_demo | https |
| 10 | comptabilite | srv_compta | https |
| 11 | support | srv_support | https |
| 12 | (tous) | tout | blocage journalisé |

- pfSense, interface TRANSIT : adresses des nomades (10.60.0.0/24) autorisées vers la zone SERVEURS en HTTPS. Le pare-feu externe trie par identité, le pare-feu interne par réseau source.
- Profil OpenVPN exporté depuis l'administration du pare-feu (le portail de cette version ne le distribue pas), récupéré par le poste pendant qu'il était sur le LAN. Le fichier n'est pas versionné.

**Tests, poste nomade 192.36.253.100, utilisatrice lea.martin (commerciaux), adresse VPN 10.60.0.6**

| Destination | Attendu | Résultat |
|---|---|---|
| CRM https://10.10.20.20 | Autorisé | OK |
| DEMO https://172.16.30.10 | Autorisé | OK |
| Comptabilité https://10.10.20.30 | Refusé | Délai dépassé |
| Support https://10.10.20.40 | Refusé | Délai dépassé |

**Difficulté : « Access denied by UAC »**
- Symptôme : OpenVPN renvoie AUTH_FAILED alors que le même compte se connecte au portail.
- Méthode : le journal Users ne contenait aucune trace des tentatives VPN, le refus venait donc du service VPN. Le journal VPN donne la raison : « Error during authentication : Access denied by UAC ».
- Constat : le droit VPN SSL accordé au groupe `commerciaux` n'est pas pris en compte, alors que l'utilisatrice en est bien membre. Un droit accordé directement à `lea.martin` fonctionne.
- État : contournement par droit individuel pour lea.martin. À reprendre : comprendre pourquoi le droit de groupe n'est pas appliqué, ou accorder le droit VPN par utilisateur et garder les groupes pour le filtrage (qui, lui, reconnaît bien les groupes).

**Autres points**
- Zone DEMO injoignable au premier test : le serveur était resté en pause depuis 22 h. Rallumé, la page s'affiche.
- L'horloge du pare-feu externe retarde d'environ 5 heures : à corriger avant la phase journalisation.

**Suite, dimanche 04/10 après-midi**
- Droit VPN SSL accordé individuellement à marc.petit, ines.roux et paul.admin. Répartition retenue : le droit de se connecter au VPN est donné par utilisateur, le droit d'atteindre une application est donné par groupe dans le filtrage.
- Test croisé avec marc.petit (groupe comptabilite), même poste et même profil que lea.martin :

| Destination | lea.martin (commerciaux) | marc.petit (comptabilite) |
|---|---|---|
| CRM 10.10.20.20 | OK | Refusé |
| DEMO 172.16.30.10 | OK | Refusé |
| Comptabilité 10.10.20.30 | Refusé | OK |
| Support 10.10.20.40 | Refusé | non testé |

- Piège rencontré : une session OpenVPN restée active après la mise en pause de la VM. Une seconde session par-dessus échoue à poser ses routes (« route add command failed: File exists ») et rien ne charge. Toujours arrêter l'ancienne session (`sudo killall openvpn`) avant d'en ouvrir une autre.

**À faire ensuite**
- Groupe administrateurs : bastion et administration séparée
- MFA des médecins

## 04/10/2026 (soir) : bastion et administration séparée

**Objectif** : exigence du sujet, « un utilisateur connecté au LAN ne doit pas pouvoir administrer directement les équipements » ; ANSSI R16.

**Fait**
- `MC-SRV-ADMIN` : bastion dans la zone ADMIN (10.10.99.10), clone lié du modèle
- pfSense, interface ADMIN : le bastion est seul autorisé vers l'administration du pare-feu interne (443), du pare-feu externe (10.255.0.1:443) et vers le SSH de la zone SERVEURS
- Méthode d'administration : rebond SSH avec redirection dynamique (`ssh -D 1080 -N mcadmin@10.10.99.10`), le navigateur du poste d'administration utilise ce tunnel comme proxy SOCKS
- Pare-feu externe : seul `srv_bastion` figure dans les hôtes autorisés à l'administration ; règle de filtrage n° 1 réduite à cette source ; délai d'inactivité des sessions d'administration limité ; protection contre la force brute active
- Pare-feu interne : règle de secours « anti-lockout » désactivée ; sur l'interface LAN, dans l'ordre : poste d'administration (10.10.10.2) vers bastion en SSH autorisé, zone ADMIN interdite au LAN, administration du pare-feu interne interdite, administration du pare-feu externe interdite

**Ordre suivi pour ne pas se couper l'accès** : instantanés, ouverture et test du chemin par le bastion, bascule de la session d'administration sur ce chemin, puis fermeture de l'accès direct.

**Tests**

| Source | Destination | Résultat |
|---|---|---|
| Bastion | Administration des deux pare-feux | HTTP 200 |
| Poste d'administration via le bastion | https://10.255.0.1/admin et https://10.10.99.254 | OK, sessions vues depuis 10.10.99.10 |
| Poste du LAN, sans bastion | https://10.10.10.254, https://10.10.99.254, https://10.255.0.1/admin | Aucune réponse (code 000) |

**Preuves dans les journaux**
- Pare-feu externe, événements système : « Starting an administrative intervention (10.10.99.10) », la précédente venait de 10.10.10.2
- Pare-feu interne : session affichée comme `admin@10.10.99.10`

**Limites à mentionner**
- Authentification du bastion par mot de passe ; en production, clés SSH et second facteur, journalisation des sessions
- Les serveurs de la DMZ ne sont pas encore administrables depuis le bastion

**Administrateurs en VPN SSL**
- `srv_bastion` ajouté au groupe `vpn_ressources` ; règle de filtrage n° 12 : `administrateurs@mediconnect.lab`, via le tunnel VPN SSL, vers `srv_bastion` en SSH uniquement ; blocage final en n° 13
- pfSense, interface TRANSIT : 10.60.0.0/24 vers 10.10.99.10 en SSH
- Test : paul.admin connecté en VPN (10.60.0.6) ouvre une session SSH sur le bastion

**À faire ensuite**
- Synchroniser les horloges des pare-feux et des postes (décalées après les mises en pause)
- MFA des médecins

## 05/10/2026 : authentification à deux facteurs des médecins

**Objectif** : le sujet demande pour les médecins un accès distinct de celui des patients, avec un niveau de sécurité supérieur et une MFA.

**Fait**
- Portail d'authentification `mc-mfa` installé sur le serveur relais, devant `/pro/` : mot de passe et code TOTP (RFC 6238, 6 chiffres, 30 secondes)
- nginx : directive `auth_request` avant toute requête vers l'espace professionnel ; sans session valide, redirection vers la page de connexion
- Base d'utilisateurs locale à la DMZ, sans appel à un annuaire interne (ANSSI R10)
- Service sous un compte dédié `mcmfa`, système de fichiers en lecture seule (durcissement systemd)
- Mesures intégrées : empreinte PBKDF2-SHA256 salée des mots de passe, cookie de session signé (`Secure`, `HttpOnly`, `SameSite=Strict`, 15 minutes), blocage 5 minutes après 5 échecs, refus du rejeu d'un code, message d'erreur identique que l'identifiant existe ou non, journal des tentatives sans mot de passe ni code
- Médecin de test `dr.dupont`, second facteur dans une application d'authentification sur téléphone

**Vérifications avant déploiement**
- Calcul TOTP conforme aux vecteurs de test de la RFC 6238
- Scénarios testés hors maquette : code valide, code faux, mot de passe faux, rejeu, blocage, cookie falsifié

**Tests depuis Internet (poste 192.36.253.100)**

| Essai | Résultat |
|---|---|
| https://192.36.253.12 sans session | Redirection vers le portail de connexion |
| Bon mot de passe, code faux | Refusé |
| Bon mot de passe, code du téléphone | Espace professionnel affiché |
| https://192.36.253.11 (patients) | Accessible sans authentification |

**Difficultés et leçons**
- Déploiement : le relais est injoignable depuis l'hôte (DMZ). Carte basculée temporairement en NAT avec une adresse provisoire, puis rebranchée sur la DMZ.
- Horloge : le serveur avait plus d'un jour de retard après les mises en pause. Le TOTP dépend de l'heure, l'horloge a été remise à l'heure avant l'enrôlement. En production : synchronisation NTP obligatoire.
- Secret TOTP affiché par erreur hors du serveur pendant l'enrôlement : un secret exposé se remplace, il ne se « protège » pas après coup.

**Limites à mentionner**
- Service minimal écrit pour la maquette ; en production, fournisseur d'identité éprouvé et clés matérielles FIDO2
- Compteurs d'échecs en mémoire, remis à zéro au redémarrage du service
- Pas encore de synchronisation d'heure automatique dans la maquette

**À faire ensuite**
- Remise à l'heure des pare-feux, IPS et journalisation centralisée
