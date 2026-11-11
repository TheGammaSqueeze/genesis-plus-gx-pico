#!/bin/bash
# Copyright (c) 2026 TheGammaSqueeze. Part of genesis-plus-gx-pico, under the Genesis Plus GX
# licence (LICENSE).
# Build the sprites only render check (tests/render_status_test.c, patch 0005) on the PC from the
# same patched sources as the blob. It runs a ROM with the full render, with render_line_status
# and with no render, hashing the save state every frame; the sprites only pass must match the
# full render on every frame.
#   tests/build_render_status_test.sh && out/gpgx_render_status_test rom.bin [frames]
source "$(dirname "$0")/host_common.sh"
host_build "$ROOT/tests/render_status_test.c" "$ROOT/out/gpgx_render_status_test"
echo "built out/gpgx_render_status_test - run: out/gpgx_render_status_test rom.bin [frames]"
