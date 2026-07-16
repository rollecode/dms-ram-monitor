# RAM Monitor

RAM usage as an animated progress bar in your [DankBar](https://github.com/AvengeMedia/DankMaterialShell), updated every second.

![Screenshot](Screenshot.png)

Shown next to its sibling [VRAM Monitor](https://github.com/rollecode/dms-vram-monitor).

## What it does

- Compact bar pill: icon, optional label, animated progress bar and percentage
- Updates every second from `/proc/meminfo` (used = MemTotal - MemAvailable, the same math `free` uses)
- Fill follows your theme accent, turns orange above 75% and red above 90%
- Click the pill for a breakdown of what is using memory, biggest first, with a kill icon on each process
- Zero dependencies

## The popout

It lists **every** consumer, not just processes. zram, page cache, kernel slab, tmpfs and buffers each get a row, because on most systems those are a large share of "used" and no process owns them. Without them the list is misleading: a pill reading 69% next to a 400 MB top process looks broken, when the real answer is that several gigabytes are sitting in compressed swap and cache.

Free is pinned to the top in the accent colour. Processes carry a kill icon; system rows do not.

Processes are measured by **private memory** (resident minus shared) rather than RSS. RSS counts shared pages once per process, so summing it double-counts and overshoots the total. Private memory sums to `AnonPages`, which is the kernel's own figure for process memory.

Each process shows a second, dimmer word where one can be resolved: the script for interpreters (`python3 neai_bot.py`), the working directory for shells, the subprocess type for Electron apps. Chromium is the exception, its helpers are zygote-forked without re-exec and inherit the parent's cmdline, so `/proc` cannot tell them apart.

The list is only collected while the popout is open.

## Installation

From the DMS plugin browser (Settings, Plugins tab, Browse), or manually:

```bash
git clone https://github.com/rollecode/dms-ram-monitor ~/.config/DankMaterialShell/plugins/ramMonitor
```

Then enable it in Settings, Plugins, and add the widget to your bar layout in Settings, Bar.

## Settings

- **Show label**: toggle the text label between the icon and the bar (on by default)
- **Label text**: customize the label (default `RAM`)
- **Entries to show**: how many rows the popout lists, 5 to 60 (default 30)

## License

MIT
