---
description: >-
  Configuration post-installation de Docker /
  Post-installation configuration of Docker
---

# Lab 03 — Après installation / Post-installation

{% tabs %}
{% tab title="Français" %}

## Objectif

Configurer Docker pour qu'il puisse être utilisé **sans sudo** et vérifier que tout fonctionne correctement avec le test `hello-world`.

## Pourquoi cette étape ?

Par défaut, le démon Docker s'exécute en tant que `root`. Pour éviter de devoir utiliser `sudo` à chaque commande Docker, on ajoute l'utilisateur au groupe `docker`.

> ⚠️ **Sécurité** : Le groupe `docker` donne des privilèges équivalents à `root`. En production, utilisez les [rootless containers](https://docs.docker.com/engine/security/rootless/).

## Étapes

### 1. Créer le groupe docker

```bash
sudo groupadd docker
```

> Si le groupe existe déjà, la commande affichera un message d'erreur inoffensif.

### 2. Ajouter votre utilisateur au groupe

```bash
sudo usermod -aG docker $USER
```

### 3. Activer le groupe pour la session

```bash
newgrp docker
```

> 💡 Alternativement, déconnectez-vous puis reconnectez-vous.

### 4. Tester avec hello-world

```bash
docker run hello-world
```

Vous devriez voir le message **"Hello from Docker!"** sans avoir utilisé `sudo`.

### 5. Vérifier le démarrage automatique

```bash
systemctl is-enabled docker    # Devrait afficher "enabled"
```

## Vérification

```bash
docker run hello-world          # Sans sudo !
docker images | grep hello      # L'image est dans le cache
```

## Test automatisé

```bash
sudo bash run-labs.sh --validate --lab 03
```

{% endtab %}
{% tab title="English" %}

## Objective

Configure Docker so it can be used **without sudo** and verify everything works correctly with the `hello-world` test.

## Why this step?

By default, the Docker daemon runs as `root`. To avoid needing `sudo` for every Docker command, we add the user to the `docker` group.

> ⚠️ **Security**: The `docker` group grants privileges equivalent to `root`. In production, use [rootless containers](https://docs.docker.com/engine/security/rootless/).

## Steps

### 1. Create the docker group

```bash
sudo groupadd docker
```

> If the group already exists, the command will show a harmless error message.

### 2. Add your user to the group

```bash
sudo usermod -aG docker $USER
```

### 3. Activate the group for the session

```bash
newgrp docker
```

> 💡 Alternatively, log out and log back in.

### 4. Test with hello-world

```bash
docker run hello-world
```

You should see the message **"Hello from Docker!"** without using `sudo`.

### 5. Verify auto-start

```bash
systemctl is-enabled docker    # Should show "enabled"
```

## Verification

```bash
docker run hello-world          # Without sudo!
docker images | grep hello      # The image is in the cache
```

## Automated test

```bash
sudo bash run-labs.sh --validate --lab 03
```

{% endtab %}
{% endtabs %}
