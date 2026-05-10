*This project has been created as part of the 42 curriculum by nburchha.*

## Description
This project, Inception, is a system administration related exercise. Its goal is to broaden my knowledge of system administration by using Docker. I will virtualize several Docker images, creating them in a personal virtual machine. The project involves setting up a small infrastructure consisting of NGINX, WordPress with php-fpm, and MariaDB, each running in their own separate containers and communicating via a custom Docker network.

### Project description
This project utilizes Docker to encapsulate services into isolated containers. The sources included encompass Dockerfiles for NGINX, WordPress, and MariaDB, alongside necessary configuration files and a `docker-compose.yml` to orchestrate them. 

**Main Design Choices:**
- **Containerization:** Each service (NGINX, WordPress, MariaDB) runs in its own dedicated container based on Alpine or Debian.
- **Orchestration:** Docker Compose is used to build, link, and manage the lifecycle of these containers seamlessly.
- **Security:** NGINX handles SSL/TLS connections securely. Passwords and sensitive data are passed using environment variables from a `.env` file, and are not hardcoded.

**Comparisons:**
- **Virtual Machines vs Docker:** VMs virtualize hardware and run a full guest OS, which is resource-heavy. Docker virtualizes the OS, sharing the host kernel and running processes in isolated containers, making it much more lightweight, faster to start, and resource-efficient.
- **Secrets vs Environment Variables:** Docker Secrets are encrypted and securely mounted into containers, ideal for highly sensitive data in Swarm mode. Environment Variables are easier to implement and use locally but can be exposed via `docker inspect` or logs, requiring careful management (e.g., keeping `.env` out of version control).
- **Docker Network vs Host Network:** A custom Docker network isolates container traffic, allowing containers to discover each other via DNS names (like `mariadb` or `wordpress`) while keeping them isolated from the external host network. The Host Network removes this isolation, sharing the host's networking stack directly, which can lead to port conflicts and less security.
- **Docker Volumes vs Bind Mounts:** Docker Volumes are managed by Docker within a specific directory on the host (`/var/lib/docker/volumes/`), making them fully independent of the host OS filesystem structure and easier to back up. Bind Mounts rely on specific host file paths, tying the container to the host's file system layout, which is less portable but gives direct access to local host files.

## Instructions
**Compilation / Installation:**
1. Ensure Docker and Docker Compose are installed on your machine.
2. Edit your `/etc/hosts` file to map `nburchha.42.fr` to `127.0.0.1`.
3. Create the necessary directories for data persistence:
   ```bash
   sudo mkdir -p /home/nburchha/data/mariadb
   sudo mkdir -p /home/nburchha/data/wordpress
   ```
4. Create a `.env` file in the `srcs` directory with the required environment variables (e.g., database credentials, domain name).

**Execution:**
To start the infrastructure, navigate to the root directory and use the Makefile:
```bash
make
# or alternatively
cd srcs
docker compose up -d --build
```
To stop the services:
```bash
make down
```

## Resources
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Docker Hub](https://hub.docker.com/_/wordpress)
- [MariaDB Docker Hub](https://hub.docker.com/_/mariadb)

**AI Usage:**
AI was used in this project to assist with generating configuration templates for NGINX and Dockerfiles, providing quick reference for `docker-compose.yml` syntax, troubleshooting configuration errors, and structuring the explanations in this README.

---
# Evaluation Checklist for Mandatory Part

## General Instructions
- [ ] Ensure all configuration files are in a `srcs` folder at the repository root.
- [ ] Ensure a `Makefile` is located at the root of the repository.
- [ ] Run the cleanup command:  
  ```bash
  docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
  ```
- [ ] Check the `docker-compose.yml` file:
  - [ ] Ensure there is no `network: host` or `links:`.
  - [ ] Ensure there is a `network(s)` section.
- [ ] Verify no `--link` is used in the `Makefile` or scripts.
- [ ] Check `Dockerfiles`:
  - [ ] Ensure no `tail -f` or background commands (e.g., `nginx & bash`) in the `ENTRYPOINT`.
  - [ ] Ensure the base image is the penultimate stable version of Alpine or Debian.
- [ ] Verify no infinite loops in scripts (e.g., `sleep infinity`, `tail -f /dev/null`).

## MariaDB and Its Volume
- [ ] Ensure there is a `Dockerfile` for MariaDB.
- [ ] Ensure no NGINX in the `Dockerfile`.
- [ ] Run `docker compose ps` to verify the container was created.
- [ ] **TODO** Verify a Volume exists and its path is `/home/login/data/`.
	- docker volume ls
	- docker inspect mariadb | grep '/home/nburchha/data'
- [ ] Confirm the student can log in to MariaDB and that the database is not empty.
  ```bash
  docker exec -it mariadb /bin/bash
  mysql -u$WP_DB_USER -p
  USE wordpress; SHOW TABLES;
  ```

## Project Overview
- [ ] Student explains:
  - [ ] How Docker and Docker Compose work.
  - [ ] Difference between Docker images used with/without Docker Compose.
  - [ ] Benefits of Docker compared to VMs.
  - [ ] The pertinence of the directory structure. (pertinence=importance)

## Docker Basics
- [ ] Ensure each service has a `Dockerfile`.
- [ ] Confirm all containers are built from the penultimate stable version of Alpine/Debian. -> no 'debian:latest'
- [ ] Verify Docker images match the names of their services.
  ```bash
  make status
  ```
- [ ] Ensure the `Makefile` sets up all services via Docker Compose without crashes.

## NGINX with SSL/TLS
- [ ] Ensure there is a `Dockerfile` for NGINX.
- [ ] Run `docker compose ps` to verify the container was created.
  ```bash
  make status
  ```
- [ ] **TODO** Confirm HTTP (port 80) is inaccessible.
- [ ] Open `https://nburchha.42.fr/` to verify:
  - [ ] The WordPress website loads (not the installation page).
  - [ ] A TLS v1.2/v1.3 certificate is used (self-signed acceptable).

## Persistence
- [ ] Reboot the VM, relaunch Docker Compose, and ensure:
  - [ ] All services are functional.
  - [ ] WordPress and MariaDB retain previous changes.

## Preliminary Tests
- [ ] Ensure no credentials, API keys, or environment variables are hardcoded in the repository; they must be in a `.env` file.
- [ ] Clone the repository on the evaluation station.

## Docker Network
- [ ] Check `docker-compose.yml` for Docker network usage.
- [ ] Run `docker network ls` to verify a network is visible.
- [ ] Student explains Docker networks simply.

## Simple Setup
- [ ] Confirm NGINX is accessible via port 443 only.
- [ ] Verify SSL/TLS certificate is used.
- [ ] Ensure WordPress is properly installed and configured:
  - [ ] Accessible at `https://nburchha.42.fr`.
  - [ ] Inaccessible at `http://nburchha.42.fr`.

## WordPress with php-fpm and Its Volume
- [ ] Ensure there is a `Dockerfile` for WordPress.
- [ ] Confirm no NGINX in the `Dockerfile`.
- [ ] Run `docker compose ps` to verify the container was created.
- [ ] Verify a Volume exists and its path is `/home/nburchha/data/`.
- [ ] Test WordPress functionality:
  - [ ] Add a comment using a user account.
  - [ ] Log in as Admin (username must not include `admin` variants).
  - [ ] Edit a page via the Admin dashboard and confirm changes on the site.
