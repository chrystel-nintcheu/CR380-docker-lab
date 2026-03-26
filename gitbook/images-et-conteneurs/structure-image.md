---
description: >-
  Comprendre la structure en couches d'une image Docker /
  Understanding the layered structure of a Docker image
---

# Lab 06 — Structure d'image / Image Structure

{% tabs %}
{% tab title="Français" %}

## Objectif

Comprendre comment Docker construit des images en **couches** (layers) à partir d'un **Dockerfile**, et manipuler les conteneurs résultants.

## Le Dockerfile

Voici le Dockerfile utilisé dans ce lab :

```dockerfile
FROM nginx

RUN apt-get update --fix-missing
RUN apt-get -y install vim
RUN apt-get -y install net-tools
RUN apt-get -y install curl

WORKDIR /usr/share/nginx/html
```

Chaque instruction `RUN` crée une **nouvelle couche** dans l'image. C'est pourquoi cette image fait ~250MB.

## Étapes

### 1. Construire l'image

```bash
docker build -t monimage:structure -f dockerfiles/dockerfile-structure .
```

### 2. Lister les images

```bash
docker images
```

### 3. Observer les couches

```bash
docker history monimage:structure
```

On compte 5 étapes (couches ajoutées par notre Dockerfile) et ~250MB d'espace disque.

### 4. Lancer le conteneur

```bash
docker run -d -p 81:80 --name nginxCT monimage:structure
```

### 5. Copier un fichier depuis le conteneur

```bash
docker cp nginxCT:/etc/nginx/conf.d/default.conf .
docker cp nginxCT:/usr/share/nginx/html/index.html .
```

### 6. Ouvrir un shell dans le conteneur

```bash
docker exec -it nginxCT /bin/bash
```

### 7. Nettoyer

```bash
docker rm -f nginxCT
```

## Concepts clés

| Concept | Description |
| ------- | ----------- |
| **FROM** | Image de base |
| **RUN** | Exécute une commande et crée une couche |
| **WORKDIR** | Définit le répertoire de travail |
| **Layer** | Chaque instruction crée une couche en lecture seule |
| **docker history** | Montre les couches d'une image |
| **docker cp** | Copie des fichiers entre hôte et conteneur |

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 06
```

{% endtab %}
{% tab title="English" %}

## Objective

Understand how Docker builds images in **layers** from a **Dockerfile**, and work with the resulting containers.

## The Dockerfile

Here is the Dockerfile used in this lab:

```dockerfile
FROM nginx

RUN apt-get update --fix-missing
RUN apt-get -y install vim
RUN apt-get -y install net-tools
RUN apt-get -y install curl

WORKDIR /usr/share/nginx/html
```

Each `RUN` instruction creates a **new layer** in the image. That's why this image is ~250MB.

## Steps

### 1. Build the image

```bash
docker build -t monimage:structure -f dockerfiles/dockerfile-structure .
```

### 2. List images

```bash
docker images
```

### 3. Inspect layers

```bash
docker history monimage:structure
```

You'll see 5 steps (layers added by our Dockerfile) and ~250MB of disk space.

### 4. Run the container

```bash
docker run -d -p 81:80 --name nginxCT monimage:structure
```

### 5. Copy a file from the container

```bash
docker cp nginxCT:/etc/nginx/conf.d/default.conf .
docker cp nginxCT:/usr/share/nginx/html/index.html .
```

### 6. Open a shell in the container

```bash
docker exec -it nginxCT /bin/bash
```

### 7. Cleanup

```bash
docker rm -f nginxCT
```

## Key concepts

| Concept | Description |
| ------- | ----------- |
| **FROM** | Base image |
| **RUN** | Executes a command and creates a layer |
| **WORKDIR** | Sets the working directory |
| **Layer** | Each instruction creates a read-only layer |
| **docker history** | Shows image layers |
| **docker cp** | Copies files between host and container |

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 06
```

{% endtab %}
{% endtabs %}
