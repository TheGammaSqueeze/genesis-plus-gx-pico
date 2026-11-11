#!/bin/bash
# Copyright (c) 2026 TheGammaSqueeze. Part of genesis-plus-gx-pico, under the Genesis Plus GX
# licence (LICENSE).
# Build the headless core check (tests/host_test.c) on the PC from the same patched sources as the
# blob: it loads a ROM through the GET_GAME_INFO_EXT buffer path as the blob does, runs frames and
# round-trips a save state. With no ROM it makes a minimal Mega Drive image of its own.
#   tests/build_host_test.sh && out/gpgx_host_test [rom.md] [frames]
source "$(dirname "$0")/host_common.sh"
host_build "$ROOT/tests/host_test.c" "$ROOT/out/gpgx_host_test"
echo "built out/gpgx_host_test - run: out/gpgx_host_test [rom.md] [frames]"
