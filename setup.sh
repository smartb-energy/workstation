#!/bin/bash

gems=(
  inspec-bin
  bundler
)

brew_packages=(
  awscli
  direnv
  git-duet
  hab
  hub
  nmap
  npm
  pyenv
  pyenv-virtualenv
  pyenv-virtualenvwrapper
  rbenv-bundler
  rbenv-chefdk
  readline
  shellcheck
  terraform@0.11
  vault
  watchman
  xz
)

brew_taps=(
  git-duet/tap
  habitat-sh/habitat
)

brew_casks=(
  atom
  docker
  iterm2
  postman
  pycharm-ce
  slack
  spectacle
  vscodium
)

atom_packages=(
  busy-signal
  intentions
  linter-shellcheck
  linter-ui-default
  teletype
)

node_modules=(
  triton
)

main() {
  install_xcode_command_line_tools
  install_brew
  install_brew_taps
  install_brew_packages
  setup_git_duet
  setup_git_aliases
  install_brew_casks
  install_atom_packages
  install_node_modules
  start_docker
  install_xcode
  install_gems
  create_ssh_key
  create_habitat_token
  configure_pyenv
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
    brew upgrade "$package" || brew install "$package"
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
    brew cask upgrade "$cask" || brew cask install "$cask"
  done
  return $?
}

install_atom_packages() {
  for package in "${atom_packages[@]}"
  do
    apm update "$package" || apm install "$package"
  done
  return $?
}

install_node_modules() {
  for module in "${node_modules[@]}"
  do
    npm update -g "$module" || npm install -g "$module"
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
    echo "Installing macOS development headers..."
    installer -pkg '/Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg' -target /
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
      gem install "${gem}" --no-document
    fi
  done
  rbenv rehash
  return $?
}

setup_git_duet() {
  curl --silent "https://raw.githubusercontent.com/smartb-energy/workstation/master/.git-authors" > "$HOME/.git-authors"
  return $?
}

setup_git_aliases() {
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.st status
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

configure_pyenv() {
  if ! grep "pyenv init -" $HOME/.bash_profile &> /dev/null
  then
    echo '
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
' >> $HOME/.bash_profile
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
  fi
  return $?
}

main

echo ""
echo "Contribute to this setup script here:"
echo "  https://github.com/smartb-energy/workstation/blob/master/setup.sh"
echo ""
