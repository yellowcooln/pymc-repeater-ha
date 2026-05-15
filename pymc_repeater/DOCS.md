# Home Assistant Add-on: pyMC Repeater Dev

## About

This add-on wraps the upstream `pymcdev/pymc-repeater:dev` container and keeps
the pyMC Repeater runtime configuration in the add-on config directory.

This is the development-tracking add-on. It is intentionally pinned to the
upstream `:dev` image, not a stable release image.

Current upstream support in this add-on image follows the `pyMC_Repeater`
project itself, including newer backends such as `pymc_tcp` when they are
present in the published `:dev` image.

The first time the add-on starts it will create:

- `/config/config.yaml`
- `/config/identity.key` when pyMC Repeater generates its node identity
- `/var/lib/pymc_repeater` for runtime data

Inside Home Assistant, `/config` above is the add-on config mount. On the host,
this add-on config lives in its own `addon_config` folder, not in Home
Assistant's main `/config`.

## Install

1. Add this repository to Home Assistant.
2. Install the `pyMC Repeater Dev` add-on.
3. Open your Home Assistant file editor, such as Studio Code Server.
4. Edit the add-on config file `config.yaml` in the add-on's own config folder.
5. Start the add-on and open the web UI on port `8000`.

## Configuration

This add-on uses a real YAML file at `/config/config.yaml`.
The add-on seeds that file on first start and then treats it as the single
source of truth. If pyMC Repeater updates the file itself, those changes are
preserved across restarts.

If you are upgrading from the previous nested-layout revision of this add-on,
startup will migrate `/config/pymc-repeater/config.yaml` into `/config/config.yaml`.

The bundled starter config is aimed at an SX1262 SPI radio. At minimum, review:

- `repeater.node_name`
- `repeater.security.admin_password`
- `repeater.security.guest_password`
- `radio.frequency`
- `sx1262.bus_id`
- `sx1262.cs_id`
- `sx1262.cs_pin`
- `sx1262.reset_pin`
- `sx1262.busy_pin`
- `sx1262.irq_pin`

If you are using a KISS modem instead of SPI radio hardware, switch
`radio_type` to `kiss` and configure the `kiss` section instead.

When editing in the Home Assistant `Configuration` tab, remember that you are
not editing the repeater YAML anymore. Use the file at `/config/config.yaml`
inside the add-on config folder instead.

## Hardware Access

This add-on currently runs with `full_access: true` and AppArmor disabled.
That is deliberate for the first version because pyMC Repeater may need a mix
of SPI, GPIO, USB, and serial access depending on the attached radio hardware.

If you want a tighter security model later, reduce this to specific Home
Assistant device and privilege mappings once the required hardware matrix is
better pinned down.

## Web UI

The upstream container exposes its web interface on port `8000`.

## Upstream Project

- Upstream repo: <https://github.com/pyMC-dev/pyMC_Repeater>
- Upstream image used by this add-on: `pymcdev/pymc-repeater:dev`
