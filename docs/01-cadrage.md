# Projet MediConnect : cadrage (étape 1)

Sujet : S. Benayoune, sécurité des réseaux. Rendu Moodle le 31/10/2026 (rapport + vidéo ~15 min). Monôme. PC hôte : 16 Go de RAM.
Référentiel : ANSSI PA-066 v3 (interconnexion d'un SI à Internet).

## Choix structurants

| Décision | Choix | Justification |
|---|---|---|
| Pare-feu externe siège | Stormshield SNS EVA (FW-EXT) | Outil du cours, porte VPN SSL, IPsec, IPS, règles par utilisateur |
| Pare-feu interne siège | pfSense (FW-INT) | R3 + R13 : externe et interne physiquement distincts ; diversité technologique (guide PA-044) |
| Pare-feu site secondaire | Stormshield SNS EVA (FW-B) | R14 : passerelles homogènes ; IPsec SNS vers SNS plus simple à démontrer |
| Pare-feu intermédiaire (R5) | Porté par FW-INT sur une interface dédiée (SRV-APP) | Économie de RAM ; limite documentée (R13 ne vise que externe/interne) |
| Patients / médecins | Deux reverse proxies distincts, deux IP publiques | R6 : chaînes séparées ; médecins en HTTPS + MFA, sans VPN |
| MFA médecins | Portail d'authentification TOTP en DMZ avec base d'utilisateurs locale | R10 : aucun annuaire interne interrogé depuis la DMZ |
| Nomades (télétravail, commerciaux) | VPN SSL Stormshield + groupes de l'annuaire | Règles basées sur l'identité |
| Inter-sites | IPsec site à site FW-EXT <-> FW-B | R15 et §2.5 |
| Routage | Statique partout | R19 |
| Politique externe | Block all, DROP silencieux | R20 |

## Besoins d'interconnexion (R1)

| Service | Sens | Qui |
|---|---|---|
| Portail patients HTTPS | Entrant | Internet |
| Espace médecins HTTPS + MFA | Entrant | Médecins (Internet) |
| VPN SSL d'accès distant | Entrant | Télétravailleurs, commerciaux, admins d'astreinte |
| IPsec site à site | Entrant / sortant | FW-B uniquement |
| Démonstration (zone DEMO) | Entrant via VPN | Commerciaux |
| Résolution DNS publique | Sortant | Relais de la DMZ uniquement |
| Mises à jour / navigation | Sortant | LAN via proxy (optionnel, sinon limite) |

## Zones et niveaux de confiance

| Zone | Réseau | Passerelle | Confiance | Contenu |
|---|---|---|---|---|
| INTERNET | 192.36.253.0/24 | .1 (NAT VirtualBox) | Nulle | Clients patients, médecins, nomades |
| DMZ-RELAIS | 172.16.10.0/24 | FW-EXT .254 | Faible, perdable | RP patients .10, RP médecins + MFA .11, résolveur DNS public .53 |
| DEMO | 172.16.30.0/24 | FW-EXT .254 | Faible, isolée | Copie de la plateforme, données fictives .10 |
| TRANSIT | 10.255.0.0/30 | FW-EXT .1 / FW-INT .2 | Lien de filtrage | Aucun hôte |
| VPN-NOMADES | 10.60.0.0/24 | FW-EXT | Moyenne (authentifié) | Pool VPN SSL |
| SRV-APP | 172.16.20.0/24 | FW-INT .254 | Moyenne | Application MediConnect .10 |
| LAN-SIEGE | 10.10.10.0/24 | FW-INT .254 | Élevée | Postes employés (client .2) |
| SERVEURS | 10.10.20.0/24 | FW-INT .254 | Élevée | Annuaire/RADIUS .10, CRM .20, compta .30, support .40, DNS interne .53 |
| ADMIN | 10.10.99.0/24 | FW-INT .254 | Maximale | Bastion .10, collecteur de journaux .20 |
| LAN-SITE-B | 10.20.10.0/24 | FW-B .254 | Élevée | Postes site B (client .2) |

Adresses publiques (NatNetwork) : FW-EXT .10 (VPN SSL, IPsec), .11 publication RP patients, .12 publication RP médecins, FW-B .20, client « Internet » .100.

## Matrice des flux (version 1)

| # | Source | Destination | Service | Action | Sur | Réf. ANSSI |
|---|---|---|---|---|---|---|
| 1 | Internet | 192.36.253.11 -> RP patients | HTTPS 443 | Pass + IPS | FW-EXT | R6, R8 |
| 2 | Internet | 192.36.253.12 -> RP médecins | HTTPS 443 | Pass + IPS | FW-EXT | R6, R8 |
| 3 | Internet | FW-EXT .10 | HTTP 80 | Redirection HTTPS ou refus | FW-EXT | HTTPS exclusif |
| 4 | FW-B .20 | FW-EXT .10 | IKE 500/4500, ESP | Pass | FW-EXT | §2.5 |
| 5 | Internet | FW-EXT .10 | VPN SSL | Pass (authentification) | FW-EXT | nomadisme |
| 6 | RP .10 / .11 | SRV-APP .10 | HTTPS 8443 | Pass | FW-EXT puis FW-INT | R5 |
| 7 | RP | Résolveur public .53 | DNS | Pass | local DMZ | §2.4.6 |
| 8 | VPN groupe commerciaux | CRM .20 + DEMO .10 | HTTPS | Pass | FW-EXT (identité) + FW-INT | identité |
| 9 | VPN groupe support | Support .40 | HTTPS | Pass | idem | identité |
| 10 | VPN groupe compta | Compta .30 | HTTPS | Pass | idem | identité |
| 11 | VPN groupe employés | Ressources bureautiques | selon service | Pass | idem | identité |
| 12 | VPN groupe admins | Bastion .10 uniquement | SSH 22 / HTTPS | Pass | idem | R16 |
| 13 | LAN-SIEGE, LAN-SITE-B | SERVEURS | services métier | Pass | FW-INT | cloisonnement |
| 14 | LAN-SITE-B | SERVEURS | via IPsec | Pass | FW-B, FW-EXT, FW-INT | §2.5 |
| 15 | Bastion .10 | Interfaces d'admin FW-EXT, FW-INT, FW-B, serveurs | HTTPS admin, SSH | Pass | tous | R16 |
| 16 | Tous équipements | Collecteur .20 | Syslog | Pass | FW-INT | R26 |
| 17 | LAN, VPN (hors admins) | Interfaces d'admin | tout | Block + log | tous | R16 |
| 18 | DMZ-RELAIS, DEMO, SRV-APP | SI interne | tout | Block + log | FW-EXT, FW-INT | R7 |
| 19 | SI interne | DNS Internet | DNS 53 | Block + log | FW-INT | §2.4.6 |
| 20 | any | any | any | Block (DROP côté Internet) | tous | R20 |

## Inventaire des VM et budget RAM (hôte 16 Go)

| VM | Rôle | Interfaces | RAM |
|---|---|---|---|
| FW-EXT (SNS EVA) | Pare-feu externe siège | OUT, DMZ-RELAIS, DEMO, TRANSIT | 1 Go |
| FW-INT (pfSense) | Pare-feu interne + intermédiaire | TRANSIT, SRV-APP, LAN-SIEGE, SERVEURS, ADMIN (5e carte via VBoxManage) | 1 Go |
| FW-B (SNS EVA) | Pare-feu site B | OUT, LAN-SITE-B | 1 Go |
| SRV-RELAIS | RP patients, RP médecins + MFA, DNS public (conteneurs) | DMZ-RELAIS | 1 Go |
| SRV-DEMO | Plateforme de démo | DEMO | 512 Mo |
| SRV-APP | Application MediConnect | SRV-APP | 512 Mo |
| SRV-INTERNE | Annuaire/RADIUS, CRM, compta, support, DNS interne (conteneurs) | SERVEURS | 1 Go |
| SRV-ADMIN | Bastion + collecteur de journaux | ADMIN | 1,5 Go |
| CLIENT-LAN | Poste employé siège | LAN-SIEGE | 512 Mo |
| CLIENT-B | Poste site B | LAN-SITE-B | 512 Mo |
| CLIENT-EXT | Patient / médecin / nomade | OUT | 512 Mo |

Total environ 9 Go si tout tourne. On démarre par blocs selon le test.

## Planning

| Semaine | Travail |
|---|---|
| 15 au 21/09 | Cadrage (ce document) + création des VM et réseaux internes |
| 22 au 28/09 | Interfaces, routage statique, DMZ, reverse proxies, DEMO |
| 29/09 au 05/10 | IPsec site à site, annuaire, VPN SSL, règles par groupe, MFA |
| 06 au 12/10 | Administration séparée, IPS/contrôle applicatif, journalisation |
| 13 au 19/10 | Campagne de tests + captures |
| 20 au 26/10 | Rapport + vidéo |
| 27 au 31/10 | Marge, dépôt Moodle |

## Limites déjà identifiées (pour le rapport)

- Commutation mutualisée par VirtualBox (R12-).
- FW-INT cumule les rôles interne et intermédiaire.
- Relais multiples sur une même VM (R11).
- Données de santé : PA-066 nécessaire mais pas suffisant (RGPD, hébergement HDS).
- Pas de redondance d'accès ni d'anti-DDoS (R17, R18).

## Correspondance avec les VM existantes (15/09)

Principe : les VM du cours (CSNx-*) restent intactes pour les labs suivants. Le projet utilise des VM préfixées `MC-` et un réseau NAT dédié `NatMediConnect` (192.36.253.0/24, DHCP désactivé).

| VM projet | Source | Remarque |
|---|---|---|
| MC-FW-EXT | 1re réimportation de l'OVA CSNx | em0 = NatMediConnect, em1 (in) = mc_transit, em2 (dmz1) = mc_dmz_relais, em3 (dmz2) = mc_demo |
| MC-Client-LAN | 1re réimportation de l'OVA CSNx | mc_lan_siege |
| MC-FW-B | 2e réimportation de l'OVA CSNx | em0 = NatMediConnect, em1 = mc_lan_site_b |
| MC-Client-B | 2e réimportation de l'OVA CSNx | mc_lan_site_b |
| MC-FW-INT | Clone complet de `pfSense`, remis en configuration d'usine | WAN = mc_transit, LAN = mc_lan_siege, OPT1 = mc_srv_app, OPT2 = mc_serveurs, OPT3 = mc_admin (5e carte via VBoxManage) |
| MC-DEB-TEMPLATE | Debian 13 netinst, sans bureau | Modèle cloné en MC-SRV-RELAIS, MC-SRV-APP, MC-SRV-DEMO, MC-SRV-INTERNE, MC-SRV-ADMIN |
| kali-linux | Existante | CLIENT-EXT (patient, médecin, nomade, tests d'attaque), sur NatMediConnect |

Non utilisées : Metas, Ubuntu-lab, GNS3 VM, pfSense2-SiteB, serveurs CSNx.
Les serveurs gardent une carte NAT le temps d'installer leurs paquets, puis basculent sur leur réseau interne.
