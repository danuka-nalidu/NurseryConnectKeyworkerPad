import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DiaryEntry.timestamp, order: .reverse) private var allEntries: [DiaryEntry]
    @Query(sort: \Child.fullName) private var allChildren: [Child]

    @State private var selectedChild: Child?
    @State private var filterType: String = "All"
    @State private var selectedEntry: DiaryEntry?
    @State private var showTimeline = true

    private var myChildren: [Child] {
        allChildren.filter { $0.keyworkerName == appState.currentUserName }
    }

    private var filteredEntries: [DiaryEntry] {
        let ids = Set(myChildren.map { $0.id })
        var entries = allEntries.filter { ids.contains($0.childId) }
        if let child = selectedChild { entries = entries.filter { $0.childId == child.id } }
        if filterType != "All"      { entries = entries.filter { $0.entryType == filterType } }
        return entries
    }

    private let entryTypes = ["All", "activity", "sleep", "nappy", "meal", "wellbeing", "milestone"]

    var body: some View {
        Group {
            if showTimeline || selectedEntry != nil {
                HSplitContent(
                    list: { diaryListContent },
                    detail: {
                        if let entry = selectedEntry {
                            diaryEntryDetailView(entry: entry)
                        } else if filteredEntries.isEmpty {
                            ContentUnavailableView("No Diary Entries", systemImage: "book.closed", description: Text("Tap + to add a new diary entry"))
                        } else {
                            diaryTimelineView
                        }
                    }
                )
            } else {
                diaryListContent
            }
        }
        .navigationTitle("Daily Diary")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        showTimeline.toggle()
                        if showTimeline { selectedEntry = nil }
                    } label: {
                        Label(showTimeline ? "Hide Timeline" : "Show Timeline", systemImage: showTimeline ? "timeline.selection" : "list.bullet")
                    }
                    Button {
                        appState.showNewDiaryEntry = true
                    } label: {
                        Label("New Entry", systemImage: "plus")
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])
                }
            }
        }
    }

    private var diaryListContent: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button { selectedChild = nil } label: {
                        Text("All Children")
                            .font(.system(size: 12, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(selectedChild == nil ? AppPalette.purple : Color.gray.opacity(0.1), in: Capsule())
                            .foregroundStyle(selectedChild == nil ? .white : AppPalette.textPrimary)
                    }
                    ForEach(myChildren) { child in
                        Button { selectedChild = child } label: {
                            Text(child.preferredName)
                                .font(.system(size: 12, weight: .semibold))
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedChild?.id == child.id ? AppPalette.purple : Color.gray.opacity(0.1), in: Capsule())
                                .foregroundStyle(selectedChild?.id == child.id ? .white : AppPalette.textPrimary)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(entryTypes, id: \.self) { type in
                        Button { filterType = type } label: {
                            Text(type == "All" ? "All" : DiaryEntry.typeLabel(type))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(filterType == type ? AppPalette.teal : Color.gray.opacity(0.08), in: Capsule())
                                .foregroundStyle(filterType == type ? .white : AppPalette.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.bottom, 8)
            }

            Divider()

            List(filteredEntries, selection: $selectedEntry) { entry in
                DiaryEntryRow(entry: entry).tag(entry)
            }
            .listStyle(.plain)
        }
    }

    private var diaryTimelineView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Timeline")
                    .font(.system(size: 20, weight: .bold))
                    .padding(.horizontal, 24)

                let todayEntries = filteredEntries.filter { Calendar.current.isDateInToday($0.timestamp) }
                let olderEntries = filteredEntries.filter { !Calendar.current.isDateInToday($0.timestamp) }

                if !todayEntries.isEmpty {
                    ForEach(todayEntries) { DiaryTimelineCard(entry: $0) }
                        .padding(.horizontal, 24)
                }
                if !olderEntries.isEmpty {
                    Text("Previous Days")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppPalette.textSecondary)
                        .padding(.horizontal, 24).padding(.top, 12)
                    ForEach(olderEntries.prefix(10)) { DiaryTimelineCard(entry: $0) }
                        .padding(.horizontal, 24)
                }
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(AppPalette.background)
    }

    private func diaryEntryDetailView(entry: DiaryEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Image(systemName: entry.entryIcon)
                        .font(.system(size: 24))
                        .foregroundStyle(entry.entryColor)
                        .frame(width: 48, height: 48)
                        .background(entry.entryColor.opacity(0.1), in: Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.entryTypeDisplay).font(.system(size: 18, weight: .bold))
                        Text("\(entry.childName) · \(entry.timestamp.dayMonthString) at \(entry.timestamp.timeString)")
                            .font(.system(size: 13))
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                    Spacer()
                    if entry.isReadByParent {
                        Label("Parent viewed", systemImage: "eye.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.green)
                    }
                }
                Divider()
                Text(entry.entryNote).font(.system(size: 15)).lineSpacing(5)
                if !entry.eyfsArea.isEmpty {
                    Label(entry.eyfsArea, systemImage: "graduationcap.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(AppPalette.indigo)
                }
                if !entry.moodRating.isEmpty {
                    HStack {
                        Text("Mood:").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppPalette.textSecondary)
                        Text(entry.moodRating.capitalized).font(.system(size: 12))
                    }
                }
                if !entry.keyworkerName.isEmpty {
                    HStack {
                        Text("Recorded by:").font(.system(size: 12, weight: .semibold)).foregroundStyle(AppPalette.textSecondary)
                        Text(entry.keyworkerName).font(.system(size: 12))
                    }
                }
                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .background(AppPalette.background)
    }
}

struct DiaryEntryRow: View {
    let entry: DiaryEntry
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.entryIcon)
                .font(.system(size: 14))
                .foregroundStyle(entry.entryColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(entry.childName).font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Text(entry.timestamp.timeString).font(.system(size: 10)).foregroundStyle(AppPalette.textSecondary)
                }
                Text(entry.entryNote).font(.system(size: 11)).foregroundStyle(AppPalette.textSecondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DiaryTimelineCard: View {
    let entry: DiaryEntry
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 4) {
                Circle()
                    .fill(entry.entryColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: entry.entryIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(entry.entryColor)
                    )
                Rectangle().fill(entry.entryColor.opacity(0.15)).frame(width: 2)
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.childName).font(.system(size: 14, weight: .bold))
                    StatusChip(label: entry.entryTypeDisplay, color: entry.entryColor)
                    Spacer()
                    Text(entry.timestamp.timeString).font(.system(size: 11)).foregroundStyle(AppPalette.textSecondary)
                }
                Text(entry.entryNote).font(.system(size: 13)).foregroundStyle(AppPalette.textPrimary).lineSpacing(2)
                if !entry.keyworkerName.isEmpty {
                    Text("By: \(entry.keyworkerName)").font(.system(size: 10)).foregroundStyle(AppPalette.textSecondary)
                }
            }
            .padding(.bottom, 12)
        }
    }
}

// MARK: - New Diary Entry Form

struct NewDiaryEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Child.fullName) private var allChildren: [Child]

    @State private var selectedChildId: UUID?
    @State private var entryType: String = "activity"
    @State private var entryNote: String = ""
    @State private var eyfsArea: String = "Communication & Language"
    @State private var moodRating: String = "happy"
    @State private var sleepStart = Date()
    @State private var sleepEnd = Date()
    @State private var sleepPosition = "Back"
    @State private var nappyType = "wet"
    @State private var creamApplied = false
    @State private var foodOffered = ""
    @State private var foodConsumed = ""

    private var myChildren: [Child] {
        allChildren.filter { $0.keyworkerName == appState.currentUserName }
    }

    let entryTypes = ["activity", "sleep", "nappy", "meal", "wellbeing", "milestone"]
    let moods = ["happy", "content", "tired", "upset", "unwell"]
    let sleepPositions = ["Back", "Side", "Front", "Sitting"]
    let nappyTypes = ["wet", "dirty", "both"]
    let eyfsOptions = [
        "Communication & Language", "Physical Development", "PSED",
        "Literacy", "Mathematics", "Understanding the World", "Expressive Arts"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Child") {
                    Picker("Select Child", selection: $selectedChildId) {
                        Text("Choose…").tag(nil as UUID?)
                        ForEach(myChildren) { Text($0.preferredName).tag($0.id as UUID?) }
                    }
                }
                Section("Entry Type") {
                    Picker("Type", selection: $entryType) {
                        ForEach(entryTypes, id: \.self) { Text(DiaryEntry.typeLabel($0)).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                Section("EYFS Area") {
                    Picker("EYFS", selection: $eyfsArea) {
                        ForEach(eyfsOptions, id: \.self) { Text($0).tag($0) }
                    }
                }
                if entryType == "sleep" {
                    Section("Sleep Details") {
                        DatePicker("Sleep Start", selection: $sleepStart, displayedComponents: .hourAndMinute)
                        DatePicker("Sleep End",   selection: $sleepEnd,   displayedComponents: .hourAndMinute)
                        Picker("Position", selection: $sleepPosition) {
                            ForEach(sleepPositions, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                if entryType == "nappy" {
                    Section("Nappy Details") {
                        Picker("Type", selection: $nappyType) {
                            ForEach(nappyTypes, id: \.self) { Text($0.capitalized).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        Toggle("Cream Applied", isOn: $creamApplied)
                    }
                }
                if entryType == "meal" {
                    Section("Meal Details") {
                        TextField("Food Offered", text: $foodOffered)
                        TextField("Food Consumed", text: $foodConsumed)
                    }
                }
                Section("Observation Notes") {
                    TextEditor(text: $entryNote).frame(minHeight: 120)
                }
                Section("Mood") {
                    Picker("Mood", selection: $moodRating) {
                        ForEach(moods, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("New Diary Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(); dismiss() }
                        .disabled(selectedChildId == nil || entryNote.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { selectedChildId = myChildren.first?.id }
        }
        .frame(minWidth: 500, minHeight: 550)
    }

    private func save() {
        guard let id = selectedChildId,
              let child = myChildren.first(where: { $0.id == id }) else { return }
        let entry = DiaryEntry(
            childId: id,
            childName: child.preferredName,
            entryType: entryType,
            description: entryNote,
            keyworkerName: appState.currentUserName
        )
        entry.eyfsArea = eyfsArea
        entry.moodRating = moodRating
        if entryType == "sleep" {
            entry.sleepStart = sleepStart; entry.sleepEnd = sleepEnd; entry.sleepPosition = sleepPosition
        }
        if entryType == "nappy" {
            entry.nappyType = nappyType; entry.creamApplied = creamApplied
        }
        if entryType == "meal" {
            entry.foodConsumed = foodConsumed
        }
        modelContext.insert(entry)
        try? modelContext.save()
    }
}

// Backwards-compat aliases so existing ContentView routing keeps working
struct DiaryTimelineView: View { var body: some View { DiaryView() } }
struct DiaryComposerView: View {
    let child: Child?
    var body: some View { NewDiaryEntryFormView() }
}
