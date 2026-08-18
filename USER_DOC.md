# User Documentation

A short guide for end users and administrators of the Inception stack.

## Provided services
- **NGINX** — reverse proxy, the only entrypoint, HTTPS only (port 443).
- **WordPress (php-fpm)** — the website itself.
- **MariaDB** — the WordPress database.
- **Bonus:** `redis` (cache), `ftp` (file access to the site), `static_site` (a small
  static page, served at `/static/`), `adminer` (DB admin UI, port 8080), `gatus`
  (status dashboard for all services, at `https://gatus.<login>.42.fr`).

## Starting and stopping
Run from the repository root:
```bash
make        # build and start everything (alias: make all)
make down   # stop the containers, keep all data
```

## Accessing the website and admin panel
- **Website:** `https://<login>.42.fr`
- **WordPress admin:** `https://<login>.42.fr/wp-admin`
- **Adminer:** `http://<login>.42.fr:8080`
- **Status page:** `https://gatus.<login>.42.fr`

Your browser will warn about the self-signed certificate — accept it to continue.

## Locating and managing credentials
All credentials live in `srcs/.env` (copy `env_default.txt` to create it, then fill in
the values). Nothing is hardcoded in the source. To change a password, edit `.env` and
restart with `make down && make`. **Never commit `.env`.**

## Checking service status
```bash
make status
```
Lists all containers with their state (Up/Exited) and ports.