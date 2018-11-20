#!/bin/bash

set -o errexit -o noglob -o pipefail

gems=(
  inspec
)

brew_packages=(
  direnv
  git-duet
  hab
  hub
  nmap
  npm
  pyenv
  rbenv-bundler
  rbenv-chefdk
  shellcheck
  watchman
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
  busy-signal
  intentions
  linter-shellcheck
  linter-ui-default
  nuclide
  teletype
)

node_modules=(
  nuclide
)

main() {
  install_xcode_command_line_tools
  install_brew
  install_brew_taps
  install_brew_packages
  setup_git_duet
  install_brew_casks
  install_atom_packages
  install_node_modules
  start_docker
  install_xcode
  install_gems
  create_ssh_key
  create_habitat_token
  return $?
}

install_xcode_command_line_tools() {
  if ! xcode-select --print-path &> /dev/null
  then
    echo "Installing Xcode command-line tools..."
    xcode-select --install
    echo "...installation of Xcode command-line tools complete."
    echo ""
  fi
  return $?
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
  return $?
}

install_brew_taps() {
  for tap in "${brew_taps[@]}"
  do
    brew tap "$tap"
  done
  return $?
}

install_brew_casks() {
  for cask in "${brew_casks[@]}"
  do
    if ! brew cask list "$cask" &> /dev/null
    then
      brew cask install "$cask"
    fi
  done
  return $?
}

install_atom_packages() {
  for package in "${atom_packages[@]}"
  do
    if ! apm list | grep "${package}" &> /dev/null
    then
      apm install "$package"
     fi
  done
  return $?
}

install_node_modules() {
  for module in "${node_modules[@]}"
  do
    if ! npm list | grep "${module}" &> /dev/null
    then
      npm install -g "$module"
     fi
  done
  return $?
}

start_docker() {
  if ! pgrep Docker &> /dev/null
  then
    open "/Applications/Docker.app"
  fi
  return $?
}

install_xcode() {
  if ! ls '/Applications/Xcode.app/' &> /dev/null
  then
    echo "Installing Xcode. You will be redirected to the Mac App Store..."
    open -a 'App Store' 'https://itunes.apple.com/us/app/xcode/id497799835'
  fi
  return $?
}

latest_ruby() {
  rbenv install --list | awk '{print $1}' | grep "^[0-9].[0-9]" | grep -v "-" | tail -n1
  return $?
}

install_gems() {
  rbenv install --skip-existing $(latest_ruby)
  rbenv global $(latest_ruby)

  if ! grep "rbenv init -" $HOME/.bash_profile &> /dev/null
  then
    echo 'eval "$(rbenv init -)"' >> $HOME/.bash_profile
    eval "$(rbenv init -)"
  fi

  for gem in "${gems[@]}"
  do
    if ! gem list | grep "${gem}" &> /dev/null
    then
      gem install "${gem}" --no-rdoc --no-ri
    fi
  done
  return $?
}

setup_git_duet() {
  curl --silent "https://raw.githubusercontent.com/smartb-energy/workstation/master/.git-authors" > "$HOME/.git-authors"
  return $?
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

  eval $(ssh-agent)

  if ! grep 'eval $(ssh-agent)' $HOME/.bash_profile &> /dev/null
  then
    echo 'eval $(ssh-agent)' >> $HOME/.bash_profile
    source $HOME/.bash_profile
  fi

  if ! ssh-add -L | grep ssh-rsa &> /dev/null
  then
    ssh-add -K "$HOME/.ssh/id_rsa"
    echo "Adding the key to the agent"
  fi

  if ! grep "ssh-add -K" $HOME/.bash_profile &> /dev/null
  then
    echo 'ssh-add -K "$HOME/.ssh/id_rsa"' >> $HOME/.bash_profile
    source $HOME/.bash_profile
  fi

  return $?
}

create_habitat_token() {
  if ! grep token "$HOME/.hab/etc/cli.toml" &> /dev/null
  then
    echo "Set up your local Habitat environment by running"
    echo "  hab cli setup"
    echo ""
  fi
  return $?
}

main

echo ""
echo "Contribute to this setup script here:"
echo "  https://github.com/smartb-energy/workstation/blob/master/setup.sh"
echo ""
