import SwiftUI
import SwiftData
import Observation

@Observable
class AttendanceViewModel {
    var searchText: String = ""
    var keyworkerName: String = ""

    init(keyworkerName: String) {
        self.keyworkerName = keyworkerName
    }

    func myChildren(from all: [Child]) -> [Child] {
        all.filter { $0.keyworkerName == keyworkerName }
    }

    func filteredChildren(from all: [Child]) -> [Child] {
        let mine = myChildren(from: all)
        if searchText.isEmpty { return mine }
        return mine.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    func checkedInCount(from all: [Child]) -> Int {
        myChildren(from: all).filter { $0.isCheckedIn }.count
    }

    func toggleAttendance(child: Child, records: [AttendanceRecord], context: ModelContext) {
        let today = Calendar.current.startOfDay(for: Date())
        if child.isCheckedIn {
            child.isCheckedIn = false
            child.checkInTime = nil
            child.checkInBy = ""
            if let record = records.first(where: {
                $0.childId == child.id && Calendar.current.isDate($0.date, inSameDayAs: today)
            }) {
                record.checkOutTime = Date()
                record.collectedBy = "Parent"
            }
            let entry = DiaryEntry(
                childId: child.id,
                childName: child.preferredName,
                entryType: "checkout",
                description: "\(child.preferredName) checked out at \(Date().timeString)",
                keyworkerName: keyworkerName
            )
            context.insert(entry)
        } else {
            child.isCheckedIn = true
            child.checkInTime = Date()
            child.checkInBy = keyworkerName
            let record = AttendanceRecord(childId: child.id, childName: child.fullName)
            record.checkInTime = Date()
            record.droppedOffBy = child.parentOneName
            context.insert(record)
            let entry = DiaryEntry(
                childId: child.id,
                childName: child.preferredName,
                entryType: "checkin",
                description: "\(child.preferredName) checked in at \(Date().timeString)",
                keyworkerName: keyworkerName
            )
            context.insert(entry)
        }
        try? context.save()
    }
}
