#!/usr/bin/env bash
# =============================================================================
# CR380 - Docker Lab Test Suite — Framework commun / Common framework
# =============================================================================
#
# FR: Ce fichier contient toutes les fonctions utilitaires partagées entre les
#     scripts de test. Il gère l'affichage coloré, les assertions, les délais
#     d'attente, le mode apprentissage, les dépendances entre tests, et la
#     génération de rapports JSON.
#
# EN: This file contains all shared utility functions used by the test scripts.
#     It handles colored output, assertions, timeouts, learn mode, test
#     dependencies, and JSON report generation.
#
# STUDENT NOTE / NOTE ÉTUDIANT:
#   Ce fichier est le "moteur" de la suite de tests. Lisez-le pour comprendre
#   comment chaque lab est validé automatiquement.
#   This file is the test suite "engine". Read it to understand how each lab
#   is automatically validated.
# =============================================================================

# -----------------------------------------------------------------------------
# Strict mode
# -----------------------------------------------------------------------------
set -o pipefail

# -----------------------------------------------------------------------------
# Resolve paths / Résolution des chemins
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RESULTS_DIR="${PROJECT_DIR}/results"
LOG_DIR="${PROJECT_DIR}/logs"
DOCKERFILES_DIR="${PROJECT_DIR}/dockerfiles"

# Source configuration
# shellcheck source=../config.env
source "${PROJECT_DIR}/config.env"

# Create output dirs if needed
mkdir -p "${RESULTS_DIR}" "${LOG_DIR}"

# -----------------------------------------------------------------------------
# Colors / Couleurs
# -----------------------------------------------------------------------------
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' DIM='' NC=''
fi

# -----------------------------------------------------------------------------
# Global counters / Compteurs globaux
# -----------------------------------------------------------------------------
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
SECTION_PASS=0
SECTION_FAIL=0
SECTION_SKIP=0
SECTION_START_TIME=0
CURRENT_SECTION=""
CURRENT_SECTION_NUM=""

# Associative array for test results (used for dependency tracking)
declare -gA TEST_RESULTS

# Command output capture
CMD_OUTPUT=""
CMD_EXIT_CODE=0

# -----------------------------------------------------------------------------
# Logging / Journalisation
# -----------------------------------------------------------------------------
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
LOG_FILE="${LOG_DIR}/test-${TIMESTAMP}.log"
REPORT_FILE="${RESULTS_DIR}/report-${TIMESTAMP}.json"

log() {
    echo "[$(date '+%H:%M:%S')] $*" >> "${LOG_FILE}"
}

# =============================================================================
# SECTION MANAGEMENT / GESTION DES SECTIONS
# =============================================================================

# FR: URLs GitBook pour chaque lab
# EN: GitBook URLs for each lab
GITBOOK_URL_00=""
GITBOOK_URL_01="${GITBOOK_BASE_URL}/docker-lab/desinstallation"
GITBOOK_URL_02="${GITBOOK_BASE_URL}/docker-lab/installation/option-2-via-apt"
GITBOOK_URL_03="${GITBOOK_BASE_URL}/docker-lab/installation/apres-installation"
GITBOOK_URL_04="${GITBOOK_BASE_URL}/docker-lab/tester-linstallation"
GITBOOK_URL_05=""
GITBOOK_URL_06="${GITBOOK_BASE_URL}/docker-lab/image/structure"
GITBOOK_URL_07="${GITBOOK_BASE_URL}/docker-lab/image/reduire-le-poids"
GITBOOK_URL_08="${GITBOOK_BASE_URL}/docker-lab/image/multi-stage-builds"
GITBOOK_URL_09="${GITBOOK_BASE_URL}/docker-lab/image/entrypoint"
GITBOOK_URL_10=""
GITBOOK_URL_11=""
GITBOOK_URL_99=""

section_header() {
    local num="$1"
    local title="$2"
    local gitbook_url="${3:-}"

    CURRENT_SECTION_NUM="${num}"
    CURRENT_SECTION="${title}"
    SECTION_PASS=0
    SECTION_FAIL=0
    SECTION_SKIP=0
    SECTION_START_TIME=$(date +%s)

    log "===== START: [${num}] ${title} ====="

    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${BLUE}  LAB ${num} — ${title}${NC}"
    if [[ -n "${gitbook_url}" ]]; then
        echo -e "${DIM}  📖 ${gitbook_url}${NC}"
    fi
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# FR: Afficher le résumé d'une section et enregistrer le résultat
# EN: Display the section summary and record the result
section_summary() {
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - SECTION_START_TIME ))
    local status="pass"
    local error=""

    if (( SECTION_FAIL > 0 )); then
        status="fail"
        error="${SECTION_FAIL} assertion(s) failed"
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="fail"
    elif (( SECTION_SKIP > 0 && SECTION_PASS == 0 )); then
        status="skip"
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="skip"
    else
        TEST_RESULTS["${CURRENT_SECTION_NUM}"]="pass"
    fi

    echo ""
    echo -e "${DIM}  ──────────────────────────────────────────────────────────${NC}"
    if [[ "${status}" == "pass" ]]; then
        echo -e "  ${GREEN}${BOLD}✓ LAB ${CURRENT_SECTION_NUM} PASSED${NC} ${DIM}(${SECTION_PASS} checks, ${duration}s)${NC}"
    elif [[ "${status}" == "skip" ]]; then
        echo -e "  ${YELLOW}${BOLD}⊘ LAB ${CURRENT_SECTION_NUM} SKIPPED${NC} ${DIM}(${duration}s)${NC}"
    else
        echo -e "  ${RED}${BOLD}✗ LAB ${CURRENT_SECTION_NUM} FAILED${NC} ${DIM}(${SECTION_PASS} passed, ${SECTION_FAIL} failed, ${duration}s)${NC}"
    fi

    write_json_result "${CURRENT_SECTION_NUM}-${CURRENT_SECTION}" "${status}" "${duration}" "${error}"

    log "===== END: [${CURRENT_SECTION_NUM}] ${CURRENT_SECTION} => ${status} (${duration}s) ====="
}

# =============================================================================
# ASSERTIONS / VÉRIFICATIONS
# =============================================================================

# FR: Marquer un test comme réussi / EN: Mark a test as passed
pass() {
    local msg="$1"
    (( TOTAL_PASS++ )) || true
    (( SECTION_PASS++ )) || true
    log "PASS: ${msg}"
    echo -e "  ${GREEN}✓${NC} ${msg}"
}

# FR: Marquer un test comme échoué avec détails et indice
# EN: Mark a test as failed with details and hint
#
# Usage: fail "description" "expected_value" "actual_value" "hint for student"
fail() {
    local msg="$1"
    local expected="${2:-}"
    local actual="${3:-}"
    local hint="${4:-}"
    (( TOTAL_FAIL++ )) || true
    (( SECTION_FAIL++ )) || true
    log "FAIL: ${msg} | expected=[${expected}] actual=[${actual}] hint=[${hint}]"
    echo -e "  ${RED}✗${NC} ${msg}"
    if [[ -n "${expected}" ]]; then
        echo -e "    ${DIM}Attendu / Expected : ${NC}${expected}"
    fi
    if [[ -n "${actual}" ]]; then
        echo -e "    ${DIM}Obtenu  / Actual   : ${NC}${actual}"
    fi
    if [[ -n "${hint}" ]]; then
        echo -e "    ${YELLOW}💡 HINT: ${hint}${NC}"
    fi
}

# FR: Marquer un test comme ignoré / EN: Mark a test as skipped
skip() {
    local msg="$1"
    local reason="${2:-}"
    (( TOTAL_SKIP++ )) || true
    (( SECTION_SKIP++ )) || true
    log "SKIP: ${msg} | reason=[${reason}]"
    echo -e "  ${YELLOW}⊘${NC} ${msg}"
    if [[ -n "${reason}" ]]; then
        echo -e "    ${DIM}Raison / Reason : ${reason}${NC}"
    fi
}

# =============================================================================
# COMMAND RUNNER / EXÉCUTION DE COMMANDES
# =============================================================================

# FR: Exécuter une commande, capturer la sortie et le code de retour
# EN: Run a command, capture output and exit code
#
# Usage: run_cmd "description" timeout_seconds command [args...]
run_cmd() {
    local description="$1"
    local cmd_timeout="$2"
    shift 2

    local cmd=("$@")

    CMD_OUTPUT=""
    CMD_EXIT_CODE=0

    log "RUN: ${cmd[*]} (timeout=${cmd_timeout}s)"

    # Run with timeout and capture output
    if (( cmd_timeout > 0 )); then
        CMD_OUTPUT=$(timeout "${cmd_timeout}" "${cmd[@]}" 2>&1) || CMD_EXIT_CODE=$?
    else
        CMD_OUTPUT=$("${cmd[@]}" 2>&1) || CMD_EXIT_CODE=$?
    fi

    # Check for timeout (exit code 124)
    if (( CMD_EXIT_CODE == 124 )); then
        log "TIMEOUT after ${cmd_timeout}s: ${cmd[*]}"
        CMD_OUTPUT="TIMEOUT after ${cmd_timeout} seconds"
    fi

    # Log output (truncated if too long)
    if (( ${#CMD_OUTPUT} > 2000 )); then
        log "OUTPUT (truncated): ${CMD_OUTPUT:0:2000}..."
    else
        log "OUTPUT: ${CMD_OUTPUT}"
    fi
    log "EXIT_CODE: ${CMD_EXIT_CODE}"

    return ${CMD_EXIT_CODE}
}

# -----------------------------------------------------------------------------
# assert_success — Run command and check it exits 0
# FR: Exécuter une commande et vérifier qu'elle réussit (code 0)
#
# Usage: assert_success "description" hint command [args...]
# -----------------------------------------------------------------------------
assert_success() {
    local description="$1"
    local hint="$2"
    shift 2

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if (( CMD_EXIT_CODE == 0 )); then
        pass "${description}"
    else
        fail "${description}" "exit code 0 (success)" "exit code ${CMD_EXIT_CODE}" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_failure — Run command and check it exits non-zero
# FR: Exécuter une commande et vérifier qu'elle échoue (code ≠ 0)
#
# Usage: assert_failure "description" hint command [args...]
# -----------------------------------------------------------------------------
assert_failure() {
    local description="$1"
    local hint="$2"
    shift 2

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if (( CMD_EXIT_CODE != 0 )); then
        pass "${description}"
    else
        fail "${description}" "non-zero exit code (failure)" "exit code 0 (success)" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_output_contains — Run command and check output contains substring
# FR: Exécuter une commande et vérifier que la sortie contient une sous-chaîne
#
# Usage: assert_output_contains "description" "substring" hint command [args...]
# -----------------------------------------------------------------------------
assert_output_contains() {
    local description="$1"
    local substring="$2"
    local hint="$3"
    shift 3

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if echo "${CMD_OUTPUT}" | grep -qi "${substring}"; then
        pass "${description}"
    else
        local actual_short="${CMD_OUTPUT}"
        if (( ${#actual_short} > 200 )); then
            actual_short="${actual_short:0:200}..."
        fi
        fail "${description}" "output containing '${substring}'" "${actual_short}" "${hint}"
    fi
}

# -----------------------------------------------------------------------------
# assert_output_not_contains — Run command and check output does NOT contain
# FR: Exécuter et vérifier que la sortie ne contient PAS une sous-chaîne
#
# Usage: assert_output_not_contains "description" "substring" hint command [args...]
# -----------------------------------------------------------------------------
assert_output_not_contains() {
    local description="$1"
    local substring="$2"
    local hint="$3"
    shift 3

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if echo "${CMD_OUTPUT}" | grep -qi "${substring}"; then
        local actual_short="${CMD_OUTPUT}"
        if (( ${#actual_short} > 200 )); then
            actual_short="${actual_short:0:200}..."
        fi
        fail "${description}" "output NOT containing '${substring}'" "${actual_short}" "${hint}"
    else
        pass "${description}"
    fi
}

# -----------------------------------------------------------------------------
# assert_output_not_empty — Run command and check output is not empty
# FR: Exécuter une commande et vérifier que la sortie n'est pas vide
#
# Usage: assert_output_not_empty "description" hint command [args...]
# -----------------------------------------------------------------------------
assert_output_not_empty() {
    local description="$1"
    local hint="$2"
    shift 2

    run_cmd "${description}" "${TIMEOUT_DEFAULT}" "$@" || true

    if [[ -n "${CMD_OUTPUT}" ]]; then
        pass "${description}"
    else
        fail "${description}" "non-empty output" "(empty)" "${hint}"
    fi
}

# =============================================================================
# DEPENDENCY MANAGEMENT / GESTION DES DÉPENDANCES
# =============================================================================

# FR: Vérifier si les dépendances d'un test ont réussi
# EN: Check if a test's dependencies have passed
#
# Usage: check_dependency "05" || return 0
# Returns 0 if dependency is met, 1 if not
check_dependency() {
    local dep_num="$1"
    local dep_result="${TEST_RESULTS[${dep_num}]:-unknown}"

    if [[ "${dep_result}" == "pass" ]]; then
        return 0
    fi

    echo -e "  ${YELLOW}⊘ Dépendance non satisfaite / Dependency not met: Lab ${dep_num} (${dep_result})${NC}"
    echo -e "  ${DIM}  Dépendance non satisfaite. Exécuter d'abord le lab ${dep_num}.${NC}"
    echo -e "  ${DIM}  Dependency not met. Run lab ${dep_num} first.${NC}"
    SECTION_SKIP=1
    TEST_RESULTS["${CURRENT_SECTION_NUM}"]="skip"
    return 1
}

# =============================================================================
# LEARN MODE / MODE APPRENTISSAGE
# =============================================================================

# FR: En mode apprentissage, afficher une explication et attendre que
#     l'étudiant appuie sur Entrée pour continuer.
# EN: In learn mode, display an explanation and wait for the student
#     to press Enter to continue.
#
# Usage: learn_pause "Explication en français" "Explanation in English"
learn_pause() {
    local msg_fr="$1"
    local msg_en="${2:-}"

    if [[ "${MODE}" != "learn" ]]; then
        return 0
    fi

    echo ""
    echo -e "${CYAN}  ╭─────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}  │${NC} ${BOLD}📘 NOTE${NC}"
    echo -e "${CYAN}  │${NC}"
    # Print FR message, wrapped
    while IFS= read -r line; do
        echo -e "${CYAN}  │${NC}  ${line}"
    done <<< "${msg_fr}"
    if [[ -n "${msg_en}" ]]; then
        echo -e "${CYAN}  │${NC}"
        while IFS= read -r line; do
            echo -e "${CYAN}  │${NC}  ${DIM}${line}${NC}"
        done <<< "${msg_en}"
    fi
    echo -e "${CYAN}  │${NC}"
    echo -e "${CYAN}  ╰─────────────────────────────────────────────────────────╯${NC}"
    echo ""

    read -rp "  ⏎ Appuyez sur Entrée pour continuer / Press Enter to continue... "
    echo ""
}

# =============================================================================
# JSON REPORT / RAPPORT JSON
# =============================================================================

# FR: Écrire un résultat de test dans le rapport JSON
# EN: Write a test result to the JSON report
write_json_result() {
    local name="$1"
    local status="$2"
    local duration="$3"
    local error="${4:-}"

    # Initialize report file if it doesn't exist
    if [[ ! -f "${REPORT_FILE}" ]]; then
        echo '{"tests":[],"summary":{}}' > "${REPORT_FILE}"
    fi

    # Append result (we'll finalize at the end)
    log "JSON: ${name} => ${status} (${duration}s)"
}

# FR: Finaliser le rapport JSON
# EN: Finalize the JSON report
finalize_report() {
    cat > "${REPORT_FILE}" <<EOF
{
  "timestamp": "${TIMESTAMP}",
  "mode": "${MODE}",
  "summary": {
    "pass": ${TOTAL_PASS},
    "fail": ${TOTAL_FAIL},
    "skip": ${TOTAL_SKIP}
  }
}
EOF

    # Cleanup old reports — keep last 10
    local count
    count=$(find "${RESULTS_DIR}" -name 'report-*.json' | wc -l)
    if (( count > 10 )); then
        find "${RESULTS_DIR}" -name 'report-*.json' -printf '%T@ %p\n' \
            | sort -n | head -n $(( count - 10 )) | awk '{print $2}' \
            | xargs rm -f
    fi

    count=$(find "${LOG_DIR}" -name 'test-*.log' | wc -l)
    if (( count > 10 )); then
        find "${LOG_DIR}" -name 'test-*.log' -printf '%T@ %p\n' \
            | sort -n | head -n $(( count - 10 )) | awk '{print $2}' \
            | xargs rm -f
    fi
}

# =============================================================================
# FINAL SUMMARY / RÉSUMÉ FINAL
# =============================================================================

# FR: Afficher le résumé final de tous les tests
# EN: Display the final summary of all tests
print_final_summary() {
    local total=$(( TOTAL_PASS + TOTAL_FAIL + TOTAL_SKIP ))

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  RÉSUMÉ FINAL / FINAL SUMMARY${NC}"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}✓ Réussis  / Passed  : ${TOTAL_PASS}${NC}"
    echo -e "  ${RED}✗ Échoués  / Failed  : ${TOTAL_FAIL}${NC}"
    echo -e "  ${YELLOW}⊘ Ignorés  / Skipped : ${TOTAL_SKIP}${NC}"
    echo -e "  ${DIM}  Total              : ${total}${NC}"
    echo ""
    echo -e "  ${DIM}📄 Log    : ${LOG_FILE}${NC}"
    echo -e "  ${DIM}📊 Report : ${REPORT_FILE}${NC}"
    echo ""

    if (( TOTAL_FAIL == 0 )); then
        echo -e "  ${GREEN}${BOLD}🎉 TOUS LES TESTS ONT RÉUSSI / ALL TESTS PASSED${NC}"
    else
        echo -e "  ${RED}${BOLD}⚠  ${TOTAL_FAIL} TEST(S) FAILED / ${TOTAL_FAIL} TEST(S) ÉCHOUÉ(S)${NC}"
        echo -e "  ${DIM}  Consultez le log pour plus de détails / Check the log for details${NC}"
    fi

    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# =============================================================================
# REPORT DIFF / COMPARAISON DE RAPPORTS
# =============================================================================

# FR: Comparer le dernier rapport avec le précédent
# EN: Compare the latest report with the previous one
diff_reports() {
    local reports
    reports=$(find "${RESULTS_DIR}" -name 'report-*.json' | sort | tail -2)
    local count
    count=$(echo "${reports}" | wc -l)

    if (( count < 2 )); then
        echo -e "${YELLOW}  Pas assez de rapports pour comparer (besoin de 2 minimum)${NC}"
        echo -e "${YELLOW}  Not enough reports to compare (need at least 2)${NC}"
        return 0
    fi

    local prev curr
    prev=$(echo "${reports}" | head -1)
    curr=$(echo "${reports}" | tail -1)

    echo -e "${BOLD}  Comparaison / Comparison:${NC}"
    echo -e "  ${DIM}Précédent / Previous: ${prev}${NC}"
    echo -e "  ${DIM}Courant   / Current : ${curr}${NC}"
    echo ""

    if command -v jq &>/dev/null; then
        local prev_summary curr_summary
        prev_summary=$(jq -r '.summary | "pass=\(.pass) fail=\(.fail) skip=\(.skip)"' "${prev}")
        curr_summary=$(jq -r '.summary | "pass=\(.pass) fail=\(.fail) skip=\(.skip)"' "${curr}")
        echo -e "  Précédent / Previous : ${prev_summary}"
        echo -e "  Courant   / Current  : ${curr_summary}"
        if [[ "${prev_summary}" == "${curr_summary}" ]]; then
            echo -e "  ${GREEN}✓ Pas de changement / No changes${NC}"
        else
            echo -e "  ${YELLOW}⚠  Résultats différents / Results differ${NC}"
        fi
    else
        diff --color=auto <(cat "${prev}") <(cat "${curr}") || true
    fi
}

# =============================================================================
# CONTAINER HELPERS / UTILITAIRES CONTENEURS
# =============================================================================

# -----------------------------------------------------------------------------
# assert_container_exists — Check a container exists (any state)
# FR: Vérifier qu'un conteneur existe (peu importe l'état)
#
# Usage: assert_container_exists "container_name"
# -----------------------------------------------------------------------------
assert_container_exists() {
    local name="$1"
    if docker ps -a --format '{{.Names}}' | grep -qx "${name}"; then
        pass "Container '${name}' exists / Conteneur '${name}' existe"
    else
        fail "Container '${name}' not found" \
             "container exists" "not found" \
             "Essayez: docker ps -a | grep ${name}"
    fi
}

# -----------------------------------------------------------------------------
# assert_container_not_exists — Check a container does NOT exist
# FR: Vérifier qu'un conteneur n'existe PAS
#
# Usage: assert_container_not_exists "container_name"
# -----------------------------------------------------------------------------
assert_container_not_exists() {
    local name="$1"
    if docker ps -a --format '{{.Names}}' | grep -qx "${name}"; then
        fail "Container '${name}' still exists" \
             "container removed" "container present" \
             "Essayez: docker rm -f ${name}"
    else
        pass "Container '${name}' cleaned up / Conteneur '${name}' nettoyé"
    fi
}

# -----------------------------------------------------------------------------
# assert_container_running — Check a container is running
# FR: Vérifier qu'un conteneur est en cours d'exécution
#
# Usage: assert_container_running "container_name"
# -----------------------------------------------------------------------------
assert_container_running() {
    local name="$1"
    local state
    state=$(docker inspect -f '{{.State.Status}}' "${name}" 2>/dev/null || echo "not found")
    if [[ "${state}" == "running" ]]; then
        pass "Container '${name}' is running / Conteneur '${name}' en exécution"
    else
        fail "Container '${name}' not running" \
             "running" "${state}" \
             "Essayez: docker start ${name}"
    fi
}

# -----------------------------------------------------------------------------
# cleanup_container — Remove a container (force, ignore errors)
# FR: Supprimer un conteneur (forcer, ignorer les erreurs)
#
# Usage: cleanup_container "container_name"
# -----------------------------------------------------------------------------
cleanup_container() {
    local name="$1"
    docker rm -f "${name}" &>/dev/null || true
    log "Cleanup: removed container ${name}"
}

# -----------------------------------------------------------------------------
# wait_for_container — Wait for a container to reach "running" state
# FR: Attendre qu'un conteneur atteigne l'état "running"
#
# Usage: wait_for_container "container_name" [timeout_seconds]
# Returns: 0 if running, 1 if timeout
# -----------------------------------------------------------------------------
wait_for_container() {
    local name="$1"
    local wait_timeout="${2:-${TIMEOUT_CONTAINER_READY}}"
    local elapsed=0

    while (( elapsed < wait_timeout )); do
        local state
        state=$(docker inspect -f '{{.State.Status}}' "${name}" 2>/dev/null || echo "not found")
        if [[ "${state}" == "running" ]]; then
            return 0
        fi
        sleep 1
        (( elapsed++ )) || true
    done
    return 1
}

# =============================================================================
# IMAGE HELPERS / UTILITAIRES IMAGES
# =============================================================================

# -----------------------------------------------------------------------------
# assert_image_exists — Check a Docker image exists locally
# FR: Vérifier qu'une image Docker existe localement
#
# Usage: assert_image_exists "image:tag"
# -----------------------------------------------------------------------------
assert_image_exists() {
    local image="$1"
    if docker image inspect "${image}" &>/dev/null; then
        pass "Image '${image}' exists / Image '${image}' existe"
    else
        fail "Image '${image}' not found" \
             "image exists" "not found" \
             "Essayez: docker pull ${image}"
    fi
}

# -----------------------------------------------------------------------------
# assert_image_not_exists — Check a Docker image does NOT exist locally
# FR: Vérifier qu'une image Docker n'existe PAS localement
#
# Usage: assert_image_not_exists "image:tag"
# -----------------------------------------------------------------------------
assert_image_not_exists() {
    local image="$1"
    if docker image inspect "${image}" &>/dev/null; then
        fail "Image '${image}' still exists" \
             "image removed" "image present" \
             "Essayez: docker rmi ${image}"
    else
        pass "Image '${image}' cleaned up / Image '${image}' nettoyée"
    fi
}

# -----------------------------------------------------------------------------
# cleanup_image — Remove an image (force, ignore errors)
# FR: Supprimer une image (forcer, ignorer les erreurs)
#
# Usage: cleanup_image "image:tag"
# -----------------------------------------------------------------------------
cleanup_image() {
    local image="$1"
    docker rmi -f "${image}" &>/dev/null || true
    log "Cleanup: removed image ${image}"
}

# -----------------------------------------------------------------------------
# assert_image_smaller_than — Check an image is smaller than a reference
# FR: Vérifier qu'une image est plus petite qu'une autre
#
# Usage: assert_image_smaller_than "slim_image" "big_image"
# -----------------------------------------------------------------------------
assert_image_smaller_than() {
    local small_img="$1"
    local big_img="$2"

    local size_small size_big
    size_small=$(docker image inspect "${small_img}" --format '{{.Size}}' 2>/dev/null || echo 0)
    size_big=$(docker image inspect "${big_img}" --format '{{.Size}}' 2>/dev/null || echo 0)

    if (( size_small > 0 && size_big > 0 && size_small < size_big )); then
        local saved=$(( (size_big - size_small) / 1048576 ))
        pass "'${small_img}' ($(( size_small / 1048576 ))MB) < '${big_img}' ($(( size_big / 1048576 ))MB) — saved ${saved}MB"
    elif (( size_small == 0 || size_big == 0 )); then
        fail "Cannot compare image sizes" \
             "both images exist" "missing image" \
             "Assurez-vous que les deux images sont construites"
    else
        fail "'${small_img}' is NOT smaller than '${big_img}'" \
             "$(( size_small / 1048576 ))MB < $(( size_big / 1048576 ))MB" \
             "$(( size_small / 1048576 ))MB >= $(( size_big / 1048576 ))MB" \
             "Vérifiez le Dockerfile slim (apt clean, rm lists, etc.)"
    fi
}

# -----------------------------------------------------------------------------
# assert_http_reachable — Check a URL returns HTTP 200 or 302
# FR: Vérifier qu'une URL retourne HTTP 200 ou 302
#
# Usage: assert_http_reachable "description" "url" [timeout]
# -----------------------------------------------------------------------------
assert_http_reachable() {
    local description="$1"
    local url="$2"
    local http_timeout="${3:-15}"

    local http_code
    http_code=$(curl -s -o /dev/null -w '%{http_code}' --max-time "${http_timeout}" "${url}" 2>/dev/null || echo "000")

    if [[ "${http_code}" == "200" ]] || [[ "${http_code}" == "302" ]] || [[ "${http_code}" == "301" ]]; then
        pass "${description} (HTTP ${http_code})"
    else
        fail "${description}" \
             "HTTP 200/301/302" "HTTP ${http_code}" \
             "Vérifiez que le conteneur est démarré et le port mappé"
    fi
}

# =============================================================================
# VOLUME HELPERS / UTILITAIRES VOLUMES
# =============================================================================

# -----------------------------------------------------------------------------
# assert_volume_exists — Check a Docker volume exists
# FR: Vérifier qu'un volume Docker existe
#
# Usage: assert_volume_exists "volume_name"
# -----------------------------------------------------------------------------
assert_volume_exists() {
    local name="$1"
    if docker volume inspect "${name}" &>/dev/null; then
        pass "Volume '${name}' exists / Volume '${name}' existe"
    else
        fail "Volume '${name}' not found" \
             "volume exists" "not found" \
             "Essayez: docker volume create ${name}"
    fi
}

# -----------------------------------------------------------------------------
# assert_volume_not_exists — Check a Docker volume does NOT exist
# FR: Vérifier qu'un volume Docker n'existe PAS
#
# Usage: assert_volume_not_exists "volume_name"
# -----------------------------------------------------------------------------
assert_volume_not_exists() {
    local name="$1"
    if docker volume inspect "${name}" &>/dev/null; then
        fail "Volume '${name}' still exists" \
             "volume removed" "volume present" \
             "Essayez: docker volume rm ${name}"
    else
        pass "Volume '${name}' cleaned up / Volume '${name}' nettoyé"
    fi
}

# -----------------------------------------------------------------------------
# cleanup_volume — Remove a volume (ignore errors)
# FR: Supprimer un volume (ignorer les erreurs)
#
# Usage: cleanup_volume "volume_name"
# -----------------------------------------------------------------------------
cleanup_volume() {
    local name="$1"
    docker volume rm -f "${name}" &>/dev/null || true
    log "Cleanup: removed volume ${name}"
}
