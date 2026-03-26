#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 04 — Premiers conteneurs / First Containers
# =============================================================================
#
# FR: Tester l'installation en manipulant des conteneurs Docker.
#     Couvre: docker run (interactif et détaché), docker exec, docker stop,
#     docker rm, ports mapping, debian et nginx.
#
# EN: Test the installation by working with Docker containers.
#     Covers: docker run (interactive and detached), docker exec, docker stop,
#     docker rm, port mapping, debian and nginx.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/tester-linstallation
# Depends on: 03
# =============================================================================

run_test() {
    section_header "04" "Premiers conteneurs / First Containers" \
        "${GITBOOK_URL_04}"

    check_dependency "03" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Cleanup any leftover containers from previous runs
    # -------------------------------------------------------------------------
    cleanup_container "${CT_DEBIAN}"
    cleanup_container "${CT_NGINX}"

    # -------------------------------------------------------------------------
    # Part A: Conteneur interactif Debian
    # FR: Lancer un conteneur Debian en mode interactif
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous allons créer un conteneur Debian interactif.\nCommande: docker run -dit --name ${CT_DEBIAN} ${IMAGE_DEBIAN}\n\n  -d : détaché (en arrière-plan)\n  -i : interactif (garder STDIN ouvert)\n  -t : allouer un pseudo-terminal" \
        "We'll create an interactive Debian container.\nCommand: docker run -dit --name ${CT_DEBIAN} ${IMAGE_DEBIAN}\n\n  -d: detached (background)\n  -i: interactive (keep STDIN open)\n  -t: allocate a pseudo-terminal"

    run_cmd "Pull Debian image" "${TIMEOUT_PULL}" \
        docker pull "${IMAGE_DEBIAN}" || true

    run_cmd "Create Debian container" "${TIMEOUT_DEFAULT}" \
        docker run -dit --name "${CT_DEBIAN}" "${IMAGE_DEBIAN}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_DEBIAN}' created / Conteneur '${CT_DEBIAN}' créé"
    else
        fail "Failed to create container '${CT_DEBIAN}'" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Essayez: docker run -dit --name ${CT_DEBIAN} ${IMAGE_DEBIAN}"
    fi

    # Wait for container to start
    if wait_for_container "${CT_DEBIAN}"; then
        pass "Container '${CT_DEBIAN}' is running / Conteneur en exécution"
    else
        fail "Container '${CT_DEBIAN}' not running after timeout" \
             "running" "not running" \
             "Essayez: docker logs ${CT_DEBIAN}"
    fi

    # -------------------------------------------------------------------------
    # docker exec: run a command inside the container
    # FR: Exécuter une commande dans le conteneur
    # -------------------------------------------------------------------------
    learn_pause \
        "Exécutons une commande dans le conteneur avec 'docker exec'.\nCommande: docker exec ${CT_DEBIAN} cat /etc/os-release" \
        "Let's run a command inside the container with 'docker exec'.\nCommand: docker exec ${CT_DEBIAN} cat /etc/os-release"

    assert_output_contains \
        "docker exec reads /etc/os-release / docker exec lit /etc/os-release" \
        "Debian" \
        "Le conteneur doit être en marche: docker start ${CT_DEBIAN}" \
        docker exec "${CT_DEBIAN}" cat /etc/os-release

    # -------------------------------------------------------------------------
    # docker ps: list running containers
    # FR: Lister les conteneurs en cours d'exécution
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions les conteneurs en cours d'exécution avec 'docker ps'." \
        "Let's check running containers with 'docker ps'."

    assert_output_contains \
        "docker ps shows '${CT_DEBIAN}' / docker ps montre '${CT_DEBIAN}'" \
        "${CT_DEBIAN}" \
        "Essayez: docker start ${CT_DEBIAN}" \
        docker ps --format '{{.Names}}'

    # -------------------------------------------------------------------------
    # docker stop + docker rm
    # FR: Arrêter et supprimer le conteneur Debian
    # -------------------------------------------------------------------------
    learn_pause \
        "Arrêtons et supprimons le conteneur Debian.\n  docker stop ${CT_DEBIAN}\n  docker rm ${CT_DEBIAN}" \
        "Let's stop and remove the Debian container.\n  docker stop ${CT_DEBIAN}\n  docker rm ${CT_DEBIAN}"

    assert_success \
        "docker stop '${CT_DEBIAN}'" \
        "Essayez: docker stop ${CT_DEBIAN}" \
        docker stop "${CT_DEBIAN}"

    assert_success \
        "docker rm '${CT_DEBIAN}'" \
        "Essayez: docker rm ${CT_DEBIAN}" \
        docker rm "${CT_DEBIAN}"

    assert_container_not_exists "${CT_DEBIAN}"

    # -------------------------------------------------------------------------
    # Part B: Conteneur Nginx avec mapping de port
    # FR: Lancer un conteneur Nginx avec mapping de port
    # -------------------------------------------------------------------------
    learn_pause \
        "Lançons un serveur web Nginx dans un conteneur avec mapping de port.\nCommande: docker run -d --name ${CT_NGINX} -p ${PORT_NGINX}:80 ${IMAGE_NGINX}\n\n  -p ${PORT_NGINX}:80 : mappe le port ${PORT_NGINX} de l'hôte au port 80 du conteneur" \
        "Let's run an Nginx web server in a container with port mapping.\nCommand: docker run -d --name ${CT_NGINX} -p ${PORT_NGINX}:80 ${IMAGE_NGINX}\n\n  -p ${PORT_NGINX}:80: maps host port ${PORT_NGINX} to container port 80"

    run_cmd "Pull Nginx image" "${TIMEOUT_PULL}" \
        docker pull "${IMAGE_NGINX}" || true

    run_cmd "Create Nginx container" "${TIMEOUT_DEFAULT}" \
        docker run -d --name "${CT_NGINX}" -p "${PORT_NGINX}:80" "${IMAGE_NGINX}" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "Container '${CT_NGINX}' created / Conteneur '${CT_NGINX}' créé"
    else
        fail "Failed to create container '${CT_NGINX}'" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Essayez: docker run -d --name ${CT_NGINX} -p ${PORT_NGINX}:80 ${IMAGE_NGINX}"
    fi

    # Wait for Nginx to be ready
    if wait_for_container "${CT_NGINX}" "${TIMEOUT_CONTAINER_READY}"; then
        pass "Container '${CT_NGINX}' is running / Conteneur en exécution"
    else
        fail "Container '${CT_NGINX}' not running" \
             "running" "not running" \
             "Essayez: docker logs ${CT_NGINX}"
    fi

    # Test HTTP access
    learn_pause \
        "Testons l'accès HTTP au serveur Nginx via le port mappé.\nCommande: curl -s http://localhost:${PORT_NGINX}" \
        "Let's test HTTP access to the Nginx server via the mapped port.\nCommand: curl -s http://localhost:${PORT_NGINX}"

    # Give nginx a moment to start
    sleep 2

    assert_output_contains \
        "Nginx responds on port ${PORT_NGINX} / Nginx répond sur le port ${PORT_NGINX}" \
        "Welcome to nginx" \
        "Vérifiez que le port ${PORT_NGINX} n'est pas utilisé: ss -tlnp | grep ${PORT_NGINX}" \
        curl -s --max-time 10 "http://localhost:${PORT_NGINX}"

    # docker logs
    learn_pause \
        "Consultez les logs du conteneur avec 'docker logs'." \
        "Check the container logs with 'docker logs'."

    assert_output_not_empty \
        "docker logs '${CT_NGINX}' has output / docker logs a une sortie" \
        "Le conteneur doit être démarré" \
        docker logs "${CT_NGINX}"

    # -------------------------------------------------------------------------
    # Cleanup: Stop and remove Nginx
    # FR: Nettoyage : arrêter et supprimer Nginx
    # -------------------------------------------------------------------------
    learn_pause \
        "Nettoyage : arrêtons et supprimons le conteneur Nginx." \
        "Cleanup: let's stop and remove the Nginx container."

    assert_success \
        "docker stop '${CT_NGINX}'" \
        "Essayez: docker stop ${CT_NGINX}" \
        docker stop "${CT_NGINX}"

    assert_success \
        "docker rm '${CT_NGINX}'" \
        "Essayez: docker rm ${CT_NGINX}" \
        docker rm "${CT_NGINX}"

    assert_container_not_exists "${CT_NGINX}"

    section_summary
}
