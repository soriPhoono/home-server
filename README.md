## 🏡 home-server
**Docker configuration files for my personal home server.**

This repository contains the Docker configuration files (Docker Compose stacks) designed for deployment to a remote server administration platform, specifically **Portainer**, providing secure, accessible management via **Tailscale**. This setup facilitates the creation of a flexible, variable-number of Docker environments (a **homelab**).

---

## ✨ Features

* **Remote Administration:** Designed for deployment via **Portainer**, allowing remote management.
* **Secure Access:** Utilizes **Tailscale** for secure, accessible administration over a private network mesh.
* **Modular Stacks:** Includes ready-to-deploy stacks for essential homelab services.
* **Core Infrastructure Stack:** Reverse proxy and automatic update management.
* **PVR (Personal Video Recorder) Stack:** A complete media server environment.

---

## ⚙️ Stacks Deployable

### 1. **Core Infrastructure & Maintenance Stack**
This stack provides essential services for networking and container upkeep:
* **Caddy:** For routing external and internal traffic to various services.
* **Watchtower:** An update agent to automatically monitor and update running Docker containers.

### 2. **Complete PVR (Private Virtual Recorder) Media Stack**
A comprehensive setup for media management and streaming:
* **Jellyfin:** A free software media system for streaming your media.
* **Jellyseerr:** A *Request Management* tool (combining functionality similar to Sonarr/Radarr/Prowlarr) for discovering, requesting, and managing media.

---

## 🔗 Prerequisite: Portainer Setup

This project is intended to be deployed as **stacks** to a Portainer instance that is managed and provisioned by a separate system.

The foundational Portainer environment is deployed using **NixOS modules** found in this external repository:

> ➡️ **Prerequisite Repository:** `https://github.com/soriphoono/dotfiles`

Specifically, the **hosting module** within that repository handles:
* Deployment of a standalone Docker environment.
* Creation of the core **Portainer container** and its accompanying **Portainer Agent**.
* Configuration for **reverse proxy exposure** and **remote control** when combined with the server stack in this repository.

**This `home-server` repository is the set of configurations that you deploy *to* that already-running Portainer instance.**

---

## 🚀 Deployment Instructions

1.  **Ensure Prerequisites are Met:** Confirm that the Portainer instance is running and accessible (ideally via Localhost) as provisioned by the NixOS setup.
2.  **Access Portainer:** Log into your Portainer web interface.
3.  **Navigate to Stacks:** Go to the **"Stacks"** section.
4.  **Add a New Stack:** Click **"Add stack."**
5.  **Configuration Method:** Choose **"Git repository."**
6.  **Enter Repository Details:**
    * **Repository URL:** `https://github.com/soriphoono/home-server.git` (or your fork)
    * **Compose Path:** Specify the path to the desired `docker-compose.yml` file within this repo (e.g., `pvr/docker-compose.yml`).
7.  **Deploy:** Configure any necessary environment variables or settings, and click **"Deploy the stack."**\

--

## Deployment steps

This project contains a number of docker-compose.yml files, each describes a particular pillar of the server's construction. The correct deployment order is below, each particular stack folder contains a readme describing extra steps after the deployment of each stack, the stack's function in the overall server structure, and locations for extra documentation.

1. [server](https://github.com/soriPhoono/home-server/blob/main/server/docker-compose.yml)
2. [backend](https://github.com/soriPhoono/home-server/blob/main/backend/docker-compose.yml)
3. [pvr](https://github.com/soriPhoono/home-server/blob/main/pvr/docker-compose.yml) (optional)

---

## 💡 Contributing

Feel free to open issues or submit pull requests for improvements, especially for new stack configurations or optimizations to the existing ones!