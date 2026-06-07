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

@Suite("DiaryEntry model") struct DiaryEntryModelTests {
    @Test func entryTypeDisplayIsCorrect() {
        let e = DiaryEntry(childId: UUID(), childName: "Test", entryType: "activity", description: "note", keyworkerName: "K")
        #expect(e.entryTypeDisplay == "Activity")
        e.entryType = "nappy"
        #expect(e.entryTypeDisplay == "Nappy")
        e.entryType = "sleep"
        #expect(e.entryTypeDisplay == "Sleep / Nap")
        e.entryType = "milestone"
        #expect(e.entryTypeDisplay == "Milestone")
    }

    @Test func entryIconIsCorrect() {
        let e = DiaryEntry(childId: UUID(), childName: "Test", entryType: "sleep", description: "note", keyworkerName: "K")
        #expect(e.entryIcon == "moon.fill")
        e.entryType = "milestone"
        #expect(e.entryIcon == "star.fill")
        e.entryType = "meal"
        #expect(e.entryIcon == "fork.knife")
    }

    @Test func typeLabelHelperIsCorrect() {
        #expect(DiaryEntry.typeLabel("activity") == "Activity")
        #expect(DiaryEntry.typeLabel("checkin") == "Check-In")
        #expect(DiaryEntry.typeLabel("checkout") == "Check-Out")
    }
}

@Suite("IncidentReport model") struct IncidentReportModelTests {
    @Test func categoryLabelMapping() {
        #expect(IncidentReport.categoryLabel("minor_accident") == "Minor Accident")
        #expect(IncidentReport.categoryLabel("safeguarding") == "Safeguarding Concern")
        #expect(IncidentReport.categoryLabel("allergic_reaction") == "Allergic Reaction")
        #expect(IncidentReport.categoryLabel("first_aid") == "First Aid Required")
    }
}

@Suite("Attendance logic") @MainActor struct AttendanceLogicTests {
    @Test func toggleCheckInCreatesAttendanceRecord() throws {
        let schema = Schema([Child.self, DiaryEntry.self, IncidentReport.self, AttendanceRecord.self,
                             MealRecord.self, Message.self, MealPlanItem.self, TransportRun.self, StockItem.self, MediaPhoto.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = container.mainContext
        let child = Child(fullName: "Test Child", dateOfBirth: Date(), keyworkerName: "Danuka Nalindu", room: "Daisy")
        ctx.insert(child)
        try ctx.save()

        let vm = AttendanceViewModel(keyworkerName: "Danuka Nalindu")
        vm.toggleAttendance(child: child, records: [], context: ctx)

        let records = try ctx.fetch(FetchDescriptor<AttendanceRecord>())
        #expect(records.count == 1)
        #expect(records.first?.childId == child.id)
        #expect(child.isCheckedIn == true)
    }

    @Test func toggleCheckInCreatesDiaryEntry() throws {
        let schema = Schema([Child.self, DiaryEntry.self, IncidentReport.self, AttendanceRecord.self,
                             MealRecord.self, Message.self, MealPlanItem.self, TransportRun.self, StockItem.self, MediaPhoto.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = container.mainContext
        let child = Child(fullName: "Test Child", dateOfBirth: Date(), keyworkerName: "Danuka Nalindu", room: "Daisy")
        ctx.insert(child)

        let vm = AttendanceViewModel(keyworkerName: "Danuka Nalindu")
        vm.toggleAttendance(child: child, records: [], context: ctx)

        let entries = try ctx.fetch(FetchDescriptor<DiaryEntry>())
        #expect(entries.contains { $0.entryType == "checkin" })
    }

    @Test func toggleCheckOutCreatesDiaryEntry() throws {
        let schema = Schema([Child.self, DiaryEntry.self, IncidentReport.self, AttendanceRecord.self,
                             MealRecord.self, Message.self, MealPlanItem.self, TransportRun.self, StockItem.self, MediaPhoto.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let ctx = container.mainContext
        let child = Child(fullName: "Test Child", dateOfBirth: Date(), keyworkerName: "Danuka Nalindu", room: "Daisy")
        child.isCheckedIn = true
        ctx.insert(child)

        let vm = AttendanceViewModel(keyworkerName: "Danuka Nalindu")
        vm.toggleAttendance(child: child, records: [], context: ctx)

        let entries = try ctx.fetch(FetchDescriptor<DiaryEntry>())
        #expect(entries.contains { $0.entryType == "checkout" })
        #expect(child.isCheckedIn == false)
    }
}

@Suite("Meal logging") @MainActor struct MealLoggingTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Child.self, DiaryEntry.self, IncidentReport.self, AttendanceRecord.self,
                             MealRecord.self, Message.self, MealPlanItem.self, TransportRun.self, StockItem.self, MediaPhoto.self])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func saveMealInsertsMealRecord() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let child = Child(fullName: "Test Child", dateOfBirth: Date(), keyworkerName: "Danuka Nalindu", room: "Daisy")
        ctx.insert(child)

        let vm = MealLogViewModel(keyworkerName: "Danuka Nalindu")
        vm.selectedMealType = "lunch"
        vm.saveMeal(childId: child.id, children: [child], foodOffered: "Pasta", foodConsumed: "most", notes: "", context: ctx)

        let records = try ctx.fetch(FetchDescriptor<MealRecord>())
        #expect(records.count == 1)
        #expect(records.first?.mealType == "lunch")
        #expect(records.first?.foodConsumed == "most")
    }

    @Test func saveMealCreatesDiaryEntry() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let child = Child(fullName: "Test Child", dateOfBirth: Date(), keyworkerName: "Danuka Nalindu", room: "Daisy")
        ctx.insert(child)

        let vm = MealLogViewModel(keyworkerName: "Danuka Nalindu")
        vm.saveMeal(childId: child.id, children: [child], foodOffered: "Pasta", foodConsumed: "all", notes: "", context: ctx)

        let entries = try ctx.fetch(FetchDescriptor<DiaryEntry>())
        #expect(entries.contains { $0.entryType == "meal" })
    }
}
