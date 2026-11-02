# Solar Halo Cooler Add-on

A small Factorio 2.0 add-on for the [Solar Halo](https://mods.factorio.com/mod/Solar-Halo) mod (by deluxev2).
It makes the supercomputer easier to keep under its 200 °C shutdown limit and shows you how hot it is.

## What it does

- **Heat limit.** Scales how much heat each supercomputer craft puts into the heat network, from 1% to 75% of the original. Power use and Compute output are unchanged.
- **Temperature on the machine.** A label such as `172°C / 200°C` and a bar (0–200 °C, tick at 160 °C) above and below every supercomputer. Colours: blue below 160, green 160–180, amber 180–200, red at 200 and above. No alerts.
- **Overview window.** A shortcut button (or `Ctrl+Shift+H`) opens a list of all supercomputers on all surfaces with location, temperature, state, machine status and a Show button that zooms to the machine.

## Install

1. Install Solar Halo.
2. Download `solar-halo-cooler_add_on_<version>.zip` from the Releases page and put it, still zipped, in your Factorio `mods` folder.
3. Start the game. If the shortcut button does not appear, add "Supercomputer overview" in the shortcut bar settings.

## Setting

Startup setting **Supercomputer heat (% of normal)**, default 75, range 1–75. Startup settings need a restart. Factorio may keep a previously saved value, so check it under Settings → Mod settings → Startup.

## How the heat limit works

Solar Halo raises the supercomputer's heat buffer by a fixed number of degrees per craft. The energy that heatsinks have to remove is that rise times the buffer's `specific_heat` (200 MJ/°C originally). The add-on lowers `specific_heat` in `data-final-fixes.lua`, so there is less heat to remove for the same temperature rise. At 100% heat a supercomputer at full load makes about 500 MW of heat; one steam-recipe heatsink removes up to about 20 MW.

## Cooling rule of thumb

On an isolated, turbine-only network each turbine supplies about 1.8 MW (165 °C steam), which caps the supercomputer's power and so its heat. Ten turbines match one heatsink's steam output. If other generators share the network, the turbines idle, steam backs up, and the heatsinks stop cooling.

## Notes

Written against Solar Halo 1.1.0/1.2.0 and Factorio 2.0. Not affiliated with the Solar Halo author.
