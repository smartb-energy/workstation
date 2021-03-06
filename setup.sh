#!/bin/bash

gems=(
  inspec-bin
  bundler
)

brew_packages=(
  awscli
  aws-iam-authenticator
  coreutils
  direnv
  gcc
  git-duet
  git-lfs
  hab
  hub
  jq
  kubectl
  nmap
  npm
  pyenv
  pyenv-virtualenv
  pyenv-virtualenvwrapper
  rbenv
  rbenv-bundler
  readline
  shellcheck
  terraform
  vault
  watchman
  xz
)

brew_packages_linux=(
  docker
)

brew_taps=(
  git-duet/tap
  habitat-sh/habitat
)

brew_casks=(
  atom
  chef-workstation
  iterm2
  postman
  pycharm-ce
  slack
  spectacle
  visual-studio-code
  google-cloud-sdk
)

atom_packages=(
  busy-signal
  intentions
  linter-shellcheck
  linter-ui-default
  teletype
)

main() {
  install_xcode_command_line_tools
  install_brew
  configure_linux_brew
  install_brew_taps
  install_brew_packages
  install_brew_casks
  setup_git_duet
  setup_git_aliases
  install_xcode
  install_gems
  return $?
}

is_ubuntu() {
  if uname -rv | grep "Ubuntu" &> "/dev/null"
  then
    return 0
  else
    return 1
  fi 
}


is_macos() {
  if uname -rv | grep "Darwin" &> "/dev/null"
  then
    return 0
  else
    return 1
  fi
}


install_xcode_command_line_tools() {
  if is_macos
  then
    if ! xcode-select --print-path &> "/dev/null"
    then
      echo "Installing Xcode command-line tools..."
      xcode-select --install
      sudo xcodebuild -license accept
      echo "...installation of Xcode command-line tools complete."
      echo ""
    fi
    return $?
  fi
}


install_brew() {
  if ! type "brew" &> "/dev/null"
  then
    if is_ubuntu
    then
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)"
      return $?
    elif is_macos
    then  
      /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
      return $?
    fi
  fi
}


install_brew_packages() {
  if is_macos || is_ubuntu
  then
    brew install $(echo "${brew_packages[*]}") || true
    brew install $(echo "${brew_packages_linux[*]}") || true
    brew upgrade $(brew ls) || true
  fi
}


install_brew_taps() {
  if is_macos || is_ubuntu
  then
    for tap in "${brew_taps[@]}"
    do
      brew tap "$tap"
    done
    return $?
  fi
}


install_brew_casks() {
  if is_macos
  then
    brew cask install $(echo "${brew_casks[*]}") || true
    brew cask upgrade $(brew cask ls) || true
  fi
}


start_docker() {
  if is_macos
  then
    if ! pgrep Docker &> /dev/null
    then
      open "/Applications/Docker.app"
    fi
  elif is_ubuntu
  then
    sudo apt update
    sudo apt install docker.io
  fi
  return $?
}


install_xcode() {
  if is_macos
  then
    if ! ls "/Applications/Xcode.app/" &> "/dev/null"
    then
      echo "You must first install Xcode. You will be redirected to the Mac App Store..."
      open -a "App Store" "https://itunes.apple.com/us/app/xcode/id497799835"
      exit 1

      if sw_vers | grep "ProductVersion" | grep "10.14" &> "/dev/null"
      then
      echo "Installing macOS development headers..."
        local headers_pkg="/Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg"
        installer -pkg "$headers_pkg" -target "/"
      fi
    fi
  fi
}


latest_ruby() {
  rbenv install --list | awk '{print $1}' | grep "^[0-9].[0-9]" | grep -v "-" | tail -n1
  return $?
}


install_gems() {
  rbenv install --skip-existing $(latest_ruby)
  rbenv global $(latest_ruby)

  if ! grep "rbenv init -" $HOME/.bash_profile &> "/dev/null"
  then
    echo 'eval "$(rbenv init -)"' >> $HOME/.bash_profile
    eval "$(rbenv init -)"
  fi

  for gem in "${gems[@]}"
  do
    if ! gem list | grep "${gem}" &> "/dev/null"
    then
      gem install "${gem}" --no-document
    fi
  done
  rbenv rehash
  return $?
}


setup_git_duet() {
  curl \
    --silent \
    "https://raw.githubusercontent.com/smartb-energy/workstation/master/.git-authors?a=$(date +%s)" \
    > "$HOME/.git-authors"
  return $?
}


setup_git_aliases() {
  git config --global alias.co checkout
  git config --global alias.br branch
  git config --global alias.ci commit
  git config --global alias.st status
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

  if ! grep 'eval $(ssh-agent)' "$HOME/.bash_profile" &> /dev/null
  then
    echo '
if ! pgrep "ssh-agent" &> "/dev/null"
then
  eval $(ssh-agent)
fi
' >> "$HOME/.bash_profile"
    source "$HOME/.bash_profile"
  fi

  if ! ssh-add -L | grep ssh-rsa &> "/dev/null"
  then
    ssh-add -K "$HOME/.ssh/id_rsa"
    echo "Adding the key to the agent"
  fi

  if ! grep "ssh-add -K" "$HOME/.bash_profile" &> "/dev/null"
  then
    echo 'ssh-add -K "$HOME/.ssh/id_rsa"' >> "$HOME/.bash_profile"
    source "$HOME/.bash_profile"
  fi

  return $?
}


create_habitat_token() {
  if ! grep token "$HOME/.hab/etc/cli.toml" &> "/dev/null"
  then
    echo "Set up your local Habitat environment by running"
    echo "  hab cli setup"
    echo ""
  fi
  return $?
}


configure_pyenv() {
  if ! grep "pyenv init -" "$HOME/.bash_profile" &> "/dev/null"
  then
    echo '
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
' >> "$HOME/.bash_profile"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
  fi
  return $?
}

configure_linux_brew() {
  if is_ubuntu
  then
    sudo apt-get install "build-essential"

    if ! grep "/home/linuxbrew/.linuxbrew/bin/brew" "$HOME/.bash_profile" &> "/dev/null"
    then
      echo '
eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
' >> "$HOME/.bash_profile"
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    if ! grep "/home/linuxbrew/.linuxbrew/bin/brew" "$HOME/.bash_profile" | grep "PATH=" &> "/dev/null"
    then
      echo '
PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
' >> "$HOME/.bash_profile"
      export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
    fi
  fi
  return $?
}


main

echo ""
echo "Contribute to this setup script here:"
echo "  https://github.com/smartb-energy/workstation/blob/master/setup.sh"
echo ""
