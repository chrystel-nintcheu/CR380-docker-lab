#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 05 — Docker Hub & gestion d'images / Docker Hub & Image Management
# =============================================================================
#
# FR: Explorer Docker Hub et manipuler les images Docker.
#     Couvre: docker search, docker pull, docker images, docker inspect,
#     docker history, tags, images Alpine, docker rmi.
#
# EN: Explore Docker Hub and manage Docker images.
#     Covers: docker search, docker pull, docker images, docker inspect,
#     docker history, tags, Alpine images, docker rmi.
#
# Depends on: 04
# =============================================================================

run_test() {
    section_header "05" "Docker Hub & images" \
        "${GITBOOK_URL_05}"

    check_dependency "04" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Part A: Docker search
    # FR: Rechercher des images sur Docker Hub
    # -------------------------------------------------------------------------
    learn_pause \
        "Docker Hub est le registre public par défaut. On peut rechercher\ndes images avec 'docker search'.\nCommande: docker search nginx --limit 5" \
        "Docker Hub is the default public registry. We can search for\nimages with 'docker search'.\nCommand: docker search nginx --limit 5"

    assert_output_contains \
        "docker search nginx finds results / docker search nginx trouve des résultats" \
        "nginx" \
        "Vérifiez votre connexion Internet / Check your internet connection" \
        docker search nginx --limit 5

    # -------------------------------------------------------------------------
    # Part B: Docker pull & tags
    # FR: Télécharger des images et comprendre les tags
    # -------------------------------------------------------------------------
    learn_pause \
        "Chaque image Docker a des 'tags' qui identifient une version.\nLe tag par défaut est 'latest'. On peut spécifier un tag:\n  docker pull nginx         → nginx:latest\n  docker pull nginx:alpine  → version Alpine (plus légère)" \
        "Each Docker image has 'tags' that identify a version.\nThe default tag is 'latest'. We can specify a tag:\n  docker pull nginx         → nginx:latest\n  docker pull nginx:alpine  → Alpine version (lighter)"

    # Pull nginx:latest
    run_cmd "Pull nginx:latest" "${TIMEOUT_PULL}" \
        docker pull "${IMAGE_NGINX}" || true
    assert_image_exists "${IMAGE_NGINX}"

    # Pull nginx:alpine
    learn_pause \
        "L'image Alpine est beaucoup plus légère (~40MB au lieu de ~190MB)\ncar elle est basée sur Alpine Linux, une distribution minimaliste." \
        "The Alpine image is much lighter (~40MB instead of ~190MB)\nbecause it's based on Alpine Linux, a minimalist distribution."

    run_cmd "Pull nginx:alpine" "${TIMEOUT_PULL}" \
        docker pull "${IMAGE_NGINX_ALPINE}" || true
    assert_image_exists "${IMAGE_NGINX_ALPINE}"

    # -------------------------------------------------------------------------
    # Part C: Docker images — list and compare
    # FR: Lister et comparer les images
    # -------------------------------------------------------------------------
    learn_pause \
        "Comparons la taille des deux images nginx.\nCommande: docker images nginx" \
        "Let's compare the size of both nginx images.\nCommand: docker images nginx"

    assert_output_contains \
        "docker images shows nginx images / docker images montre les images nginx" \
        "nginx" \
        "Les images doivent être téléchargées d'abord" \
        docker images nginx

    # Show size comparison
    run_cmd "Get nginx:latest size" "${TIMEOUT_DEFAULT}" \
        docker image inspect "${IMAGE_NGINX}" --format '{{.Size}}' || true
    local size_latest="${CMD_OUTPUT}"

    run_cmd "Get nginx:alpine size" "${TIMEOUT_DEFAULT}" \
        docker image inspect "${IMAGE_NGINX_ALPINE}" --format '{{.Size}}' || true
    local size_alpine="${CMD_OUTPUT}"

    if [[ -n "${size_latest}" ]] && [[ -n "${size_alpine}" ]] && \
       (( size_alpine < size_latest )); then
        pass "Alpine image is smaller than latest / Image Alpine plus petite que latest"
    else
        pass "Image sizes retrieved / Tailles d'images récupérées"
    fi

    # -------------------------------------------------------------------------
    # Part D: Docker inspect
    # FR: Inspecter une image en détail
    # -------------------------------------------------------------------------
    learn_pause \
        "docker inspect montre les métadonnées complètes d'une image\n(layers, variables d'environnement, port exposés, etc.)" \
        "docker inspect shows complete metadata of an image\n(layers, environment variables, exposed ports, etc.)"

    assert_output_contains \
        "docker inspect shows Nginx exposed port / docker inspect montre le port exposé" \
        "80/tcp" \
        "L'image nginx doit être téléchargée" \
        docker inspect "${IMAGE_NGINX}" --format '{{json .Config.ExposedPorts}}'

    # -------------------------------------------------------------------------
    # Part E: Docker history
    # FR: Voir l'historique de construction d'une image
    # -------------------------------------------------------------------------
    learn_pause \
        "docker history montre les couches (layers) de l'image et les\ncommandes Dockerfile qui les ont créées." \
        "docker history shows the image layers and the Dockerfile\ncommands that created them."

    assert_output_not_empty \
        "docker history nginx has output / docker history nginx a une sortie" \
        "L'image nginx doit être téléchargée" \
        docker history "${IMAGE_NGINX}"

    # -------------------------------------------------------------------------
    # Part F: Cleanup — remove pulled images
    # FR: Nettoyage — supprimer les images téléchargées
    # -------------------------------------------------------------------------
    learn_pause \
        "Nettoyons les images téléchargées avec 'docker rmi'.\nNote: Les images seront re-téléchargées dans les prochains labs." \
        "Let's clean up the downloaded images with 'docker rmi'.\nNote: Images will be re-downloaded in upcoming labs."

    # Don't actually remove nginx — it's needed by later labs
    # Just demonstrate rmi with alpine variant
    cleanup_image "${IMAGE_NGINX_ALPINE}"
    assert_image_not_exists "${IMAGE_NGINX_ALPINE}"

    section_summary
}
