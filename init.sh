#!/usr/bin/env bash

# Setup variables
SKILLS_REPO_URL="${SKILLS_REPO_URL:-https://github.com/antunesdq/skills.git}"
SKILLS_CLONE_DIR="${SKILLS_CLONE_DIR:-${HOME}/.skills/skills-antunesdq}"
OMP_CONFIG="${ROOT}/mattdq.omp.json"

main() {
  echo "Starting bootstrap..."

  # 1. Clone Skills
  mkdir -p "$(dirname "${SKILLS_CLONE_DIR}")"
  git clone "${SKILLS_REPO_URL}" "${SKILLS_CLONE_DIR}"

  # 2. Install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  # 3. Setup Brew Environment
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # 4. Install Brew dependencies and App Store apps
  brew bundle --file="Brewfile"
  mas install 937984704

  # 5. Activate Oh My Posh in .zshrc
  echo "eval \"\$(oh-my-posh init zsh --config ${OMP_CONFIG})\"" >> "$HOME/.zshrc"
  brew install --cask font-meslo-lg-nerd-font     
  echo "Done. Restart your terminal or run: source ~/.zshrc"
}

main "$@"
