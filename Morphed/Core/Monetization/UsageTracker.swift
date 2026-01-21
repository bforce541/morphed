// Morphed/Core/Monetization/UsageTracker.swift

import Foundation

/// Local usage tracking, with optional backend sync (stubbed).
enum UsageTracker {
    private static let storageKey = "morphed_usage_stats_v1"
    
    struct Stats: Codable {
        var totalMorphs: Int = 0
        var hdExports: Int = 0
        var maxModeUses: Int = 0
        var cleanModeUses: Int = 0
    }
    
    static func load() -> Stats {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Stats.self, from: data) {
            return decoded
        }
        return Stats()
    }
    
    static func recordMorph(isMax: Bool) {
        var stats = load()
        stats.totalMorphs += 1
        if isMax {
            stats.maxModeUses += 1
        } else {
            stats.cleanModeUses += 1
        }
        persist(stats)
        AnalyticsTracker.track("morph_completed", properties: ["isMax": isMax])
    }
    
    static func recordHDExport() {
        var stats = load()
        stats.hdExports += 1
        persist(stats)
        AnalyticsTracker.track("hd_export", properties: nil)
    }
    
    private static func persist(_ stats: Stats) {
        if let data = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}


