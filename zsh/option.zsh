# 候補が多い場合は詰めて表示
setopt list_packed

# コマンドラインの引数でも補完を有効にする（--prefix=/userなど）
setopt magic_equal_subst
# cd -<tab>で以前移動したディレクトリを表示
setopt auto_pushd

# auto_pushdで重複するディレクトリは記録しない
setopt pushd_ignore_dups

autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# 直前と同じコマンドの場合は履歴に追加しない
setopt hist_ignore_dups
setopt correct_all # typoを検出
setopt auto_cd # cdコマンドの保管