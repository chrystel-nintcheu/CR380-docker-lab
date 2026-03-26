---
description: >-
  Tester l'installation avec vos premiers conteneurs Docker /
  Test the installation with your first Docker containers
---

# Lab 04 — Premiers conteneurs / First Containers

{% tabs %}
{% tab title="Français" %}

## Objectif

Manipuler vos premiers conteneurs Docker : créer, exécuter, inspecter, arrêter et supprimer un conteneur interactif (Debian) et un serveur web (Nginx) avec mapping de port.

## Partie A : Conteneur Debian interactif

### 1. Créer un conteneur Debian

```bash
docker run -dit --name debianCT debian
```

| Option | Description |
| ------ | ----------- |
| `-d` | Mode détaché (arrière-plan) |
| `-i` | Mode interactif (STDIN ouvert) |
| `-t` | Alloue un pseudo-terminal |
| `--name debianCT` | Nom du conteneur |

### 2. Exécuter une commande dans le conteneur

```bash
docker exec debianCT cat /etc/os-release
```

### 3. Lister les conteneurs actifs

```bash
docker ps
```

### 4. Arrêter et supprimer le conteneur

```bash
docker stop debianCT
docker rm debianCT
```

## Partie B : Serveur Nginx avec port mapping

### 1. Lancer Nginx

```bash
docker run -d --name nginxCT -p 80:80 nginx
```

Le flag `-p 80:80` mappe le port **80** de l'hôte au port **80** du conteneur.

### 2. Tester l'accès HTTP

```bash
curl http://localhost:80
```

Vous devriez voir la page d'accueil Nginx : **"Welcome to nginx!"**

### 3. Consulter les logs

```bash
docker logs nginxCT
```

### 4. Nettoyer

```bash
docker stop nginxCT
docker rm nginxCT
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 04
```

{% endtab %}
{% tab title="English" %}

## Objective

Work with your first Docker containers: create, run, inspect, stop, and remove an interactive container (Debian) and a web server (Nginx) with port mapping.

## Part A: Interactive Debian container

### 1. Create a Debian container

```bash
docker run -dit --name debianCT debian
```

| Option | Description |
| ------ | ----------- |
| `-d` | Detached mode (background) |
| `-i` | Interactive mode (STDIN open) |
| `-t` | Allocate a pseudo-terminal |
| `--name debianCT` | Container name |

### 2. Execute a command inside the container

```bash
docker exec debianCT cat /etc/os-release
```

### 3. List active containers

```bash
docker ps
```

### 4. Stop and remove the container

```bash
docker stop debianCT
docker rm debianCT
```

## Part B: Nginx server with port mapping

### 1. Run Nginx

```bash
docker run -d --name nginxCT -p 80:80 nginx
```

The `-p 80:80` flag maps host port **80** to container port **80**.

### 2. Test HTTP access

```bash
curl http://localhost:80
```

You should see the Nginx welcome page: **"Welcome to nginx!"**

### 3. Check the logs

```bash
docker logs nginxCT
```

### 4. Cleanup

```bash
docker stop nginxCT
docker rm nginxCT
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 04
```

{% endtab %}
{% endtabs %}
