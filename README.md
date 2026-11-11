# genesis-plus-gx-pico

[Genesis Plus GX](https://github.com/ekeeke/Genesis-Plus-GX) by **Charles MacDonald** and
**Eke-Eke**, in its **libretro** port ([libretro/Genesis-Plus-GX](https://github.com/libretro/Genesis-Plus-GX)),
built as a loadable Mega Drive / Genesis, Master System, Game Gear and SG-1000 core for the GammaOS
bootloader emulator on the Konkr Pocket Advance (MediaTek MT6785, `lk-mt6785`, branch
`lk-gba-emu-sd-card-kpa`).

All of the emulation is Genesis Plus GX's. This repository adds no emulation code: it holds the
upstream tree as a submodule, a small set of patches, the glue that lets Genesis Plus GX run inside
a bootloader with no operating system, a build script and two host tests.

**This is an experimental project and does not accept issues.** Please do not report problems you
see with genesis-plus-gx-pico to Genesis Plus GX or to libretro either: this build runs the core in
a bootloader on hardware upstream does not target, so its behaviour here says nothing about
Genesis Plus GX itself.

## Credits

- **Charles MacDonald** wrote the original Genesis Plus (1998-2003).
- **Eke-Eke** has developed it as Genesis Plus GX since 2007: the accuracy work, the Master
  System, Game Gear, SG-1000 and Sega CD support, the cartridge hardware and nearly everything
  else this core does.
- **The libretro team** maintain the libretro port (`libretro/libretro.c`, Eke-Eke and Daniel De
  Matteis among its authors), which this blob drives.
- Genesis Plus GX itself builds on the work of others, which this blob carries too: Karl Stenerud's
  Musashi 68000 core, the MAME Z80 core (Juergen Buchmueller), the MAME YM2612 and YM2413 cores
  (Jarek Burczynski, Tatsuyuki Satoh), Nuked OPN2 and Nuked OPLL (Alexey Khokholov, Nuke.YKT),
  Shay Green's Blip_Buffer and NTSC filters, notaz's SVP emulation and Neil C's 3 band equaliser.
  See upstream's `README.md`, `HISTORY.txt` and `LICENSE.txt` for the complete list.

## License

Genesis Plus GX is **not** free for every use. Its licence, copied unchanged from upstream in
`LICENSE`, allows redistribution and derivative works only if they are **not sold and not used in
a commercial product or activity**, and asks that a modified build comes with **its complete
source code** and the copyright notice. A few parts are under other licences, stated in the same
file: Nuked OPN2, the NTSC filters and Blip_Buffer are under the GNU LGPL 2.1, and libraries this
blob does not build (Tremor, minimp3, libchdr and its decoders) have their own notices there.

The blob is built from Genesis Plus GX and its libretro port with the patches in `patches/`, so it
is a modified build under those terms. The glue in `pico/`, the patches, the host tests in `tests/`
and the scripts are by TheGammaSqueeze and are provided under the same Genesis Plus GX licence.
The blob also links parts of newlib's libm and of libgcc; `THIRD_PARTY_NOTICES.md` lists what is
in the blob and under which licence. Every release carries the complete source the blob was built
from (`tools/package.sh`).

## Layout

| Path | What it is |
| --- | --- |
| `upstream/` | libretro/Genesis-Plus-GX, as a git submodule, never modified in place |
| `patches/` | changes to upstream, applied by `build.sh` to a copy in `out/src` |
| `pico/pico_core.c` | the LK's core interface (`genesis_core_abi.h`, version 4) filled in for Genesis Plus GX's libretro API |
| `pico/pico_heap.c` | the heap: a bump allocator over the LK's emulator arena, with mark and reset for run ahead |
| `pico/pico_libc.c` | the small C library the blob links instead of newlib's |
| `pico/pico_stubs.c` | what the libretro port references but the bootloader does not need (file access, the yx5200 cartridge) and a few more C library pieces |
| `pico/genesis_core_abi.h` | a copy of `lk-mt6785/emu/genesis/genesis_core_abi.h`; the LK's copy is the reference |
| `pico/blob.ld` | link script: flat image at 0x4F800000, 20 byte header |
| `build.sh` | builds `out/genesis-plus-gx-pico.blob` |
| `tests/` | host tests built on a PC from the same patched sources, see "Testing on a PC" |
| `tools/package.sh` | packs a release: the SD card zip and the source archive, into `dist/` |
| `.github/workflows/build.yml` | CI: builds every push, publishes a release for a `v*` tag |
| `THIRD_PARTY_NOTICES.md` | what is in the blob and under which licence |

### Patches

Upstream base: libretro/Genesis-Plus-GX `a7985a9c` (2026-08-28), the tree the LK's copy was taken
from. The patches turn that tree into exactly the sources the LK built its core from: every file
the LK had is byte for byte the same after them. Each patch is a plain unified diff with a short
header; the core's files have CRLF line endings, and so do the matching lines of the patches
(`.gitattributes` keeps git from touching them).

| Patch | Why |
| --- | --- |
| `0001-static-inline.patch` | `retro_inline.h` makes `INLINE` mean `static inline`. The 68000, Z80 and sound cores define handlers as `INLINE` and take their addresses for dispatch tables; with plain C99 `inline` those handlers have no out of line body, and the flat link of the blob found them undefined. |
| `0002-sound-rebase.patch` | `sound_rebase()` clears the Blip_Buffer integrators and the FM output carry, so the frame after a rewind's state load starts its sound from silence instead of stepping against what was left from before the load (the buzz heard when rewinding). The LK calls it through the interface's `sound_rebase`. |
| `0003-wide-pixel-stores.patch` | `merge()` writes four pixels per 32 bit store and `remap_line()` two (16 bit output), when the destination is aligned and the width allows it, else the original loops. The pictures are byte identical (checked with a frame CRC); on the device a frame went from 5647 to 5101 us. |
| `0004-hq-fm-note.patch` | A comment only: the high quality FM and PSG resampling cost about 1 % of a frame, so they stay on. |
| `0005-render-line-status.patch` | `render_line_status()` draws only what the game can observe of a line (sprite collision and overflow flags, sprite masking, the next line's sprite list), not the background or the colour conversion, and `render_status_only` makes the frame's line loop use it. Run ahead's committed frame and fast forward frames, which are never shown, use it (`set_av_skip` video 2). Anything but mode 5 without interlace mode 2 is drawn in full. `tests/render_status_test.c` checks it against the full render. |

## Building

Needs `arm-none-eabi-gcc` with newlib (tested with 10.3-2021.07), python3 and git.

```
git clone --recurse-submodules <this repository>   # or: git submodule update --init upstream
./build.sh
```

Output: `out/genesis-plus-gx-pico.blob`, plus the ELF and a link map. The script prints the size,
how much of the 8 MiB core slot it takes, and its SHA-256.

Build settings, the ones the LK has always built this core with: ARMv8-A, 32 bit, the soft float
ABI without NEON (`-mfloat-abi=soft`), tuned for the Cortex-A76, link time optimisation, `-O3` for the code that runs every frame (68000, Z80, VDP,
sound, memory maps, input) and `-O2` for the rest, `-Os` for the glue. The defines are upstream's
`Makefile.libretro` ARM set without the CD image libraries: ROMs arrive as buffers, so there is no
zip, CHD, MP3 or Ogg Vorbis support, and Sega CD games cannot be loaded.

### Reproducing the LK's blob

Until this repository, the LK built the same core from a copy in `lk-mt6785/emu/genesis`
(`build_core.sh` and `build_core_blob.sh`). `build.sh` uses the same compiler, flags, defines,
source list, object order, link order and link script, and the patched sources are the LK's files
byte for byte. The one thing the LK's build put in the blob that depends on where it was built is
`__FILE__` in two asserts of the NTSC filter (`md_ntsc_impl.h`, `sms_ntsc_impl.h`): the LK's blob
holds `/work/kpa/lk-mt6785/emu/genesis/core/ntsc/...`. `build.sh` maps that prefix to nothing
(`core/ntsc/...`), so the blob is the same wherever the repository is checked out. To get the LK's
exact bytes, give it the LK's directory:

```
SRC_PREFIX=/work/kpa/lk-mt6785/emu/genesis ./build.sh
cmp out/genesis-plus-gx-pico.blob /work/kpa/lk-mt6785/emu/genesis/core_genesis.blob   # identical
```

Without `SRC_PREFIX` the two path strings are shorter (64 bytes in all against the LK's path);
the code is the same instruction for instruction, and only the addresses of the data placed after
those strings move.

## Releases and CI

`.github/workflows/build.yml` builds the blob on Ubuntu 22.04 (its `gcc-arm-none-eabi` is the
10.3-2021.07 toolchain the blob is developed with) for every push and pull request, runs the host
test on its built in Mega Drive image, and keeps the packaged result as a workflow artifact.
Pushing a tag named `v*` also publishes a GitHub release with:

- `genesis-plus-gx-pico-<version>.zip`: `cores/genesis-plus-gx-pico.blob` (copy the `cores` folder
  to the root of the SD card), its SHA-256, `BUILD_INFO.txt`, `LICENSE`, `THIRD_PARTY_NOTICES.md`
  and `licenses/`;
- `genesis-plus-gx-pico-<version>-src.tar.gz`: this repository with the upstream submodule at the
  commit the blob was built from (the complete source the licence asks to go with the blob);
- `genesis-plus-gx-pico.blob` on its own.

Locally the same package comes from `./build.sh && tools/package.sh`.

## Testing on a PC

Two host tests build the core natively (x86-64, gcc, zlib) from the same patched sources and
defines as the blob, with the glue replaced by the small stand-ins in `tests/host_stubs.c`. Both
run `./build.sh src` first, which only prepares `out/src`.

```
tests/build_host_test.sh && out/gpgx_host_test [rom.md] [frames]
tests/build_render_status_test.sh && out/gpgx_render_status_test rom.bin [frames]
```

- `host_test.c` loads a ROM through the GET_GAME_INFO_EXT buffer path exactly as the blob does,
  runs frames and checks that a save state round trip is exact. Without a ROM it makes a minimal
  Mega Drive image of its own, so it also runs in CI.
- `render_status_test.c` runs the same ROM and scripted input three times from the same state:
  with the full render, with `render_line_status` (patch 0005) and with no render at all, hashing
  the save state after every frame. The sprites only pass must be `IDENTICAL` to the full render
  on every frame; the plain skip is expected to drift in games that use sprite collision.
  Sonic the Hedgehog 2, 3000 frames: status only identical, the plain skip first differs at frame
  167. `NOHASH=1` times the three runs without the hashing.

## Installing

Copy `out/genesis-plus-gx-pico.blob` to the SD card as `/cores/genesis-plus-gx-pico.blob`. The LK
runs Mega Drive / Genesis, Master System, Game Gear and SG-1000 games with it; without the file it
cannot start them (`fastboot oem cores` lists the core files on the card and their headers).

## How the LK uses it

- When one of these games is started, the LK opens `/cores/genesis-plus-gx-pico.blob` on the card
  and reads the 20 byte header: magic `0x31474553` ("SEG1"), interface version 4, the entry
  offset, the image size and the total span with the BSS. It checks that the entry is inside the
  image and that the span fits the core slot, 0x4F800000 to 0x50000000 (8 MiB; the blob takes
  about 4.6 MiB with its BSS). The file may stop up to 15 bytes short of the image size, since
  objcopy leaves out the zero pad that aligns the image end.
- It copies the image to 0x4F800000, zeroes the rest of the span, cleans the data cache and
  invalidates the instruction cache over it, and calls the entry (`genesis_core_blob_init`) with
  its imports (the pad state and the wall clock). The blob returns its export table, which carries
  the same magic and version again.
- `heap_init` hands the core the LK's emulator arena at 0x50000000. Genesis Plus GX is built with
  `USE_DYNAMIC_ALLOC`, so its large buffers (the cartridge, up to 32 MiB, work RAM, VRAM, sound)
  live there and the slot only holds the code and a small BSS.
- The ROM is passed as a buffer: `load` answers libretro's GET_GAME_INFO_EXT with it, and the
  system (Mega Drive, Master System, Game Gear, SG-1000) follows from the folder the game came
  from. The Mega Drive gets a 6 button pad.
- Each `run` is one `retro_run`: a 16 bit RGB565 picture and its 44.1 kHz stereo sound. Battery
  saves (`sram_ptr`/`sram_size`), save states, run ahead, rewind (with `sound_rebase`), fast
  forward, the region option and the frame rate the panel follows (`fps_milli`) all go through the
  export table in `genesis_core_abi.h`.

## Target notes for maintainers

- **The interface.** `pico/genesis_core_abi.h` is the contract with the LK: `genesis_core_exports`
  (what the LK calls) and `genesis_core_imports` (what the LK gives the core). The version is
  written twice, in the header and as a literal in `pico/blob.ld`; change both together, and keep
  the copy here identical to the LK's.
- **No NEON, no hardware floating point.** The blob uses the soft float ABI and never touches the
  VFP or NEON registers, so it does not depend on the LK saving them across thread switches.
- **The C library.** The blob links no newlib libc: `pico/pico_libc.c` and `pico/pico_stubs.c`
  provide the few functions the core needs, compiled outside LTO and with `-fno-builtin`, since GCC
  otherwise turns their byte loops into calls to `memcpy` and `memset` themselves. newlib's libm
  (the FM chips, the equaliser and the NTSC filters build their tables with `sin`, `cos`, `pow`,
  `exp`, `log` and a few more) and libgcc's
  soft float and division helpers are linked from the toolchain.
- **Allocation.** `free` does nothing: the arena is reset for every game (the LK's menu uses it
  too while open). `heap_mark` and `heap_reset` exist for run ahead's save and load pairs; the
  core allocates almost nothing while serialising.
