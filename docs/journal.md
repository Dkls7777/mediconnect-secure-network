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
