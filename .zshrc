
# Created by Noah Dominic <github.com/noahdominic>

# ================= #
# ZSH customisation #
# ================= #

## ZSH plugins
source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
setopt autocd

## ZSH histfiles
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt appendhistory

## ZSH prompt
function parse_git_branch () {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)\ /'
}
setopt PROMPT_SUBST
PROMPT='%F{green}%B%n@%m%b%f %~ %F{cyan}$(parse_git_branch)%f%# '

## ZSH keybindings
bindkey "^[[3~"   delete-char
bindkey "^[[H"    beginning-of-line
bindkey "^[[F"    end-of-line
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word


# ============================================================================
# ENVIRONMENTAL VARIABLES 
# ============================================================================

## Path - mine
export PATH=$PATH$(find $HOME/scripts/ -type d -exec echo -n ":"{} \;) # Adds all the dirs in
                                                        # `~/scripts`
export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/Documents/Notebook/bin/md2pdf
export PATH=$PATH:$HOME/Applications

## Path - 3rd party
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/.deno/bin
export GOBIN=$HOME/go/bin
export PATH=$PATH:$GOBIN
export PATH=$PATH:$HOME/miktex-bin
export PATH=$PATH:/opt/zig

## For React Native/Expo/Android
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

export TZ="Asia/Manila"

# ============================================================================
# Functions 
# ============================================================================


## mkcd - mkdir then cd

mkcd() {
    if [ $# -eq 0 ]; then
        echo "Error: No directory name provided."
        return 1
    else
        if [ $# -gt 1 ]; then
            echo "Error: Only one directory name can be provided."
            return 1
        fi
    fi

    mkdir -p -- "$1" &&
    cd -- "$1"
}

# ============================================================================
# Aliases - General
# ============================================================================

## Shortcut aliases for ls

# For greek keyboard accidentally being activated
alias μακε='make'

# For BSD
export CLICOLOR=1

ls --color=auto &> /dev/null && alias ls='ls -p --color=auto' ||
alias ls='ls -p'
alias ll='ls -plh'
alias la='ls -plah'

## Aliases for rm
alias rmall='rm -rf * .*'

## Windows-isms and macOS-isms
alias cls='clear'
alias dir='ls -lh'
alias del='rm'
alias open='xdg-open'

## Open .zshrc on nano THEN automatically load it
alias zshrc='nano ~/.zshrc && source ~/.zshrc'

## NVIDIA aliases
alias nvidia-smi='watch --interval 0.6 nvidia-smi'

## Program preferences 
if command -v fastfetch >/dev/null 2>&1; then
    alias neofetch='fastfetch'
fi
if command -v gnome-text-editor >/dev/null 2>&1; then
    alias gte='gnome-text-editor'
fi
if command -v microsoft-edge >/dev/null 2>&1; then
    alias microsoft-edge="microsoft-edge --enable-features=UseOzonePlatform --ozone-platform=wayland"
fi

## Fix for common typos
alias 'cd..'='cd ..'

## Aliases for flatpak apps
alias apostrophe="flatpak run org.gnome.gitlab.somas.Apostrophe"

## Laptop CLI stuff
alias batc='cat /sys/class/power_supply/BAT0/capacity'
alias bats='cat /sys/class/power_supply/BAT0/status'

# ============================================================================
# Development - Proj Managemetn
# ============================================================================

## Git
alias g='git'
alias ga='git add'
alias gadd='git add'
alias ga.='git add .'
alias gc='git commit'
alias gcommit='git commit'
alias gcm='git commit -m'
alias gcam='git commit -am'
alias gpush='git push'
alias gpull='git pull'
alias gss='git status'
alias gstat='git status'
alias ghash='git hash-object -w'
alias gundo='git reset HEAD~'
alias gb='git branch'
alias gco='git checkout'
alias gcheckout='git checkout'
alias grebase='git rebase'
alias gr='git rebase'
alias gmerge='git merge'
alias gdf='git diff'
alias gdiff='git diff'

# ============================================================================
# Development - Software
# ============================================================================

## CMake
alias cmake-build='cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Debug'

## Rust/Cargo
type cargo >/dev/null 2>&1 && alias ccheck="cargo check"
type cargo >/dev/null 2>&1 && alias crun="cargo run"

## Python: PyEnv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
type pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"

## Python: Conda
__conda_setup="$('/usr/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/noahdominic/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/noahdominic/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/noahdominic/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup

## For GBA Dev
export DEVKITPRO=/opt/devkitpro
export DEVKITARM=${DEVKITPRO}/devkitARM
export DEVKITPPC=${DEVKITPRO}/devkitPPC
export PATH=${DEVKITPRO}/tools/bin:$PATH
alias vgam="visualboyadvance-m"


# ============================================================================
# Development - Web
# ============================================================================

## NPM/PNPM
export PNPM_HOME="/home/noahdominic/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
alias pnpx='pnpm dlx'

## NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

## Jekyll
type jekyll >/dev/null 2>&1 && alias 'bejs'='bundle exec jekyll serve'
export GEM_HOME='~/gems'
export PATH=$PATH:$HOME/gems/bin:/home/noahdominic/.cargo/bin

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="/usr/local/opt/bzip2/bin:$PATH"

PATH="/home/noahdominic/perl5/bin${PATH:+:${PATH}}"; export PATH;
PERL5LIB="/home/noahdominic/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/noahdominic/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/noahdominic/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/noahdominic/perl5"; export PERL_MM_OPT;

# pnpm
export PNPM_HOME="/home/noahdominic/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
