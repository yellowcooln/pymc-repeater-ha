#!/bin/sh
set -eu

PERSISTENT_CONFIG_DIR="/config"
PERSISTENT_CONFIG_FILE="${PERSISTENT_CONFIG_DIR}/config.yaml"
TEMPLATE_CONFIG_FILE="/usr/share/pymc-repeater/config.yaml.example"
RUNTIME_CONFIG_DIR="/etc/pymc_repeater"
DATA_DIR="/var/lib/pymc_repeater"
UI_OPTIONS_FILE="/data/options.json"
SUPERVISOR_ADDON_INFO_URL="http://supervisor/addons/self/info"
CONFIG_SOURCE="unknown"

mkdir -p "${PERSISTENT_CONFIG_DIR}"
mkdir -p "${DATA_DIR}"

if [ -f "${UI_OPTIONS_FILE}" ]; then
    echo "[pymc-repeater-ha] found add-on options file at ${UI_OPTIONS_FILE}"
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
    print("[pymc-repeater-ha] add-on options did not contain a non-empty config_yaml value")
    raise SystemExit(0)

output_path.write_text(config_yaml.rstrip("\n") + "\n", encoding="utf-8")
PY

    if [ -s "${TEMP_CONFIG_FILE}" ]; then
        if [ ! -f "${PERSISTENT_CONFIG_FILE}" ]; then
            cp "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
            echo "[pymc-repeater-ha] created ${PERSISTENT_CONFIG_FILE} from add-on options"
            CONFIG_SOURCE="add-on options"
        elif ! cmp -s "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"; then
            cp "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
            echo "[pymc-repeater-ha] updated ${PERSISTENT_CONFIG_FILE} from add-on options"
            CONFIG_SOURCE="add-on options"
        else
            CONFIG_SOURCE="add-on options"
        fi
    fi

    rm -f "${TEMP_CONFIG_FILE}"
else
    echo "[pymc-repeater-ha] no add-on options file present at ${UI_OPTIONS_FILE}"
fi

if [ "${CONFIG_SOURCE}" = "unknown" ] && [ -n "${SUPERVISOR_TOKEN:-}" ]; then
    echo "[pymc-repeater-ha] attempting Supervisor API fallback via ${SUPERVISOR_ADDON_INFO_URL}"
    TEMP_CONFIG_FILE="$(mktemp)"
    python3 - "${SUPERVISOR_ADDON_INFO_URL}" "${SUPERVISOR_TOKEN}" "${TEMP_CONFIG_FILE}" <<'PY'
import json
import pathlib
import sys
import urllib.request

url = sys.argv[1]
token = sys.argv[2]
output_path = pathlib.Path(sys.argv[3])

request = urllib.request.Request(
    url,
    headers={
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    },
)

try:
    with urllib.request.urlopen(request, timeout=10) as response:
        payload = json.loads(response.read().decode("utf-8"))
except Exception as exc:
    print(f"[pymc-repeater-ha] Supervisor API fallback failed: {exc}")
    raise SystemExit(0)

data = payload.get("data") if isinstance(payload, dict) else None
options = data.get("options") if isinstance(data, dict) else None
config_yaml = options.get("config_yaml", "") if isinstance(options, dict) else ""

if not isinstance(config_yaml, str) or not config_yaml.strip():
    print("[pymc-repeater-ha] Supervisor API options did not contain a non-empty config_yaml value")
    raise SystemExit(0)

output_path.write_text(config_yaml.rstrip("\n") + "\n", encoding="utf-8")
PY

    if [ -s "${TEMP_CONFIG_FILE}" ]; then
        if [ ! -f "${PERSISTENT_CONFIG_FILE}" ]; then
            cp "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
            echo "[pymc-repeater-ha] created ${PERSISTENT_CONFIG_FILE} from Supervisor API options"
            CONFIG_SOURCE="Supervisor API options"
        elif ! cmp -s "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"; then
            cp "${TEMP_CONFIG_FILE}" "${PERSISTENT_CONFIG_FILE}"
            echo "[pymc-repeater-ha] updated ${PERSISTENT_CONFIG_FILE} from Supervisor API options"
            CONFIG_SOURCE="Supervisor API options"
        else
            CONFIG_SOURCE="Supervisor API options"
        fi
    fi

    rm -f "${TEMP_CONFIG_FILE}"
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
