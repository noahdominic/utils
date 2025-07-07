#!/bin/sh

# Install base stuff via package manager
echo "1. Installing base stuff"
echo "    List of stuff to be installed:"
echo "      - neovim"
echo "      - pandoc"
echo "      - tldr"
echo "      - npm"
echo "      - pip"
echo "      - tree"
echo "      - tmux"
echo "      - nmap"
echo "      - fastfetch"
if command -v apt >/dev/null 2>&1; then
    echo "  Detected Debian-based system.  Installing with APT..."
    sudo add-apt-repository ppa:zhangsongcui3371/fastfetch
    sudo apt update
    sudo apt install neovim pandoc tldr npm python3-pip tree tmux fastfetch nmap ripgrep
elif command -v dnf >/dev/null 2>&1; then
    echo "  Detected RHEL-based system.  Installing with DNF..."
    sudo dnf install neovim pandoc tldr npm python3-pip tree tmux fastfetch nmap ripgrep
fi

# Install PNPM from NPM
if command -v npm >/dev/null 2>&1; then
    sudo npm -g install pnpm
fi

# Set up neovim
if [ ! -d "$HOME/.config/nvim" ]; then
    git clone git@github.com:noahdominic/nvim-config "$HOME/.config/nvim"
    pnpm add -g tree-sitter-cli
else
    echo "  $HOME/.config/nvim already exists.  Skipping neovim config."
fi

# Set up scripts folder
if [ ! -L "$HOME/scripts" ]; then
    ln -s "$HOME/Developer/utils/scripts" "$HOME"
    echo "  Made link: $HOME/Developer/scripts -> $HOME/scripts"
else
    echo "  $HOME/scripts already exists.  Skipping soft-linking."
fi
