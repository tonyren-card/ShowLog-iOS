import SwiftUI

enum WatchStatus: String, Codable, CaseIterable {
    case watching  = "Watching"
    case completed = "Completed"
    case queued    = "Queue"
    case dropped   = "Dropped"

    var icon: String {
        switch self {
        case .watching:  return "play.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .queued:    return "clock.fill"
        case .dropped:   return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .watching:  return .showGreen
        case .completed: return .blue
        case .queued:    return .textMuted
        case .dropped:   return .red
        }
    }
}
