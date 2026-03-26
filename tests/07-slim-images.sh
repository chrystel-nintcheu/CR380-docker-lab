#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 07 — Réduire le poids / Slim Images
# =============================================================================
#
# FR: Optimiser la taille d'une image Docker en combinant les instructions RUN,
#     nettoyant le cache APT et supprimant les fichiers temporaires.
#
# EN: Optimize Docker image size by combining RUN instructions, cleaning
#     APT cache, and removing temporary files.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/image/reduire-le-poids
# Depends on: 06
# =============================================================================

run_test() {
    section_header "07" "Réduire le poids / Slim Images" \
        "${GITBOOK_URL_07}"

    check_dependency "06" || { section_summary; return; }

    local dockerfile="${DOCKERFILES_DIR}/dockerfile-slim"
    local container_name="${CT_NGINX_SLIM}"

    # Cleanup from previous runs
    cleanup_container "${container_name}"
    cleanup_image "${IMG_SLIM}" 2>/dev/null

    # -------------------------------------------------------------------------
    # Step 1: Verify slim Dockerfile exists
    # FR: Vérifier que le Dockerfile slim existe
    # -------------------------------------------------------------------------
    learn_pause \
        "Le Dockerfile slim combine toutes les installations en un seul RUN\net nettoie le cache APT. Cela réduit la taille de l'image.\n\nAstuces d'optimisation:\n- Combiner les RUN avec &&\n- apt clean + autoremove + purge\n- rm -rf /var/lib/apt/lists/*" \
        "The slim Dockerfile combines all installations in a single RUN\nand cleans the APT cache. This reduces the image size.\n\nOptimization tips:\n- Combine RUNs with &&\n- apt clean + autoremove + purge\n- rm -rf /var/lib/apt/lists/*"

    if [[ -f "${dockerfile}" ]]; then
        pass "Slim Dockerfile found / Dockerfile slim trouvé"
    else
        fail "Slim Dockerfile not found" "${dockerfile}" "not found" \
             "Le fichier dockerfile-slim devrait être dans dockerfiles/"
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 2: Build slim image
    # FR: Construire l'image slim
    # -------------------------------------------------------------------------
    learn_pause \
        "Construction de l'image optimisée.\nCommande: docker build -t ${IMG_SLIM} -f ${dockerfile} ." \
        "Building the optimized image.\nCommand: docker build -t ${IMG_SLIM} -f ${dockerfile} ."

    run_cmd "Build slim image ${IMG_SLIM}" "${TIMEOUT_BUILD}" \
        docker build -t "${IMG_SLIM}" -f "${dockerfile}" "${PROJECT_DIR}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Slim image built: ${IMG_SLIM} / Image slim construite"
    else
        fail "Failed to build slim image" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez le Dockerfile et votre connexion Internet"
        section_summary; return
    fi

    assert_image_exists "${IMG_SLIM}"

    # -------------------------------------------------------------------------
    # Step 3: Compare sizes
    # FR: Comparer les tailles
    # -------------------------------------------------------------------------
    learn_pause \
        "Comparons la taille de l'image slim avec l'image de structure.\nL'image slim devrait être plus petite grâce à l'optimisation." \
        "Let's compare the slim image size with the structure image.\nThe slim image should be smaller thanks to optimization."

    # Ensure structure image exists (should from Lab 06, or rebuild)
    if ! docker image inspect "${IMG_STRUCTURE}" &>/dev/null; then
        local structure_df="${DOCKERFILES_DIR}/dockerfile-structure"
        if [[ -f "${structure_df}" ]]; then
            run_cmd "Rebuild structure image for comparison" "${TIMEOUT_BUILD}" \
                docker build -t "${IMG_STRUCTURE}" -f "${structure_df}" "${PROJECT_DIR}" || true
        fi
    fi

    assert_image_smaller_than "${IMG_SLIM}" "${IMG_STRUCTURE}"

    # -------------------------------------------------------------------------
    # Step 4: Docker history comparison
    # FR: Comparer l'historique
    # -------------------------------------------------------------------------
    learn_pause \
        "Comparons les couches. L'image structure a 4 couches RUN séparées.\nL'image slim n'en a qu'une seule (les RUN sont combinés)." \
        "Let's compare layers. The structure image has 4 separate RUN layers.\nThe slim image has only one (RUNs are combined)."

    assert_output_not_empty \
        "docker history slim has output" \
        "L'image slim doit être construite" \
        docker history "${IMG_SLIM}"

    # -------------------------------------------------------------------------
    # Step 5: Run the slim container
    # FR: Exécuter le conteneur slim
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que l'image slim fonctionne correctement.\nCommande: docker run -d -p ${PORT_NGINX}:80 --name ${container_name} ${IMG_SLIM}" \
        "Let's verify the slim image works correctly.\nCommand: docker run -d -p ${PORT_NGINX}:80 --name ${container_name} ${IMG_SLIM}"

    run_cmd "Run slim container" "${TIMEOUT_DEFAULT}" \
        docker run -d -p "${PORT_NGINX}:80" --name "${container_name}" "${IMG_SLIM}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Slim container running / Conteneur slim en exécution"
    else
        fail "Failed to run slim container" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Le port ${PORT_NGINX} est-il déjà utilisé ?"
    fi

    wait_for_container "${container_name}" || true
    sleep 2

    assert_output_contains \
        "Nginx slim responds on port ${PORT_NGINX}" \
        "nginx" \
        "Vérifiez: docker logs ${container_name}" \
        curl -s --max-time 10 "http://localhost:${PORT_NGINX}"

    # -------------------------------------------------------------------------
    # Step 6: Prune unused resources
    # FR: Libérer l'espace disque
    # -------------------------------------------------------------------------
    learn_pause \
        "docker container prune et docker image prune suppriment\nles ressources inutilisées (conteneurs arrêtés, images orphelines)." \
        "docker container prune and docker image prune remove\nunused resources (stopped containers, dangling images)."

    # Cleanup
    cleanup_container "${container_name}"
    assert_container_not_exists "${container_name}"

    section_summary
}
