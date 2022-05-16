#!/usr/bin/env bash

set -eu

VERSION="2022.02.01"
FOLDER="buildroot-$VERSION"
DOWNLOAD_URL="https://buildroot.org/downloads/buildroot-$VERSION.tar.gz"

getbuildroot() {
    curl -LO "$DOWNLOAD_URL"
    tar xf "$(basename $DOWNLOAD_URL)"
}

build() {
    local arch="$1"

    if [[ ! -d "$FOLDER" ]]; then
        getbuildroot
    fi

    cp "config-$arch" "$FOLDER/.config"
    cd "$FOLDER"

    make -j "$(nproc)"
}

deploy() {
    local arch
    local dir
    arch="$1"
    dir="$(mktemp -d)"

    find "$FOLDER/output/target" -type f -executable -exec cp '{}' "$dir/" \;
    rsync -e "ssh -o VerifyHostKeyDNS=yes -o StrictHostKeyChecking=accept-new" -rP --delete "$dir/" "deploy@tatooine.sevenbyte.org:binaries.rumpelsepp.org/binaries/$arch"

    rm -rf "$dir"
}

usage() {
    local SCRIPTNAME
    SCRIPTNAME=$(basename "$0")

    echo "usage: $SCRIPTNAME [-b ARCH] [-d ARCH] [-gh]"
    echo ""
    echo "commands:"
    echo "  -b       Build all stuff for architecture"
    echo "  -d       Deploy all stuff for architecture"
    echo "  -g       Download and untar buildroot"
    echo "  -h       Show this page and exit"
}

while getopts "b:d:gh" arg; do
    case "$arg" in
        b) build  "$OPTARG";;
        d) deploy "$OPTARG";;
        g) getbuildroot;;
        h) usage && exit 0;;
        *) usage && exit 1;;
    esac
done
