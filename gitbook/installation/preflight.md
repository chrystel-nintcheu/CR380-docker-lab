# Lab 00 — Vérifications préalables / Preflight Checks

{% tabs %}
{% tab title="Français" %}

## Objectif

Vérifier que votre environnement est prêt pour les labs Docker : système d'exploitation, accès sudo, connexion Internet, espace disque et outils requis.

## Étapes

### 1. Vérifier le système d'exploitation

```bash
lsb_release -d
```

Résultat attendu : `Ubuntu 24.04` ou supérieur.

### 2. Vérifier l'accès sudo

```bash
sudo -n true
```

Si cette commande échoue, configurez sudo sans mot de passe ou exécutez `sudo -v` d'abord.

### 3. Vérifier la connexion Internet

```bash
curl -s --max-time 10 -o /dev/null -w '%{http_code}' https://hub.docker.com
```

Résultat attendu : un code HTTP (200, 301, etc.)

### 4. Vérifier l'espace disque

```bash
df -BG /
```

Minimum requis : 10 Go d'espace libre.

### 5. Vérifier les outils requis

```bash
which curl jq git
```

Tous les trois doivent être présents. Sinon :

```bash
sudo apt-get install -y curl jq git
```

{% endtab %}

{% tab title="English" %}

## Objective

Verify your environment is ready for the Docker labs: operating system, sudo access, Internet connectivity, disk space, and required tools.

## Steps

### 1. Check operating system

```bash
lsb_release -d
```

Expected: `Ubuntu 24.04` or later.

### 2. Check sudo access

```bash
sudo -n true
```

If this fails, configure passwordless sudo or run `sudo -v` first.

### 3. Check Internet connectivity

```bash
curl -s --max-time 10 -o /dev/null -w '%{http_code}' https://hub.docker.com
```

Expected: an HTTP code (200, 301, etc.)

### 4. Check disk space

```bash
df -BG /
```

Minimum required: 10 GB free space.

### 5. Check required tools

```bash
which curl jq git
```

All three must be present. If not:

```bash
sudo apt-get install -y curl jq git
```

{% endtab %}
{% endtabs %}
