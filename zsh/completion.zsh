# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

zstyle ':completion:*:default' list-colors di=4 ex=33

zstyle ':completion:*' completer _complete _approximate _prefix

zstyle ':completion:*:approximate' max-errors 2 NUMERIC

