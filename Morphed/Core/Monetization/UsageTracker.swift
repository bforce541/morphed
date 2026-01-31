// Morphed/Core/Monetization/UsageTracker.swift

import Foundation

/// Local usage tracking, with optional backend sync (stubbed).
enum UsageTracker {
    private static let storageKey = "morphed_usage_stats_v2"
    
    struct Stats: Codable {
        var totalMorphs: Int = 0
        var hdExports: Int = 0
        var presenceUses: Int = 0
        var physiqueUses: Int = 0
        var faceUses: Int = 0
        var professionalityUses: Int = 0
    }
    
    static func load() -> Stats {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(Stats.self, from: data) {
            return decoded
        }
        return Stats()
    }
    
    static func recordMorph(mode: EditorViewModel.EditMode) {
        var stats = load()
        stats.totalMorphs += 1
        switch mode {
        case .presence: stats.presenceUses += 1
        case .physique: stats.physiqueUses += 1
        case .face: stats.faceUses += 1
        case .professionality: stats.professionalityUses += 1
        }
        persist(stats)
        AnalyticsTracker.track("morph_completed", properties: ["mode": mode.rawValue])
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

