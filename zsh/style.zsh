autoload -U colors; colors

zstyle ':completion:*' list-colors 'di=36' 'ex=31' 'ln=35'

curl -sS https://starship.rs/install.sh | sh -s -- --yes
eval "$(starship init zsh)"
starship preset bracketed-segments -o ~/starship.toml