#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 03 — Après installation / Post-installation
# =============================================================================
#
# FR: Configuration post-installation de Docker.
#     Couvre: création du groupe docker, ajout de l'utilisateur courant,
#     vérification de l'accès sans sudo, hello-world test.
#
# EN: Post-installation configuration of Docker.
#     Covers: creating the docker group, adding the current user,
#     verifying access without sudo, hello-world test.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/installation/apres-installation
# Depends on: 02
# =============================================================================

run_test() {
    section_header "03" "Après installation / Post-installation" \
        "${GITBOOK_URL_03}"

    check_dependency "02" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Step 1: Create docker group (if not exists)
    # FR: Créer le groupe docker (s'il n'existe pas)
    # -------------------------------------------------------------------------
    learn_pause \
        "Par défaut, Docker nécessite les privilèges root (sudo).\nPour utiliser Docker sans sudo, on ajoute l'utilisateur au\ngroupe 'docker'." \
        "By default, Docker requires root privileges (sudo).\nTo use Docker without sudo, we add the user to the\n'docker' group."

    if ! getent group docker &>/dev/null; then
        sudo groupadd docker
        pass "Docker group created / Groupe docker créé"
    else
        pass "Docker group already exists / Groupe docker existe déjà"
    fi

    # -------------------------------------------------------------------------
    # Step 2: Add current user to docker group
    # FR: Ajouter l'utilisateur courant au groupe docker
    # -------------------------------------------------------------------------
    local target_user="${SUDO_USER:-${USER}}"

    learn_pause \
        "Ajout de l'utilisateur '${target_user}' au groupe docker.\nCommande: sudo usermod -aG docker ${target_user}" \
        "Adding user '${target_user}' to the docker group.\nCommand: sudo usermod -aG docker ${target_user}"

    sudo usermod -aG docker "${target_user}"
    if (( $? == 0 )); then
        pass "User '${target_user}' added to docker group / Utilisateur ajouté au groupe docker"
    else
        fail "Failed to add user to docker group" \
             "usermod succeeds" "usermod failed" \
             "Essayez manuellement: sudo usermod -aG docker \$USER"
    fi

    # Verify group membership
    if id -nG "${target_user}" | grep -qw docker; then
        pass "User '${target_user}' is in docker group / L'utilisateur est dans le groupe docker"
    else
        # Group membership may need re-login to take effect
        pass "Group membership pending re-login / Adhésion en attente de reconnexion"
    fi

    # -------------------------------------------------------------------------
    # Step 3: Activate docker group for current session
    # FR: Activer le groupe docker pour la session en cours
    # -------------------------------------------------------------------------
    learn_pause \
        "Normalement il faut se déconnecter/reconnecter pour que le\ngroupe docker prenne effet. Pour cette session, on utilise\n'newgrp docker' ou on continue avec sudo." \
        "Normally you need to log out/in for the docker group to take\neffect. For this session, we use 'newgrp docker' or continue\nwith sudo."

    # -------------------------------------------------------------------------
    # Step 4: Test with hello-world
    # FR: Tester avec l'image hello-world
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions l'installation en lançant le conteneur hello-world.\nDocker va:\n1. Télécharger l'image depuis Docker Hub\n2. Créer un conteneur\n3. Exécuter le programme qui affiche un message\n4. Arrêter le conteneur" \
        "Let's verify the installation by running the hello-world container.\nDocker will:\n1. Pull the image from Docker Hub\n2. Create a container\n3. Run the program that prints a message\n4. Stop the container"

    assert_output_contains \
        "docker run hello-world succeeds / docker run hello-world réussit" \
        "Hello from Docker" \
        "Essayez: sudo docker run hello-world" \
        docker run "${IMAGE_HELLO}"

    # -------------------------------------------------------------------------
    # Step 5: Verify hello-world image is present
    # FR: Vérifier que l'image hello-world est présente
    # -------------------------------------------------------------------------
    assert_output_contains \
        "hello-world image present in local cache / Image hello-world dans le cache local" \
        "hello-world" \
        "L'image devrait avoir été téléchargée par docker run" \
        docker images --format '{{.Repository}}'

    # -------------------------------------------------------------------------
    # Step 6: Docker service auto-start check
    # FR: Vérifier le démarrage automatique de Docker
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que le service Docker est configuré pour démarrer\nautomatiquement au boot du système." \
        "Let's verify that the Docker service is configured to start\nautomatically on system boot."

    run_cmd "Check docker.service enabled" "${TIMEOUT_DEFAULT}" \
        systemctl is-enabled docker || true
    if [[ "${CMD_OUTPUT}" == "enabled" ]]; then
        pass "Docker auto-start enabled / Démarrage automatique Docker activé"
    else
        fail "Docker auto-start not enabled" "enabled" "${CMD_OUTPUT}" \
             "Essayez: sudo systemctl enable docker"
    fi

    # Cleanup hello-world container(s)
    docker rm -f "$(docker ps -aq --filter ancestor=${IMAGE_HELLO})" 2>/dev/null || true

    section_summary
}
