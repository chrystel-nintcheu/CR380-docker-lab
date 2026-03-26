#!/usr/bin/env bash
# =============================================================================
# CR380 — Lab 99 : Nettoyage complet / Full teardown
# =============================================================================
#
# FR: Supprime tous les conteneurs, images, volumes et réseaux créés
#     pendant les labs. Remet l'environnement à zéro.
# EN: Removes all containers, images, volumes and networks created
#     during the labs. Resets the environment to a clean state.
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"
source "$SCRIPT_DIR/../config.env"

run_test() {

LAB_NUMBER=99
LAB_TITLE="Nettoyage complet / Full teardown"
section_header "$LAB_NUMBER" "$LAB_TITLE"

PASSED=0 FAILED=0 SKIPPED=0

# ── Vérification Docker disponible / Check Docker available ──────────────
if ! command -v docker &>/dev/null; then
  skip "Docker n'est pas installé — rien à nettoyer / Docker not installed — nothing to clean"
  SKIPPED=$((SKIPPED + 1))
  section_summary "$LAB_NUMBER" "$PASSED" "$FAILED" "$SKIPPED"
  return
fi

step=1

# ═══════════════════════════════════════════════════════════════════════════
# STEP 1 — Arrêter et supprimer les conteneurs / Stop and remove containers
# ═══════════════════════════════════════════════════════════════════════════
CONTAINERS=(
  "$CT_DEBIAN"
  "$CT_NGINX"
  "$CT_NGINX_SLIM"
  "$CT_DRUPAL"
  "$CT_DRUPAL_EP"
  "$CT_COPY"
)

for ct in "${CONTAINERS[@]}"; do
  if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "$ct"; then
    if docker rm -f "$ct" &>/dev/null; then
      pass "[$step] Conteneur supprimé / Container removed: $ct"
      PASSED=$((PASSED + 1))
    else
      fail "[$step] Impossible de supprimer / Cannot remove: $ct"
      FAILED=$((FAILED + 1))
    fi
  else
    pass "[$step] Conteneur déjà absent / Container already absent: $ct"
    PASSED=$((PASSED + 1))
  fi
  step=$((step + 1))
done

# ═══════════════════════════════════════════════════════════════════════════
# STEP 2 — Supprimer les images construites / Remove built images
# ═══════════════════════════════════════════════════════════════════════════
IMAGES=(
  "$IMG_STRUCTURE"
  "$IMG_SLIM"
  "$IMG_MULTISTAGE"
  "$IMG_ENTRYPOINT"
)

for img in "${IMAGES[@]}"; do
  if docker image inspect "$img" &>/dev/null; then
    if docker rmi -f "$img" &>/dev/null; then
      pass "[$step] Image supprimée / Image removed: $img"
      PASSED=$((PASSED + 1))
    else
      fail "[$step] Impossible de supprimer / Cannot remove: $img"
      FAILED=$((FAILED + 1))
    fi
  else
    pass "[$step] Image déjà absente / Image already absent: $img"
    PASSED=$((PASSED + 1))
  fi
  step=$((step + 1))
done

# ═══════════════════════════════════════════════════════════════════════════
# STEP 3 — Supprimer les images téléchargées / Remove pulled images
# ═══════════════════════════════════════════════════════════════════════════
PULLED_IMAGES=(
  "$IMAGE_NGINX"
  "$IMAGE_NGINX_ALPINE"
  "$IMAGE_DEBIAN"
  "$IMAGE_UBUNTU"
  "$IMAGE_PHP"
  "$IMAGE_HELLO"
)

for img in "${PULLED_IMAGES[@]}"; do
  if docker image inspect "$img" &>/dev/null; then
    if docker rmi -f "$img" &>/dev/null; then
      pass "[$step] Image supprimée / Image removed: $img"
      PASSED=$((PASSED + 1))
    else
      fail "[$step] Impossible de supprimer / Cannot remove: $img"
      FAILED=$((FAILED + 1))
    fi
  else
    pass "[$step] Image déjà absente / Image already absent: $img"
    PASSED=$((PASSED + 1))
  fi
  step=$((step + 1))
done

# ═══════════════════════════════════════════════════════════════════════════
# STEP 4 — Supprimer les volumes / Remove volumes
# ═══════════════════════════════════════════════════════════════════════════
VOLUMES=(
  "$VOL_NAME"
)

for vol in "${VOLUMES[@]}"; do
  if docker volume inspect "$vol" &>/dev/null; then
    if docker volume rm "$vol" &>/dev/null; then
      pass "[$step] Volume supprimé / Volume removed: $vol"
      PASSED=$((PASSED + 1))
    else
      fail "[$step] Impossible de supprimer / Cannot remove: $vol"
      FAILED=$((FAILED + 1))
    fi
  else
    pass "[$step] Volume déjà absent / Volume already absent: $vol"
    PASSED=$((PASSED + 1))
  fi
  step=$((step + 1))
done

# ═══════════════════════════════════════════════════════════════════════════
# STEP 5 — Nettoyage final / Final prune
# ═══════════════════════════════════════════════════════════════════════════
if docker system prune -f &>/dev/null; then
  pass "[$step] Nettoyage système réussi / System prune succeeded"
  PASSED=$((PASSED + 1))
else
  fail "[$step] Nettoyage système échoué / System prune failed"
  FAILED=$((FAILED + 1))
fi

# ── Résumé / Summary ────────────────────────────────────────────────────
section_summary "$LAB_NUMBER" "$PASSED" "$FAILED" "$SKIPPED"

} # end run_test
