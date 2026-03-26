#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 10 — COPY, ADD & docker cp
# =============================================================================
#
# FR: Comprendre les instructions COPY et ADD dans un Dockerfile,
#     et utiliser docker cp pour transférer des fichiers.
#
# EN: Understand COPY and ADD Dockerfile instructions,
#     and use docker cp to transfer files.
#
# Depends on: 09
# =============================================================================

run_test() {
    section_header "10" "COPY, ADD & docker cp" \
        "${GITBOOK_URL_10}"

    check_dependency "09" || { section_summary; return; }

    local container_name="${CT_COPY}"
    local test_dir="/tmp/cr380-copy-test-$$"

    # Cleanup from previous runs
    cleanup_container "${container_name}"
    rm -rf "${test_dir}"
    mkdir -p "${test_dir}"

    # -------------------------------------------------------------------------
    # Step 1: Create test files
    # FR: Créer des fichiers de test
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous allons tester docker cp pour copier des fichiers\nentre l'hôte et un conteneur." \
        "We'll test docker cp to copy files between the host\nand a container."

    echo "Hello from host - CR380" > "${test_dir}/test-host.txt"
    pass "Test file created / Fichier de test créé"

    # -------------------------------------------------------------------------
    # Step 2: Start a container
    # FR: Démarrer un conteneur
    # -------------------------------------------------------------------------
    run_cmd "Start container" "${TIMEOUT_DEFAULT}" \
        docker run -dit --name "${container_name}" "${IMAGE_DEBIAN}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${container_name}' started"
    else
        fail "Failed to start container" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" ""
        section_summary; return
    fi

    wait_for_container "${container_name}" || true

    # -------------------------------------------------------------------------
    # Step 3: docker cp — host to container
    # FR: docker cp — de l'hôte vers le conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "docker cp copie des fichiers de l'hôte vers le conteneur.\nCommande: docker cp fichier conteneur:/chemin" \
        "docker cp copies files from host to container.\nCommand: docker cp file container:/path"

    assert_success \
        "docker cp host→container / docker cp hôte→conteneur" \
        "Essayez: docker cp ${test_dir}/test-host.txt ${container_name}:/tmp/" \
        docker cp "${test_dir}/test-host.txt" "${container_name}:/tmp/"

    # Verify file was copied
    assert_output_contains \
        "File exists in container / Fichier présent dans le conteneur" \
        "Hello from host" \
        "Le fichier devrait avoir été copié" \
        docker exec "${container_name}" cat /tmp/test-host.txt

    # -------------------------------------------------------------------------
    # Step 4: docker cp — container to host
    # FR: docker cp — du conteneur vers l'hôte
    # -------------------------------------------------------------------------
    learn_pause \
        "docker cp copie aussi dans l'autre sens : conteneur → hôte.\nCommande: docker cp conteneur:/chemin fichier_local" \
        "docker cp also works in reverse: container → host.\nCommand: docker cp container:/path local_file"

    # Create a file inside the container
    docker exec "${container_name}" sh -c 'echo "Hello from container - CR380" > /tmp/test-container.txt' || true

    assert_success \
        "docker cp container→host / docker cp conteneur→hôte" \
        "Essayez: docker cp ${container_name}:/tmp/test-container.txt ${test_dir}/" \
        docker cp "${container_name}:/tmp/test-container.txt" "${test_dir}/"

    # Verify file was copied
    if [[ -f "${test_dir}/test-container.txt" ]] && grep -q "Hello from container" "${test_dir}/test-container.txt"; then
        pass "File copied from container to host / Fichier copié du conteneur vers l'hôte"
    else
        fail "File not found on host" "${test_dir}/test-container.txt" "not found" \
             "Vérifiez les permissions"
    fi

    # -------------------------------------------------------------------------
    # Step 5: COPY vs ADD in Dockerfile
    # FR: COPY vs ADD dans un Dockerfile
    # -------------------------------------------------------------------------
    learn_pause \
        "Dans un Dockerfile:\n\n  COPY: copie des fichiers locaux → image\n          (simple, prévisible, recommandé)\n\n  ADD:  comme COPY, mais en plus:\n          - Décompresse automatiquement les .tar.gz\n          - Accepte les URL (déconseillé)\n\n➡ Recommandation: toujours utiliser COPY sauf si vous avez\n  besoin de la décompression automatique de ADD." \
        "In a Dockerfile:\n\n  COPY: copies local files → image\n          (simple, predictable, recommended)\n\n  ADD:  like COPY, but also:\n          - Auto-extracts .tar.gz archives\n          - Accepts URLs (discouraged)\n\n➡ Recommendation: always use COPY unless you need\n  ADD's auto-extraction feature."

    pass "COPY vs ADD explained / COPY vs ADD expliqué"

    # -------------------------------------------------------------------------
    # Step 6: Copy a directory
    # FR: Copier un répertoire entier
    # -------------------------------------------------------------------------
    learn_pause \
        "docker cp fonctionne aussi avec les répertoires." \
        "docker cp also works with directories."

    mkdir -p "${test_dir}/subdir"
    echo "file1" > "${test_dir}/subdir/file1.txt"
    echo "file2" > "${test_dir}/subdir/file2.txt"

    assert_success \
        "docker cp directory host→container" \
        "Essayez: docker cp ${test_dir}/subdir ${container_name}:/tmp/" \
        docker cp "${test_dir}/subdir" "${container_name}:/tmp/"

    assert_output_contains \
        "Directory contents visible in container" \
        "file1.txt" \
        "Le répertoire devrait avoir été copié" \
        docker exec "${container_name}" ls /tmp/subdir/

    # -------------------------------------------------------------------------
    # Cleanup
    # -------------------------------------------------------------------------
    cleanup_container "${container_name}"
    assert_container_not_exists "${container_name}"
    rm -rf "${test_dir}"

    section_summary
}
