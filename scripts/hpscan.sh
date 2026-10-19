#!/bin/sh
set -eu

readonly PROG="${0##*/}"

optional=
job_url=
partial=

usage() {
	[ "$1" -eq 0 ] || exec >&2
	cat <<EOF
Usage: SCANNER_IP=<address> $PROG [options] [name]

  -t  pdf | jpeg                          (default: pdf)
  -c  colour | bw                         (default: colour)
  -s  a4 | letter | 4x6 | 5x7 | 10x15     (default: a4)
  -r  text | high | photo | screen        (default: text)
  -q  quality, 0 to 100                   (default: 100)
  -l  -5 (lighter) to 5 (darker)          (default: 0)

Set SCANNER_IP variable to set the printer address, eg.:
  
  SCANNER_UP=192.168.1.1 $PROG -s letter document.pdf
EOF
	exit "$1"
}

die() {
	printf '%s: %s\n' "$PROG" "$*" >&2
	exit 1
}

cleanup() {
	if [ -n "$job_url" ]; then
		curl_escl --request DELETE "$job_url" >/dev/null 2>&1 || true
	fi
	if [ -n "$partial" ]; then
		rm -f -- "$partial"
	fi
}

curl_escl() {
	curl --silent --show-error --connect-timeout 5 "$@"
}

add_setting() {
	optional="$optional
	<scan:$1>$2</scan:$1>"
}

scan_settings() {
	cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<scan:ScanSettings  xmlns:scan="http://schemas.hp.com/imaging/escl/2011/05/03" xmlns:dd="http://www.hp.com/schemas/imaging/con/dictionaries/1.0/" xmlns:dd3="http://www.hp.com/schemas/imaging/con/dictionaries/2009/04/06" xmlns:fw="http://www.hp.com/schemas/imaging/con/firewall/2011/01/05" xmlns:scc="http://schemas.hp.com/imaging/escl/2011/05/03" xmlns:pwg="http://www.pwg.org/schemas/2010/12/sm">
	<pwg:Version>2.1</pwg:Version>
	<scan:Intent>Document</scan:Intent>
	<pwg:ScanRegions>
		<pwg:ScanRegion>
			<pwg:XOffset>0</pwg:XOffset>
			<pwg:YOffset>0</pwg:YOffset>
			<pwg:Width>$width</pwg:Width>
			<pwg:Height>$height</pwg:Height>
		</pwg:ScanRegion>
	</pwg:ScanRegions>
	<pwg:InputSource>Platen</pwg:InputSource>
	<scan:DocumentFormatExt>$mime</scan:DocumentFormatExt>
	<scan:XResolution>$dpi</scan:XResolution>
	<scan:YResolution>$dpi</scan:YResolution>
	<scan:ColorMode>$mode</scan:ColorMode>$optional
</scan:ScanSettings>
EOF
}

main() {
	format=pdf
	colour=colour
	size=a4
	preset=text
	quality=100
	level=0

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
	[ "$#" -le 1 ] || usage 1

	[ -n "${SCANNER_IP:-}" ] || die "SCANNER_IP is not set (e.g. SCANNER_IP=192.168.1.58 $PROG)"
	escl_url=http://$SCANNER_IP/eSCL

	case $format in
		pdf)      mime=application/pdf; ext=pdf ;;
		jpeg|jpg) mime=image/jpeg;      ext=jpg ;;
		*) die "unknown type '$format'" ;;
	esac

	case $colour in
		colour|color) mode=RGB24 ;;
		bw)           mode=Grayscale8 ;;
		*) die "unknown colour setting '$colour'" ;;
	esac

	# Width and height in 300ths of an inch
	case $size in
		a4)     width=2481; height=3508 ;;
		letter) width=2550; height=3300 ;;
		4x6)    width=1200; height=1800 ;;
		5x7)    width=1500; height=2100 ;;
		10x15)  width=1181; height=1772 ;;
		*) die "unknown paper size '$size'" ;;
	esac

	case $preset in
		text)   dpi=300 ;;
		high)   dpi=600 ;;
		photo)  dpi=200 ;;
		screen) dpi=75 ;;
		*) die "unknown resolution '$preset'" ;;
	esac

	case $quality in
		0|[1-9]|[1-9][0-9]|100) ;;
		*) die "quality must be 0 to 100" ;;
	esac

	case $level in
		[+-][1-5]|[0-5]) level=${level#+} ;;
		*) die "lighter/darker must be -5 to 5" ;;
	esac

	name=${1:-scan}
	case $name in
		*.$ext) ;;
		*) name=$name.$ext ;;
	esac

	trap cleanup EXIT
	trap 'exit 1' HUP INT TERM

	curl_escl --fail --output /dev/null "$escl_url/ScannerCapabilities" \
		|| die "no answer from $SCANNER_IP"

	# This is from the Lighter/Darker slider on the web UI.
	# The number t in [-5,5] is inverted and scaled so f(5)=0, f(-5)=2000 and
	# limited to [1,1999].
	tone=$(( 1000 - level * 200 ))
	[ "$tone" -ge 1 ] || tone=1
	[ "$tone" -le 1999 ] || tone=1999

	add_setting Brightness "$tone"
	add_setting Contrast "$tone"
	add_setting CompressionFactor "$((100 - quality))"

	# ==========================================================================

	response=$(scan_settings \
		| curl_escl --include --request POST \
			--header 'Content-Type: text/xml' \
			--data-binary @- "$escl_url/ScanJobs" \
		| tr -d '\r')
	job_url=$(printf '%s\n' "$response" \
		| awk 'tolower($1) == "location:" { print $2; exit }')
	if [ -z "$job_url" ]; then
		printf '%s\n' "$response" >&2
		die "the printer refused the job"
	fi
	case $job_url in
		http://*|https://*) ;;
		/*) job_url=http://$SCANNER_IP$job_url ;;
	esac

	partial=$name.part

	curl_escl --fail --max-time 300 --output "$partial" "$job_url/NextDocument" \
		|| die "the scan failed"
	mv -- "$partial" "$name"
	partial=

	printf 'Saved %s\n' "$name"
}

main "$@"