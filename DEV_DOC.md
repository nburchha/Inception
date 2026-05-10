# Developer Documentation

This document explains how to configure, build, and manage the Inception project infrastructure from a developer's perspective.

## Setting Up the Environment from Scratch

### 1. Prerequisites
Ensure the host machine (typically a Debian or Ubuntu Virtual Machine) has the following installed:
- `docker`
- `docker-compose` (or the `docker compose` plugin)
- `make`

### 2. Configuration Files & Host Setup
To allow the project to resolve the custom domain locally, you must add an entry to the host's DNS resolution file:
```bash
sudo nano /etc/hosts
# Add the following line:
127.0.0.1 nburchha.42.fr
```

### 3. Persistent Data Directories
Before launching the containers, you must manually create the host directories that will be bound to the Docker volumes to ensure data persistence:
```bash
sudo mkdir -p /home/nburchha/data/wordpress
sudo mkdir -p /home/nburchha/data/mariadb
```

### 4. Secrets and `.env` File
Create a `.env` file in the `srcs/` directory. This file is critical as Docker Compose relies on it to pass secrets to the containers. 
Example of required variables (adjust values as needed):
```env
DOMAIN_NAME=nburchha.42.fr

MYSQL_ROOT_PASSWORD=strong_root_password
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
MYSQL_PASSWORD=wp_password

WP_ADMIN_USER=wp_admin
WP_ADMIN_PASSWORD=admin_password
WP_ADMIN_EMAIL=admin@nburchha.42.fr

WP_USER=author
WP_USER_PASSWORD=author_password
WP_USER_EMAIL=author@nburchha.42.fr
```

## Building and Launching the Project

The root directory contains a `Makefile` that simplifies Docker Compose operations. 
To build the Docker images from the provided Dockerfiles and launch the containers in detached mode, run:
```bash
make
```
Under the hood, this executes `cd srcs && docker compose up -d --build`. The `--build` flag ensures that any changes made to the `Dockerfile`s or configurations are applied.

## Container and Volume Management

Here are the relevant commands to manage the infrastructure:

- **Check container status:**
  ```bash
  make status
  # OR: docker ps
  ```
- **Stop containers (without deleting data):**
  ```bash
  make down
  ```
- **View logs for a specific service (useful for debugging):**
  ```bash
  docker logs <container_name>  # e.g., docker logs nginx
  ```
- **Execute a shell inside a running container:**
  ```bash
  docker exec -it <container_name> sh  # e.g., docker exec -it mariadb sh
  ```
- **Clean the environment (stop containers, remove images, and prune networks):**
  ```bash
  make clean
  ```
- **Deep Clean (Removes EVERYTHING, including Docker volumes and the local host data directories):**
  ```bash
  make fclean
  ```

## Data Storage and Persistence

Data persistence is handled via Docker Volumes mapped to specific paths on the host file system.
- **Mechanism:** The `docker-compose.yml` file uses named volumes. However, under the `volumes:` configuration, these named volumes are explicitly bound to local host directories utilizing the `device` parameter with the `local` driver.
- **Database Data:** MariaDB stores its database files inside the container at `/var/lib/mysql`. This is mapped to the host at `/home/nburchha/data/mariadb`.
- **Website Data:** WordPress stores its application files and downloaded media in `/var/www/wordpress`. This is mapped to the host at `/home/nburchha/data/wordpress`.

Because the data is written directly to the host machine's `/home/nburchha/data/` path, destroying the Docker containers (or even the Docker volumes via `docker volume rm`) will **not** result in data loss, provided the host directories remain intact.