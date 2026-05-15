#!/bin/sh
set -eu

PERSISTENT_CONFIG_DIR="/config"
PERSISTENT_CONFIG_FILE="${PERSISTENT_CONFIG_DIR}/config.yaml"
TEMPLATE_CONFIG_FILE="/usr/share/pymc-repeater/config.yaml.example"
RUNTIME_CONFIG_DIR="/etc/pymc_repeater"
DATA_DIR="/var/lib/pymc_repeater"

mkdir -p "${PERSISTENT_CONFIG_DIR}"
mkdir -p "${DATA_DIR}"

if [ ! -f "${PERSISTENT_CONFIG_FILE}" ]; then
    cp "${TEMPLATE_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
    echo "[pymc-repeater-ha] created ${PERSISTENT_CONFIG_FILE} from bundled template"
fi

if [ "$(readlink "${RUNTIME_CONFIG_DIR}" 2>/dev/null || true)" != "${PERSISTENT_CONFIG_DIR}" ]; then
    rm -rf "${RUNTIME_CONFIG_DIR}"
    ln -s "${PERSISTENT_CONFIG_DIR}" "${RUNTIME_CONFIG_DIR}"
fi

exec python3 -m repeater.main --config "${RUNTIME_CONFIG_DIR}/config.yaml"
