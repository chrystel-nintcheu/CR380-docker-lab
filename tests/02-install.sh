#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 02 — Installation de Docker / Docker Installation
# =============================================================================
#
# FR: Installation de Docker CE via le dépôt officiel APT (Option 2).
#     Couvre: ajout de la clé GPG, configuration du dépôt, installation des
#     paquets docker-ce, docker-ce-cli, containerd.io, docker-buildx-plugin,
#     docker-compose-plugin. Activation et démarrage du service.
#
# EN: Install Docker CE via the official APT repository (Option 2).
#     Covers: adding GPG key, configuring the repository, installing docker-ce,
#     docker-ce-cli, containerd.io, docker-buildx-plugin,
#     docker-compose-plugin packages. Enabling and starting the service.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/installation/option-2-via-apt
# Depends on: 01
# =============================================================================

run_test() {
    section_header "02" "Installation de Docker / Docker Installation" \
        "${GITBOOK_URL_02}"

    check_dependency "01" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Step 1: Install prerequisites
    # FR: Installer les pré-requis pour HTTPS sur APT
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous devons d'abord installer les paquets nécessaires pour\nutiliser un dépôt APT via HTTPS : ca-certificates et curl." \
        "We first need to install packages required to use an\nAPT repository over HTTPS: ca-certificates and curl."

    run_cmd "Update package index" "${TIMEOUT_APT}" \
        sudo apt-get update || true

    run_cmd "Install prerequisites (ca-certificates, curl)" "${TIMEOUT_APT}" \
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl
    if (( CMD_EXIT_CODE == 0 )); then
        pass "Prerequisites installed / Pré-requis installés"
    else
        fail "Failed to install prerequisites" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez votre connexion Internet / Check your internet connection"
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 2: Add Docker's official GPG key
    # FR: Ajouter la clé GPG officielle de Docker
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous ajoutons la clé GPG officielle de Docker pour vérifier\nl'authenticité des paquets téléchargés. La clé est stockée dans\n/etc/apt/keyrings/docker.asc." \
        "We add Docker's official GPG key to verify the authenticity of\ndownloaded packages. The key is stored at\n/etc/apt/keyrings/docker.asc."

    sudo install -m 0755 -d /etc/apt/keyrings

    run_cmd "Download Docker GPG key" "${TIMEOUT_DEFAULT}" \
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
            -o /etc/apt/keyrings/docker.asc
    if (( CMD_EXIT_CODE == 0 )); then
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        pass "Docker GPG key added / Clé GPG Docker ajoutée"
    else
        fail "Failed to download Docker GPG key" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Vérifiez votre connexion Internet / Check your internet connection"
        section_summary; return
    fi

    # Verify the key file exists and is readable
    if [[ -f /etc/apt/keyrings/docker.asc ]]; then
        pass "GPG key file exists / Fichier de clé GPG présent"
    else
        fail "GPG key file missing" "/etc/apt/keyrings/docker.asc" "not found" \
             "Réessayez le téléchargement / Retry the download"
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 3: Add Docker APT repository
    # FR: Ajouter le dépôt Docker à la liste des sources APT
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous ajoutons le dépôt Docker officiel à APT. La ligne contient:\n- L'architecture du processeur (amd64, arm64, etc.)\n- La version d'Ubuntu (jammy, noble, etc.)\n- La clé GPG pour la vérification" \
        "We add the official Docker repository to APT. The line includes:\n- The processor architecture (amd64, arm64, etc.)\n- The Ubuntu release (jammy, noble, etc.)\n- The GPG key for verification"

    # shellcheck disable=SC1091
    local arch
    arch=$(dpkg --print-architecture)
    # shellcheck source=/dev/null
    local codename
    codename=$(. /etc/os-release && echo "${VERSION_CODENAME}")

    echo "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${codename} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
        pass "Docker repository added / Dépôt Docker ajouté"
    else
        fail "Docker repository file missing" \
             "/etc/apt/sources.list.d/docker.list" "not found" \
             "Vérifiez les permissions / Check permissions"
        section_summary; return
    fi

    # Update package index with new repo
    run_cmd "Update package index with Docker repo" "${TIMEOUT_APT}" \
        sudo apt-get update || true

    # -------------------------------------------------------------------------
    # Step 4: Install Docker packages
    # FR: Installer les paquets Docker CE
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous installons maintenant les paquets Docker:\n- docker-ce : le moteur Docker\n- docker-ce-cli : la ligne de commande\n- containerd.io : le runtime de conteneurs\n- docker-buildx-plugin : construction avancée\n- docker-compose-plugin : orchestration multi-conteneurs" \
        "We now install the Docker packages:\n- docker-ce: the Docker engine\n- docker-ce-cli: the command line interface\n- containerd.io: the container runtime\n- docker-buildx-plugin: advanced build features\n- docker-compose-plugin: multi-container orchestration"


    # Stop unattended-upgrades daemon which holds apt locks
    sudo systemctl stop unattended-upgrades.service 2>/dev/null || true
    sudo systemctl disable unattended-upgrades.service 2>/dev/null || true

    # Clear APT cache and wait for any apt-get locks to release
    sudo apt-get clean 2>/dev/null || true
    sudo systemctl stop apt-daily.service 2>/dev/null || true
    sudo systemctl stop apt-daily-upgrade.service 2>/dev/null || true
    sleep 2
    local lock_wait=0
    while [ -f /var/lib/apt/lists/lock ] || [ -f /var/cache/apt/archives/lock ] || [ -f /var/lib/dpkg/lock ] || [ -f /var/lib/dpkg/lock-frontend ]; do
        if (( lock_wait > 90 )); then
            echo "[warn] APT lock still held after 90s, force-breaking and proceeding"
            sudo rm -f /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend 2>/dev/null || true
            break
        fi
        sleep 1
        lock_wait=$((lock_wait + 1))
    done
    run_cmd "Install Docker CE packages" "${TIMEOUT_BUILD}" \
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin
    if (( CMD_EXIT_CODE == 0 )); then
        pass "Docker packages installed / Paquets Docker installés"
    else
        fail "Failed to install Docker packages" \
             "exit code 0" "exit code ${CMD_EXIT_CODE}" \
             "Essayez: sudo apt-get update && réessayez / Try: sudo apt-get update && retry"
        section_summary; return
    fi

    # -------------------------------------------------------------------------
    # Step 5: Enable and start Docker service
    # FR: Activer et démarrer le service Docker
    # -------------------------------------------------------------------------
    learn_pause \
        "Nous activons le service Docker au démarrage et le démarrons\nimmédiatement avec systemctl." \
        "We enable the Docker service to start on boot and start it\nimmediately with systemctl."

    sudo systemctl enable docker 2>/dev/null || true
    sudo systemctl enable containerd 2>/dev/null || true
    sudo systemctl start docker 2>/dev/null || true

    # -------------------------------------------------------------------------
    # Verification: Docker is installed and running
    # FR: Vérification : Docker est installé et actif
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que Docker est correctement installé et en cours\nd'exécution." \
        "Let's verify Docker is correctly installed and running."

    # Docker binary exists
    if command -v docker &>/dev/null; then
        pass "docker binary found / binaire docker trouvé"
    else
        fail "docker binary not found" "docker in PATH" "not found" \
             "L'installation a échoué / Installation failed"
    fi

    # Docker version
    assert_output_not_empty \
        "docker --version returns output / docker --version retourne une sortie" \
        "Essayez: sudo apt-get install docker-ce / Try: sudo apt-get install docker-ce" \
        docker --version

    # Docker service is active
    run_cmd "Check Docker service status" "${TIMEOUT_DEFAULT}" \
        systemctl is-active docker || true
    if [[ "${CMD_OUTPUT}" == "active" ]]; then
        pass "Docker service is active / Service Docker actif"
    else
        fail "Docker service not active" "active" "${CMD_OUTPUT}" \
             "Essayez: sudo systemctl start docker / Try: sudo systemctl start docker"
    fi

    # containerd service is active
    run_cmd "Check containerd service status" "${TIMEOUT_DEFAULT}" \
        systemctl is-active containerd || true
    if [[ "${CMD_OUTPUT}" == "active" ]]; then
        pass "containerd service is active / Service containerd actif"
    else
        fail "containerd service not active" "active" "${CMD_OUTPUT}" \
             "Essayez: sudo systemctl start containerd"
    fi

    # Docker info works (confirms daemon connectivity)
    assert_success \
        "docker info succeeds / docker info réussit" \
        "Essayez: sudo systemctl restart docker" \
        docker info

    section_summary
}
