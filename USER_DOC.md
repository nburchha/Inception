# User Documentation

This document provides a straightforward guide for end users and administrators to understand, use, and manage the Inception project infrastructure.

## Provided Services
This stack provides a complete hosting environment for a WordPress website. The infrastructure consists of three main services:
1. **NGINX**: A web server acting as a reverse proxy. It securely handles incoming HTTPS traffic and serves the web pages.
2. **WordPress (with php-fpm)**: The core application serving the website's content and logic.
3. **MariaDB**: The database engine that stores all of the website's data, including user accounts, posts, and site configurations.

## Starting and Stopping the Project
To manage the lifecycle of the project, you must run commands from the root directory of the repository:

- **Start the services:** 
  ```bash
  make
  ```
  *(Alternatively, you can run `make up`)*

- **Stop the services:** 
  ```bash
  make down
  ```
  This will stop the containers safely without destroying the persistent data.

## Accessing the Website and Administration Panel
Ensure that the services are running. You can access the website and admin panel via your web browser:

- **Main Website:** [https://nburchha.42.fr](https://nburchha.42.fr)
- **WordPress Administration Panel:** [https://nburchha.42.fr/wp-admin](https://nburchha.42.fr/wp-admin)

*(Note: You must accept the self-signed SSL certificate warning in your browser to access the site).*

## Locating and Managing Credentials
For security reasons, no passwords or sensitive credentials are hardcoded in the source code. All credentials are managed via environment variables.

- **Location:** Credentials must be stored in a file named `.env` located inside the `srcs/` directory.
- **Management:** This file defines database users, passwords, and WordPress admin accounts. If you need to change a password, update the value in this file and restart the infrastructure. **Do not share this file or commit it to version control.**

## Checking Service Status
To ensure that all services are running correctly:
```bash
make status
```
This command will list all running Docker containers associated with the project, displaying their current state (e.g., "Up" or "Exited") and the ports they are listening on. NGINX should be the only service exposing ports to the host (port 443).