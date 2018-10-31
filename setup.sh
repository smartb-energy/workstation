#!/bin/bash

set -x -o errexit -o noglob -o pipefail

brew_packages=(
  direnv
  git-duet
  hab
  hub
  pyenv
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

main() {
  install_xcode_command_line_tools
  install_brew
  install_brew_packages
  install_brew_taps
  install_brew_casks
  start_docker
	install_xcode
	# create_ssh_key
	# create_habitat_token
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
    brew cask install "$cask"
  done
}

start_docker() {
  if ! pgrep Docker &> /dev/null
  then
    open '/Applications/Docker.app'
  fi
}

install_xcode() {
  if ! ls '/Applications/Xcode.app/' &> /dev/null
  then
    echo "Installing Xcode. You will be redirected to the Mac App Store..."
    open -a 'App Store' 'https://itunes.apple.com/us/app/xcode/id497799835'
  fi
}

main
