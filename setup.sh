#!/bin/bash

set -x -o errexit -o noglob -o pipefail

brew_packages=(
  direnv
  git-duet
  hab
  hub
  pyenv
  rbenv-chefdk
  shellcheck
)

brew_taps=(
  git-duet/tap
  habitat-sh/habitat
)

brew_casks=(
  atom
  docker
  pycharm-ce
  slack
)

atom_packages=(
  teletype
  linter-shellcheck
)

main() {
  install_xcode_command_line_tools
  install_brew
  install_brew_taps
  install_brew_packages
  setup_git_duet
  create_habitat_token
  install_brew_casks
  install_atom_packages
  start_docker
  install_xcode
  create_ssh_key
}

install_xcode_command_line_tools() {
  if ! xcode-select --print-path &> /dev/null
  then
    echo "Installing Xcode command-line tools..."
    xcode-select --install
    echo "...installation of Xcode command-line tools complete."
    echo ""
  fi
}

install_brew() {
  if ! type "brew" &> /dev/null
  then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  return $?
}

install_brew_packages() {
  for package in "${brew_packages[@]}"
  do
    if ! type "$package" &> /dev/null
    then
      brew install "$package"
    fi
  done
}

install_brew_taps() {
  for tap in "${brew_taps[@]}"
  do
    brew tap "$tap"
  done
}

install_brew_casks() {
  for cask in "${brew_casks[@]}"
  do
    if ! brew cask list "$cask" &> /dev/null
    then
      brew cask install "$cask"
    fi
  done
}

install_atom_packages() {
  for package in "${atom_packages[@]}"
  do
    apm install "$package"
  done
}

start_docker() {
  if ! pgrep Docker &> /dev/null
  then
    open "/Applications/Docker.app"
  fi
}

install_xcode() {
  if ! ls '/Applications/Xcode.app/' &> /dev/null
  then
    echo "Installing Xcode. You will be redirected to the Mac App Store..."
    open -a 'App Store' 'https://itunes.apple.com/us/app/xcode/id497799835'
  fi
}

setup_git_duet() {
  curl --silent "https://raw.githubusercontent.com/smartb-energy/workstation/master/.git-authors" > "$HOME/.git-authors"
}

create_ssh_key() {
  if ! ls "$HOME/.ssh/id_rsa" &> /dev/null
  then
    ssh-keygen -b 4096
    echo "A new ssh key pair has been generated for you. Copy your public ssh"
    echo "key to the macOS pasteboard like this:"
    echo "  cat $HOME/.ssh/id_rsa.pub | pbcopy"
    echo "You can then paste into your GitHub account, a chat message, etc."
    echo ""
  fi
}

create_habitat_token() {
  if ! grep token "$HOME/.hab/etc/cli.toml" &> /dev/null
  then
    echo "Set up your local Habitat environment by running"
    echo "  hab cli setup"
    echo ""
  fi
}

main
