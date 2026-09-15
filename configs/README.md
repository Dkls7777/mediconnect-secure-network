# Configurations

Ce dossier contient des exports **nettoyés** des équipements, pour documenter la configuration.

## Règles avant tout commit

- Pas de sauvegarde brute Stormshield (`.na`) : elle contient des secrets. Exporter plutôt des captures ou des extraits de règles.
- pfSense : retirer de `config.xml` les hachages de mots de passe (`bcrypt-hash`), les clés (`prv`), les certificats et les secrets de tunnel avant de le versionner.
- Pas de clé privée, certificat, profil VPN (`.ovpn`) ni fichier `.env`.
- Vérifier avec `git diff --cached` avant chaque commit.
