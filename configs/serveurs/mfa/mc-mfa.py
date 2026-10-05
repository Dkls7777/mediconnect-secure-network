#!/usr/bin/env python3
# MediConnect - portail d'authentification a deux facteurs de l'espace medecins.
# Mot de passe + code TOTP (RFC 6238). Bibliotheque standard uniquement.
# Base d'utilisateurs locale a la DMZ : aucun annuaire interne n'est interroge (ANSSI R10).
#
#   sudo mc-mfa adduser <identifiant>   cree ou remplace un medecin, affiche son secret TOTP
#   sudo mc-mfa list                    liste les identifiants
#   sudo mc-mfa code <identifiant>      affiche le code courant (maquette uniquement)
#   mc-mfa serve                        lance le service (appele par systemd)
import base64, getpass, hashlib, hmac, html, json, os, secrets, struct, sys, time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, quote

BASE = os.environ.get("MC_MFA_DIR", "/etc/mediconnect/mfa")
USERS = os.path.join(BASE, "users.json")
KEYFILE = os.path.join(BASE, "secret.key")
LOGFILE = os.environ.get("MC_MFA_LOG", "/var/log/mediconnect/mfa.log")
LISTEN = ("127.0.0.1", int(os.environ.get("MC_MFA_PORT", "9000")))
COOKIE = "mc_pro_session"
SESSION_TTL = 15 * 60        # duree d'une session, en secondes
MAX_FAILS = 5                # echecs avant blocage
LOCK_TIME = 5 * 60           # duree du blocage, en secondes
PBKDF2_ROUNDS = 200_000

fails = {}       # (identifiant, adresse) -> [nombre d'echecs, fin du blocage]
last_step = {}   # identifiant -> dernier pas TOTP accepte (anti-rejeu)


def log(event, user, ip, detail=""):
    line = "%s %s user=%s ip=%s %s" % (time.strftime("%Y-%m-%d %H:%M:%S"), event, user or "-", ip or "-", detail)
    print(line.strip(), flush=True)
    try:
        with open(LOGFILE, "a") as f:
            f.write(line.strip() + "\n")
    except OSError:
        pass


def load_users():
    try:
        with open(USERS) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {}


def save_users(users):
    os.makedirs(BASE, exist_ok=True)
    tmp = USERS + ".tmp"
    with open(os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "w") as f:
        json.dump(users, f, indent=1)
    try:  # lance par root (sudo), le fichier doit rester lisible par le compte du service
        owner = os.stat(BASE)
        os.chown(tmp, owner.st_uid, owner.st_gid)
    except OSError:
        pass
    os.replace(tmp, USERS)


def server_key():
    with open(KEYFILE, "rb") as f:
        return f.read()


def hash_password(password, salt):
    return hashlib.pbkdf2_hmac("sha256", password.encode(), salt, PBKDF2_ROUNDS).hex()


def totp(secret_b32, step):
    key = base64.b32decode(secret_b32, casefold=True)
    digest = hmac.new(key, struct.pack(">Q", step), hashlib.sha1).digest()
    offset = digest[-1] & 0x0F
    number = struct.unpack(">I", digest[offset:offset + 4])[0] & 0x7FFFFFFF
    return "%06d" % (number % 1_000_000)


def check_totp(user, secret_b32, code):
    """Accepte le pas courant et ses deux voisins (30 s de derive), jamais deux fois le meme pas."""
    now = int(time.time()) // 30
    for step in (now, now - 1, now + 1):
        if hmac.compare_digest(totp(secret_b32, step), code):
            if last_step.get(user, 0) >= step:
                return False
            last_step[user] = step
            return True
    return False


def make_cookie(user):
    expiry = str(int(time.time()) + SESSION_TTL)
    payload = base64.urlsafe_b64encode(user.encode()).decode() + "." + expiry
    sig = hmac.new(server_key(), payload.encode(), hashlib.sha256).hexdigest()
    return payload + "." + sig


def read_cookie(header):
    for part in (header or "").split(";"):
        name, _, value = part.strip().partition("=")
        if name != COOKIE:
            continue
        try:
            b64user, expiry, sig = value.split(".")
            payload = b64user + "." + expiry
            good = hmac.new(server_key(), payload.encode(), hashlib.sha256).hexdigest()
            if hmac.compare_digest(good, sig) and int(expiry) > time.time():
                return base64.urlsafe_b64decode(b64user).decode()
        except (ValueError, OSError):
            pass
    return None


PAGE = """<!doctype html>
<html lang="fr"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>MediConnect Pro - Authentification</title><style>
body{margin:0;font-family:system-ui,Segoe UI,Arial,sans-serif;background:#f4f7fb;color:#12263a}
header{background:#0b6b57;color:#fff;padding:18px 32px;display:flex;justify-content:space-between;align-items:center}
header b{font-size:22px}main{max-width:420px;margin:48px auto;padding:0 20px}
.card{background:#fff;border-radius:10px;padding:28px;box-shadow:0 1px 4px rgba(0,0,0,.08)}
label{display:block;margin:14px 0 6px;font-weight:600}
input{width:100%%;box-sizing:border-box;padding:10px;border:1px solid #c5d0dc;border-radius:6px;font-size:16px}
button{margin-top:20px;width:100%%;padding:12px;border:0;border-radius:6px;background:#0b6b57;color:#fff;font-size:16px;cursor:pointer}
.err{background:#fde8e8;color:#9b1c1c;padding:10px 12px;border-radius:6px;margin-bottom:8px}
.note{color:#6b7c8f;font-size:13px;margin-top:16px}footer{text-align:center;color:#6b7c8f;font-size:13px;padding:24px}
</style></head><body>
<header><b>MediConnect Pro</b><span>Authentification renforcee</span></header>
<main><div class="card"><h1>Connexion</h1>%(error)s
<form method="post" action="/mfa/login" autocomplete="off">
<label for="u">Identifiant</label><input id="u" name="username" required autofocus>
<label for="p">Mot de passe</label><input id="p" name="password" type="password" required>
<label for="c">Code a usage unique (6 chiffres)</label><input id="c" name="code" inputmode="numeric" pattern="[0-9]{6}" maxlength="6" required>
<button type="submit">Se connecter</button></form>
<p class="note">Deux facteurs sont exiges : votre mot de passe et le code affiche par votre application d'authentification.</p>
</div></main><footer>Espace reserve aux professionnels de sante. Maquette de projet (EFREI).</footer></body></html>"""


class Handler(BaseHTTPRequestHandler):
    server_version = "mc-mfa"
    sys_version = ""

    def log_message(self, *args):
        pass

    def client_ip(self):
        return self.headers.get("X-Real-IP") or self.client_address[0]

    def reply(self, code, body=b"", headers=()):
        self.send_response(code)
        for name, value in headers:
            self.send_header(name, value)
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(body)

    def page(self, error="", code=200):
        box = '<div class="err">%s</div>' % html.escape(error) if error else ""
        self.reply(code, (PAGE % {"error": box}).encode(), [("Content-Type", "text/html; charset=utf-8")])

    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/mfa/check":
            user = read_cookie(self.headers.get("Cookie"))
            if user:
                self.reply(204, headers=[("X-MC-User", user)])
            else:
                self.reply(401)
        elif path == "/mfa/login":
            self.page()
        elif path == "/mfa/logout":
            user = read_cookie(self.headers.get("Cookie"))
            if user:
                log("LOGOUT", user, self.client_ip())
            self.reply(302, headers=[("Location", "/mfa/login"),
                                     ("Set-Cookie", COOKIE + "=; Path=/; Max-Age=0; Secure; HttpOnly; SameSite=Strict")])
        else:
            self.reply(404)

    do_HEAD = do_GET

    def do_POST(self):
        if self.path.split("?")[0] != "/mfa/login":
            return self.reply(404)
        length = min(int(self.headers.get("Content-Length") or 0), 4096)
        form = parse_qs(self.rfile.read(length).decode("utf-8", "replace"))
        user = (form.get("username") or [""])[0].strip().lower()[:64]
        password = (form.get("password") or [""])[0]
        code = (form.get("code") or [""])[0].strip()
        ip = self.client_ip()
        key = (user, ip)
        count, locked_until = fails.get(key, [0, 0])
        if locked_until > time.time():
            log("LOGIN_BLOCKED", user, ip, "compte temporairement bloque")
            return self.page("Trop de tentatives. Reessayez dans quelques minutes.", 429)

        record = load_users().get(user)
        # Meme message et meme travail de calcul que l'identifiant existe ou non.
        salt = bytes.fromhex(record["salt"]) if record else b"\0" * 16
        password_ok = hmac.compare_digest(hash_password(password, salt), record["hash"] if record else "")
        code_ok = bool(record) and password_ok and check_totp(user, record["totp"], code)
        if code_ok:
            fails.pop(key, None)
            log("LOGIN_OK", user, ip, "mot de passe et code TOTP valides")
            cookie = "%s=%s; Path=/; Max-Age=%d; Secure; HttpOnly; SameSite=Strict" % (COOKIE, make_cookie(user), SESSION_TTL)
            return self.reply(302, headers=[("Location", "/pro/"), ("Set-Cookie", cookie)])

        count += 1
        reason = "identifiant inconnu" if not record else ("mot de passe invalide" if not password_ok else "code TOTP invalide")
        if count >= MAX_FAILS:
            fails[key] = [0, time.time() + LOCK_TIME]
            log("LOGIN_FAIL", user, ip, reason + ", blocage %d s" % LOCK_TIME)
        else:
            fails[key] = [count, 0]
            log("LOGIN_FAIL", user, ip, reason)
        self.page("Identifiant, mot de passe ou code incorrect.", 401)


def cmd_adduser(user):
    user = user.strip().lower()
    if sys.stdin.isatty():
        password = getpass.getpass("Mot de passe pour %s : " % user)
        if password != getpass.getpass("Confirmation : "):
            sys.exit("Les deux saisies different.")
    else:
        password = sys.stdin.readline().rstrip("\n")
    if len(password) < 8:
        sys.exit("Mot de passe trop court (8 caracteres minimum).")
    salt = secrets.token_bytes(16)
    secret = base64.b32encode(secrets.token_bytes(20)).decode()
    users = load_users()
    users[user] = {"salt": salt.hex(), "hash": hash_password(password, salt), "totp": secret}
    save_users(users)
    print()
    print("Medecin enregistre :", user)
    print("Secret TOTP        :", " ".join(secret[i:i + 4] for i in range(0, len(secret), 4)))
    print("Lien otpauth       : otpauth://totp/%s?secret=%s&issuer=%s" % (quote("MediConnect Pro:" + user), secret, quote("MediConnect Pro")))
    print()
    print("A saisir une seule fois dans l'application d'authentification du medecin")
    print("(type : base sur l'heure, 6 chiffres, 30 secondes). Ne jamais versionner ce secret.")


def main():
    args = sys.argv[1:]
    if args[:1] == ["serve"]:
        log("START", None, None, "ecoute sur %s:%d" % LISTEN)
        ThreadingHTTPServer(LISTEN, Handler).serve_forever()
    elif args[:1] == ["adduser"] and len(args) == 2:
        cmd_adduser(args[1])
    elif args[:1] == ["list"]:
        print("\n".join(sorted(load_users())) or "(aucun medecin)")
    elif args[:1] == ["code"] and len(args) == 2:
        record = load_users().get(args[1].lower())
        if not record:
            sys.exit("Identifiant inconnu.")
        left = 30 - int(time.time()) % 30
        print("%s  (valable encore %d s, aide de maquette : en production seul le telephone du medecin connait ce code)" % (totp(record["totp"], int(time.time()) // 30), left))
    else:
        sys.exit(__doc__ or "Usage : mc-mfa serve | adduser <id> | list | code <id>")


if __name__ == "__main__":
    main()
