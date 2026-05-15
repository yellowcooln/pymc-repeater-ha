# Home Assistant Add-on: pyMC Repeater

## About

This add-on wraps the upstream `pymcdev/pymc-repeater:dev` container and keeps
the pyMC Repeater runtime configuration in the add-on config directory.

The first time the add-on starts it will create:

- `/config/config.yaml`
- `/config/identity.key` when pyMC Repeater generates its node identity
- `/var/lib/pymc_repeater` for runtime data

Inside Home Assistant, `/config` above is the add-on config mount. The exact
host path is managed by Home Assistant, but it is the persistent config folder
for this add-on.

## Install

1. Add this repository to Home Assistant.
2. Install the `pyMC Repeater` add-on.
3. Start the add-on once so it seeds `config.yaml`.
4. Stop the add-on.
5. Edit `config.yaml` in the add-on config folder to match your hardware.
6. Start the add-on again and open the web UI on port `8000`.

## Configuration

This add-on uses a file-based configuration instead of mirroring the full
upstream YAML into Home Assistant options. `pyMC_Repeater` has a large nested
radio configuration, and keeping it as YAML is the most maintainable first
version.

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
