autoload -U colors; colors



curl -sS https://starship.rs/install.sh | sh -s -- --yes
eval "$(starship init zsh)"
starship preset bracketed-segments -o ~/starship.toml

zstyle ':completion:*' list-colors 'di=36' 'ex=31' 'ln=35'