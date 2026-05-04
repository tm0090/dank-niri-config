#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  dank-niri-config installer
#  Usage (one-liner):
#    curl -fsSL https://raw.githubusercontent.com/tm0090/dank-niri-config/main/install.sh | bash
# ─────────────────────────────────────────────────────────────

set -euo pipefail

REPO_URL="https://github.com/tm0090/dank-niri-config/archive/refs/heads/main.tar.gz"
REPO_NAME="dank-niri-config"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STAGING_BASE="${TMPDIR:-/tmp}/dank-niri-inspect-$$"

# ── colours ────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}${BOLD}[info]${RESET}  $*"; }
ok()      { echo -e "${GREEN}${BOLD}[ ok ]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[warn]${RESET}  $*"; }
err()     { echo -e "${RED}${BOLD}[err ]${RESET}  $*" >&2; }
sep()     { echo -e "${BOLD}────────────────────────────────────────────────${RESET}"; }

# ── helpers ────────────────────────────────────────────────────
ask_yn() {
    # ask_yn "question" → returns 0 for yes, 1 for no
    local prompt="$1"
    while true; do
        echo -en "${BOLD}${prompt} [y/N] ${RESET}"
        read -r reply </dev/tty
        case "${reply,,}" in
            y|yes) return 0 ;;
            n|no|"") return 1 ;;
            *) echo "  Please answer y or n." ;;
        esac
    done
}

ask_path() {
    local prompt="$1" default="$2"
    echo -en "${BOLD}${prompt} [${default}]: ${RESET}"
    read -r reply </dev/tty
    echo "${reply:-$default}"
}

# ── download ───────────────────────────────────────────────────
download_repo() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    info "Downloading ${REPO_NAME} …"
    if command -v curl &>/dev/null; then
        curl -fsSL "$REPO_URL" | tar -xz -C "$tmp_dir"
    elif command -v wget &>/dev/null; then
        wget -qO- "$REPO_URL" | tar -xz -C "$tmp_dir"
    else
        err "Neither curl nor wget found. Please install one and retry."
        exit 1
    fi
    # GitHub archives unpack as  <repo>-<branch>/
    echo "$tmp_dir/${REPO_NAME}-main"
}

# ── install logic ──────────────────────────────────────────────
install_dir() {
    # install_dir <src_dir> <dest_parent>
    local src="$1" dest_parent="$2"
    local dir_name
    dir_name="$(basename "$src")"
    local dest="${dest_parent}/${dir_name}"

    mkdir -p "$dest_parent"

    local conflicts=()
    while IFS= read -r -d '' src_file; do
        local rel="${src_file#${src}/}"
        local dst_file="${dest}/${rel}"
        if [[ -e "$dst_file" ]]; then
            conflicts+=("$dst_file")
        fi
    done < <(find "$src" -type f -print0)

    if [[ ${#conflicts[@]} -eq 0 ]]; then
        cp -rn "$src" "$dest_parent/"
        ok "Installed → ${dest}"
    else
        warn "The following files already exist and would be overwritten:"
        for f in "${conflicts[@]}"; do
            echo "    ${YELLOW}${f}${RESET}"
        done
        echo
        if ask_yn "  Skip installing ${CYAN}${dir_name}${RESET} to ${dest} (safe choice)?"; then
            warn "Skipped ${dir_name}."
            if ask_yn "  Copy to a staging folder so you can inspect & install manually?"; then
                local stage="${STAGING_BASE}/${dir_name}"
                mkdir -p "$stage"
                cp -r "$src/." "$stage/"
                ok "Staged at ${YELLOW}${stage}${RESET}"
                echo -e "  ${BOLD}Tip:${RESET} diff with → ${CYAN}diff -rq ${stage} ${dest}${RESET}"
            fi
        else
            warn "Installing only NEW files (existing files will NOT be overwritten)."
            cp -rn "$src" "$dest_parent/"
            ok "Partial install done → ${dest}"
        fi
    fi
}

# ── main ───────────────────────────────────────────────────────
main() {
    sep
    echo -e "${BOLD}${CYAN}  dank-niri-config installer${RESET}"
    sep
    echo

    local repo_dir
    repo_dir="$(download_repo)"

    info "Config target: ${BOLD}${CONFIG_DIR}${RESET}"
    echo

    # Discover top-level directories in the repo (skip hidden / root files)
    local dirs=()
    while IFS= read -r -d '' d; do
        dirs+=("$d")
    done < <(find "$repo_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    if [[ ${#dirs[@]} -eq 0 ]]; then
        err "No config directories found in the downloaded archive."
        exit 1
    fi

    info "Found config directories to install:"
    for d in "${dirs[@]}"; do
        echo "    ${CYAN}$(basename "$d")${RESET} → ${CONFIG_DIR}/$(basename "$d")"
    done
    echo

    if ! ask_yn "Proceed with installation?"; then
        warn "Aborted by user."
        exit 0
    fi
    echo

    for d in "${dirs[@]}"; do
        sep
        info "Processing: ${BOLD}$(basename "$d")${RESET}"
        install_dir "$d" "$CONFIG_DIR"
        echo
    done

    sep
    ok "All done!"
    if [[ -d "$STAGING_BASE" ]]; then
        echo
        info "Staged files for manual review are in:"
        echo -e "    ${YELLOW}${STAGING_BASE}${RESET}"
        echo -e "  ${BOLD}Remove when done:${RESET} ${CYAN}rm -rf ${STAGING_BASE}${RESET}"
    fi
    sep

    # Clean up temp download
    rm -rf "$(dirname "$repo_dir")"
}

main "$@"
