---
description: >-
  Nettoyage complet de l'environnement Docker / Full Docker environment teardown
---

# Lab 99 — Nettoyage

{% tabs %}
{% tab title="Français" %}

## Objectif

Remettre l'environnement à zéro en supprimant **tous les conteneurs, images, volumes et caches** créés pendant les labs.

## Pourquoi nettoyer ?

- Libérer l'espace disque occupé par les images et volumes
- Éviter les conflits de noms lors d'une prochaine session
- Repartir d'un état propre pour un nouvel étudiant

## Étapes

### 1. Supprimer tous les conteneurs du lab

```bash
docker rm -f debianCT nginxCT nginxCT-slim drupal10 drupal10x copyCT
```

### 2. Supprimer les images construites

```bash
docker rmi -f monimage:structure monimage:structure-slim \
  monimage:multi-stage img:entrypoint
```

### 3. Supprimer les images téléchargées

```bash
docker rmi -f nginx nginx:alpine debian ubuntu:jammy \
  php:8.2-apache-bookworm hello-world
```

### 4. Supprimer les volumes

```bash
docker volume rm www_data
```

### 5. Nettoyage système

```bash
docker system prune -f
```

> **Attention** : `docker system prune` supprime les conteneurs arrêtés, les réseaux inutilisés et les images pendantes. Ajoutez `--volumes` pour inclure les volumes anonymes.

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 99
```

{% endtab %}
{% tab title="English" %}

## Objective

Reset the environment by removing **all containers, images, volumes, and caches** created during the labs.

## Why clean up?

- Free disk space used by images and volumes
- Avoid name conflicts in the next session
- Start from a clean state for a new student

## Steps

### 1. Remove all lab containers

```bash
docker rm -f debianCT nginxCT nginxCT-slim drupal10 drupal10x copyCT
```

### 2. Remove built images

```bash
docker rmi -f monimage:structure monimage:structure-slim \
  monimage:multi-stage img:entrypoint
```

### 3. Remove pulled images

```bash
docker rmi -f nginx nginx:alpine debian ubuntu:jammy \
  php:8.2-apache-bookworm hello-world
```

### 4. Remove volumes

```bash
docker volume rm www_data
```

### 5. System prune

```bash
docker system prune -f
```

> **Warning**: `docker system prune` removes stopped containers, unused networks, and dangling images. Add `--volumes` to include anonymous volumes.

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 99
```

{% endtab %}
{% endtabs %}
