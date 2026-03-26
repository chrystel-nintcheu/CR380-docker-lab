---
description: >-
  Comprendre ENTRYPOINT et CMD et leur interaction /
  Understanding ENTRYPOINT and CMD and their interaction
---

# Lab 09 — ENTRYPOINT & CMD

{% tabs %}
{% tab title="Français" %}

## Objectif

Comprendre la différence entre `ENTRYPOINT` et `CMD`, et comment ils interagissent au démarrage d'un conteneur.

## ENTRYPOINT vs CMD

| Instruction | Rôle | Peut être remplacé ? |
| ----------- | ---- | -------------------- |
| `ENTRYPOINT` | Commande qui s'exécute **toujours** | Oui, avec `--entrypoint` |
| `CMD` | Arguments **par défaut** passés à ENTRYPOINT | Oui, via `docker run img <cmd>` |

## Le script entrypoint.sh

```bash
#!/usr/bin/env bash
set -e

echo "ServerName localhost" >> /etc/apache2/apache2.conf

if [ -n "$APACHE_DOCUMENT_ROOT" ]; then
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
fi

if command -v a2enmod; then
    a2enmod rewrite
fi

exec "$@"    # ← Exécute la CMD passée en paramètre
```

## Le Dockerfile

```dockerfile
COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

CMD ["apachectl", "-D", "FOREGROUND"]
ENTRYPOINT ["entrypoint.sh"]
```

## Étapes

### 1. Construire l'image

```bash
docker build --build-arg UBUNTU_VERSION=jammy \
  --build-arg PHP_VERSION=8.2-apache-bookworm \
  --build-arg DRUPAL_VERSION=10.0.0 \
  -t img:entrypoint -f dockerfiles/dockerfile-entrypoint dockerfiles/
```

### 2. Lancer avec la CMD par défaut

```bash
docker run -d --rm -p 8091:80 --name drupal10x img:entrypoint
```

→ Apache démarre (CMD = `apachectl -D FOREGROUND`)

### 3. Supplanter la CMD

```bash
docker run --rm img:entrypoint date
```

→ Le script entrypoint.sh s'exécute, puis `date` est passé via `exec "$@"`

### 4. Supplanter l'ENTRYPOINT

```bash
docker run --rm --entrypoint cat img:entrypoint /etc/hostname
```

→ Le script entrypoint.sh est remplacé par `cat`

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 09
```

{% endtab %}
{% tab title="English" %}

## Objective

Understand the difference between `ENTRYPOINT` and `CMD`, and how they interact when a container starts.

## ENTRYPOINT vs CMD

| Instruction | Role | Can be overridden? |
| ----------- | ---- | ------------------ |
| `ENTRYPOINT` | Command that **always** runs | Yes, with `--entrypoint` |
| `CMD` | **Default** arguments passed to ENTRYPOINT | Yes, via `docker run img <cmd>` |

## The entrypoint.sh script

```bash
#!/usr/bin/env bash
set -e

echo "ServerName localhost" >> /etc/apache2/apache2.conf

if [ -n "$APACHE_DOCUMENT_ROOT" ]; then
    sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
    sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf
fi

if command -v a2enmod; then
    a2enmod rewrite
fi

exec "$@"    # ← Executes the CMD passed as parameter
```

## The Dockerfile

```dockerfile
COPY entrypoint.sh /usr/bin
RUN chmod +x /usr/bin/entrypoint.sh

CMD ["apachectl", "-D", "FOREGROUND"]
ENTRYPOINT ["entrypoint.sh"]
```

## Steps

### 1. Build the image

```bash
docker build --build-arg UBUNTU_VERSION=jammy \
  --build-arg PHP_VERSION=8.2-apache-bookworm \
  --build-arg DRUPAL_VERSION=10.0.0 \
  -t img:entrypoint -f dockerfiles/dockerfile-entrypoint dockerfiles/
```

### 2. Run with default CMD

```bash
docker run -d --rm -p 8091:80 --name drupal10x img:entrypoint
```

→ Apache starts (CMD = `apachectl -D FOREGROUND`)

### 3. Override the CMD

```bash
docker run --rm img:entrypoint date
```

→ The entrypoint.sh script runs, then `date` is passed via `exec "$@"`

### 4. Override the ENTRYPOINT

```bash
docker run --rm --entrypoint cat img:entrypoint /etc/hostname
```

→ The entrypoint.sh script is replaced by `cat`

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 09
```

{% endtab %}
{% endtabs %}
