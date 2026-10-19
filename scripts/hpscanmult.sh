#!/bin/sh
set -eu

readonly PROG="${0##*/}"
readonly HPSCAN="${HPSCAN:-$(dirname -- "$0")/hpscan.sh}"

workdir=

usage() {
	[ "$1" -eq 0 ] || exec >&2
	cat <<EOF
Usage: SCANNER_IP=<address> $PROG [options] pages name

  pages  number of pages to scan
  name   output file, .pdf is appended if missing

  -t  pdf                                 (default: pdf)
  -c  colour | bw                         (default: colour)
  -s  a4 | letter | 4x6 | 5x7 | 10x15     (default: a4)
  -r  text | high | photo | screen        (default: text)
  -q  quality, 0 to 100                   (default: 100)
  -l  -5 (lighter) to 5 (darker)          (default: 0)

SCANNER_IP is required and must be set in the environment, e.g.

  SCANNER_IP=192.168.1.1 $PROG -c bw 3 invoice
EOF
	exit "$1"
}

warn() {
	printf '%s: %s\n' "$PROG" "$*" >&2
}

die() {
	warn "$@"
	exit 1
}

cleanup() {
	status=$?
	[ -n "$workdir" ] || return 0
	if [ "$status" -eq 0 ]; then
		rm -rf -- "$workdir"
	elif ! rmdir -- "$workdir" 2>/dev/null; then
		warn "scanned pages are kept in $workdir"
	fi
}

check_requirements() {
	missing=0
	if [ -z "${SCANNER_IP:-}" ]; then
		warn "SCANNER_IP is not set (e.g. SCANNER_IP=192.168.1.58 $PROG 3 invoice)"
		missing=1
	fi
	if ! command -v pdfunite >/dev/null 2>&1; then
		warn "pdfunite is not installed (it is part of poppler)"
		missing=1
	fi
	if [ ! -x "$HPSCAN" ]; then
		warn "cannot execute $HPSCAN"
		missing=1
	fi
	[ "$missing" -eq 0 ] || exit 1
}

main() {
	format=pdf
	colour=
	size=
	preset=
	quality=
	level=

	while getopts t:c:s:r:q:l:h opt; do
		case $opt in
			t) format=$OPTARG ;;
			c) colour=$OPTARG ;;
			s) size=$OPTARG ;;
			r) preset=$OPTARG ;;
			q) quality=$OPTARG ;;
			l) level=$OPTARG ;;
			h) usage 0 ;;
			*) usage 1 ;;
		esac
	done
	shift $((OPTIND - 1))
	[ "$#" -eq 2 ] || usage 1
	pages=$1
	name=$2

	check_requirements

	case $format in
		pdf) ;;
		jpeg|jpg) die "jpeg is not supported: the pages are merged with pdfunite" ;;
		*) die "unknown type '$format'" ;;
	esac

	case $pages in
		''|0*|*[!0-9]*) die "pages must be a positive whole number" ;;
	esac

	case $name in
		*.pdf) ;;
		*) name=$name.pdf ;;
	esac

	set -- -t pdf
	[ -z "$colour" ] || set -- "$@" -c "$colour"
	[ -z "$size" ] || set -- "$@" -s "$size"
	[ -z "$preset" ] || set -- "$@" -r "$preset"
	[ -z "$quality" ] || set -- "$@" -q "$quality"
	[ -z "$level" ] || set -- "$@" -l "$level"

	trap cleanup EXIT
	trap 'exit 1' HUP INT TERM

	workdir=$(mktemp -d "${TMPDIR:-/tmp}/$PROG.XXXXXX")

	for label in $(seq -w 1 "$pages"); do
		printf 'Page %s of %s: place it on the glass, then press Enter to scan (Ctrl-C to quit): ' \
			"$label" "$pages"
		read -r _ || die "aborted"
		"$HPSCAN" "$@" "$workdir/$label.pdf" >/dev/null
	done

	pdfunite "$workdir"/*.pdf "$name"
	printf 'Saved %s\n' "$name"
}

main "$@"