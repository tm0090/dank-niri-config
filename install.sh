#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║         dank-niri-config  —  Safe Installer          ║
# ║   https://github.com/tm0090/dank-niri-config         ║
# ╚══════════════════════════════════════════════════════╝
set -euo pipefail

# ── colours ──────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { printf "${CYAN}▶${RESET}  %s\n" "$*"; }
ok()   { printf "${GREEN}✔${RESET}  %s\n" "$*"; }
warn() { printf "${YELLOW}⚠${RESET}  %s\n" "$*"; }
err()  { printf "${RED}✖${RESET}  %s\n" "$*" >&2; }
die()  { err "$*"; exit 1; }
hr()   { printf '%s\n' "────────────────────────────────────────────────────"; }

# ── constants ────────────────────────────────────────────
REPO_ZIP="https://github.com/tm0090/dank-niri-config/archive/refs/heads/main.zip"
REPO_DIR_NAME="dank-niri-config-main"
CONFIG_DIRS=("niri" "DankMaterialShell")
TARGET_BASE="${HOME}/.config"
INSPECT_BASE="${HOME}/.config/dank-niri-inspect"
TMP_DIR="$(mktemp -d)"

cleanup() { rm -rf "${TMP_DIR}"; }
trap cleanup EXIT

printf "\n${BOLD}dank-niri-config installer${RESET}\n\n"
hr

# ── dependency check ─────────────────────────────────────
for cmd in curl unzip; do
    command -v "$cmd" &>/dev/null || die "Required command not found: $cmd"
done

# ── download ─────────────────────────────────────────────
log "Downloading config archive …"
curl -fsSL --progress-bar "${REPO_ZIP}" -o "${TMP_DIR}/config.zip" \
    || die "Download failed — check your internet connection."
ok "Downloaded archive"

log "Extracting …"
unzip -q "${TMP_DIR}/config.zip" -d "${TMP_DIR}"
EXTRACTED="${TMP_DIR}/${REPO_DIR_NAME}"
[[ -d "${EXTRACTED}" ]] || die "Unexpected archive layout — extraction failed."
ok "Extracted to temp directory"
hr

# ── per-folder install logic ─────────────────────────────
NEEDS_INSPECT=()

for dir in "${CONFIG_DIRS[@]}"; do
    SRC="${EXTRACTED}/${dir}"
    DEST="${TARGET_BASE}/${dir}"

    printf "\n${BOLD}[%s]${RESET}\n" "${dir}"

    if [[ ! -d "${SRC}" ]]; then
        warn "Source folder '${dir}' not found in archive — skipping."
        continue
    fi

    if [[ -e "${DEST}" ]]; then
        warn "${DEST} already exists — ${BOLD}skipping to avoid overwrite${RESET}."
        NEEDS_INSPECT+=("${dir}")
    else
        log "Installing → ${DEST}"
        cp -r "${SRC}" "${DEST}"
        ok "Installed ${dir}"
    fi
done

hr

# ── inspection prompt ────────────────────────────────────
if [[ ${#NEEDS_INSPECT[@]} -gt 0 ]]; then
    printf "\n${YELLOW}The following folders already exist and were not overwritten:${RESET}\n"
    for d in "${NEEDS_INSPECT[@]}"; do
        printf "    • %s/%s\n" "${TARGET_BASE}" "${d}"
    done

    printf "\n${BOLD}Would you like to copy the new configs to an inspection folder so you${RESET}\n"
    printf "${BOLD}can manually compare and apply changes?${RESET}\n"
    printf "    Inspection path: ${CYAN}%s${RESET}\n\n" "${INSPECT_BASE}"
    printf "${BOLD}Create inspection folder? [y/N]:${RESET} "
    read -r REPLY </dev/tty

    case "${REPLY}" in
        [yY]|[yY][eE][sS])
            mkdir -p "${INSPECT_BASE}"
            for d in "${NEEDS_INSPECT[@]}"; do
                SRC="${EXTRACTED}/${d}"
                IDEST="${INSPECT_BASE}/${d}"
                if [[ -e "${IDEST}" ]]; then
                    warn "Inspection copy already exists at ${IDEST} — overwriting."
                    rm -rf "${IDEST}"
                fi
                cp -r "${SRC}" "${IDEST}"
                ok "Copied ${d} → ${IDEST}"
            done
            printf "\n${GREEN}${BOLD}Inspection copies ready at:${RESET}\n"
            printf "    ${CYAN}%s${RESET}\n" "${INSPECT_BASE}"
            printf "\nDiff tip:  ${BOLD}diff -r ~/.config/<dir> %s/<dir>${RESET}\n" "${INSPECT_BASE}"
            ;;
        *)
            log "Skipped inspection folder creation."
            ;;
    esac
fi

# ── summary ──────────────────────────────────────────────
hr
printf "\n${GREEN}${BOLD}Done!${RESET}\n\n"
printf "  Installed configs live in: ${CYAN}%s${RESET}\n" "${TARGET_BASE}"
[[ ${#NEEDS_INSPECT[@]} -gt 0 ]] && \
    printf "  Skipped (already exist):   ${YELLOW}%s${RESET}\n" "${NEEDS_INSPECT[*]}"
printf "\n"
