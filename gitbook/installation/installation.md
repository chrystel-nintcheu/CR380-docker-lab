---
description: >-
  Installation de Docker CE via le dépôt officiel APT /
  Installing Docker CE via the official APT repository
---

# Lab 02 — Installation / Installation

{% tabs %}
{% tab title="Français" %}

## Objectif

Installer Docker CE (Community Edition) sur Ubuntu via le **dépôt officiel APT** de Docker (Option 2). C'est la méthode recommandée pour un environnement de production ou de développement.

## Étapes

### 1. Installer les pré-requis

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
```

### 2. Ajouter la clé GPG officielle de Docker

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

> 🔑 La clé GPG permet de vérifier l'authenticité des paquets téléchargés depuis le dépôt Docker.

### 3. Ajouter le dépôt Docker à APT

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4. Installer les paquets Docker

```bash
sudo apt-get update
sudo apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

| Paquet | Description |
| ------ | ----------- |
| `docker-ce` | Le moteur Docker |
| `docker-ce-cli` | L'interface en ligne de commande |
| `containerd.io` | Le runtime de conteneurs |
| `docker-buildx-plugin` | Construction avancée d'images |
| `docker-compose-plugin` | Orchestration multi-conteneurs |

### 5. Activer et démarrer le service

```bash
sudo systemctl enable docker containerd
sudo systemctl start docker
```

## Vérification

```bash
docker --version            # Affiche la version installée
systemctl is-active docker  # Devrait afficher "active"
sudo docker info            # Informations détaillées du démon
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 02
```

{% endtab %}
{% tab title="English" %}

## Objective

Install Docker CE (Community Edition) on Ubuntu via the **official Docker APT repository** (Option 2). This is the recommended method for production or development environments.

## Steps

### 1. Install prerequisites

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
```

### 2. Add Docker's official GPG key

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

> 🔑 The GPG key verifies the authenticity of packages downloaded from the Docker repository.

### 3. Add the Docker repository to APT

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### 4. Install Docker packages

```bash
sudo apt-get update
sudo apt-get install -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
```

| Package | Description |
| ------- | ----------- |
| `docker-ce` | The Docker engine |
| `docker-ce-cli` | The command line interface |
| `containerd.io` | The container runtime |
| `docker-buildx-plugin` | Advanced image building |
| `docker-compose-plugin` | Multi-container orchestration |

### 5. Enable and start the service

```bash
sudo systemctl enable docker containerd
sudo systemctl start docker
```

## Verification

```bash
docker --version            # Shows installed version
systemctl is-active docker  # Should show "active"
sudo docker info            # Detailed daemon information
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 02
```

{% endtab %}
{% endtabs %}
