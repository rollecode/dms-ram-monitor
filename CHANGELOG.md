# Changelog

### 1.3.1: 2026-07-17

* Reword the Available row's hint to "free to use": "usable right now" was one glance from reading as usage

### 1.3.0: 2026-07-17

* Show Available pinned on top instead of MemFree: what programs can actually use, not the deliberately tiny free count
* Explain system rows in place with three dim words: page cache, disk buffers, kernel slab, kernel overhead
* Count only physical RAM in the pill percentage: zram's share is excluded, it keeps its own row
* Colour every popout bar with the orange and red thresholds; Available keeps the accent
* Keep the pill a constant width: digits changing every second no longer resize it and churn the bar layout

### 1.2.0: 2026-07-17

* Add a popout listing what is actually using memory, biggest first, with a kill icon on each process
* List every consumer, not just processes: zram, page cache, kernel slab, tmpfs and buffers get their own rows, so the pill's percentage adds up instead of looking unexplained next to a 400 MB top process
* Pin Free to the top of the list in the accent colour
* Show a second, dimmer word per process: the script for interpreters (`python3 neai_bot.py`), the working directory for shells and `claude`, the subprocess type for Electron apps. Chromium cannot be resolved this way, its helpers inherit the parent's cmdline
* Measure processes by private memory (resident minus shared) rather than RSS, which double-counts shared pages and would overshoot the total
* Add a slider for how many rows the popout lists, 5 to 60, default 30
* Only collect the list while the popout is open

### 1.1.0: 2026-07-07

* Add an optional text label after the icon, on by default, customisable

### 1.0.0: 2026-07-07

* Initial release: RAM usage as an animated progress bar in the DankBar, updated every second
