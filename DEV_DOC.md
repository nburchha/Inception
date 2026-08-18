# Developer Documentation

How to set up, build, and manage the Inception infrastructure from scratch.

## 1. Prerequisites
On the VM: `docker`, `docker compose` (plugin), `make`.

## 2. Host setup
Map the project domain to localhost:
```bash
sudo sh -c 'echo "127.0.0.1 <login>.42.fr" >> /etc/hosts'
```

## 3. Secrets: the `.env` file
Copy the template and fill in real values — this is the only place credentials live:
```bash
cp env_default.txt srcs/.env
```
Required keys (see `env_default.txt`): `DOMAIN`, `WP_DB_NAME`, `WP_DB_USER`,
`WP_DB_PASSWORD`, `WP_DB_HOST`, `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_PASSWORD`,
`WP_ADMIN_EMAIL`, `WP_USER`, `WP_USER_EMAIL`, `WP_USER_PASSWORD`, `FTP_USER`,
`FTP_PASSWORD`, and the volume paths `DATABASE_VOLUME_PATH`, `WEB_VOLUME_PATH`,
`GATUS_VOLUME_PATH` (default `/home/<login>/data/{database,web,gatus}`).
`WP_ADMIN_USER` must not contain `admin`/`administrator` in any casing.
`.env` is git-ignored; never commit real credentials.

## 4. Build and launch
```bash
make
```
This creates the host volume directories and runs, under the hood:
```bash
docker compose -f srcs/docker-compose.yml up --build -d --wait
```
Each service has its own Dockerfile under `srcs/requirements/<service>/`, built from
Debian bullseye or Alpine (never `latest`). Images are never pulled pre-built.

## 5. Container and volume management
| Task | Command |
|---|---|
| Check status | `make status` (or `docker compose -f srcs/docker-compose.yml ps`) |
| View logs | `docker logs <container>` (e.g. `docker logs nginx`) |
| Shell into a container | `docker exec -it <container> sh` |
| Stop (keep data) | `make down` |
| Run automated checks | `make test` / `make test-full` (`tests/run.sh`) |
| Remove containers/images/networks | `make clean` |
| Full reset (also volumes + host data) | `make fclean` |

## 6. Data storage and persistence
Persistent data lives on two Docker **named volumes**, defined in
`srcs/docker-compose.yml` with `driver_opts: {type: none, o: bind}` so they are
pinned to host paths under `/home/<login>/data/` (bind mounts are not used):
- `database` → MariaDB's `/var/lib/mysql`, host path `$DATABASE_VOLUME_PATH`.
- `web` → WordPress files (and the FTP/NGINX mount point), host path `$WEB_VOLUME_PATH`.
- `gatus_data` (bonus) → Gatus's SQLite state, host path `$GATUS_VOLUME_PATH`.

Because the volumes are bound to real host directories, data survives
`docker compose down`, container recreation, and even a VM reboot, as long as those
host directories aren't deleted (`make fclean` does delete them, on purpose).
