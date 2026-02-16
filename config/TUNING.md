# Timing Tuning Guide

Reference for adjusting hold-tap and combo timing parameters. Each section describes what to look for and which direction to adjust. All parameters are set per-behavior in `urchin.keymap`.

## tapping-term-ms (currently 200ms)

**Applies to:** All hold-tap behaviors (home row mods and thumb layer-taps).

**What it does:** The maximum time a key can be held before ZMK commits to a hold. Below this window, a press-release is a tap; beyond it, it's a hold. With `flavor = "balanced"`, the decision also considers whether another key was pressed during the window.

| Symptom | Direction | Example |
|---------|-----------|---------|
| Modifier combos register as taps (e.g. Ctrl+C types `sc`) | Decrease | Finish typing, quickly Ctrl+C — registers as letters instead |
| Normal typing triggers accidental holds/modifiers | Increase | Fast typing produces phantom Ctrl/GUI/Alt |

**Current values:** 200ms on all behaviors (`hml`, `hmr`, `hml_gui`, `hmr_gui`, `hml_ctrl`, `hmr_ctrl`, `hmr_alt`, `lt_thumb`).

## require-prior-idle-ms (currently 100ms)

**Applies to:** Pinky GUI keys only (`hml_gui` for A, `hmr_gui` for O).

**What it does:** If the previous keypress was within this window, the hold-tap resolves as a tap regardless of other heuristics. Prevents false GUI activation during fast typing rolls through the pinky. This is the ZMK equivalent of QMK's `FLOW_TAP_TERM`.

| Symptom | Direction | Example |
|---------|-----------|---------|
| GUI triggers during fast typing through A or O | Decrease | Typing "star" or "boat" activates GUI |
| GUI+key shortcut fails after typing (registers as plain letter) | Increase | Pause after typing, hit GUI+Tab, get `a` instead |

**Current value:** 100ms on `hml_gui` and `hmr_gui`. Not used on other behaviors — Shift (T/N) and Ctrl (S/E) need to activate reliably even mid-typing.

## quick-tap-ms (currently 80ms thumbs, 120ms home row, 0ms E)

**Applies to:** All hold-tap behaviors, with per-behavior values.

**What it does:** After tapping a key, if you press it again within this window, ZMK registers a repeat tap instead of evaluating hold. Lower values require faster double-taps to repeat. Setting to 0 disables repeat-tap entirely.

| Symptom | Direction | Example |
|---------|-----------|---------|
| Accidental repeated taps (double space, double backspace) | Decrease | Pressing space twice in quick succession when only one was intended |
| Can't intentionally repeat a key fast enough | Increase | Want to tap-tap-tap space quickly but second tap activates layer |

**Current values:**
- **120ms** — Most home row mods (`hml`, `hmr`, `hml_gui`, `hmr_gui`, `hml_ctrl`, `hmr_alt`)
- **80ms** — Thumb layer-taps (`lt_thumb`), tighter because thumbs are more prone to accidental double-taps
- **0ms** — Right Ctrl/E key (`hmr_ctrl`), disabled because E is frequently used in Ctrl chords right after typing E

## hold-while-undecided (boolean)

**Applies to:** All hold-tap behaviors except the GUI pinky keys (`hml_gui`, `hmr_gui`).

**What it does:** When enabled, ZMK speculatively activates the hold action (modifier or layer) while waiting for the tapping-term to decide. If the key is released as a tap, the hold is undone and the tap is sent. This eliminates the delay between pressing a modifier and the modified key registering. Equivalent to QMK's `SPECULATIVE_HOLD`.

| Symptom | Direction | Example |
|---------|-----------|---------|
| Modifier or layer feels laggy — there's a visible delay before the held action takes effect | Enable | Hold S for Ctrl+C, but Ctrl doesn't register until after tapping-term expires |
| False modifier activations during fast typing rolls | Disable | Rolling through home row triggers brief phantom modifiers between keystrokes |

**Current values:** Enabled on `hml`, `hmr`, `hml_ctrl`, `hmr_ctrl`, `lt_thumb`. Omitted on:
- **`hml_gui`, `hmr_gui`** — GUI pinky keys use `require-prior-idle-ms` instead; combining both would make GUI too eager during typing
- **`hmr_alt`** — ZMK sends the speculative modifier to the host immediately (unlike QMK which buffers it internally). A brief Alt press-release during typing rolls triggers Firefox's menu bar activation on Linux/GTK

## hold-trigger-key-positions (positional hold-tap)

**Applies to:** All home row mod behaviors (not thumb layer-taps).

**What it does:** Lists key positions that are allowed to trigger a hold. Keys not in this list force a tap resolution. This implements cross-hand-only hold activation — same-hand keys produce taps. Equivalent to QMK's `CHORDAL_HOLD`.

| Symptom | Direction | Example |
|---------|-----------|---------|
| Same-hand shortcut doesn't work (modifier + key on same side) | Add the key position to the list | Ctrl+C (both left hand) doesn't work because position 22 isn't in `hml`'s list |
| Typing rolls on the same hand trigger false holds | Remove the key position from the list | Rolling S→T triggers Ctrl because T is in `hml_ctrl`'s allowed positions |

**Current values:**
- **`hml`** (R, T) — `KEYS_R THUMBS` (opposite hand + thumbs only)
- **`hmr`** (N) — `KEYS_L THUMBS`
- **`hml_gui`** (A) — `KEYS_R THUMBS 21 22 24` (adds X, C, B for GUI+copy/paste)
- **`hml_ctrl`** (S) — `KEYS_R THUMBS 21 22 24` (adds X, C, B for Ctrl+X/C/V)
- **`hmr_ctrl`** (E) — `KEYS_L THUMBS`
- **`hmr_alt`** (I) — `KEYS_L THUMBS 5 25` (adds J, K for Alt+J/K browser devtools)
- **`hmr_gui`** (O) — `KEYS_L THUMBS 5 25` (same as `hmr_alt`)

**Note:** `hold-trigger-on-release` is also enabled on all home row mods, allowing nested hold-taps (e.g. holding two modifiers simultaneously) to resolve correctly.

## Combo timeout-ms (currently 50ms)

**Applies to:** All thumb combos (30+31 and 32+33).

**What it does:** The maximum time between the two key presses for ZMK to recognize them as a combo rather than individual keys. Both keys must be pressed within this window.

| Symptom | Direction | Example |
|---------|-----------|---------|
| Combos fire when you meant to press individual thumb keys | Decrease | Pressing Space then Tab quickly triggers Esc (Media combo) instead |
| Combos fail to register — you get individual keys instead | Increase | Pressing both thumbs together but getting Space+Tab instead of Esc |

**Current value:** 50ms on all combos.
