# Copyright (c) 2026 TheGammaSqueeze. Part of genesis-plus-gx-pico, under the Genesis Plus GX
# licence (LICENSE).
# Sourced by the host test build scripts: prepares out/src (the upstream sources with patches/
# applied, as build.sh does for the blob) and builds a host program from those sources, the glue's
# stand-ins in tests/host_stubs.c and the test's own file. Built natively (x86-64, hosted) with
# the blob's defines; a 64 bit host cannot catch pointer bugs that only show on 32 bit.
#   host_build <test.c> <output>
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
export LC_ALL=C

host_build() {
	local test=$1 bin=$2 src=$ROOT/out/src
	local obj=$ROOT/out/host/$(basename "${test%.c}")
	"$ROOT/build.sh" src >/dev/null
	local INC="-I$src/core -I$src/core/z80 -I$src/core/m68k -I$src/core/ntsc -I$src/core/sound \
		-I$src/core/input_hw -I$src/core/cd_hw -I$src/core/cart_hw -I$src/core/cart_hw/svp \
		-I$src/libretro -I$src/libretro/libretro-common/include"
	local DEFS="-DLSB_FIRST -DBYTE_ORDER=LITTLE_ENDIAN -D__LIBRETRO__ -DALIGN_LONG -DALIGN_WORD \
		-DMAXROMSIZE=33554432 -DUSE_DYNAMIC_ALLOC \
		-DUSE_16BPP_RENDERING -DFRONTEND_SUPPORTS_RGB565 -DHAVE_YM3438_CORE -DHAVE_OPLL_CORE"
	local F="-O2 -w -fno-strict-aliasing -std=gnu99 $DEFS $INC"
	rm -rf "$obj"; mkdir -p "$obj"
	# the blob's source list: core/ without the MP3 decoder, the CHD library and yx5200
	local f
	for f in $(cd "$src" && find core -name '*.c' | grep -v '/minimp3/' | grep -v '/libchdr/' | grep -v 'yx5200' | sort) libretro/libretro.c; do
		gcc $F -c "$src/$f" -o "$obj/$(echo "${f%.c}" | tr / _).o"
	done
	gcc $F -c "$ROOT/tests/host_stubs.c" -o "$obj/host_stubs.o"
	gcc $F -c "$test" -o "$obj/test_main.o"
	gcc -O2 "$obj"/*.o -o "$bin" -lm -lz
}
