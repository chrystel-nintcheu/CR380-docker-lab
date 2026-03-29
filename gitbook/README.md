# Accueil — CR380 Labs Docker

Bienvenue dans le guide pratique du cours CR380 de Polytechnique Montréal. Ce guide accompagne la suite de tests automatisés qui reproduit chaque exercice de lab Docker.

{% tabs %}
{% tab title="Français" %}
{% hint style="info" %}
Ce guide est généré à partir du dépôt [CR380-docker-lab](https://github.com/chrystel-nintcheu/CR380-docker-lab). Les commandes présentées sont les mêmes que celles exécutées par la suite de tests automatisés.
{% endhint %}
{% endtab %}

{% tab title="English" %}
{% hint style="info" %}
This guide is generated from the [CR380-docker-lab](https://github.com/chrystel-nintcheu/CR380-docker-lab) repository. The commands shown are the same as those executed by the automated test suite.
{% endhint %}
{% endtab %}
{% endtabs %}

## Progression des labs

| # | Lab | Phase | Dépendance |
|---|-----|-------|------------|
| 00 | Vérifications préalables | — | Aucun |
| 01 | Désinstallation | Installation et configuration | Lab 00 |
| 02 | Installation | Installation et configuration | Lab 01 |
| 03 | Après installation | Installation et configuration | Lab 02 |
| 04 | Premiers conteneurs | Conteneurs et images | Lab 03 |
| 05 | Docker Hub | Conteneurs et images | Lab 04 |
| 06 | Structure d'image | Construction d'images | Lab 05 |
| 07 | Réduire le poids | Construction d'images | Lab 06 |
| 08 | Multi-stage builds | Construction avancée | Lab 07 |
| 09 | ENTRYPOINT & CMD | Construction avancée | Lab 08 |
| 10 | COPY, ADD & docker cp | Construction avancée | Lab 09 |
| 11 | Volumes | Persistance | Lab 10 |
| 99 | Nettoyage final | Finalisation | Aucun |

## Prérequis système

{% tabs %}
{% tab title="Français" %}
Avant de commencer, assurez-vous que votre machine répond à ces critères :

- **OS** : Ubuntu 24.04 ou supérieur (amd64)
- **Disque** : au moins 10 Go d'espace libre
- **Internet** : accès à `hub.docker.com`
- **Sudo** : accès sans mot de passe (ou mot de passe en cache)
- **Outils** : `git`, `curl`, `jq` installés
{% endtab %}

{% tab title="English" %}
Before starting, make sure your machine meets these requirements:

- **OS**: Ubuntu 24.04 or later (amd64)
- **Disk**: at least 10 GB free space
- **Internet**: access to `hub.docker.com`
- **Sudo**: passwordless or cached password
- **Tools**: `git`, `curl`, `jq` installed
{% endtab %}
{% endtabs %}

## Structure du cours

Le cours est divisé en quatre grandes sections :

1. **Installation et configuration** (Labs 00–03) — Vérifier l'environnement, désinstaller, installer Docker, configurer les permissions.
2. **Conteneurs et images** (Labs 04–05) — Lancer des conteneurs, explorer Docker Hub.
3. **Construction d'images** (Labs 06–09) — Dockerfile, couches, optimisation, multi-stage builds, ENTRYPOINT/CMD.
4. **Persistance** (Labs 10–11) — Transférer des fichiers, gérer les volumes.

Un lab de nettoyage (Lab 99) remet votre environnement dans son état initial.
