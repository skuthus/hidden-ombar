# Hidden Om-Bar

Collapse Omarchy bar widgets behind a chevron so the bar stays quiet until you need it.

Inspired by [Hidden Bar](https://github.com/dwarvesf/hidden) for macOS, but this is a different plugin with a different name: it hides **Omarchy shell widgets**, not macOS menu extras.

**Expanded**

![Expanded](expanded.png)

**Collapsed**

![Collapsed](collapsed.png)

## Install

```bash
omarchy plugin add https://github.com/skuthus/hidden-ombar.git --enable
```

Omarchy will warn that third-party plugins run unsandboxed, then ask which bar section to use. **Right** is the usual choice.

Place the chevron **after** the widgets you want to hide (drag widgets on the bar, or use `omarchy bar move`). Everything before the chevron in that section collapses. Everything after it stays visible.

Example: tray, network, audio, **Hidden Om-Bar**, clock — tray/network/audio tuck away; the clock stays put.

## Usage

- **Left click** the chevron to expand or collapse
- **Right click** to open preferences
- **Middle click** to toggle auto-collapse
- Drag the chevron (or neighboring widgets) to choose what is hidden
- The bar starts expanded for a second, then collapses, matching Hidden Bar

### Preferences

| Setting | Default | Meaning |
| --- | --- | --- |
| Auto collapse | on | Collapse again after a delay |
| Collapse after | 10s | 5, 10, 15, 30, or 60 seconds |
| Hover to expand | off | Hold the pointer on the chevron to peek |
| Hide widgets before this icon | on | Off hides widgets *after* the chevron instead |

Auto-collapse waits while the pointer is on the bar, while you drag widgets, or while the preferences card is open.

### Keyboard shortcut

```bash
omarchy-shell skuthus.hidden-om-bar toggle
omarchy-shell skuthus.hidden-om-bar expand
omarchy-shell skuthus.hidden-om-bar collapse
```

Example Hyprland bind in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + H", nil, "omarchy-shell skuthus.hidden-om-bar toggle")
```

## Remove

```bash
omarchy plugin remove skuthus.hidden-om-bar --yes
```

Widget settings live in that plugin's layout entry in `~/.config/omarchy/shell.json`. Removing the plugin takes the entry with it. No other files are written.

## License

MIT. Not affiliated with Hidden Bar or Dwarves Foundation.
