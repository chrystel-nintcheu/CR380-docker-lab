#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 09 — ENTRYPOINT & CMD
# =============================================================================
#
# FR: Comprendre ENTRYPOINT et CMD et leur interaction.
#     Couvre: ENTRYPOINT exec form, CMD par défaut, override CMD,
#     override ENTRYPOINT, script entrypoint.sh, exec "$@".
#
# EN: Understand ENTRYPOINT and CMD and their interaction.
#     Covers: ENTRYPOINT exec form, default CMD, CMD override,
#     ENTRYPOINT override, entrypoint.sh script, exec "$@".
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/image/entrypoint
# Depends on: 08
# =============================================================================

run_test() {
    section_header "09" "ENTRYPOINT & CMD" \
        "${GITBOOK_URL_09}"

    check_dependency "08" || { section_summary; return; }

    local dockerfile="${DOCKERFILES_DIR}/dockerfile-entrypoint"
    local entrypoint_script="${DOCKERFILES_DIR}/entrypoint.sh"
    local container_name="${CT_DRUPAL_EP}"

    # Cleanup from previous runs
    cleanup_container "${container_name}"
    cleanup_image "${IMG_ENTRYPOINT}" 2>/dev/null

    # -------------------------------------------------------------------------
    # Step 1: Understand ENTRYPOINT vs CMD
    # FR: Comprendre ENTRYPOINT vs CMD
    # -------------------------------------------------------------------------
    learn_pause \
        "ENTRYPOINT et CMD sont deux instructions Dockerfile:\n\n  ENTRYPOINT: commande qui s'exécute TOUJOURS au démarrage\n  CMD: arguments par défaut passés à ENTRYPOINT\n\nSi on fait: docker run img date\n  → ENTRYPOINT reçoit 'date' au lieu du CMD par défaut" \
        "ENTRYPOINT and CMD are two Dockerfile instructions:\n\n  ENTRYPOINT: command that ALWAYS runs at startup\n  CMD: default arguments passed to ENTRYPOINT\n\nIf we do: docker run img date\n  → ENTRYPOINT receives 'date' instead of the default CMD"

    # Verify supporting files
    if [[ -f "${dockerfile}" ]]; then
        pass "Dockerfile-entrypoint found / Dockerfile trouvé"
    else
        fail "Dockerfile not found" "${dockerfile}" "not found" ""
        section_summary; return
    fi

    if [[ -f "${entrypoint_script}" ]]; then
        pass "entrypoint.sh found / entrypoint.sh trouvé"
    else
        fail "entrypoint.sh not found" "${entrypoint_script}" "not found" ""
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 2: Build the entrypoint image
    # FR: Construire l'image avec ENTRYPOINT
    # -------------------------------------------------------------------------
    learn_pause \
        "Construction de l'image avec ENTRYPOINT.\nLe script entrypoint.sh:\n  1. Configure Apache (ServerName, DocumentRoot)\n  2. Active mod_rewrite\n  3. Exécute la CMD via 'exec \"\$@\"'" \
        "Building the image with ENTRYPOINT.\nThe entrypoint.sh script:\n  1. Configures Apache (ServerName, DocumentRoot)\n  2. Enables mod_rewrite\n  3. Executes CMD via 'exec \"\$@\"'"

    run_cmd "Build entrypoint image ${IMG_ENTRYPOINT}" "${TIMEOUT_BUILD}" \
        docker build \
            --build-arg "UBUNTU_VERSION=${UBUNTU_VERSION}" \
            --build-arg "PHP_VERSION=${PHP_VERSION}" \
            --build-arg "DRUPAL_VERSION=${DRUPAL_VERSION}" \
            -t "${IMG_ENTRYPOINT}" \
            -f "${dockerfile}" \
            "${DOCKERFILES_DIR}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Entrypoint image built: ${IMG_ENTRYPOINT}"
    else
        fail "Failed to build entrypoint image" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez le Dockerfile et entrypoint.sh"
        section_summary; return
    fi

    assert_image_exists "${IMG_ENTRYPOINT}"

    # -------------------------------------------------------------------------
    # Step 3: Run with default CMD
    # FR: Exécuter avec la CMD par défaut
    # -------------------------------------------------------------------------
    learn_pause \
        "Lançons le conteneur avec la CMD par défaut (apachectl -D FOREGROUND).\nLe script entrypoint.sh s'exécute d'abord, puis lance Apache." \
        "Let's run the container with the default CMD (apachectl -D FOREGROUND).\nThe entrypoint.sh script runs first, then launches Apache."

    run_cmd "Run container with default CMD" "${TIMEOUT_DEFAULT}" \
        docker run -d --rm -p "${PORT_ENTRYPOINT}:80" --name "${container_name}" "${IMG_ENTRYPOINT}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${container_name}' running with default CMD"
    else
        fail "Failed to start container" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Le port ${PORT_ENTRYPOINT} est-il déjà utilisé ?"
    fi

    wait_for_container "${container_name}" || true
    sleep 5

    # Verify Apache is running (default CMD)
    assert_http_reachable \
        "Apache responds on port ${PORT_ENTRYPOINT} (default CMD)" \
        "http://localhost:${PORT_ENTRYPOINT}"

    cleanup_container "${container_name}"

    # -------------------------------------------------------------------------
    # Step 4: Override CMD with 'date'
    # FR: Remplacer CMD avec 'date'
    # -------------------------------------------------------------------------
    learn_pause \
        "Supplanter la CMD par défaut avec 'date'.\nCommande: docker run --rm ${IMG_ENTRYPOINT} date\n\nLe script entrypoint.sh s'exécute, puis 'date' est passé\nvia exec \"\$@\" au lieu de 'apachectl -D FOREGROUND'." \
        "Override the default CMD with 'date'.\nCommand: docker run --rm ${IMG_ENTRYPOINT} date\n\nThe entrypoint.sh script runs, then 'date' is passed\nvia exec \"\$@\" instead of 'apachectl -D FOREGROUND'."

    run_cmd "Override CMD with date" "${TIMEOUT_DEFAULT}" \
        docker run --rm "${IMG_ENTRYPOINT}" date || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -n "${CMD_OUTPUT}" ]]; then
        pass "CMD override with 'date' works / Remplacement CMD par 'date' fonctionne"
    else
        fail "CMD override failed" \
             "date output" "${CMD_OUTPUT:-empty}" \
             "Vérifiez que entrypoint.sh contient 'exec \"\$@\"'"
    fi

    # -------------------------------------------------------------------------
    # Step 5: Override ENTRYPOINT
    # FR: Remplacer ENTRYPOINT
    # -------------------------------------------------------------------------
    learn_pause \
        "On peut aussi remplacer l'ENTRYPOINT avec --entrypoint.\nCommande: docker run --rm --entrypoint cat ${IMG_ENTRYPOINT} /etc/hostname" \
        "We can also override ENTRYPOINT with --entrypoint.\nCommand: docker run --rm --entrypoint cat ${IMG_ENTRYPOINT} /etc/hostname"

    run_cmd "Override ENTRYPOINT with cat" "${TIMEOUT_DEFAULT}" \
        docker run --rm --entrypoint cat "${IMG_ENTRYPOINT}" /etc/hostname || true

    if (( CMD_EXIT_CODE == 0 )) && [[ -n "${CMD_OUTPUT}" ]]; then
        pass "ENTRYPOINT override with '--entrypoint cat' works"
    else
        fail "ENTRYPOINT override failed" \
             "hostname output" "${CMD_OUTPUT:-empty}" \
             "Essayez: docker run --rm --entrypoint cat ${IMG_ENTRYPOINT} /etc/hostname"
    fi

    section_summary
}
