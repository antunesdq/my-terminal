#!/usr/bin/env bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Setup variables
SKILLS_REPO_URL="${SKILLS_REPO_URL:-https://github.com/antunesdq/skills.git}"
SKILLS_CLONE_DIR="${SKILLS_CLONE_DIR:-${HOME}/.skills/skills-antunesdq}"
OMP_CONFIG="${ROOT}/mattdq.omp.json"

main() {
  echo "Starting bootstrap..."

  # 1. Clone Skills
  mkdir -p "$(dirname "${SKILLS_CLONE_DIR}")"
  if [[ ! -d "${SKILLS_CLONE_DIR}/.git" ]]; then
    git clone "${SKILLS_REPO_URL}" "${SKILLS_CLONE_DIR}"
  fi

  # 2. Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # 3. Setup Brew Environment
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # 4. Install Brew dependencies and App Store apps
  brew bundle --file="Brewfile"
  mas install 937984704

  # 5. Activate Oh My Posh in .zshrc
  OMP_INIT="eval \"\$(oh-my-posh init zsh --config ${OMP_CONFIG})\""
  if [[ -f "$HOME/.zshrc" ]]; then
    grep -v 'oh-my-posh init zsh' "$HOME/.zshrc" > "${HOME}/.zshrc.tmp"
    mv "${HOME}/.zshrc.tmp" "$HOME/.zshrc"
  fi
  echo "${OMP_INIT}" >> "$HOME/.zshrc"
  brew install --cask font-meslo-lg-nerd-font     
  echo "Done. Restart your terminal or run: source ~/.zshrc"
}

main "$@"
