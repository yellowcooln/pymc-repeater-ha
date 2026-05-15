#!/bin/sh
set -eu

PERSISTENT_CONFIG_DIR="/config"
PERSISTENT_CONFIG_FILE="${PERSISTENT_CONFIG_DIR}/config.yaml"
TEMPLATE_CONFIG_FILE="/usr/share/pymc-repeater/config.yaml.example"
RUNTIME_CONFIG_DIR="/etc/pymc_repeater"
DATA_DIR="/var/lib/pymc_repeater"
UI_OPTIONS_FILE="/data/options.json"

mkdir -p "${PERSISTENT_CONFIG_DIR}"
mkdir -p "${DATA_DIR}"

if [ -f "${UI_OPTIONS_FILE}" ]; then
    TEMP_CONFIG_FILE="$(mktemp)"
    python3 - "${UI_OPTIONS_FILE}" "${TEMP_CONFIG_FILE}" <<'PY'
import json
import pathlib
import sys

options_path = pathlib.Path(sys.argv[1])
output_path = pathlib.Path(sys.argv[2])

try:
    options = json.loads(options_path.read_text(encoding="utf-8"))
except FileNotFoundError:
    raise SystemExit(0)

config_yaml = options.get("config_yaml", "")
if not isinstance(config_yaml, str) or not config_yaml.strip():
    raise SystemExit(0)

output_path.write_text(config_yaml.rstrip("\n") + "\n", encoding="utf-8")
PY

    if [ -s "${TEMP_CONFIG_FILE}" ]; then
        if [ ! -f "${PERSISTENT_CONFIG_FILE}" ]; then
            cp "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
            echo "[pymc-repeater-ha] created ${PERSISTENT_CONFIG_FILE} from add-on options"
        elif ! cmp -s "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"; then
            cp "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
            echo "[pymc-repeater-ha] updated ${PERSISTENT_CONFIG_FILE} from add-on options"
        fi
    fi

    rm -f "${TEMP_CONFIG_FILE}"
fi

if [ ! -f "${PERSISTENT_CONFIG_FILE}" ]; then
    cp "${TEMPLATE_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
    echo "[pymc-repeater-ha] created ${PERSISTENT_CONFIG_FILE} from bundled template"
fi

if [ "$(readlink "${RUNTIME_CONFIG_DIR}" 2>/dev/null || true)" != "${PERSISTENT_CONFIG_DIR}" ]; then
    rm -rf "${RUNTIME_CONFIG_DIR}"
    ln -s "${PERSISTENT_CONFIG_DIR}" "${RUNTIME_CONFIG_DIR}"
fi

exec python3 -m repeater.main --config "${RUNTIME_CONFIG_DIR}/config.yaml"
