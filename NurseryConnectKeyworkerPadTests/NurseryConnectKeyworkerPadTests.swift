import Testing
import Foundation
import SwiftData
@testable import NurseryConnectKeyworkerPad

@Suite("Child model") struct ChildModelTests {
    @Test func childInitialisationPopulatesPreferredName() {
        let c = Child(fullName: "Sethmi Wickramasinghe", dateOfBirth: Date(), keyworkerName: "K", room: "Daisy")
        #expect(c.preferredName == "Sethmi")
        #expect(c.initials == "SW")
    }
    @Test func allergenParsingSplitsCommaList() {
        let c = Child(fullName: "X Y", dateOfBirth: Date(), keyworkerName: "K", room: "R")
        c.allergenList = "milk, egg, peanut"
        #expect(c.allergens.count == 3)
        #expect(c.hasAllergens)
    }
}

@Suite("Sample data") @MainActor struct SampleSeedTests {
    @Test func populateInsertsChildrenAndAttendance() throws {
        let schema = Schema([Child.self, DiaryEntry.self, IncidentReport.self, AttendanceRecord.self, MealRecord.self, Message.self, MealPlanItem.self, TransportRun.self, StockItem.self, MediaPhoto.self])
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [cfg])
        SampleData.populate(in: container.mainContext)
        let kids = try container.mainContext.fetch(FetchDescriptor<Child>())
        #expect(kids.count == 8)
        let att = try container.mainContext.fetch(FetchDescriptor<AttendanceRecord>())
        #expect(att.count == 8)
    }
}

@Suite("AppState") struct AppStateTests {
    @Test func defaultSectionIsDashboard() {
        let s = AppState()
        #expect(s.selectedSection == .dashboard)
        #expect(s.keyworkerName == "Danuka Nalindu")
    }
    @Test func sectionShortcutsAreUnique() {
        let keys = KeyworkerSection.allCases.map { $0.shortcutKey }
        #expect(Set(keys).count == keys.count)
    }
}
