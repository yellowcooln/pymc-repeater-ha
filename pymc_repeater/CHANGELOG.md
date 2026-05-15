# Changelog

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
