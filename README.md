# System Stats Widget (macOS)

A macOS desktop widget (WidgetKit) that shows live **CPU, memory, and disk usage**,
refreshed automatically on a timeline.

## Requirements

- macOS 14 (Sonoma) or later on the machine where the widget runs
- Xcode 15 or later to build

## Project layout

```
SysStatsWidget/
├── SysStatsWidget.xcodeproj      Xcode project (app target + widget extension target)
├── SysStatsWidget/               Host app (minimal SwiftUI app)
│   ├── SysStatsWidgetApp.swift
│   └── Info.plist
└── SysStatsWidgetExtension/      WidgetKit extension
    ├── SysStatsWidget.swift      Widget, TimelineProvider, and SwiftUI views
    ├── StatsCollector.swift      CPU / memory / disk sampling (mach + FileManager)
    └── Info.plist
```

## Build and run

1. Copy this folder to your Mac and open `SysStatsWidget.xcodeproj` in Xcode.
2. Select the **SysStatsWidget** scheme and run (Cmd-R). The host app must be built
   and run once so macOS registers the embedded widget extension.
3. Add the widget: open Notification Center (click the clock in the menu bar) and
   click **Edit Widgets**, or right-click the desktop and choose **Edit Widgets**
   (macOS 15+). Search for **System Stats**, pick a size (small / medium / large),
   and add it. Drag it onto the desktop if you placed it in Notification Center.

## How it works

- `Provider` (a `TimelineProvider`) produces one entry per refresh and schedules
  the next reload with `.after(...)`. The interval is `refreshInterval = 60`
  seconds in `SysStatsWidget.swift` — change it to tune freshness vs. battery.
- `SystemStatsCollector` reads:
  - CPU: `host_processor_info(..., PROCESSOR_CPU_LOAD_INFO, ...)` tick deltas
    between reloads (first sample falls back to the since-boot average).
  - Memory: `ProcessInfo.physicalMemory` for total, `host_statistics64(...,
    HOST_VM_INFO64, ...)` free pages for used.
  - Disk: `FileManager.attributesOfFileSystem(forPath: "/")` for the startup
    volume's total/free space.
- Both targets have **app sandbox disabled** (`ENABLE_SANDBOX = NO`) because the
  mach host-statistics APIs are unavailable to sandboxed processes. This is fine
  for local/development builds; if you ever distribute through the Mac App Store,
  replace the mach calls with sandbox-compatible alternatives or request the
  appropriate entitlements.

## Customizing

- Widget identity: `kind` in `SysStatsWidget.swift` and `configurationDisplayName`.
- Sizes: `supportedFamilies([.systemSmall, .systemMedium, .systemLarge])`.
- Layout: `smallLayout` / `mediumLayout` / `largeLayout` in `StatsWidgetView`.
- Refresh cadence: `refreshInterval` in `Provider`.
- Bundle IDs: `PRODUCT_BUNDLE_IDENTIFIER` in the target build settings
  (`com.example.sysstatswidget` / `com.example.sysstatswidget.extension`).

## Note

This project was authored in a Linux sandbox without a Swift toolchain, so it has
not been compiled here. Open it in Xcode on a Mac; if Xcode reports the project
format needs updating, accept the prompt.
