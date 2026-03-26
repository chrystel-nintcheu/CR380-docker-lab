---
description: >-
  Réduire le poids d'une image Docker / Reducing Docker image size
---

# Lab 07 — Réduire le poids / Slim Images

{% tabs %}
{% tab title="Français" %}

## Objectif

Optimiser la taille d'une image Docker en combinant les instructions `RUN` et en nettoyant les fichiers temporaires.

## Problème

L'image `monimage:structure` du lab précédent fait ~250MB parce que chaque instruction `RUN` crée une couche distincte, y compris le cache APT.

## Solution : le Dockerfile slim

```dockerfile
FROM nginx

RUN apt-get update \
    && apt-get -y install vim \
       net-tools \
       curl \
    && apt -y autoremove \
    && apt -y clean \
    && apt -y purge \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/share/nginx/html
```

### Optimisations appliquées

| Technique | Effet |
| --------- | ----- |
| Un seul `RUN` avec `&&` | Réduit le nombre de couches |
| `apt autoremove` | Supprime les paquets inutiles |
| `apt clean` | Vide le cache APT |
| `rm -rf /var/lib/apt/lists/*` | Supprime les index de paquets |

## Étapes

### 1. Construire l'image optimisée

```bash
docker build -t monimage:structure-slim -f dockerfiles/dockerfile-slim .
```

### 2. Comparer les tailles

```bash
docker images | grep monimage
```

### 3. Comparer les couches

```bash
docker history monimage:structure-slim
```

### 4. Tester l'image

```bash
docker run -d -p 80:80 --name nginxCT-slim monimage:structure-slim
curl http://localhost:80
```

### 5. Libérer de l'espace

```bash
docker container prune
docker image prune
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 07
```

{% endtab %}
{% tab title="English" %}

## Objective

Optimize Docker image size by combining `RUN` instructions and cleaning up temporary files.

## Problem

The `monimage:structure` image from the previous lab is ~250MB because each `RUN` instruction creates a separate layer, including the APT cache.

## Solution: the slim Dockerfile

```dockerfile
FROM nginx

RUN apt-get update \
    && apt-get -y install vim \
       net-tools \
       curl \
    && apt -y autoremove \
    && apt -y clean \
    && apt -y purge \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/share/nginx/html
```

### Applied optimizations

| Technique | Effect |
| --------- | ------ |
| Single `RUN` with `&&` | Reduces layer count |
| `apt autoremove` | Removes unnecessary packages |
| `apt clean` | Clears APT cache |
| `rm -rf /var/lib/apt/lists/*` | Removes package indexes |

## Steps

### 1. Build the optimized image

```bash
docker build -t monimage:structure-slim -f dockerfiles/dockerfile-slim .
```

### 2. Compare sizes

```bash
docker images | grep monimage
```

### 3. Compare layers

```bash
docker history monimage:structure-slim
```

### 4. Test the image

```bash
docker run -d -p 80:80 --name nginxCT-slim monimage:structure-slim
curl http://localhost:80
```

### 5. Free up space

```bash
docker container prune
docker image prune
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 07
```

{% endtab %}
{% endtabs %}
