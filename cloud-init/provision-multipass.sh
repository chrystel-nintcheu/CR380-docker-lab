#!/usr/bin/env bash
# =============================================================================
# CR380 - Docker Lab — Multipass Provisioner
# =============================================================================
#
# FR: Lance une VM Multipass avec cloud-init pour le lab Docker.
# EN: Launch a Multipass VM with cloud-init for the Docker lab.
#
# Usage: ./provision-multipass.sh [vm-name]
# =============================================================================
set -euo pipefail

VM_NAME="${1:-cr380-docker}"
CLOUD_INIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/user-data-fresh.yaml"

if ! command -v multipass &>/dev/null; then
    echo "ERROR: multipass is not installed."
    echo "  Install: sudo snap install multipass"
    exit 1
fi

if multipass info "${VM_NAME}" &>/dev/null; then
    echo "VM '${VM_NAME}' already exists. Delete it first:"
    echo "  multipass delete ${VM_NAME} && multipass purge"
    exit 1
fi

echo "Launching VM '${VM_NAME}'..."
multipass launch 24.04 \
    --name "${VM_NAME}" \
    --cloud-init "${CLOUD_INIT}" \
    --cpus 2 \
    --memory 4G \
    --disk 20G

echo ""
echo "VM '${VM_NAME}' is ready."
echo "  Shell:  multipass shell ${VM_NAME}"
echo "  Mount:  multipass mount \$(pwd)/.. ${VM_NAME}:/home/ubuntu/CR380-docker-lab"
echo "  Delete: multipass delete ${VM_NAME} && multipass purge"
