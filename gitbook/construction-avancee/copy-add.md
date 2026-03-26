---
description: >-
  Comprendre COPY, ADD et docker cp / Understanding COPY, ADD and docker cp
---

# Lab 10 — COPY, ADD & docker cp

{% tabs %}
{% tab title="Français" %}

## Objectif

Comprendre les instructions `COPY` et `ADD` dans un Dockerfile, et utiliser `docker cp` pour transférer des fichiers entre l'hôte et un conteneur.

## docker cp

### Hôte → Conteneur

```bash
docker cp fichier.txt mon_conteneur:/tmp/
```

### Conteneur → Hôte

```bash
docker cp mon_conteneur:/tmp/fichier.txt ./
```

### Copier un répertoire

```bash
docker cp mon_repertoire/ mon_conteneur:/tmp/
```

## COPY vs ADD dans un Dockerfile

| Instruction | Fonctionnalité |
| ----------- | -------------- |
| `COPY` | Copie des fichiers locaux vers l'image. Simple et prévisible. **Recommandé.** |
| `ADD` | Comme `COPY` + décompression automatique des archives `.tar.gz` + support des URLs |

> 💡 **Bonne pratique** : Utilisez toujours `COPY` sauf si vous avez besoin de la décompression automatique de `ADD`.

### Exemple COPY

```dockerfile
COPY index.html /usr/share/nginx/html/
COPY config/ /etc/myapp/
```

### Exemple ADD

```dockerfile
ADD archive.tar.gz /opt/app/    # Décompressé automatiquement
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 10
```

{% endtab %}
{% tab title="English" %}

## Objective

Understand `COPY` and `ADD` Dockerfile instructions, and use `docker cp` to transfer files between the host and a container.

## docker cp

### Host → Container

```bash
docker cp file.txt my_container:/tmp/
```

### Container → Host

```bash
docker cp my_container:/tmp/file.txt ./
```

### Copy a directory

```bash
docker cp my_directory/ my_container:/tmp/
```

## COPY vs ADD in a Dockerfile

| Instruction | Functionality |
| ----------- | ------------- |
| `COPY` | Copies local files to the image. Simple and predictable. **Recommended.** |
| `ADD` | Like `COPY` + automatic `.tar.gz` extraction + URL support |

> 💡 **Best practice**: Always use `COPY` unless you need `ADD`'s auto-extraction feature.

### COPY example

```dockerfile
COPY index.html /usr/share/nginx/html/
COPY config/ /etc/myapp/
```

### ADD example

```dockerfile
ADD archive.tar.gz /opt/app/    # Auto-extracted
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 10
```

{% endtab %}
{% endtabs %}
