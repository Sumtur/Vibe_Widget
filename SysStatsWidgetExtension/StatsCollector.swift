import Foundation

struct SystemStats {
    let cpuUsage: Double
    let memoryUsed: UInt64
    let memoryTotal: UInt64
    let diskUsed: UInt64
    let diskTotal: UInt64
}

enum SystemStatsCollector {
    private static var previousCPUTicks: (total: UInt64, idle: UInt64)?

    static func collect() -> SystemStats {
        let memory = memoryUsage()
        let disk = diskUsage()
        return SystemStats(
            cpuUsage: cpuUsage(),
            memoryUsed: memory.used,
            memoryTotal: memory.total,
            diskUsed: disk.used,
            diskTotal: disk.total
        )
    }

    private static func cpuUsage() -> Double {
        var processorCount = mach_msg_type_number_t()
        var cpuLoadInfo: processor_info_array_t = nil
        var cpuLoadInfoCount = mach_msg_type_number_t()

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &processorCount,
            &cpuLoadInfo,
            &cpuLoadInfoCount
        )
        guard result == KERN_SUCCESS, let info = cpuLoadInfo else { return 0 }

        let load = info.withMemoryRebound(
            to: processor_cpu_load_info_data_t.self,
            capacity: Int(processorCount)
        ) { buffer in
            var total: UInt64 = 0
            var idle: UInt64 = 0
            for index in 0..<Int(processorCount) {
                let ticks = buffer[index].cpu_ticks
                total += UInt64(ticks.0) + UInt64(ticks.1) + UInt64(ticks.2) + UInt64(ticks.3)
                idle += UInt64(ticks.2)
            }
            return (total: total, idle: idle)
        }
        vm_deallocate(
            mach_task_self_,
            vm_address_t(bitPattern: info),
            vm_size_t(cpuLoadInfoCount) * vm_size_t(MemoryLayout<integer_t>.stride)
        )

        let previous = previousCPUTicks
        previousCPUTicks = load
        guard let previous, load.total > previous.total else {
            return load.total > 0 ? (Double(load.total - load.idle) / Double(load.total)) * 100 : 0
        }
        let totalDelta = load.total - previous.total
        let idleDelta = load.idle - previous.idle
        return (Double(totalDelta - idleDelta) / Double(totalDelta)) * 100
    }

    private static func memoryUsage() -> (used: UInt64, total: UInt64) {
        let total = ProcessInfo.processInfo.physicalMemory

        var pageSize = vm_size_t()
        host_page_size(mach_host_self(), &pageSize)

        var stats = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { rebound in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, rebound, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (used: 0, total: total) }

        let free = UInt64(stats.free_count) * UInt64(pageSize)
        let used = total > free ? total - free : 0
        return (used: used, total: total)
    }

    private static func diskUsage() -> (used: UInt64, total: UInt64) {
        guard
            let attributes = try? FileManager.default.attributesOfFileSystem(forPath: "/"),
            let total = attributes[.systemSize] as? NSNumber,
            let free = attributes[.systemFreeSize] as? NSNumber
        else { return (used: 0, total: 0) }

        let totalValue = total.uint64Value
        let freeValue = free.uint64Value
        return (used: totalValue > freeValue ? totalValue - freeValue : 0, total: totalValue)
    }
}
