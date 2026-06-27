autoload -Uz vcs_info
precmd() { vcs_info }

zstyle ':vcs_info:git:*' formats '%b'
zstyle ':vcs_info:git:*' actionformats '%b|%a'

function nix_shell_indicator() {
  [[ -n "$IN_NIX_SHELL" ]] && echo "[nix>shell] "
}

function git_branch_indicator() {
  [[ -n "$vcs_info_msg_0_" ]] && echo "[git>$vcs_info_msg_0_] "
}

local user_color='%F{15}'
local host_color='%F{15}'
local dir_color='%F{2}' 
local nix_color='%F{6}'
local git_color='%F{5}'
local prompt_color='%F{15}'
local reset='%f'

setopt PROMPT_SUBST

PROMPT='${user_color}%n${reset}@${host_color}%m${reset} ${dir_color}%~${reset}'
PROMPT+=$'\n'
PROMPT+='${nix_color}$(nix_shell_indicator)${reset}'
PROMPT+='${git_color}$(git_branch_indicator)${reset}'
PROMPT+='${prompt_color}-> ${reset}'
