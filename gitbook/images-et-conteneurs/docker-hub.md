---
description: >-
  Explorer Docker Hub et gérer les images Docker /
  Explore Docker Hub and manage Docker images
---

# Lab 05 — Docker Hub & Images

{% tabs %}
{% tab title="Français" %}

## Objectif

Apprendre à rechercher, télécharger, inspecter et comparer des images Docker sur Docker Hub.

## Docker Hub

[Docker Hub](https://hub.docker.com) est le registre public par défaut pour les images Docker. Il contient des milliers d'images officielles et communautaires.

## Étapes

### 1. Rechercher des images

```bash
docker search nginx --limit 5
```

Vous verrez les résultats triés par popularité, avec des images `OFFICIAL` maintenues par Docker.

### 2. Télécharger une image

```bash
docker pull nginx           # Tag par défaut: latest
docker pull nginx:alpine    # Tag spécifique: Alpine
```

> 💡 Les **tags** identifient une version spécifique d'une image. `latest` est le tag par défaut.

### 3. Lister les images locales

```bash
docker images nginx
```

Comparez les tailles : `nginx:latest` (~190MB) vs `nginx:alpine` (~40MB).

### 4. Inspecter une image

```bash
docker inspect nginx --format '{{json .Config.ExposedPorts}}'
```

### 5. Voir l'historique de construction

```bash
docker history nginx
```

Chaque ligne représente une **couche** (layer) de l'image.

### 6. Supprimer une image

```bash
docker rmi nginx:alpine
```

## Concepts clés

| Concept | Description |
| ------- | ----------- |
| **Tag** | Identifiant de version (ex: `latest`, `alpine`, `1.25`) |
| **Layer** | Couche de l'image, créée par chaque instruction Dockerfile |
| **Alpine** | Distribution Linux légère, images plus petites |
| **Official** | Images maintenues par Docker, vérifiées |

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 05
```

{% endtab %}
{% tab title="English" %}

## Objective

Learn to search, download, inspect, and compare Docker images on Docker Hub.

## Docker Hub

[Docker Hub](https://hub.docker.com) is the default public registry for Docker images. It contains thousands of official and community images.

## Steps

### 1. Search for images

```bash
docker search nginx --limit 5
```

Results are sorted by popularity, with `OFFICIAL` images maintained by Docker.

### 2. Pull an image

```bash
docker pull nginx           # Default tag: latest
docker pull nginx:alpine    # Specific tag: Alpine
```

> 💡 **Tags** identify a specific version of an image. `latest` is the default tag.

### 3. List local images

```bash
docker images nginx
```

Compare sizes: `nginx:latest` (~190MB) vs `nginx:alpine` (~40MB).

### 4. Inspect an image

```bash
docker inspect nginx --format '{{json .Config.ExposedPorts}}'
```

### 5. View build history

```bash
docker history nginx
```

Each line represents a **layer** of the image.

### 6. Remove an image

```bash
docker rmi nginx:alpine
```

## Key concepts

| Concept | Description |
| ------- | ----------- |
| **Tag** | Version identifier (e.g., `latest`, `alpine`, `1.25`) |
| **Layer** | Image layer, created by each Dockerfile instruction |
| **Alpine** | Lightweight Linux distribution, smaller images |
| **Official** | Images maintained by Docker, verified |

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 05
```

{% endtab %}
{% endtabs %}
