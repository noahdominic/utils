#!/usr/bin/env bash
set -euo pipefail

readonly REPO="ryanoasis/nerd-fonts"
readonly DEST="${DEST:-$HOME/.local/share/fonts/FOSS/Nerd-Fonts}"
readonly STYLE_REGEX='.*-(Regular|Italic|Bold|BoldItalic)\.(ttf|otf)'

usage() {
    cat <<EOF
Usage: ${0##*/} [OPTION | all | FONT...]

Downloads Nerd Fonts, keeping only Regular, Italic, Bold and BoldItalic
(no Propo variants).

Options:
  -h, --help    show this help and exit
  -l, --list    list available fonts and exit

Arguments:
  FONT...       one or more archive names, e.g. Hack Iosevka
  all           every font in the release (asks for confirmation first)

Environment:
  DEST          install root (default: $DEST)
  TAG           release to use (default: latest)
EOF
}

die() {
    echo "$*" >&2
    exit 1
}

require_tools() {
    local tool
    for tool in curl tar xz find; do
        command -v "$tool" >/dev/null || die "Missing: $tool"
    done
}

resolve_tag() {
    [[ -n "${TAG:-}" ]] && return
    # The redirect avoids the rate-limited API.
    TAG=$(curl -fsSLI -o /dev/null -w '%{url_effective}' \
        "https://github.com/$REPO/releases/latest")
    TAG=${TAG##*/}
}

fonts_json() {
    curl -fsSL "https://raw.githubusercontent.com/$REPO/$TAG/bin/scripts/lib/fonts.json"
}

list_fonts() {
    fonts_json \
        | grep -E '"(folderName|description)"' \
        | sed -E 's/^ *"[a-zA-Z]+": *"//; s/",? *$//; s/\\"/"/g' \
        | paste -d'\t' - - \
        | awk -F'\t' '{ printf "%-24s %s\n", $1, $2 }'
}

all_font_names() {
    fonts_json \
        | grep '"folderName"' \
        | sed -E 's/.*: *"([^"]+)".*/\1/'
}

confirm_all() {
    local count=$1 reply=""
    echo "Warning: this downloads all $count font families." >&2
    echo "It is a large download (several GB) and will take a while." >&2
    read -r -p "Are you sure? [y/N] " reply || true
    [[ $reply =~ ^[Yy]([Ee][Ss])?$ ]] || die "Aborted."
}

install_font() {
    local name=$1 work=$2
    local archive="$work/$name.tar.xz"
    local extract="$work/$name"
    local target="$DEST/${name// /}"
    local kept=0 file

    echo "==> $name"
    if ! curl -fsSL -o "$archive" \
        "https://github.com/$REPO/releases/download/$TAG/$name.tar.xz"; then
        echo "    download failed, skipping" >&2
        return
    fi

    mkdir -p "$extract" "$target"
    tar -xf "$archive" -C "$extract"
    rm -f "$archive"

    while IFS= read -r -d '' file; do
        mv -f "$file" "$target/"
        ((++kept))
    done < <(find "$extract" -type f -regextype posix-extended \
        -regex "$STYLE_REGEX" ! -name '*Propo*' -print0)

    rm -rf "$extract"

    if ((kept == 0)); then
        rmdir "$target" 2>/dev/null || true
        echo "    nothing matched, skipped" >&2
    else
        echo "    kept $kept files"
    fi
}

refresh_font_cache() {
    command -v fc-cache >/dev/null || return 0
    fc-cache -f "$DEST"
    echo "Font cache refreshed."
}

main() {
    case "${1:-}" in
        ""|-h|--help) usage; exit 0 ;;
    esac

    require_tools
    resolve_tag
    echo "Release: $TAG" >&2

    if [[ $1 == -l || $1 == --list ]]; then
        list_fonts
        exit 0
    fi

    local fonts=("$@") arg
    for arg in "$@"; do
        if [[ $arg == all ]]; then
            mapfile -t fonts < <(all_font_names)
            confirm_all "${#fonts[@]}"
            break
        fi
    done
    echo "Fonts: ${#fonts[@]}"

    local work
    work=$(mktemp -d)
    trap "rm -rf '$work'" EXIT
    mkdir -p "$DEST"

    local name
    for name in "${fonts[@]}"; do
        install_font "$name" "$work"
    done

    refresh_font_cache
    echo "Done: $DEST"
}

main "$@"