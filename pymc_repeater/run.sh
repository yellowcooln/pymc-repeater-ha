#!/bin/sh
set -eu

ADDON_CONFIG_ROOT="/config"
PERSISTENT_CONFIG_DIR="${ADDON_CONFIG_ROOT}/pymc-repeater"
PERSISTENT_CONFIG_FILE="${PERSISTENT_CONFIG_DIR}/config.yaml"
TEMPLATE_CONFIG_FILE="/usr/share/pymc-repeater/config.yaml.example"
RUNTIME_CONFIG_DIR="/etc/pymc_repeater"
DATA_DIR="/var/lib/pymc_repeater"
LEGACY_CONFIG_FILE="${ADDON_CONFIG_ROOT}/config.yaml"
LEGACY_IDENTITY_FILE="${ADDON_CONFIG_ROOT}/identity.key"
CONFIG_SOURCE="unknown"

mkdir -p "${ADDON_CONFIG_ROOT}"
mkdir -p "${PERSISTENT_CONFIG_DIR}"
mkdir -p "${DATA_DIR}"

if [ ! -f "${PERSISTENT_CONFIG_FILE}" ] && [ -f "${LEGACY_CONFIG_FILE}" ]; then
    cp "${LEGACY_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
    echo "[pymc-repeater-ha] migrated legacy config from ${LEGACY_CONFIG_FILE} to ${PERSISTENT_CONFIG_FILE}"
    CONFIG_SOURCE="migrated legacy config"
fi

if [ ! -f "${PERSISTENT_CONFIG_DIR}/identity.key" ] && [ -f "${LEGACY_IDENTITY_FILE}" ]; then
    cp "${LEGACY_IDENTITY_FILE}" "${PERSISTENT_CONFIG_DIR}/identity.key"
    chmod 600 "${PERSISTENT_CONFIG_DIR}/identity.key" || true
    echo "[pymc-repeater-ha] migrated legacy identity key into ${PERSISTENT_CONFIG_DIR}"
fi

if [ ! -f "${PERSISTENT_CONFIG_FILE}" ]; then
    cp "${TEMPLATE_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
    echo "[pymc-repeater-ha] created ${PERSISTENT_CONFIG_FILE} from bundled template"
    CONFIG_SOURCE="bundled template"
elif [ "${CONFIG_SOURCE}" = "unknown" ]; then
    CONFIG_SOURCE="existing persistent config"
fi

if [ "$(readlink "${RUNTIME_CONFIG_DIR}" 2>/dev/null || true)" != "${PERSISTENT_CONFIG_DIR}" ]; then
    rm -rf "${RUNTIME_CONFIG_DIR}"
    ln -s "${PERSISTENT_CONFIG_DIR}" "${RUNTIME_CONFIG_DIR}"
fi

python3 - "${PERSISTENT_CONFIG_FILE}" "${CONFIG_SOURCE}" <<'PY'
import pathlib
import sys

import yaml

config_path = pathlib.Path(sys.argv[1])
config_source = sys.argv[2]

radio_type = "unknown"
node_name = "unknown"
try:
    config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
    radio_type = str(config.get("radio_type", "missing"))
    node_name = str(config.get("repeater", {}).get("node_name", "missing"))
except Exception as exc:
    print(f"[pymc-repeater-ha] failed to inspect effective config: {exc}")
else:
    print(
        f"[pymc-repeater-ha] effective config source: {config_source}; "
        f"radio_type={radio_type}; node_name={node_name}; path={config_path}"
    )
PY

exec python3 -m repeater.main --config "${RUNTIME_CONFIG_DIR}/config.yaml"
