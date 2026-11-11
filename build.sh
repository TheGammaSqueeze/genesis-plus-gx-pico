#!/bin/bash
# Copyright (c) 2026 TheGammaSqueeze. Part of genesis-plus-gx-pico, under the Genesis Plus GX
# licence (LICENSE).
# genesis-plus-gx-pico: build the Genesis Plus GX core blob for the GammaOS LK (lk-mt6785, Konkr
# Pocket Advance).
#
#   ./build.sh            -> out/genesis-plus-gx-pico.blob (copy it to the SD card as
#                            /cores/genesis-plus-gx-pico.blob)
#   ./build.sh src        -> only out/src: the upstream sources with patches/ applied (the host
#                            tests in tests/ build from it)
#   ./build.sh clean
#
# The upstream tree (submodule upstream/, libretro/Genesis-Plus-GX) is never modified: its core/
# and libretro/ are copied to out/src, the patches in patches/ are applied there, and that copy is
# compiled together with the glue in pico/. Genesis Plus GX's emulation (core/) and its libretro
# port (libretro/libretro.c) are built; Sega CD image loading (CHD, MP3 and Ogg Vorbis CD audio) is
# not wired up: the cd_hw hardware compiles, but no CD BIOS or disc is ever loaded.
#
# Target: the LK runs the core in 32 bit state on the MT6785. Built for ARMv8-A with the soft
# float ABI and no NEON, link time optimisation, the per frame code (68000, Z80, VDP, sound, memory
# maps, input) at -O3 and the rest at -O2. These are the flags, defines, source list, link order and
# link script the LK built this core with in emu/genesis (build_core.sh and build_core_blob.sh),
# so the blob is byte for byte the one the LK tree builds (see README.md, "Reproducing the LK's
# blob").
set -euo pipefail
cd "$(dirname "$0")"
ROOT=$PWD
OUT=$ROOT/out
CROSS=${CROSS:-arm-none-eabi-}
CC=${CROSS}gcc
AR=${CROSS}ar
OBJCOPY=${CROSS}objcopy
# The archive's member order (and so the link) follows a sorted list: sort the same everywhere.
export LC_ALL=C

if [ "${1:-}" = clean ]; then rm -rf "$OUT"; exit 0; fi

if [ ! -f upstream/core/system.c ]; then
	git submodule update --init upstream
fi

UPSTREAM_REV=$(git -C upstream describe --tags --always 2>/dev/null || git -C upstream rev-parse --short HEAD)
PICO_REV=$(git describe --always --dirty 2>/dev/null || echo unknown)
VERSION="Genesis Plus GX ${UPSTREAM_REV} (pico ${PICO_REV})"

rm -rf "$OUT/src"
mkdir -p "$OUT/src"
cp -a upstream/core upstream/libretro "$OUT/src/"
# EXTRA_PATCHES: more patches for experiments, applied after these; releases use none
for p in patches/*.patch ${EXTRA_PATCHES:-}; do
	[ -e "$p" ] || continue
	echo ">> patch $(basename "$p")"
	case "$p" in /*) pp=$p;; *) pp=$ROOT/$p;; esac
	(cd "$OUT/src" && patch -p1 --quiet --forward < "$pp")
done

if [ "${1:-}" = src ]; then echo "out/src ready"; exit 0; fi
rm -rf "$OUT/obj"
mkdir -p "$OUT/obj/core"

SRC=$OUT/src
INC="-I$SRC/core -I$SRC/core/z80 -I$SRC/core/m68k -I$SRC/core/ntsc -I$SRC/core/sound \
	-I$SRC/core/input_hw -I$SRC/core/cd_hw -I$SRC/core/cart_hw -I$SRC/core/cart_hw/svp \
	-I$SRC/libretro -I$SRC/libretro/libretro-common/include"

# The ARM defines of upstream's Makefile.libretro, without the CD image libraries (no HAVE_CHD,
# no HAVE_ZLIB: ROMs come in as buffers, never as zip or chd files). RGB565 output.
DEFS="-DLSB_FIRST -DBYTE_ORDER=LITTLE_ENDIAN -D__LIBRETRO__ -DALIGN_LONG -DALIGN_WORD \
	-DMAXROMSIZE=33554432 -DUSE_DYNAMIC_ALLOC \
	-DUSE_16BPP_RENDERING -DFRONTEND_SUPPORTS_RGB565 -DHAVE_YM3438_CORE -DHAVE_OPLL_CORE"

# __FILE__ (in the NTSC filter's asserts) would put the build directory into the blob: map it to
# a path relative to out/src so the blob does not depend on where the repository is checked out.
# SRC_PREFIX=<dir> maps it to <dir> instead, e.g. the LK's emu/genesis to reproduce its blob.
if [ -n "${SRC_PREFIX:-}" ]; then PREFIX_MAP="-fmacro-prefix-map=$SRC=${SRC_PREFIX%/}"
else PREFIX_MAP="-fmacro-prefix-map=$SRC/="; fi

ARCH="-march=armv8-a -mtune=cortex-a76 -mfloat-abi=soft -mthumb-interwork -ffreestanding \
	-fno-short-enums -mno-unaligned-access -fno-strict-aliasing"
# -fno-ipa-icf avoids a GCC 10.3 segfault in the LTO link
CORE_FLAGS="$ARCH -fno-common -flto -ffat-lto-objects -fno-ipa-icf -ffunction-sections \
	-fdata-sections -std=gnu99 $DEFS $INC $PREFIX_MAP"
GLUE_FLAGS="$ARCH -Os -fno-common -flto -ffat-lto-objects -fno-ipa-icf -ffunction-sections \
	-fdata-sections -std=gnu99 $DEFS $INC $PREFIX_MAP"
# The C runtime glue is compiled outside LTO, as plain objects: its memcpy and memset are byte
# loops that GCC's loop distribution would otherwise turn into calls to memcpy and memset, which
# inside the LTO partition left memcpy undefined at the link. -fno-builtin for the same reason.
RT_FLAGS="$ARCH -Os -fno-common -fno-tree-loop-distribute-patterns -fno-builtin \
	-ffunction-sections -fdata-sections -std=gnu99 $DEFS $INC $PREFIX_MAP"

# Genesis Plus GX: every C file of core/ except the MP3 decoder (CD audio), the CHD library and the
# yx5200 MP3 player cartridge (it needs the MP3 decoder), plus the libretro port.
CORE_SRCS="core/cart_hw/areplay.c core/cart_hw/eeprom_93c.c core/cart_hw/eeprom_i2c.c
	core/cart_hw/eeprom_spi.c core/cart_hw/flash_cfi.c core/cart_hw/ggenie.c core/cart_hw/md_cart.c
	core/cart_hw/megasd.c core/cart_hw/sms_cart.c core/cart_hw/sram.c core/cart_hw/svp/ssp16.c
	core/cart_hw/svp/svp.c core/cd_hw/cd_cart.c core/cd_hw/cdc.c core/cd_hw/cdd.c core/cd_hw/gfx.c
	core/cd_hw/pcm.c core/cd_hw/scd.c core/debug/cpuhook.c core/genesis.c core/input_hw/activator.c
	core/input_hw/gamepad.c core/input_hw/graphic_board.c core/input_hw/input.c
	core/input_hw/lightgun.c core/input_hw/mouse.c core/input_hw/paddle.c core/input_hw/smash.c
	core/input_hw/sportspad.c core/input_hw/teamplayer.c core/input_hw/terebi_oekaki.c
	core/input_hw/xe_1ap.c core/io_ctrl.c core/loadrom.c core/m68k/m68kcpu.c core/m68k/s68kcpu.c
	core/mem68k.c core/membnk.c core/memz80.c core/ntsc/md_ntsc.c core/ntsc/sms_ntsc.c
	core/sound/blip_buf.c core/sound/eq.c core/sound/opll.c core/sound/psg.c core/sound/sound.c
	core/sound/tremor/bitwise.c core/sound/tremor/block.c core/sound/tremor/codebook.c
	core/sound/tremor/floor0.c core/sound/tremor/floor1.c core/sound/tremor/framing.c
	core/sound/tremor/info.c core/sound/tremor/mapping0.c core/sound/tremor/mdct.c
	core/sound/tremor/registry.c core/sound/tremor/res012.c core/sound/tremor/sharedbook.c
	core/sound/tremor/synthesis.c core/sound/tremor/vorbisfile.c core/sound/tremor/window.c
	core/sound/ym2413.c core/sound/ym2612.c core/sound/ym3438.c core/state.c core/system.c
	core/vdp_ctrl.c core/vdp_render.c core/z80/z80.c libretro/libretro.c"

# The code that runs every frame gets -O3, everything else -O2 (paths without core/ and .c)
HOT=" m68k/m68kcpu z80/z80 vdp_render vdp_ctrl vdp_sms system sound/sound sound/ym2612 sound/sn76489
	sound/ym2413 sound/blip_buf sound/psg mem68k memz80 membnk io_ctrl input_hw/input "
HOT=$(echo $HOT)
opt_for() {
	local r=${1%.c}; r=${r#core/}
	case " $HOT " in *" $r "*) echo -O3;; *) echo -O2;; esac
}

CORE_OBJS=()
for f in $CORE_SRCS; do
	o="$OUT/obj/core/$(echo "${f%.c}" | tr '/' '_').o"
	$CC $CORE_FLAGS $(opt_for "$f") -c "$SRC/$f" -o "$o"
	CORE_OBJS+=("$o")
done
LIB=$OUT/obj/libgenesis.a
rm -f "$LIB"
$AR rcs "$LIB" $(printf '%s\n' "${CORE_OBJS[@]}" | sort)

$CC $GLUE_FLAGS -Wall -c pico/pico_core.c  -o "$OUT/obj/pico_core.o"
$CC $GLUE_FLAGS -Wall -c pico/pico_heap.c  -o "$OUT/obj/pico_heap.o"
$CC $RT_FLAGS   -w    -c pico/pico_libc.c  -o "$OUT/obj/pico_libc.o"
$CC $RT_FLAGS   -w    -c pico/pico_stubs.c -o "$OUT/obj/pico_stubs.o"

LIBGCC=$($CC $GLUE_FLAGS -print-libgcc-file-name)
LIBM=$($CC $GLUE_FLAGS -print-file-name=libm.a)

ELF=$OUT/genesis-plus-gx-pico.elf
BLOB=$OUT/genesis-plus-gx-pico.blob
$CC $GLUE_FLAGS -O2 -nostdlib -nostartfiles \
	-Wl,-T,"$ROOT/pico/blob.ld" -Wl,--gc-sections -Wl,-Map,"$OUT/genesis-plus-gx-pico.map" \
	"$OUT/obj/pico_core.o" "$OUT/obj/pico_heap.o" "$OUT/obj/pico_libc.o" "$OUT/obj/pico_stubs.o" \
	-Wl,--start-group "$LIB" "$LIBM" "$LIBGCC" -Wl,--end-group \
	-o "$ELF"
$OBJCOPY -O binary "$ELF" "$BLOB"

python3 - "$BLOB" "$VERSION" <<'EOF'
import struct, sys, hashlib
d = open(sys.argv[1], 'rb').read()
magic, ver, entry, load, span = struct.unpack_from('<5I', d)
assert magic == 0x31474553 and ver == 4, "bad header"
# objcopy leaves out the zero pad that aligns the image end to 16 bytes, so the file can stop up
# to 15 bytes short of load_size; the LK zeroes those bytes with the BSS
assert len(d) <= load < len(d) + 16, "load size %d does not match file %d" % (load, len(d))
slot = 0x50000000 - 0x4F800000
assert span <= slot, "span %d does not fit the 8 MiB core slot" % span
print("genesis-plus-gx-pico.blob: %s" % sys.argv[2])
print("  file %d bytes, span %d bytes (%.2f MiB of the 8 MiB slot), entry +0x%x" % (len(d), span, span / 1048576.0, entry))
print("  sha256 %s" % hashlib.sha256(d).hexdigest())
EOF
