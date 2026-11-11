#!/bin/bash
# Copyright (c) 2026 TheGammaSqueeze. Part of genesis-plus-gx-pico, under the Genesis Plus GX
# licence (LICENSE).
# Package a built blob for release (run ./build.sh first):
#
#   tools/package.sh            -> dist/genesis-plus-gx-pico-<version>.zip
#                                  dist/genesis-plus-gx-pico-<version>-src.tar.gz
#
# The zip is what goes on the SD card plus the licence texts: cores/genesis-plus-gx-pico.blob,
# LICENSE (Genesis Plus GX's), THIRD_PARTY_NOTICES.md, README.md and, when the toolchain ships it,
# newlib's copyright file, since the blob links parts of newlib's libm. The source archive is the
# complete source the Genesis Plus GX licence asks a modified build to come with: this repository
# and the upstream submodule at the commit the blob was built from.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f out/genesis-plus-gx-pico.blob ] || { echo "out/genesis-plus-gx-pico.blob missing: run ./build.sh first" >&2; exit 1; }

VER=${VERSION:-$(git describe --tags --always --dirty 2>/dev/null || echo unknown)}
NAME=genesis-plus-gx-pico-$VER
PACK=dist/$NAME
rm -rf "$PACK" "dist/$NAME.zip" "dist/$NAME-src.tar.gz"
mkdir -p "$PACK/cores" "$PACK/licenses"

cp out/genesis-plus-gx-pico.blob "$PACK/cores/"
cp LICENSE THIRD_PARTY_NOTICES.md README.md "$PACK/"
NEWLIB_DOC=$(ls /usr/share/doc/libnewlib-arm-none-eabi/copyright 2>/dev/null || true)
if [ -n "$NEWLIB_DOC" ]; then
	cp "$NEWLIB_DOC" "$PACK/licenses/newlib-COPYRIGHT.txt"
else
	echo "note: newlib's copyright file not found; see THIRD_PARTY_NOTICES.md" >&2
fi
(cd "$PACK/cores" && sha256sum genesis-plus-gx-pico.blob > genesis-plus-gx-pico.blob.sha256)
{
	echo "genesis-plus-gx-pico $VER"
	echo "upstream Genesis Plus GX (libretro) $(git -C upstream rev-parse HEAD)"
	echo "toolchain $(${CROSS:-arm-none-eabi-}gcc --version | head -1)"
	echo "blob sha256 $(cut -d' ' -f1 "$PACK/cores/genesis-plus-gx-pico.blob.sha256")"
} > "$PACK/BUILD_INFO.txt"
(cd dist && rm -f "$NAME.zip" && zip -qr "$NAME.zip" "$NAME")

# The complete source: every tracked file, the submodule's included
git ls-files --recurse-submodules -z | tar --null -czf "dist/$NAME-src.tar.gz" --transform "s,^,$NAME-src/," -T -

echo "dist/$NAME.zip"
echo "dist/$NAME-src.tar.gz"
