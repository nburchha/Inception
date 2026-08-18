*This project has been created as part of the 42 curriculum by nburchha.*

## Description
Inception is a system administration project built around Docker. It sets up a small
web infrastructure — NGINX, WordPress with php-fpm, and MariaDB — each running in its
own container, orchestrated with Docker Compose and connected through a custom Docker
network. On top of the mandatory stack, five bonus services are included: `redis`
(WordPress object cache), `ftp` (access to the WordPress volume), `static_site` (a
static portfolio page), `adminer` (a lightweight DB admin UI), and `gatus`, a custom
status-page service that continuously health-checks every other container and shows
their status at a glance — chosen because a multi-container stack needs a single place
to see "is everything actually up", which none of the other bonus services provide.

**Main design choices:**
- **Containerization:** every service runs in its own container, built from a
  Dockerfile (`penultimate stable` Debian bullseye or Alpine, no `latest` tags).
- **Orchestration:** `docker compose` builds, links, and manages the lifecycle of all
  containers via `srcs/docker-compose.yml`, driven by the root `Makefile`.
- **Secrets:** no credentials are hardcoded; all sensitive values are injected via a
  `.env` file (see `env_default.txt` for the required keys).
- **Persistence:** WordPress files and the MariaDB database are stored on Docker
  **named volumes** (`web`, `database`) that are bound to `/home/<login>/data/` on the
  host, so data survives container/volume recreation.

**Comparisons:**
- **Virtual Machines vs Docker:** VMs virtualize hardware and run a full guest OS —
  heavy and slow to boot. Docker containers share the host kernel and only isolate
  processes, making them lightweight, fast to start, and resource-efficient.
- **Secrets vs Environment Variables:** Docker secrets are encrypted and mounted only
  into the containers that need them, ideal for real production Swarm secrets.
  Environment variables (used here, via `.env`) are simpler for local dev but can leak
  through `docker inspect` or logs, so `.env` is kept out of version control.
- **Docker Network vs Host Network:** the custom `inception` bridge network lets
  containers reach each other by service name (`mariadb`, `wordpress`, ...) while
  staying isolated from the host. `network: host` removes that isolation, sharing the
  host's network stack directly — forbidden by the subject.
- **Docker Volumes vs Bind Mounts:** named volumes are managed by Docker and portable
  across hosts; here they're additionally pinned to a host path via `driver_opts`
  (`type: none, o: bind`) to satisfy the "data must live under `/home/<login>/data`"
  requirement while still being real named volumes, not raw bind mounts.

## Instructions
1. Install Docker and Docker Compose on your VM.
2. Point your domain at localhost: add `127.0.0.1 <login>.42.fr` to `/etc/hosts`.
3. Copy `env_default.txt` to `srcs/.env` and fill in the values (DB/WP credentials,
   `DOMAIN`, volume paths, ...).
4. Build and start everything from the repo root:
   ```bash
   make
   ```
   This creates the host data directories and runs
   `docker compose -f srcs/docker-compose.yml up --build -d --wait`.
5. Visit `https://<login>.42.fr` (accept the self-signed certificate).

Other targets: `make down`, `make status`, `make logs`, `make clean`, `make fclean`,
`make test` / `make test-full` (see `tests/`). Details: [USER_DOC.md](USER_DOC.md) for
day-to-day use, [DEV_DOC.md](DEV_DOC.md) for full setup from scratch.

## Resources
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress CLI (wp-cli)](https://developer.wordpress.org/cli/commands/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [Gatus](https://github.com/TwiN/gatus)

**AI usage:** AI was used to draft NGINX/Dockerfile configuration templates, explain
`docker-compose.yml` syntax, help debug container startup/health-check issues, and
structure this documentation. All generated content was reviewed and adapted by hand
before being committed. Further AI helped create the bash testing suite.
