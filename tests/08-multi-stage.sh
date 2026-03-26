#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 08 — Multi-stage builds
# =============================================================================
#
# FR: Construire une application Drupal avec un build multi-stage.
#     Couvre: multi-stage builds, ARG/ENV, COPY --from, VOLUME, EXPOSE,
#     Drupal 10 avec PHP/Apache.
#
# EN: Build a Drupal application with a multi-stage build.
#     Covers: multi-stage builds, ARG/ENV, COPY --from, VOLUME, EXPOSE,
#     Drupal 10 with PHP/Apache.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/image/multi-stage-builds
# Depends on: 07
# =============================================================================

run_test() {
    section_header "08" "Multi-stage builds" \
        "${GITBOOK_URL_08}"

    check_dependency "07" || { section_summary; return; }

    local dockerfile="${DOCKERFILES_DIR}/dockerfile-multistage"
    local container_name="${CT_DRUPAL}"

    # Cleanup from previous runs
    cleanup_container "${container_name}"
    cleanup_image "${IMG_MULTISTAGE}" 2>/dev/null

    # -------------------------------------------------------------------------
    # Step 1: Understand multi-stage builds
    # FR: Comprendre les builds multi-stage
    # -------------------------------------------------------------------------
    learn_pause \
        "Un build multi-stage utilise plusieurs FROM dans un Dockerfile.\n\nStage 1 (tmpbuilder): Ubuntu + curl → télécharge Drupal\nStage 2 (final): PHP/Apache → copie Drupal depuis stage 1\n\nL'image finale ne contient PAS Ubuntu ni curl — seulement\nce dont Drupal a besoin pour fonctionner." \
        "A multi-stage build uses multiple FROM in a Dockerfile.\n\nStage 1 (tmpbuilder): Ubuntu + curl → downloads Drupal\nStage 2 (final): PHP/Apache → copies Drupal from stage 1\n\nThe final image does NOT contain Ubuntu or curl — only\nwhat Drupal needs to run."

    if [[ -f "${dockerfile}" ]]; then
        pass "Multi-stage Dockerfile found / Dockerfile multi-stage trouvé"
    else
        fail "Multi-stage Dockerfile not found" "${dockerfile}" "not found" \
             "Le fichier dockerfile-multistage devrait être dans dockerfiles/"
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 2: Build the multi-stage image
    # FR: Construire l'image multi-stage
    # -------------------------------------------------------------------------
    learn_pause \
        "Construction de l'image avec des build-args.\nCommande: docker build \\\\\n  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \\\\\n  --build-arg PHP_VERSION=${PHP_VERSION} \\\\\n  --build-arg DRUPAL_VERSION=${DRUPAL_VERSION} \\\\\n  -t ${IMG_MULTISTAGE} -f dockerfile-multistage ." \
        "Building the image with build-args.\nCommand: docker build \\\\\n  --build-arg UBUNTU_VERSION=${UBUNTU_VERSION} \\\\\n  --build-arg PHP_VERSION=${PHP_VERSION} \\\\\n  --build-arg DRUPAL_VERSION=${DRUPAL_VERSION} \\\\\n  -t ${IMG_MULTISTAGE} -f dockerfile-multistage ."

    run_cmd "Build multi-stage image ${IMG_MULTISTAGE}" "${TIMEOUT_BUILD}" \
        docker build \
            --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}" \
            --build-arg "PHP_VERSION=${PHP_VERSION}" \
            --build-arg "DRUPAL_VERSION=${DRUPAL_VERSION}" \
            -t "${IMG_MULTISTAGE}" \
            -f "${dockerfile}" \
            "${PROJECT_DIR}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Multi-stage image built: ${IMG_MULTISTAGE}"
    else
        fail "Failed to build multi-stage image" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez le Dockerfile et votre connexion Internet"
        section_summary; return
    fi

    assert_image_exists "${IMG_MULTISTAGE}"

    # -------------------------------------------------------------------------
    # Step 3: Run the Drupal container
    # FR: Exécuter le conteneur Drupal
    # -------------------------------------------------------------------------
    learn_pause \
        "Lançons le conteneur Drupal sur le port ${PORT_DRUPAL}.\nCommande: docker run -dp ${PORT_DRUPAL}:80 --name ${container_name} ${IMG_MULTISTAGE}" \
        "Let's run the Drupal container on port ${PORT_DRUPAL}.\nCommand: docker run -dp ${PORT_DRUPAL}:80 --name ${container_name} ${IMG_MULTISTAGE}"

    run_cmd "Run Drupal container" "${TIMEOUT_DEFAULT}" \
        docker run -dp "${PORT_DRUPAL}:80" --name "${container_name}" "${IMG_MULTISTAGE}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Drupal container started on port ${PORT_DRUPAL}"
    else
        fail "Failed to start Drupal container" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Le port ${PORT_DRUPAL} est-il déjà utilisé ?"
    fi

    wait_for_container "${container_name}" || true

    # Give Apache/PHP time to start
    sleep 5

    # -------------------------------------------------------------------------
    # Step 4: Verify HTTP access
    # FR: Vérifier l'accès HTTP
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que Drupal répond sur le port ${PORT_DRUPAL}.\nOn attend un code HTTP 200 ou 302 (redirection vers l'installation)." \
        "Let's verify Drupal responds on port ${PORT_DRUPAL}.\nWe expect HTTP 200 or 302 (redirect to installation)."

    assert_http_reachable \
        "Drupal responds on port ${PORT_DRUPAL} / Drupal répond sur le port ${PORT_DRUPAL}" \
        "http://localhost:${PORT_DRUPAL}"

    # -------------------------------------------------------------------------
    # Step 5: Verify multi-stage benefits
    # FR: Vérifier les avantages du multi-stage
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que l'image finale ne contient pas Ubuntu (le builder).\nLe stage tmpbuilder est utilisé uniquement pour le téléchargement." \
        "Let's verify the final image doesn't contain Ubuntu (the builder).\nThe tmpbuilder stage is used only for downloading."

    # Check that the final image is PHP-based, not Ubuntu-based
    run_cmd "Inspect base image" "${TIMEOUT_DEFAULT}" \
        docker exec "${container_name}" php --version || true
    if (( CMD_EXIT_CODE == 0 )); then
        pass "PHP is available in final image (correct base)"
    else
        fail "PHP not found in final image" "PHP available" "not found" \
             "L'image finale devrait être basée sur php:apache"
    fi

    # Composer should be available via COPY --from=composer
    assert_success \
        "Composer is available (COPY --from=composer)" \
        "composer doit être copié depuis l'image composer:latest" \
        docker exec "${container_name}" composer --version

    # -------------------------------------------------------------------------
    # Cleanup
    # FR: Nettoyage
    # -------------------------------------------------------------------------
    cleanup_container "${container_name}"
    assert_container_not_exists "${container_name}"

    section_summary
}
