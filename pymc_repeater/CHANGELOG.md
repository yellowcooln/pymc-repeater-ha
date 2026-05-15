# Changelog

## 0.1.10

- Add an informational config tab entry showing the add-on config file location

## 0.1.9

- Remove the extra nested `pymc-repeater/` directory inside the add-on config mount
- Migrate nested config and identity files back to `/config/config.yaml` and `/config/identity.key`
- Refresh the bundled example config from the current upstream `config.yaml.example`

## 0.1.8

- Move add-on config to `/config/pymc-repeater/config.yaml`
- Seed and preserve a real file-based config instead of syncing from add-on options
- Migrate legacy `/config/config.yaml` and `/config/identity.key` into the new folder

## 0.1.7

- Fallback to the Supervisor self-info API when `/data/options.json` is absent
- Distinguish `existing persistent config` from the bundled template in startup logs

## 0.1.6

- Log whether the add-on options file exists and whether `config_yaml` is empty
- Include effective `node_name` with the startup config diagnostic

## 0.1.5

- Log the effective add-on config source and parsed `radio_type` at startup
- Document that the wrapped upstream image does not currently provide `pymc_tcp`

## 0.1.4

- Rename the visible add-on to `pyMC Repeater Dev`
- Document that this repository tracks the upstream `:dev` image

## 0.1.3

- Update starter config header to direct users to the three-dot "Edit in YAML" view

## 0.1.2

- Add commented `pymc_tcp` example to the default configuration template
- Document that comments in the Configuration tab must stay inside `config_yaml`

## 0.1.1

- Add editable `config_yaml` field in the Home Assistant Configuration tab
- Mirror Configuration tab YAML into `/config/config.yaml` on startup

## 0.1.0

- Initial Home Assistant add-on scaffold
- Wraps `pymcdev/pymc-repeater:dev`
- Seeds persistent `config.yaml` on first start
