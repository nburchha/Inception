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
  mysql -u$WP_DB_USER -p$WP_DB_PASSWORD -h$WP_DB_HOST $WP_DB_NAME

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
- [ ] Ensure the `Makefile` sets up all services via Docker Compose without crashes.

## NGINX with SSL/TLS
- [ ] Ensure there is a `Dockerfile` for NGINX.
- [ ] Run `docker compose ps` to verify the container was created.
  ```bash
  make status
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