#!/usr/bin/zsh
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
    printf "\r  [ ${color}${prefix}${COLOR_RESET} ] %s\n" "$message" >&2
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
    local filename="$(basename "$src")"
    local type=""
    
    if [ -L "$dst" ]; then
        type="symbolic link"
    elif [ -d "$dst" ]; then
        type="directory"
    elif [ -f "$dst" ]; then
        type="file"
    fi
    
    if [ -L "$dst" ]; then
        local currentSrc
        currentSrc="$(readlink "$dst")"
        if [ "$currentSrc" = "$src" ]; then
            info "Checking $filename..."
            success "Correct link already exists"
            echo "skip"
            return 0
        fi
    fi

    warn "A $type already exists: $dst ($(basename "$src"))"
    if [ -t 0 ]; then  # 端末から入力を読み取れる場合
        warn "What do you want to do? [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all"
        local action
        read -r -k1 action
        echo

        case "$action" in
            o ) echo "overwrite";;
            O ) echo "overwrite_all";;
            b ) echo "backup";;
            B ) echo "backup_all";;
            s ) echo "skip";;
            S ) echo "skip_all";;
            * ) echo "skip";;
        esac
    else  # 端末から入力を読み取れない場合
        info "No terminal detected - defaulting to overwrite"
        echo "overwrite"
    fi
}

create_link() {
    local src="$1"
    local dst="$2"
    local action="$3"
    local filename="$(basename "$src")"
    
    case "$action" in
        "overwrite"|"overwrite_all")
            info "Removing existing $filename..."
            rm -rf "$dst"
            success "Removed $dst"
            info "Creating link for $filename..."
            ln -s "$src" "$dst"
            success "Linked $src to $dst"
            ;;
        "backup"|"backup_all")
            info "Creating backup of $filename..."
            mv "$dst" "${dst}.backup"
            success "Moved $dst to ${dst}.backup"
            info "Creating link for $filename..."
            ln -s "$src" "$dst"
            success "Linked $src to $dst"
            ;;
        "skip"|"skip_all")
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
    local overwrite_all="$5"
    local backup_all="$6"
    local skip_all="$7"
    local action
    info "Processing file ($current/$total): $filename"

    if [ -f "$dst" ] || [ -d "$dst" ] || [ -L "$dst" ]; then
        if [ "$overwrite_all" = "true" ]; then
            create_link "$src" "$dst" "overwrite_all"
        elif [ "$backup_all" = "true" ]; then
            create_link "$src" "$dst" "backup_all"
        elif [ "$skip_all" = "true" ]; then
            create_link "$src" "$dst" "skip_all"
        else 
            action=$(handle_existing_file "$dst" "$src" | tr -d '[:space:]')
            create_link "$src" "$dst" "$action"
        fi
    else
        info "Creating new link for $filename..."
        ln -s "$src" "$dst"
        success "Linked $src to $dst"
    fi
    echo "$action"
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
    local overwrite_all=false
    local backup_all=false
    local skip_all=false
    
    while IFS= read -r src; do
        current=$((current + 1))
        local dst="$HOME/.$(basename "${src%.*}")"
        local returned_action=$(link_file "$src" "$dst" "$current" "$total_files" "$overwrite_all" "$backup_all" "$skip_all")
        # Update all flags based on last action
        case "$returned_action" in
            "overwrite_all") overwrite_all=true; backup_all=false; skip_all=false ;;
            "backup_all") overwrite_all=false; backup_all=true; skip_all=false ;;
            "skip_all") info "aaa"; overwrite_all=false; backup_all=false; skip_all=true ;;
        esac
        echo ''
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

install_software() {
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
}

# Main execution
main() {
    # echo ''
    # setup_gitconfig
    echo ''
    install_software
    install_dotfiles
    install_dependencies
    echo ''
    success "All installed!"
    source ~/.zshrc
}

main "$@"