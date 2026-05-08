#!/usr/bin/env bash
# Bootstrap a new Mac: Homebrew, apps, oh-my-posh.
# Paths are derived from this repo — no hardcoded username.
#
# Prerequisite: Xcode or Command Line Tools installed first (git + compiler toolchain for Homebrew).
#
# Optional env:
#   SKILLS_REPO_URL=…        Git URL for Cursor/agent skills (default: antunesdq/skills).
#   SKILLS_CLONE_DIR=…       Where to clone them (default: ~/.cursor/skills-antunesdq).
#   DISABLE_SKILLS_CLONE=1   Skip cloning/updating the skills repo.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_REPO_URL="${SKILLS_REPO_URL:-https://github.com/antunesdq/skills.git}"
SKILLS_CLONE_DIR="${SKILLS_CLONE_DIR:-${HOME}/.cursor/skills-antunesdq}"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }

ensure_brew_on_path() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

clone_skills_repo() {
  if [[ "${DISABLE_SKILLS_CLONE:-0}" == "1" ]]; then
    info "Skipping skills clone (DISABLE_SKILLS_CLONE=1)."
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git not available; skipping skills clone."
    return 0
  fi

  mkdir -p "$(dirname "${SKILLS_CLONE_DIR}")"

  if [[ -d "${SKILLS_CLONE_DIR}/.git" ]]; then
    info "Updating skills repo at ${SKILLS_CLONE_DIR}..."
    git -C "${SKILLS_CLONE_DIR}" pull --ff-only || warn "git pull failed for skills repo."
    return 0
  fi

  if [[ -e "${SKILLS_CLONE_DIR}" ]]; then
    warn "${SKILLS_CLONE_DIR} exists and is not a git clone; skipping skills clone."
    warn "Remove it or set SKILLS_CLONE_DIR to an empty path."
    return 0
  fi

  info "Cloning skills repo (${SKILLS_REPO_URL})..."
  if ! git clone --depth 1 "${SKILLS_REPO_URL}" "${SKILLS_CLONE_DIR}"; then
    warn "Skills clone failed (network or permissions). Re-run ./init.sh later or clone manually."
    return 0
  fi
  info "Skills available at: ${SKILLS_CLONE_DIR} (point Cursor or agent rules at this tree if needed)."
}

install_homebrew() {
  ensure_brew_on_path
  if command -v brew >/dev/null 2>&1; then
    info "Homebrew already installed."
    return 0
  fi
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ensure_brew_on_path
  command -v brew >/dev/null 2>&1 || {
    warn "Homebrew was installed but is not on PATH. Open a new terminal or run:"
    warn '  eval "$(/opt/homebrew/bin/brew shellenv)"'
    exit 1
  }
}

bundle_install() {
  info "Installing formulae and casks from Brewfile..."
  brew bundle --file="${ROOT}/Brewfile"
}

install_mas_apps() {
  ensure_brew_on_path
  command -v mas >/dev/null 2>&1 || brew install mas

  # Amphetamine — Mac App Store id 937984704
  local amphetamine_id=937984704

  if ! mas account >/dev/null 2>&1; then
    warn "Not signed into the Mac App Store (mas account failed)."
    warn "Open the App Store app, sign in, then run:"
    warn "  mas install ${amphetamine_id}"
    return 0
  fi

  info "Installing Amphetamine from the Mac App Store..."
  mas install "${amphetamine_id}" || warn "mas install Amphetamine failed (already installed?)"
}

configure_oh_my_posh() {
  local omp_config="${ROOT}/mattdq.omp.json"
  [[ -f "${omp_config}" ]] || {
    warn "Missing theme file: ${omp_config}"
    return 0
  }

  local marker="# my-terminal oh-my-posh"
  touch "${HOME}/.zshrc"
  if grep -qF "${marker}" "${HOME}/.zshrc" 2>/dev/null; then
    info "oh-my-posh already referenced in ~/.zshrc."
    return 0
  fi

  info "Adding oh-my-posh to ~/.zshrc..."
  {
    echo ""
    echo "${marker}"
    echo "eval \"\$(oh-my-posh init zsh --config \"${omp_config}\")\""
  } >>"${HOME}/.zshrc"
}

main() {
  info "Bootstrap using repo: ${ROOT}"
  clone_skills_repo
  install_homebrew
  bundle_install
  install_mas_apps
  configure_oh_my_posh
  info "Done. Open a new terminal or run: source ~/.zshrc"
}

main "$@"
