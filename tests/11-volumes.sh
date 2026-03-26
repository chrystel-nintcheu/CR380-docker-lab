#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 11 — Volumes
# =============================================================================
#
# FR: Comprendre et utiliser les volumes Docker pour la persistance des données.
#     Couvre: docker volume create, volumes nommés, bind mounts,
#     persistance à travers le cycle de vie des conteneurs.
#
# EN: Understand and use Docker volumes for data persistence.
#     Covers: docker volume create, named volumes, bind mounts,
#     persistence across container lifecycle.
#
# Depends on: 10
# =============================================================================

run_test() {
    section_header "11" "Volumes" \
        "${GITBOOK_URL_11}"

    check_dependency "10" || { section_summary; return; }

    local test_vol="${VOL_NAME}"
    local container_name="vol-test-ct"

    # Cleanup from previous runs
    cleanup_container "${container_name}"
    cleanup_container "${container_name}-2"
    cleanup_volume "${test_vol}"

    # -------------------------------------------------------------------------
    # Step 1: Create a named volume
    # FR: Créer un volume nommé
    # -------------------------------------------------------------------------
    learn_pause \
        "Un volume Docker persiste les données indépendamment du conteneur.\nContrairement aux fichiers dans le conteneur, les données dans un\nvolume survivent à la suppression du conteneur.\n\nCommande: docker volume create ${test_vol}" \
        "A Docker volume persists data independently of the container.\nUnlike files in the container, data in a volume survives\ncontainer removal.\n\nCommand: docker volume create ${test_vol}"

    assert_success \
        "docker volume create ${test_vol}" \
        "Essayez: docker volume create ${test_vol}" \
        docker volume create "${test_vol}"

    assert_volume_exists "${test_vol}"

    # -------------------------------------------------------------------------
    # Step 2: List and inspect volumes
    # FR: Lister et inspecter les volumes
    # -------------------------------------------------------------------------
    learn_pause \
        "docker volume ls liste tous les volumes.\ndocker volume inspect montre les détails (point de montage, etc.)." \
        "docker volume ls lists all volumes.\ndocker volume inspect shows details (mount point, etc.)."

    assert_output_contains \
        "docker volume ls shows '${test_vol}'" \
        "${test_vol}" \
        "Le volume devrait avoir été créé" \
        docker volume ls --format '{{.Name}}'

    assert_output_not_empty \
        "docker volume inspect '${test_vol}' has output" \
        "Le volume devrait exister" \
        docker volume inspect "${test_vol}"

    # -------------------------------------------------------------------------
    # Step 3: Use a named volume with a container
    # FR: Utiliser un volume nommé avec un conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "Montons le volume dans un conteneur et écrivons des données.\nCommande: docker run -v ${test_vol}:${VOL_MOUNT} ...\n\nLe flag -v monte le volume '${test_vol}' dans le conteneur à\nl'emplacement '${VOL_MOUNT}'." \
        "Let's mount the volume in a container and write data.\nCommand: docker run -v ${test_vol}:${VOL_MOUNT} ...\n\nThe -v flag mounts volume '${test_vol}' in the container at\n'${VOL_MOUNT}'."

    # Write data to volume via container
    run_cmd "Write data to volume" "${TIMEOUT_DEFAULT}" \
        docker run --rm -v "${test_vol}:${VOL_MOUNT}" "${IMAGE_DEBIAN}" \
            sh -c "echo 'CR380 persistence test - $(date)' > ${VOL_MOUNT}/test-persistence.txt" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Data written to volume / Données écrites dans le volume"
    else
        fail "Failed to write data to volume" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez que le volume est créé"
    fi

    # -------------------------------------------------------------------------
    # Step 4: Verify persistence — read from a NEW container
    # FR: Vérifier la persistance — lire depuis un NOUVEAU conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions la persistance: lisons les données depuis un NOUVEAU conteneur.\nLe conteneur précédent a été supprimé (--rm), mais les données\nrestent dans le volume." \
        "Let's verify persistence: read the data from a NEW container.\nThe previous container was removed (--rm), but the data\nremains in the volume."

    assert_output_contains \
        "Data persists in new container / Données persistantes dans un nouveau conteneur" \
        "CR380 persistence test" \
        "Les données devraient persister dans le volume" \
        docker run --rm -v "${test_vol}:${VOL_MOUNT}" "${IMAGE_DEBIAN}" \
            cat "${VOL_MOUNT}/test-persistence.txt"

    # -------------------------------------------------------------------------
    # Step 5: Shared volume between containers
    # FR: Volume partagé entre conteneurs
    # -------------------------------------------------------------------------
    learn_pause \
        "Plusieurs conteneurs peuvent partager le même volume.\nLançons deux conteneurs utilisant le même volume." \
        "Multiple containers can share the same volume.\nLet's run two containers using the same volume."

    # Container 1 writes
    run_cmd "Container 1 writes" "${TIMEOUT_DEFAULT}" \
        docker run --rm -v "${test_vol}:${VOL_MOUNT}" "${IMAGE_DEBIAN}" \
            sh -c "echo 'Written by container 1' > ${VOL_MOUNT}/shared.txt" || true

    # Container 2 reads
    assert_output_contains \
        "Container 2 reads data from container 1 / Conteneur 2 lit les données du conteneur 1" \
        "Written by container 1" \
        "Les données devraient être partagées via le volume" \
        docker run --rm -v "${test_vol}:${VOL_MOUNT}" "${IMAGE_DEBIAN}" \
            cat "${VOL_MOUNT}/shared.txt"

    # -------------------------------------------------------------------------
    # Step 6: Bind mount (host directory)
    # FR: Montage lié (répertoire hôte)
    # -------------------------------------------------------------------------
    learn_pause \
        "Un bind mount utilise un répertoire de l'hôte directement.\nCommande: docker run -v /chemin/hote:/chemin/conteneur ...\n\nDifférence avec un volume nommé:\n  Volume nommé: géré par Docker, portable\n  Bind mount: lié à un chemin de l'hôte, accès direct" \
        "A bind mount uses a host directory directly.\nCommand: docker run -v /host/path:/container/path ...\n\nDifference from a named volume:\n  Named volume: managed by Docker, portable\n  Bind mount: tied to a host path, direct access"

    local bind_dir="/tmp/cr380-bind-test-$$"
    mkdir -p "${bind_dir}"
    echo "Bind mount test - CR380" > "${bind_dir}/bind-test.txt"

    assert_output_contains \
        "Bind mount works / Montage lié fonctionne" \
        "Bind mount test" \
        "Le fichier devrait être visible dans le conteneur" \
        docker run --rm -v "${bind_dir}:${VOL_MOUNT}:ro" "${IMAGE_DEBIAN}" \
            cat "${VOL_MOUNT}/bind-test.txt"

    rm -rf "${bind_dir}"

    # -------------------------------------------------------------------------
    # Step 7: Cleanup volume
    # FR: Nettoyer le volume
    # -------------------------------------------------------------------------
    learn_pause \
        "Supprimons le volume.\nCommande: docker volume rm ${test_vol}" \
        "Let's remove the volume.\nCommand: docker volume rm ${test_vol}"

    cleanup_volume "${test_vol}"
    assert_volume_not_exists "${test_vol}"

    section_summary
}
