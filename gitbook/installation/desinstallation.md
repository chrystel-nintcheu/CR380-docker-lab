---
description: >-
  Désinstallation complète de Docker pour repartir sur une base propre /
  Complete uninstallation of Docker for a clean start
---

# Lab 01 — Désinstallation / Uninstallation

{% tabs %}
{% tab title="Français" %}

## Objectif

Avant d'installer Docker proprement, il faut s'assurer qu'il n'existe **aucune version antérieure** sur le système. Ce lab vous guide à travers une désinstallation complète.

## Pourquoi désinstaller d'abord ?

Les anciennes versions de Docker (`docker`, `docker.io`, `docker-engine`) ou des installations non officielles peuvent causer des conflits avec la version officielle Docker CE. On nettoie tout avant de recommencer.

## Étapes

### 1. Arrêter les services Docker

```bash
sudo systemctl stop docker docker.socket containerd
```

### 2. Purger les paquets Docker

```bash
sudo apt-get remove --purge -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin \
  docker-ce-rootless-extras
```

Supprimer aussi les anciennes versions non officielles :

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 \
           podman-docker containerd runc; do
    sudo apt-get remove --purge -y "$pkg" 2>/dev/null || true
done
```

### 3. Nettoyer le cache APT

```bash
sudo apt-get clean
sudo apt-get autoremove -y
```

### 4. Supprimer les fichiers résiduels

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

> ⚠️ **Attention** : Ceci supprime **toutes** les images, conteneurs, volumes et réseaux Docker !

### 5. Supprimer le dépôt Docker et la clé GPG

```bash
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.asc
```

### 6. Supprimer les groupes Docker

```bash
sudo groupdel docker 2>/dev/null || true
```

### 7. Mettre à jour la liste des paquets

```bash
sudo apt-get update --fix-missing
```

## Vérification

Vérifiez que Docker n'est plus installé :

```bash
docker --version    # Devrait échouer : command not found
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 01
```

{% endtab %}
{% tab title="English" %}

## Objective

Before installing Docker properly, you must ensure there are **no previous versions** on the system. This lab guides you through a complete uninstallation.

## Why uninstall first?

Old versions of Docker (`docker`, `docker.io`, `docker-engine`) or unofficial installations can conflict with the official Docker CE version. We clean everything before starting fresh.

## Steps

### 1. Stop Docker services

```bash
sudo systemctl stop docker docker.socket containerd
```

### 2. Purge Docker packages

```bash
sudo apt-get remove --purge -y \
  docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin \
  docker-ce-rootless-extras
```

Also remove old unofficial versions:

```bash
for pkg in docker.io docker-doc docker-compose docker-compose-v2 \
           podman-docker containerd runc; do
    sudo apt-get remove --purge "$pkg" 2>/dev/null || true
done
```

### 3. Clean APT cache

```bash
sudo apt-get clean
sudo apt-get autoremove -y
```

### 4. Remove leftover files

```bash
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

> ⚠️ **Warning**: This deletes **all** Docker images, containers, volumes, and networks!

### 5. Remove Docker repository and GPG key

```bash
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.asc
```

### 6. Remove Docker groups

```bash
sudo groupdel docker 2>/dev/null || true
```

### 7. Update the package list

```bash
sudo apt-get update --fix-missing
```

## Verification

Verify Docker is no longer installed:

```bash
docker --version    # Should fail: command not found
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 01
```

{% endtab %}
{% endtabs %}
