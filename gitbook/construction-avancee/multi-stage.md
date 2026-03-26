---
description: >-
  Construire une application avec un build multi-stage /
  Building an application with a multi-stage build
---

# Lab 08 — Multi-stage builds

{% tabs %}
{% tab title="Français" %}

## Objectif

Utiliser un build **multi-stage** pour construire une application Drupal 10 avec PHP/Apache, en séparant le téléchargement (stage 1) de l'image finale (stage 2).

## Pourquoi multi-stage ?

Un build classique inclut tous les outils de construction dans l'image finale. Avec multi-stage :

- **Stage 1** (`tmpbuilder`) : Ubuntu + curl → télécharge Drupal
- **Stage 2** (final) : PHP/Apache → copie uniquement Drupal

L'image finale est plus petite car elle ne contient ni Ubuntu ni curl.

## Le Dockerfile

```dockerfile
ARG UBUNTU_VERSION=jammy
ARG PHP_VERSION=8.2-apache-bookworm

FROM ubuntu:${UBUNTU_VERSION} AS tmpbuilder
# ... télécharge Drupal ...

FROM php:${PHP_VERSION}
# ... installe les extensions PHP ...
COPY --from=tmpbuilder /tmp/drupal_src /var/www/html
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
EXPOSE 80
```

## Étapes

### 1. Construire l'image

```bash
docker build \
  --build-arg UBUNTU_VERSION=jammy \
  --build-arg PHP_VERSION=8.2-apache-bookworm \
  --build-arg DRUPAL_VERSION=10.0.0 \
  -t monimage:multi-stage \
  -f dockerfiles/dockerfile-multistage .
```

### 2. Exécuter Drupal

```bash
docker run -dp 8090:80 --name drupal10 monimage:multi-stage
```

### 3. Tester dans le navigateur

Ouvrez `http://localhost:8090` — vous devriez voir l'assistant d'installation Drupal.

## Concepts clés

| Concept | Description |
| ------- | ----------- |
| `FROM ... AS name` | Nomme un stage de construction |
| `COPY --from=stage` | Copie des fichiers depuis un autre stage |
| `ARG` | Variable de construction (build-time) |
| `ENV` | Variable d'environnement (runtime) |
| `VOLUME` | Déclare un point de montage |
| `EXPOSE` | Documente le port exposé |

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 08
```

{% endtab %}
{% tab title="English" %}

## Objective

Use a **multi-stage** build to create a Drupal 10 application with PHP/Apache, separating the download (stage 1) from the final image (stage 2).

## Why multi-stage?

A regular build includes all build tools in the final image. With multi-stage:

- **Stage 1** (`tmpbuilder`): Ubuntu + curl → downloads Drupal
- **Stage 2** (final): PHP/Apache → copies only Drupal

The final image is smaller because it contains neither Ubuntu nor curl.

## The Dockerfile

```dockerfile
ARG UBUNTU_VERSION=jammy
ARG PHP_VERSION=8.2-apache-bookworm

FROM ubuntu:${UBUNTU_VERSION} AS tmpbuilder
# ... downloads Drupal ...

FROM php:${PHP_VERSION}
# ... installs PHP extensions ...
COPY --from=tmpbuilder /tmp/drupal_src /var/www/html
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
EXPOSE 80
```

## Steps

### 1. Build the image

```bash
docker build \
  --build-arg UBUNTU_VERSION=jammy \
  --build-arg PHP_VERSION=8.2-apache-bookworm \
  --build-arg DRUPAL_VERSION=10.0.0 \
  -t monimage:multi-stage \
  -f dockerfiles/dockerfile-multistage .
```

### 2. Run Drupal

```bash
docker run -dp 8090:80 --name drupal10 monimage:multi-stage
```

### 3. Test in browser

Open `http://localhost:8090` — you should see the Drupal installation wizard.

## Key concepts

| Concept | Description |
| ------- | ----------- |
| `FROM ... AS name` | Names a build stage |
| `COPY --from=stage` | Copies files from another stage |
| `ARG` | Build-time variable |
| `ENV` | Runtime environment variable |
| `VOLUME` | Declares a mount point |
| `EXPOSE` | Documents the exposed port |

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 08
```

{% endtab %}
{% endtabs %}
