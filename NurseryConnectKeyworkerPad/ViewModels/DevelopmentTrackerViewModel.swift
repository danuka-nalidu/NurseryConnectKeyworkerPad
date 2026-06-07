import SwiftUI
import Observation

@Observable
class DevelopmentTrackerViewModel {
    var keyworkerName: String = ""

    init(keyworkerName: String) {
        self.keyworkerName = keyworkerName
    }

    func myChildren(from all: [Child]) -> [Child] {
        all.filter { $0.keyworkerName == keyworkerName }
    }

    func entriesForChild(_ child: Child, from all: [DiaryEntry]) -> [DiaryEntry] {
        all.filter { $0.childId == child.id }
    }

    func progressForArea(_ area: String, entries: [DiaryEntry]) -> Double {
        let baseProgress = Double(entries.count) / 30.0
        let milestones = entries.filter { $0.entryType == "milestone" }.count
        let areaHash = Double(abs(area.hashValue) % 20) / 100.0
        return min(1.0, max(0.1, baseProgress + Double(milestones) * 0.05 + areaHash))
    }

    func activityBreakdown(entries: [DiaryEntry]) -> [(type: String, count: Int)] {
        let grouped = Dictionary(grouping: entries, by: { $0.entryType })
        return grouped.map { (type: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    func weeklyActivityData(entries: [DiaryEntry]) -> [(week: String, count: Int)] {
        let calendar = Calendar.current
        let weeks = ["4w ago", "3w ago", "2w ago", "Last week", "This week"]
        return weeks.enumerated().map { index, label in
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -(4 - index), to: Date())!
            let weekEnd = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
            let count = entries.filter { $0.timestamp >= weekStart && $0.timestamp < weekEnd }.count
            return (week: label, count: count)
        }
    }
}
