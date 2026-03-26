---
description: >-
  Comprendre et utiliser les volumes Docker / Understanding and using Docker volumes
---

# Lab 11 — Volumes

{% tabs %}
{% tab title="Français" %}

## Objectif

Comprendre les volumes Docker pour **persister les données** au-delà du cycle de vie des conteneurs.

## Pourquoi les volumes ?

Par défaut, les données écrites dans un conteneur sont **éphémères** : elles disparaissent quand le conteneur est supprimé. Les volumes permettent de :

- Persister les données (bases de données, fichiers uploadés)
- Partager des données entre conteneurs
- Découpler les données du cycle de vie du conteneur

## Types de stockage persistant

| Type | Commande | Usage |
| ---- | -------- | ----- |
| **Volume nommé** | `-v nom:/chemin` | Géré par Docker, portable |
| **Bind mount** | `-v /hôte:/conteneur` | Accès direct au FS hôte |
| **tmpfs** | `--tmpfs /chemin` | En mémoire uniquement |

## Étapes

### 1. Créer un volume nommé

```bash
docker volume create www_data
```

### 2. Lister et inspecter

```bash
docker volume ls
docker volume inspect www_data
```

### 3. Monter dans un conteneur

```bash
docker run --rm -v www_data:/var/www/html debian \
  sh -c 'echo "Hello" > /var/www/html/test.txt'
```

### 4. Vérifier la persistance

```bash
docker run --rm -v www_data:/var/www/html debian \
  cat /var/www/html/test.txt
```

→ Les données survivent entre les conteneurs !

### 5. Bind mount

```bash
docker run --rm -v $(pwd):/data:ro debian ls /data
```

Le flag `:ro` monte en lecture seule.

### 6. Supprimer le volume

```bash
docker volume rm www_data
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 11
```

{% endtab %}
{% tab title="English" %}

## Objective

Understand Docker volumes to **persist data** beyond the container lifecycle.

## Why volumes?

By default, data written inside a container is **ephemeral**: it disappears when the container is removed. Volumes allow you to:

- Persist data (databases, uploaded files)
- Share data between containers
- Decouple data from the container lifecycle

## Types of persistent storage

| Type | Command | Usage |
| ---- | ------- | ----- |
| **Named volume** | `-v name:/path` | Managed by Docker, portable |
| **Bind mount** | `-v /host:/container` | Direct host FS access |
| **tmpfs** | `--tmpfs /path` | Memory only |

## Steps

### 1. Create a named volume

```bash
docker volume create www_data
```

### 2. List and inspect

```bash
docker volume ls
docker volume inspect www_data
```

### 3. Mount in a container

```bash
docker run --rm -v www_data:/var/www/html debian \
  sh -c 'echo "Hello" > /var/www/html/test.txt'
```

### 4. Verify persistence

```bash
docker run --rm -v www_data:/var/www/html debian \
  cat /var/www/html/test.txt
```

→ Data survives between containers!

### 5. Bind mount

```bash
docker run --rm -v $(pwd):/data:ro debian ls /data
```

The `:ro` flag mounts read-only.

### 6. Remove the volume

```bash
docker volume rm www_data
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 11
```

{% endtab %}
{% endtabs %}
