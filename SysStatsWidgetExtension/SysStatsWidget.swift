import SwiftUI
import WidgetKit

struct StatsEntry: TimelineEntry {
    let date: Date
    let cpuUsage: Double
    let memoryUsed: UInt64
    let memoryTotal: UInt64
    let diskUsed: UInt64
    let diskTotal: UInt64
}

struct Provider: TimelineProvider {
    private let refreshInterval: TimeInterval = 60

    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(
            date: Date(),
            cpuUsage: 42,
            memoryUsed: 11 * 1024 * 1024 * 1024,
            memoryTotal: 16 * 1024 * 1024 * 1024,
            diskUsed: 240 * 1024 * 1024 * 1024,
            diskTotal: 500 * 1024 * 1024 * 1024
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        let entry = currentEntry()
        let nextUpdate = entry.date.addingTimeInterval(refreshInterval)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func currentEntry() -> StatsEntry {
        let stats = SystemStatsCollector.collect()
        return StatsEntry(
            date: Date(),
            cpuUsage: stats.cpuUsage,
            memoryUsed: stats.memoryUsed,
            memoryTotal: stats.memoryTotal,
            diskUsed: stats.diskUsed,
            diskTotal: stats.diskTotal
        )
    }
}

struct SysStatsWidget: Widget {
    let kind: String = "com.example.sysstatswidget.stats"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            StatsWidgetView(entry: entry)
        }
        .configurationDisplayName("System Stats")
        .description("CPU, memory and disk usage at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct StatsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StatsEntry

    private static let byteFormatter: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter
    }()

    var body: some View {
        content
            .containerBackground(.fill.tertiary, for: .widget)
            .widgetURL(URL(string: "sysstatswidget://open"))
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemSmall:
            smallLayout
        case .systemLarge:
            largeLayout
        default:
            mediumLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            statRow(title: "CPU", percent: entry.cpuUsage, detail: "\(Int(entry.cpuUsage.rounded()))%", tint: .orange)
            statRow(title: "Memory", percent: memoryPercent, detail: Self.byteFormatter.string(fromByteCount: Int64(entry.memoryUsed)), tint: .blue)
        }
        .padding()
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            statRow(title: "CPU", percent: entry.cpuUsage, detail: "\(Int(entry.cpuUsage.rounded()))%", tint: .orange)
            statRow(title: "Memory", percent: memoryPercent, detail: "\(Self.byteFormatter.string(fromByteCount: Int64(entry.memoryUsed))) / \(Self.byteFormatter.string(fromByteCount: Int64(entry.memoryTotal)))", tint: .blue)
            statRow(title: "Disk", percent: diskPercent, detail: "\(Self.byteFormatter.string(fromByteCount: Int64(entry.diskUsed))) / \(Self.byteFormatter.string(fromByteCount: Int64(entry.diskTotal)))", tint: .purple)
        }
        .padding()
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("System Stats", systemImage: "gauge.with.needle.fill")
                    .font(.headline)
                Spacer()
                Text(entry.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Divider()
            statRow(title: "CPU", percent: entry.cpuUsage, detail: "\(Int(entry.cpuUsage.rounded()))% of \(ProcessInfo.processInfo.processorCount) cores", tint: .orange)
            statRow(title: "Memory", percent: memoryPercent, detail: "\(Self.byteFormatter.string(fromByteCount: Int64(entry.memoryUsed))) of \(Self.byteFormatter.string(fromByteCount: Int64(entry.memoryTotal))) used", tint: .blue)
            statRow(title: "Disk", percent: diskPercent, detail: "\(Self.byteFormatter.string(fromByteCount: Int64(entry.diskUsed))) of \(Self.byteFormatter.string(fromByteCount: Int64(entry.diskTotal))) used", tint: .purple)
        }
        .padding()
    }

    private var memoryPercent: Double {
        entry.memoryTotal > 0 ? Double(entry.memoryUsed) / Double(entry.memoryTotal) * 100 : 0
    }

    private var diskPercent: Double {
        entry.diskTotal > 0 ? Double(entry.diskUsed) / Double(entry.diskTotal) * 100 : 0
    }

    private func statRow(title: String, percent: Double, detail: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: min(max(percent, 0), 100), total: 100)
                .tint(tint)
        }
    }
}

#Preview(as: .systemMedium) {
    SysStatsWidget()
} timeline: {
    StatsEntry(date: .now, cpuUsage: 37, memoryUsed: 11_000_000_000, memoryTotal: 16_000_000_000, diskUsed: 240_000_000_000, diskTotal: 500_000_000_000)
}
