#!/usr/bin/env bash
#
# Dotfiles installation script
# This script sets up dotfiles and configures git settings

# Exit on error, undefined variable, pipe failure
set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
readonly DOTFILES_ROOT="$(cd "${SCRIPT_DIR}" && pwd -P)"
readonly COLOR_INFO="\033[00;34m"
readonly COLOR_WARN="\033[0;33m"
readonly COLOR_SUCCESS="\033[00;32m"
readonly COLOR_ERROR="\033[0;31m"
readonly COLOR_RESET="\033[0m"

# Message display functions
print_message() {
    local color="$1"
    local message="$2"
    local prefix="$3"
    printf "\r  [ ${color}${prefix}${COLOR_RESET} ] %s\n" "$message"
}

info() { print_message "$COLOR_INFO" "$1" ".." ; }
warn() { print_message "$COLOR_WARN" "$1" "??" ; }
success() { print_message "$COLOR_SUCCESS" "$1" "OK" ; }
error() { print_message "$COLOR_ERROR" "$1" "FAIL" ; echo ''; exit 1; }

# Git configuration
get_git_credential_helper() {
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "osxkeychain"
    else
        echo "cache"
    fi
}

setup_gitconfig() {
    local git_config_path="git/gitconfig.local.symlink"
    
    if [ -f "$git_config_path" ]; then
        info "Git config already exists, skipping setup"
        return 0
    fi

    info "Setting up gitconfig"
    local git_credential
    git_credential="$(get_git_credential_helper)"

    warn "What is your github author name?"
    read -r git_authorname
    warn "What is your github author email?"
    read -r git_authoremail

    sed -e "s/AUTHORNAME/$git_authorname/g" \
        -e "s/AUTHOREMAIL/$git_authoremail/g" \
        -e "s/GIT_CREDENTIAL_HELPER/$git_credential/g" \
        "${git_config_path}.example" > "$git_config_path"

    success "Git configuration completed"
}

# File management
handle_existing_file() {
    local dst="$1"
    local src="$2"
    local currentSrc
    
    if [ -L "$dst" ]; then
        currentSrc="$(readlink "$dst")"
        if [ "$currentSrc" = "$src" ]; then
            # 既に正しいリンクが存在する場合
            echo "already_exists"
            return 0
        fi
    fi

    warn "File already exists: $dst ($(basename "$src")), what do you want to do?
    [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
    
    local action
    read -r -n 1 action
    echo

    case "$action" in
        [oO]) echo "overwrite";;
        [bB]) echo "backup";;
        [sS]) echo "skip";;
        *) return 0;;
    esac
}

create_link() {
    local src="$1"
    local dst="$2"
    local action="$3"
    local filename="$(basename "$src")"
    
    case "$action" in
        "already_exists")
            info "Checking $filename..."
            success "Correct link already exists, skipping"
            ;;
        "overwrite")
            info "Removing existing $filename..."
            rm -rf "$dst"
            success "Removed $dst"
            info "Creating link for $filename..."
            ln -s "$src" "$dst"
            success "Linked $src to $dst"
            ;;
        "backup")
            info "Creating backup of $filename..."
            mv "$dst" "${dst}.backup"
            success "Moved $dst to ${dst}.backup"
            info "Creating link for $filename..."
            ln -s "$src" "$dst"
            success "Linked $src to $dst"
            ;;
        "skip")
            info "Skipping $filename..."
            success "Skipped $src"
            ;;
    esac
}

link_file() {
    local src="$1"
    local dst="$2"
    local current="$3"
    local total="$4"
    local filename="$(basename "$src")"

    info "Processing file ($current/$total): $filename"

    if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]; then
        local action
        action=$(handle_existing_file "$dst" "$src")
        create_link "$src" "$dst" "$action"
    else
        info "Creating new link for $filename..."
        ln -s "$src" "$dst"
        success "Linked $src to $dst"
    fi
    echo ''
}

install_dotfiles() {
    info "Installing dotfiles"
    echo ''
    
    # Count total files first
    local total_files
    total_files=$(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' -not -path '*.git*' | wc -l)
    info "Found $total_files files to process"
    echo ''
    
    local current=0
    while IFS= read -r src; do
        current=$((current + 1))
        local dst="$HOME/.$(basename "${src%.*}")"
        link_file "$src" "$dst" "$current" "$total_files"
    done < <(find -H "$DOTFILES_ROOT" -maxdepth 2 -name '*.symlink' -not -path '*.git*')
    
    success "All dotfiles have been processed"
}

# Dependencies installation
install_dependencies() {
    if [ "$(uname -s)" = "Darwin" ]; then
        info "Installing dependencies"
        if source "bin/dot" | while read -r data; do info "$data"; done; then
            success "Dependencies installed"
        else
            error "Error installing dependencies"
        fi
    fi
}

# Main execution
main() {
    echo ''
    setup_gitconfig
    echo ''
    install_dotfiles
    install_dependencies
    echo ''
    success "All installed!"
}

main "$@"