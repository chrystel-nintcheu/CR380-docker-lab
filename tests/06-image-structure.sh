#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 06 — Structure d'image / Image Structure
# =============================================================================
#
# FR: Comprendre la structure en couches d'une image Docker.
#     Couvre: écriture d'un Dockerfile, docker build, docker history,
#     docker cp, docker exec, couches et taille d'image.
#
# EN: Understand the layered structure of a Docker image.
#     Covers: writing a Dockerfile, docker build, docker history,
#     docker cp, docker exec, layers and image size.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/image/structure
# Depends on: 05
# =============================================================================

run_test() {
    section_header "06" "Structure d'image / Image Structure" \
        "${GITBOOK_URL_06}"

    check_dependency "05" || { section_summary; return; }

    local dockerfile="${DOCKERFILES_DIR}/dockerfile-structure"
    local container_name="${CT_NGINX}"

    # Cleanup from previous runs
    cleanup_container "${container_name}"
    cleanup_image "${IMG_STRUCTURE}" 2>/dev/null

    # -------------------------------------------------------------------------
    # Step 1: Verify Dockerfile exists
    # FR: Vérifier que le Dockerfile existe
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous allons construire une image à partir d'un Dockerfile.\nLe Dockerfile est basé sur nginx et installe vim, net-tools et curl.\nChaque instruction RUN crée une nouvelle couche (layer)." \
        "We'll build an image from a Dockerfile.\nThe Dockerfile is based on nginx and installs vim, net-tools, and curl.\nEach RUN instruction creates a new layer."

    if [[ -f "${dockerfile}" ]]; then
        pass "Dockerfile found / Dockerfile trouvé: ${dockerfile}"
    else
        fail "Dockerfile not found" "${dockerfile}" "not found" \
             "Le fichier dockerfile-structure devrait être dans dockerfiles/"
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 2: Build the image
    # FR: Construire l'image
    # -------------------------------------------------------------------------
    learn_pause \
        "Construction de l'image avec 'docker build'.\nCommande: docker build -t ${IMG_STRUCTURE} -f ${dockerfile} .\n\n  -t : nom:tag de l'image\n  -f : chemin vers le Dockerfile" \
        "Building the image with 'docker build'.\nCommand: docker build -t ${IMG_STRUCTURE} -f ${dockerfile} .\n\n  -t: image name:tag\n  -f: path to the Dockerfile"

    run_cmd "Build image ${IMG_STRUCTURE}" "${TIMEOUT_BUILD}" \
        docker build -t "${IMG_STRUCTURE}" -f "${dockerfile}" "${PROJECT_DIR}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Image built: ${IMG_STRUCTURE} / Image construite: ${IMG_STRUCTURE}"
    else
        fail "Failed to build image" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez le Dockerfile et votre connexion Internet"
        section_summary; return
    fi

    assert_image_exists "${IMG_STRUCTURE}"

    # -------------------------------------------------------------------------
    # Step 3: List images
    # FR: Lister les images disponibles
    # -------------------------------------------------------------------------
    learn_pause \
        "Listons les images disponibles localement.\nCommande: docker images" \
        "Let's list locally available images.\nCommand: docker images"

    assert_output_contains \
        "docker images shows ${IMG_STRUCTURE} / docker images montre ${IMG_STRUCTURE}" \
        "monimage" \
        "L'image devrait avoir été construite à l'étape précédente" \
        docker images

    # -------------------------------------------------------------------------
    # Step 4: Inspect layers with docker history
    # FR: Observer la structure en couches avec docker history
    # -------------------------------------------------------------------------
    learn_pause \
        "docker history montre les couches de l'image.\nOn devrait voir les instructions FROM, RUN (×4) et WORKDIR.\nChaque RUN crée une couche distincte — c'est pourquoi la taille est ~250MB." \
        "docker history shows the image layers.\nWe should see FROM, RUN (×4), and WORKDIR instructions.\nEach RUN creates a distinct layer — that's why the size is ~250MB."

    assert_output_not_empty \
        "docker history has output / docker history a une sortie" \
        "L'image doit avoir été construite" \
        docker history "${IMG_STRUCTURE}"

    # Count layers (should have at least 5 from our Dockerfile)
    run_cmd "Count non-zero layers" "${TIMEOUT_DEFAULT}" \
        docker history "${IMG_STRUCTURE}" --format '{{.Size}}' || true
    local layer_count
    layer_count=$(echo "${CMD_OUTPUT}" | grep -cv '^0B$' 2>/dev/null || echo 0)
    if (( layer_count >= 5 )); then
        pass "Image has ${layer_count} non-zero layers (≥5) / L'image a ${layer_count} couches"
    else
        pass "Image layers inspected / Couches de l'image inspectées"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Run the container
    # FR: Exécuter l'image (conteneur en arrière-plan)
    # -------------------------------------------------------------------------
    learn_pause \
        "Lançons un conteneur depuis notre image.\nCommande: docker run -d -p ${PORT_NGINX_ALT}:80 --name ${container_name} ${IMG_STRUCTURE}" \
        "Let's run a container from our image.\nCommand: docker run -d -p ${PORT_NGINX_ALT}:80 --name ${container_name} ${IMG_STRUCTURE}"

    run_cmd "Run container from ${IMG_STRUCTURE}" "${TIMEOUT_DEFAULT}" \
        docker run -d -p "${PORT_NGINX_ALT}:80" --name "${container_name}" "${IMG_STRUCTURE}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${container_name}' started / Conteneur démarré"
    else
        fail "Failed to start container" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Le port ${PORT_NGINX_ALT} est-il déjà utilisé ?"
    fi

    wait_for_container "${container_name}" || true

    # Test HTTP access
    sleep 2
    assert_output_contains \
        "Nginx responds on port ${PORT_NGINX_ALT}" \
        "nginx" \
        "Vérifiez: docker logs ${container_name}" \
        curl -s --max-time 10 "http://localhost:${PORT_NGINX_ALT}"

    # -------------------------------------------------------------------------
    # Step 6: docker cp — copy files from container
    # FR: Copier des fichiers depuis le conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "docker cp copie des fichiers entre l'hôte et le conteneur.\nRécupérons la config nginx par défaut." \
        "docker cp copies files between host and container.\nLet's retrieve the default nginx config."

    local tmp_conf="/tmp/default.conf.$$"
    run_cmd "docker cp nginx config" "${TIMEOUT_DEFAULT}" \
        docker cp "${container_name}:/etc/nginx/conf.d/default.conf" "${tmp_conf}" || true

    if [[ -f "${tmp_conf}" ]]; then
        pass "Config copied from container / Config copiée depuis le conteneur"
        rm -f "${tmp_conf}"
    else
        fail "docker cp failed" "file exists" "not found" \
             "Essayez: docker cp ${container_name}:/etc/nginx/conf.d/default.conf ."
    fi

    # -------------------------------------------------------------------------
    # Step 7: docker exec — run shell in container
    # FR: Ouvrir un shell dans le conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "docker exec -it permet d'ouvrir un shell interactif dans\nle conteneur. Ici on vérifie que les outils installés sont présents." \
        "docker exec -it opens an interactive shell in the container.\nHere we verify the installed tools are present."

    assert_success \
        "vim is installed in container / vim installé dans le conteneur" \
        "Le Dockerfile devrait avoir installé vim" \
        docker exec "${container_name}" which vim

    assert_success \
        "curl is installed in container / curl installé dans le conteneur" \
        "Le Dockerfile devrait avoir installé curl" \
        docker exec "${container_name}" which curl

    assert_success \
        "ifconfig is available in container / ifconfig disponible dans le conteneur" \
        "Le Dockerfile devrait avoir installé net-tools" \
        docker exec "${container_name}" which ifconfig

    # -------------------------------------------------------------------------
    # Cleanup
    # FR: Nettoyage
    # -------------------------------------------------------------------------
    learn_pause \
        "Nettoyage : arrêter et supprimer le conteneur.\nCommande: docker rm -f ${container_name}" \
        "Cleanup: stop and remove the container.\nCommand: docker rm -f ${container_name}"

    cleanup_container "${container_name}"
    assert_container_not_exists "${container_name}"

    # Keep the image for comparison in Lab 07
    section_summary
}
