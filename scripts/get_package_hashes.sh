#!/usr/bin/env bash
#
# Prints the package sha256 hash for all platform files
# Useful to create new homebrew formulas
set -e
set -o pipefail

VERSION=$1
DOWNLOAD_URL='https://github.com/barracuda-cloudgen-access/access-cli/releases/download/v%VERSION/access-cli_%PLATFORM.tar.gz'

PLATFORMS="macOS_arm64 macOS_x86_64 Linux_x86_64 Linux_i386"

function print_usage() {
    echo "Usage: $0 [version]"
}

if [[ -z "$VERSION" ]]; then
    print_usage
    exit 1
fi

echo Version: "$VERSION"

for PLATFORM in $PLATFORMS; do
    URL=${DOWNLOAD_URL//\%VERSION/$VERSION}
    URL=${URL//\%PLATFORM/$PLATFORM}

    echo -e "\nGetting SHA256 for $PLATFORM - $URL"
    TMPFILE="/tmp/access-cli_${VERSION}_${PLATFORM}.tar.gz"
    if ! curl -sfL --show-error "$URL" > "$TMPFILE"; then
        exit 1
    fi
    sha256sum "$TMPFILE"
done
