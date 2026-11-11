# Third party notices

The genesis-plus-gx-pico blob (`genesis-plus-gx-pico.blob`) is built from the following. It is a
modified build of Genesis Plus GX and is distributed under the Genesis Plus GX licence
(`LICENSE`, copied unchanged from upstream): not for sale and not for any commercial product or
activity, and every redistribution of the blob must come with its complete source code.

## Genesis Plus GX and its libretro port

- Source: <https://github.com/libretro/Genesis-Plus-GX>, the `upstream/` submodule, at the commit
  recorded in this repository (and in `BUILD_INFO.txt` of a release), with the patches in
  `patches/`.
- Copyright (c) 1998-2003 Charles MacDonald, copyright (c) 2007-2026 Eke-Eke, some portions
  copyright Nicola Salmoria and the MAME team. The libretro port (`libretro/libretro.c`): Eke-Eke,
  Daniel De Matteis and the libretro contributors. Under the Genesis Plus GX licence, the first
  part of `LICENSE`.
- Compiled: `upstream/core/` except the MP3 decoder (`core/sound/minimp3/`), the CHD library and
  the yx5200 MP3 player cartridge, and `upstream/libretro/libretro.c`. The headers of
  `upstream/libretro/libretro-common/include/` (copyright the RetroArch team, under the MIT style
  notice in each file) are used to compile it; none of libretro-common's C files are built.
- Parts of the core under other licences, all stated in `LICENSE`:
  - **Nuked OPN2** (`core/sound/ym3438.c`, Alexey Khokholov, Nuke.YKT): GNU LGPL 2.1 or later.
  - **NTSC filters** (`core/ntsc/`, Shay Green): GNU LGPL 2.1 or later.
  - **Blip_Buffer** (`core/sound/blip_buf.c`, Shay Green): GNU LGPL 2.1 or later.
  - The full LGPL 2.1 text follows the Blip_Buffer notice in `LICENSE`. The blob links these
    statically; the complete source of the blob and the script that builds it, which every
    release carries, let anyone rebuild it with a modified version of these libraries.
  - **Tremor** (Ogg Vorbis), **minimp3** and **libchdr** with its decoders are listed in
    `LICENSE` too but are not part of the blob: Tremor is compiled into the archive but nothing
    references it (no CD audio), so the link leaves it out; the others are not compiled.
- `LICENSE` ends with the licences of the Wii port's libraries (libogc, libfat, libWiiDRC), which
  this blob does not contain.
- Each upstream file keeps its own notice (Musashi 68000 core by Karl Stenerud, the MAME Z80,
  YM2612 and YM2413 cores, Nuked OPLL, notaz's SVP, Neil C's equaliser, which is in the public
  domain, and others).

## This repository

The glue in `pico/`, the patches in `patches/`, the host tests in `tests/` and the build and
packaging scripts: Copyright (c) 2026 TheGammaSqueeze, under the Genesis Plus GX licence
(`LICENSE`). `pico/genesis_core_abi.h` is a copy of the interface header of the GammaOS LK
(lk-mt6785) by the same author, provided here under the same terms.

## The C runtime linked into the blob

- **newlib's libm** (Sun Microsystems' fdlibm and the newlib contributors): `sin`, `cos`, `pow`,
  `exp`, `log`, `sqrt`, `floor`, `rint` and their helpers (the link map,
  `out/genesis-plus-gx-pico.map`, lists every object). These files carry the fdlibm notice
  ("Permission to use, copy, modify, and distribute this software is freely granted, provided
  that this notice is preserved"); newlib's notices are in its `COPYING.NEWLIB` and, for the
  toolchain the releases are built with (Ubuntu's `libnewlib-arm-none-eabi`), in the copyright
  file shipped in a release as `licenses/newlib-COPYRIGHT.txt`. newlib's C library itself is not
  linked; `pico/pico_libc.c` and `pico/pico_stubs.c` stand in for it.
- **libgcc** (the GCC project): soft float arithmetic and 64 bit division helpers. GPL-3.0 with
  the GCC Runtime Library Exception, which places no conditions on the compiled blob.

## Corresponding source

The Genesis Plus GX licence asks that a modified build comes with the complete source code of
everything it was built from. Every release carries `genesis-plus-gx-pico-<version>-src.tar.gz`,
this repository with the upstream submodule at the exact commit the blob was built from.
`./build.sh` rebuilds the blob from it.
