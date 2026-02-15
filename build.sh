#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
ZMK_DIR="${REPO_DIR}/.zmk"
FIRMWARE_DIR="${REPO_DIR}/firmware"
IMAGE="docker.io/zmkfirmware/zmk-build-arm:stable"
BOARD="nice_nano_v2"

# Container-internal paths
C_REPO="/zmk-config"
C_ZMK="${C_REPO}/.zmk"
C_CONFIG="${C_REPO}/config"
C_ZEPHYR_CMAKE="${C_ZMK}/zephyr/share/zephyr-package/cmake"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMMAND]

Commands:
  left          Build left half only
  right         Build right half only
  setup         Wipe workspace, re-initialize, and build both halves

Options:
  --update      Run west update before building
  -h, --help    Show this help message

With no command, builds both halves.
Output: firmware/urchin_left.uf2, firmware/urchin_right.uf2
EOF
    exit 0
}

# Parse arguments
UPDATE=false
SIDES=()
SETUP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --update) UPDATE=true; shift ;;
        -h|--help) usage ;;
        setup) SETUP=true; shift ;;
        left|right) SIDES+=("$1"); shift ;;
        *) echo "Unknown argument: $1" >&2; usage ;;
    esac
done

[[ ${#SIDES[@]} -eq 0 ]] && SIDES=(left right)

# Handle setup: wipe workspace
if $SETUP; then
    echo "Wiping workspace..."
    rm -rf "$ZMK_DIR"
fi

mkdir -p "$FIRMWARE_DIR"

# Prepare the config symlink directory. west init needs this to exist
# beforehand, and the symlink must use the container-internal path since
# west runs inside the container.
mkdir -p "${ZMK_DIR}/config"
ln -sf "${C_CONFIG}/west.yml" "${ZMK_DIR}/config/west.yml"

NEEDS_INIT=false
[[ ! -f "${ZMK_DIR}/.west/config" ]] && NEEDS_INIT=true

# Build the script that runs inside the container
build_container_script() {
    local cmds=()

    if $NEEDS_INIT; then
        cmds+=("west init -l ${C_ZMK}/config/")
        cmds+=("west config manifest.group-filter -- -hal")
        cmds+=("west config manifest.project-filter -- -lvgl,-nanopb,-zmk-studio-messages")
        cmds+=("west update")
    elif $UPDATE; then
        cmds+=("west update")
    fi

    for side in "${SIDES[@]}"; do
        cmds+=("echo '=== Building ${side} ==='")
        cmds+=("west build -s zmk/app -d build/${side} -b ${BOARD} -p -- -DSHIELD=urchin_${side} -DZMK_CONFIG=${C_CONFIG} -DCMAKE_PREFIX_PATH=${C_ZEPHYR_CMAKE}")
        cmds+=("cp build/${side}/zephyr/zmk.uf2 ${C_REPO}/firmware/urchin_${side}.uf2")
    done

    local result="${cmds[0]}"
    for ((i=1; i<${#cmds[@]}; i++)); do
        result+=" && ${cmds[$i]}"
    done
    echo "$result"
}

echo "Building: ${SIDES[*]}"
podman run --rm \
    --userns=keep-id \
    -v "${REPO_DIR}:${C_REPO}:Z" \
    -w "${C_ZMK}" \
    "$IMAGE" \
    /bin/bash -c "$(build_container_script)"

echo ""
for side in "${SIDES[@]}"; do
    echo "Firmware: firmware/urchin_${side}.uf2"
done
