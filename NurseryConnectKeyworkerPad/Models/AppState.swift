import SwiftUI
import Observation

enum KeyworkerSection: String, CaseIterable, Identifiable {
    case dashboard, roster, attendance, diary, meal, incident, development, reports

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard:   return "Dashboard"
        case .roster:      return "My Key Children"
        case .attendance:  return "Attendance"
        case .diary:       return "Daily Diary"
        case .meal:        return "Meals"
        case .incident:    return "Incidents"
        case .development: return "Development"
        case .reports:     return "Reports"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:   return "square.grid.2x2.fill"
        case .roster:      return "person.3.fill"
        case .attendance:  return "checkmark.circle.fill"
        case .diary:       return "book.pages.fill"
        case .meal:        return "fork.knife"
        case .incident:    return "exclamationmark.shield.fill"
        case .development: return "chart.line.uptrend.xyaxis"
        case .reports:     return "doc.richtext.fill"
        }
    }

    var color: Color {
        switch self {
        case .dashboard:   return AppPalette.primary
        case .roster:      return AppPalette.teal
        case .attendance:  return AppPalette.green
        case .diary:       return AppPalette.purple
        case .meal:        return AppPalette.orange
        case .incident:    return AppPalette.red
        case .development: return AppPalette.indigo
        case .reports:     return AppPalette.accent
        }
    }

    var shortcutKey: Character {
        switch self {
        case .dashboard:   return "0"
        case .roster:      return "1"
        case .attendance:  return "2"
        case .diary:       return "3"
        case .meal:        return "4"
        case .incident:    return "5"
        case .development: return "6"
        case .reports:     return "7"
        }
    }
}

enum KeyworkerQuickAction: Identifiable {
    case newDiary
    case newIncident
    var id: String {
        switch self {
        case .newDiary: return "diary"
        case .newIncident: return "incident"
        }
    }
}

@Observable
class AppState {
    var keyworkerName: String = "Nuwani Wijerathne"
    var room: String = "Daisy Room"
    var nurseryName: String = "Bright Horizons Nursery — Colombo"
    var selectedSection: KeyworkerSection = .dashboard
    var selectedChildId: UUID? = nil
    var pendingAction: KeyworkerQuickAction? = nil
    var showNewDiaryEntry: Bool = false
    var showNewIncident: Bool = false

    // Aliases used by ported keyworker views
    var currentUserName: String { keyworkerName }
    var assignedRoom: String { room }
}
