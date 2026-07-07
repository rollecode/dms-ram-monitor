# RAM Monitor

RAM usage as an animated progress bar in your [DankBar](https://github.com/AvengeMedia/DankMaterialShell), updated every second.

![Screenshot](Screenshot.png)

Shown next to its sibling [VRAM Monitor](https://github.com/rollecode/dms-vram-monitor).

## What it does

- Compact bar pill: icon, optional label, animated progress bar and percentage
- Updates every second from `/proc/meminfo` (used = MemTotal - MemAvailable, the same math `free` uses)
- Fill follows your theme accent, turns orange above 75% and red above 90%
- Zero dependencies

## Installation

From the DMS plugin browser (Settings, Plugins tab, Browse), or manually:

```bash
git clone https://github.com/rollecode/dms-ram-monitor ~/.config/DankMaterialShell/plugins/ramMonitor
```

Then enable it in Settings, Plugins, and add the widget to your bar layout in Settings, Bar.

## Settings

- **Show label**: toggle the text label between the icon and the bar (on by default)
- **Label text**: customize the label (default `RAM`)

## License

MIT
