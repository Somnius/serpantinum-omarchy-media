# Serpantinum Media for Omarchy

An unofficial clean-room Omarchy plugin inspired by the motion and presentation of Ilya Miro's Serpantinum widgets. It combines native output volume, mute, output selection, and MPRIS playback in one animated popup.

## Requirements

- Omarchy 4.x
- Quickshell 0.3.x as shipped by Omarchy

That is the complete base requirement. PipeWire/MPRIS integration, Qt, the Omarchy design system, and plugin management are already part of supported Omarchy installations. Do **not** install replacements for them. The plugin does not require Cava or EasyEffects and never prompts for packages.

## Install

```bash
omarchy plugin add https://github.com/Somnius/serpantinum-omarchy-media --enable
```

The widget defaults to the right section. Move it with Omarchy if desired:

```bash
omarchy bar move somnius.serpantinum-media --section right
```

Left-click opens the popup, right-click toggles mute, and the wheel adjusts volume. While the popup is focused, Left/Right adjusts volume, Space toggles playback, and Escape closes it. The popup offers the current output, safe native output selection, and controls for the selected MPRIS player.

## Configuration

Settings are inline values on the widget entry in `~/.config/omarchy/shell.json`:

```json
{
  "id": "somnius.serpantinum-media",
  "maxVolume": 100,
  "reduceMotion": false
}
```

- `maxVolume`: slider/wheel ceiling from 1–150 percent; defaults to 100, including when an invalid value is supplied.
- `reduceMotion`: removes this plugin's content and liquid-fill transitions. Omarchy may still animate its host popup surface.

Omarchy hot-reloads the plugin and settings. No packaged file under `/usr/share/omarchy` should be edited.

## Behavior and limitations

- PipeWire and MPRIS are authoritative; the plugin does not poll `pactl`, `wpctl`, or `playerctl`.
- If PipeWire has no default sink, audio controls disable and state why.
- If no MPRIS player exists, the media card remains as an explicit empty state.
- Output selection uses Quickshell's native `preferredDefaultAudioSink` API. Some hardware/profile changes remain the responsibility of Omarchy's built-in audio panel.
- Player preference is transient and resets with shell/plugin reload.
- Album artwork is requested only from the URL published by the player while the popup exists; failure falls back to a themed icon.
- Cava waveform and EasyEffects controls are intentionally outside the base release.

## Update and remove

```bash
omarchy plugin update somnius.serpantinum-media
omarchy plugin disable somnius.serpantinum-media
omarchy plugin remove somnius.serpantinum-media
```

## Development

```bash
omarchy plugin validate .
node tests/model.test.js
qmllint -I /usr/share/omarchy/shell BarWidget.qml
```

The last command may report import-resolution limitations outside the live Omarchy shell; runtime imports are supplied by `omarchy-shell`.

## Security and privacy

The plugin executes no external commands, installs no packages, writes no files, uses no privileged operation, and has no independent network client. Media artwork URLs originate from the active MPRIS player and are handled by QML's image loader.

## License and attribution

Independent plugin code is MIT licensed. See [NOTICE.md](NOTICE.md) for inspiration, clean-room, and non-endorsement details. No Serpantinum source code or assets are included.
