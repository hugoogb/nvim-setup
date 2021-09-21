#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

BOLD='\033[1m'
ITALIC='\033[3m'
NORMAL="\033[0m"

color_print() {
  if [ -t 1 ]; then
    echo -e "$@$NORMAL"
  else
    echo "$@" | sed "s/\\\033\[[0-9;]*m//g"
  fi
}

stderr_print() {
  color_print "$@" >&2
}

warn() {
  stderr_print "$YELLOW$1"
}

error() {
  stderr_print "$RED$1"
  exit 1
}

info() {
  color_print "$CYAN$1"
}

ok() {
  color_print "$GREEN$1"
}

program_exists() {
  command -v $1 &> /dev/null
}

# modify
REPO=nvim-setup

ACTUAL_DIR=`pwd`
REPO_DIR=$HOME/$REPO
TEMP_DIR=$HOME/temp
CONFIG_DIR=$HOME/.config

if [ ! -d $TEMP_DIR ]; then
  mkdir $TEMP_DIR
fi

if [ ! -d $CONFIG_DIR ]; then
  mkdir $CONFIG_DIR
fi

ok "Welcome to @hugoogb $REPO!!!"
info "Starting process..."

sleep 1

if ! program_exists "git"; then
  error "ERROR: git is not installed"
fi

# Dotfiles update
update_repo() {
  cd $REPO_DIR
  info "Updating $REPO..."
  git config --global pull.rebase false
  git pull origin master
  cd $REPO_DIR
}

clone_repo() {
  if [ -d $REPO_DIR]; then
    warn "WARNING: $REPO directory already exists"
  else
    info "Cloning $REPO..."
    git clone https://github.com/hugoogb/$REPO.git $REPO_DIR
  fi

  update_repo

  ok "$REPO cloned and updated"
}

clone_update_repo() {
  clone_repo
}

# LSP Install
lsp_dependencies() {
  info "Installing LSP dependencies..."

  # npm setup
  NPM_GLOBAL_DIR=$HOME/.npm-global

  if [ ! -d $NPM_GLOBAL_DIR ]; then
    mkdir $NPM_GLOBAL_DIR
  fi

  npm config set prefix '~/.npm-global'

  npm i -g npm

  # Neovim providers
  npm install -g neovim
  pip install pynvim
}

# Installing Vim-Plug
vimplug_install() {
  info "Installing vim-plug..."

  VIM_PLUG_FILE=$CONFIG_DIR/nvim/autoload/plug.vim

  if [ ! -e $VIM_PLUG_FILE ]; then
    sh -c 'curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  else
    warn "WARNING: vim-plug already installed"
  fi
}

neovim_setup() {
  info "Copying (neo)vim plugins file..."

  NVIM_DIR=$CONFIG_DIR/nvim

  if [ ! -d $NEOVIM_DIR ]; then
    mkdir -p $NVIM_DIR
  fi

  NEOVIM_PLUGINS_FILE=$NVIM_DIR/plug/plugins.vim

  if [ ! -e $NEOVIM_PLUGINS_FILE ]; then
    cp -rfv $REPO_DIR/nvim/plug $NVIM_DIR
  else
    warn "WARNING: neovim plugins file already exists, using existing file"
  fi
}

# Bootstraping NVIM
nvim_bootstrap() {
  info "Bootstraping nVim..."

  nvim --headless "+PlugUpgrade" "+PlugInstall" "+qall"
  warn "WARNING: not performing :PlugUpdate and :PlugClean, do it manually"
}

nvim_copy_setup_files() {
  # Link neovim configuration
  info "Setting up (neo)vim config..."

  cp -fv $REPO_DIR/nvim/init.vim $NVIM_DIR
  cp -rfv $REPO_DIR/nvim/general $NVIM_DIR
  cp -rfv $REPO_DIR/nvim/keys $NVIM_DIR
  cp -rfv $REPO_DIR/nvim/theme $NVIM_DIR
  cp -rfv $REPO_DIR/nvim/lua $NVIM_DIR
  cp -rfv $REPO_DIR/nvim/plugconf $NVIM_DIR
}

# Installing lsp servers
lsp_bootstrap() {
  info "Setting up lsp servers..."

  # LspInstall vimls
  npm install -g vim-language-server

  # LspInstall bashls
  npm install -g bash-language-server

  # LspInstall pyls
  pip install jedi
  pip install 'python-language-server[all]'
  pip install setuptools

  # LspInstall html
  npm install -g vscode-html-languageserver-bin

  # LspInstall cssls
  npm install -g vscode-css-languageserver-bin

  # LspInstall jsonls
  npm install -g vscode-json-languageserver

  # LspInstall tsserver
  npm install -g typescript typescript-language-server

  # LspInstall clangd
  # LspInstall cmake-language-server
  pip install cmake-language-server
}

nvim_setup() {
  lsp_dependencies
  vimplug_install
  neovim_setup
  nvim_bootstrap
  nvim_copy_setup_files
  lsp_bootstrap
}

main() {
  clone_update_repo
  nvim_setup
}

main

rm -rf $TEMP_DIR

ok "$REPO done!!!"
warn "WARNING: don't forget to reboot in order to get everything working properly"