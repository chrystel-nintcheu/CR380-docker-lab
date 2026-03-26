#!/usr/bin/env bash
# =============================================================================
# CR380 - Lab 01 — Désinstallation / Uninstallation
# =============================================================================
#
# FR: Désinstallation complète de Docker pour repartir sur une base propre.
#     Couvre: arrêt du service, purge des paquets, suppression des fichiers
#     résiduels, suppression du dépôt Docker (si présent), suppression des
#     groupes docker.
#
# EN: Complete uninstallation of Docker for a clean start.
#     Covers: stopping the service, purging packages, removing leftover files,
#     removing Docker repository (if present), removing docker groups.
#
# GitBook: ${GITBOOK_BASE_URL}/docker-lab/desinstallation
# Depends on: 00-preflight
# =============================================================================

run_test() {
    section_header "01" "Désinstallation / Uninstallation" \
        "${GITBOOK_URL_01}"

    check_dependency "00" || { section_summary; return; }

    # -------------------------------------------------------------------------
    # Check if Docker is installed
    # FR: Vérifier si Docker est installé
    # -------------------------------------------------------------------------
    if command -v docker &>/dev/null || dpkg -l docker-ce 2>/dev/null | grep -q '^ii'; then

        learn_pause \
            "Docker est installé. Nous allons le désinstaller complètement.\nCela inclut: arrêt du service, purge des paquets, suppression des\nfichiers résiduels, suppression du dépôt et du groupe docker." \
            "Docker is installed. We will uninstall it completely.\nThis includes: stopping the service, purging packages, removing\nleftover files, removing the repository and docker group."

        # ---------------------------------------------------------------------
        # Step 1: Stop docker service
        # FR: Arrêter le service Docker
        # ---------------------------------------------------------------------
        learn_pause \
            "Commande: sudo systemctl stop docker docker.socket containerd\nNous arrêtons d'abord le service Docker avant de le désinstaller." \
            "Command: sudo systemctl stop docker docker.socket containerd\nWe stop the Docker service before uninstalling."

        for svc in docker docker.socket containerd; do
            sudo systemctl stop "${svc}" 2>/dev/null || true
        done
        pass "Docker services stopped / Services Docker arrêtés"

        # Stop all containers first to avoid purge issues
        if command -v docker &>/dev/null; then
            docker stop $(docker ps -aq) 2>/dev/null || true
            docker rm -f $(docker ps -aq) 2>/dev/null || true
        fi

        # ---------------------------------------------------------------------
        # Step 2: Purge docker packages
        # FR: Purger les paquets Docker
        # ---------------------------------------------------------------------
        learn_pause \
            "Commande: sudo apt-get -o DPkg::Lock::Timeout=120 purge docker-ce docker-ce-cli containerd.io ...\napt remove --purge supprime le paquet ET ses fichiers de config." \
            "Command: sudo apt-get -o DPkg::Lock::Timeout=120 purge docker-ce docker-ce-cli containerd.io ...\napt remove --purge removes the package AND its config files."

        run_cmd "Purge Docker packages" "0" \
            sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 remove --purge -y \
            docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin \
            docker-ce-rootless-extras 2>/dev/null || true

        # Remove old / unofficial versions
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 \
                   podman-docker containerd runc; do
            sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 remove --purge -y "${pkg}" 2>/dev/null || true
        done

        run_cmd "Clean apt cache" "${TIMEOUT_DEFAULT}" \
            sudo apt-get -o DPkg::Lock::Timeout=120 clean || true
        run_cmd "Autoremove unused packages" "0" \
            sudo DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=120 autoremove -y || true

        pass "Packages purged / Paquets purgés"

        # ---------------------------------------------------------------------
        # Step 3: Remove leftover files
        # FR: Supprimer les fichiers résiduels
        # ---------------------------------------------------------------------
        learn_pause \
            "Suppression des fichiers résiduels dans /var/lib/docker et\n/var/lib/containerd." \
            "Removing leftover files in /var/lib/docker and\n/var/lib/containerd."

        if [[ -d /var/lib/docker ]] || [[ -d /var/lib/containerd ]]; then
            sudo rm -rf /var/lib/docker
            sudo rm -rf /var/lib/containerd
            pass "Leftover files removed / Fichiers résiduels supprimés"
        else
            pass "No leftover files found / Aucun fichier résiduel"
        fi

        # ---------------------------------------------------------------------
        # Step 4: Remove Docker repository and GPG key
        # FR: Supprimer le dépôt Docker et la clé GPG
        # ---------------------------------------------------------------------
        learn_pause \
            "Suppression des sources APT et de la clé GPG de Docker." \
            "Removing Docker APT sources and GPG key."

        if [[ -f /etc/apt/sources.list.d/docker.list ]]; then
            sudo rm -f /etc/apt/sources.list.d/docker.list
            pass "Docker APT source removed / Source APT Docker supprimée"
        else
            pass "No Docker APT source found / Aucune source APT Docker"
        fi

        if [[ -f /etc/apt/keyrings/docker.asc ]]; then
            sudo rm -f /etc/apt/keyrings/docker.asc
            pass "Docker GPG key removed / Clé GPG Docker supprimée"
        else
            pass "No Docker GPG key found / Aucune clé GPG Docker"
        fi

        # ---------------------------------------------------------------------
        # Step 5: Remove docker groups
        # FR: Supprimer les groupes docker
        # ---------------------------------------------------------------------
        learn_pause \
            "Suppression des groupes système créés par Docker." \
            "Removing system groups created by Docker."

        local groups
        groups=$(cut -d: -f1 /etc/group | grep docker || true)
        if [[ -n "${groups}" ]]; then
            while IFS= read -r grp; do
                sudo groupdel "${grp}" 2>/dev/null || true
                log "Deleted group: ${grp}"
            done <<< "${groups}"
            pass "Docker groups removed / Groupes Docker supprimés"
        else
            pass "No docker groups found / Aucun groupe docker"
        fi

        # Update package list
        run_cmd "Update package list" "${TIMEOUT_APT}" \
            sudo apt-get -o DPkg::Lock::Timeout=120 update --fix-missing || true

    else
        pass "Docker was not installed — nothing to uninstall / Docker n'était pas installé"
    fi

    # -------------------------------------------------------------------------
    # Verification: Assert clean state
    # FR: Vérification : S'assurer que le système est propre
    # -------------------------------------------------------------------------
    learn_pause \
        "Vérifions que tout a bien été supprimé." \
        "Let's verify everything has been removed."

    # Assert docker binary is gone
    hash -r  # Clear shell's command hash table after package removal
    if ! command -v docker &>/dev/null; then
        pass "docker binary not found (clean) / binaire docker absent (propre)"
    else
        fail "docker binary still present" \
             "docker not found" \
             "$(which docker)" \
             "Essayez: sudo apt remove --purge docker-ce && hash -r"
    fi

    # Assert no docker groups remain
    local remaining_groups
    remaining_groups=$(cut -d: -f1 /etc/group | grep docker || true)
    if [[ -z "${remaining_groups}" ]]; then
        pass "No docker groups remain / Aucun groupe docker restant"
    else
        fail "Docker groups still present" \
             "no docker groups" \
             "${remaining_groups}" \
             "Essayez: sudo groupdel docker"
    fi

    # Assert /var/lib/docker is gone
    if [[ ! -d /var/lib/docker ]]; then
        pass "/var/lib/docker removed / /var/lib/docker supprimé"
    else
        fail "/var/lib/docker still exists" \
             "directory not found" \
             "directory exists" \
             "Essayez: sudo rm -rf /var/lib/docker"
    fi

    # Assert Docker APT source is gone
    if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
        pass "Docker APT source removed / Source APT Docker supprimée"
    else
        fail "Docker APT source still present" \
             "file not found" \
             "file exists" \
             "Essayez: sudo rm /etc/apt/sources.list.d/docker.list"
    fi

    section_summary
}
