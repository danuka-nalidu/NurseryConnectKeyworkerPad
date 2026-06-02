import SwiftUI
import SwiftData

struct ChildDetailView: View {
    let child: Child
    @Query private var diary: [DiaryEntry]
    @State private var showingDiary = false
    @State private var showingIncident = false

    init(child: Child) {
        self.child = child
        let id = child.id
        _diary = Query(filter: #Predicate<DiaryEntry> { $0.childId == id },
                       sort: \DiaryEntry.timestamp, order: .reverse)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                AllergenBanner(child: child)
                quickActions
                timeline
            }
            .padding(24)
        }
        .background(AppPalette.background)
        .navigationTitle(child.preferredName)
        .sheet(isPresented: $showingDiary) { DiaryComposerView(child: child) }
        .sheet(isPresented: $showingIncident) { IncidentDraftView(prefill: child) }
    }

    private var header: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle().fill(AppPalette.gradient(AppPalette.primary)).frame(width: 72, height: 72)
                Text(child.initials).font(.title2.bold()).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(child.fullName).font(.title2.bold())
                Text("\(child.displayAge) · \(child.room)").font(.subheadline).foregroundStyle(AppPalette.textSecondary)
                Text("Parent: \(child.parentOneName.isEmpty ? "—" : child.parentOneName)")
                    .font(.caption).foregroundStyle(AppPalette.textSecondary)
            }
            Spacer()
            VStack {
                Image(systemName: child.isCheckedIn ? "checkmark.seal.fill" : "moon.fill")
                    .font(.title2).foregroundStyle(child.isCheckedIn ? AppPalette.green : AppPalette.secondary)
                Text(child.isCheckedIn ? "Checked in" : "Not in")
                    .font(.caption).foregroundStyle(AppPalette.textSecondary)
            }
        }
        .tileStyle()
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button { showingDiary = true } label: {
                Label("Diary entry", systemImage: "plus.bubble.fill")
            }.buttonStyle(FilledButtonStyle(color: AppPalette.primary))
            Button { showingIncident = true } label: {
                Label("Log incident", systemImage: "exclamationmark.triangle.fill")
            }.buttonStyle(FilledButtonStyle(color: AppPalette.accent))
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TODAY'S TIMELINE").groupTitleStyle()
            if diary.isEmpty {
                Text("No entries yet today.")
                    .font(.subheadline)
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .tileStyle()
            } else {
                ForEach(diary.prefix(20)) { entry in
                    DiaryRow(entry: entry)
                }
            }
        }
    }
}

struct DiaryRow: View {
    let entry: DiaryEntry
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(entry.entryColor.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: entry.entryIcon).foregroundStyle(entry.entryColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.entryTypeDisplay).font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(entry.timestamp.shortTimeString).font(.caption).foregroundStyle(AppPalette.textSecondary)
                }
                Text(entry.entryNote).font(.body).foregroundStyle(AppPalette.textPrimary)
                if !entry.eyfsArea.isEmpty {
                    Text(entry.eyfsArea).font(.caption2).padding(.horizontal,8).padding(.vertical,3)
                        .background(AppPalette.teal.opacity(0.15)).foregroundStyle(AppPalette.teal)
                        .clipShape(Capsule())
                }
            }
        }
        .tileStyle(padding: 14)
    }
}
