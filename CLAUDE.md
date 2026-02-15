# ZMK Config - Urchin Keyboard

## Project Overview

ZMK firmware configuration for a 34-key Urchin split keyboard (nice_nano_v2). Ported from Byron's QMK userspace (`../qmk_userspace/users/byron/`).

## Key Files

- `config/urchin.keymap` - Complete keymap: behaviors, combos, 7 layers
- `config/urchin.conf` - ZMK Kconfig settings (mouse/pointing enabled)
- `config/west.yml` - West manifest (ZMK v0.3 + urchin-zmk-module)
- `build.yaml` - GitHub Actions build matrix (urchin_left, urchin_right)
- `build.sh` - Local build script using podman

## Layout

Colemak with urob-style "timeless" home row mods using positional hold-tap.

### Key Position Map

```
 0  1  2  3  4       5  6  7  8  9
10 11 12 13 14      15 16 17 18 19
20 21 22 23 24      25 26 27 28 29
         30 31      32 33
```

### Home Row Mods

Left: A(GUI), R(ALT), S(CTL), T(SFT). Right: N(SFT), E(CTL), I(LALT), O(GUI).

7 behavior variants handle per-key differences:
- `hml`/`hmr` - standard positional hold-tap (cross-hand)
- `hml_gui`/`hmr_gui` - pinky GUI keys with `require-prior-idle-ms` (flow tap)
- `hml_ctrl` - left Ctrl with same-hand C/X/V exception (copy/paste)
- `hmr_ctrl` - right Ctrl with quick-tap disabled (E key)
- `hmr_alt` - right Alt with same-hand J/K exception (browser devtools)

### Thumb Keys (4 physical + 2 combos)

```
Physical: [NAV/Space] [MOUSE/Tab]   [SYM/Enter] [NUM/Bspc]
Combos:   [MEDIA/Esc (30+31)]       [FUN/Del (32+33)]
```

Combos have per-layer bindings (e.g., DOT on NUM, LPAR on SYM, DEL on NAV).

### Layers

BASE, NAV, NUM, SYM, FUN, MEDIA, MOUSE. Matches QMK source exactly.

## QMK-to-ZMK Mapping

| QMK | ZMK |
|-----|-----|
| PERMISSIVE_HOLD | `flavor = "balanced"` |
| CHORDAL_HOLD | Positional hold-tap (`hold-trigger-key-positions`) |
| SPECULATIVE_HOLD | `hold-while-undecided` |
| FLOW_TAP_TERM | `require-prior-idle-ms` |
| QUICK_TAP_TERM | `quick-tap-ms` |

## Building

### Local (podman)

`./build.sh` builds firmware inside a podman container (`zmk-build-arm:stable`). The west workspace lives in `.zmk/` (gitignored) and is auto-initialized on first run.

```
./build.sh              # build both halves
./build.sh left         # build left half only
./build.sh right        # build right half only
./build.sh --update     # run west update before building
./build.sh setup        # wipe .zmk/ workspace and rebuild from scratch
```

Output: `firmware/urchin_left.uf2`, `firmware/urchin_right.uf2`.

### CI (GitHub Actions)

Push to GitHub and the Actions workflow builds firmware for both halves. Firmware .uf2 files appear as build artifacts.

## Related Repositories

- `../qmk_userspace` - QMK version (canonical source for keymap design decisions)
- `../miryoku_zmk` - Previous ZMK config (miryoku-based, no longer used)
