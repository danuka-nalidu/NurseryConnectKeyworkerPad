import SwiftUI
import SwiftData
import Charts

struct DevelopmentView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Child.fullName) private var allChildren: [Child]
    @Query(sort: \DiaryEntry.timestamp, order: .reverse) private var allEntries: [DiaryEntry]

    @State private var selectedChild: Child?
    @State private var vm = DevelopmentTrackerViewModel(keyworkerName: "")

    private let eyfsAreas = [
        "Communication & Language",
        "Physical Development",
        "Personal, Social & Emotional",
        "Literacy",
        "Mathematics",
        "Understanding the World",
        "Expressive Arts & Design"
    ]

    var body: some View {
        HSplitContent(
            list: {
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("EYFS Development")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppPalette.indigo)
                        Text("Track each child's progress")
                            .font(.system(size: 11))
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    Divider()

                    List(vm.myChildren(from: allChildren), selection: $selectedChild) { child in
                        DevelopmentChildRow(child: child, entryCount: vm.entriesForChild(child, from: allEntries).count)
                            .tag(child)
                    }
                    .listStyle(.plain)
                }
            },
            detail: {
                if let child = selectedChild {
                    ChildDevelopmentDetailView(child: child, entries: vm.entriesForChild(child, from: allEntries), eyfsAreas: eyfsAreas, vm: vm)
                } else {
                    ContentUnavailableView(
                        "Select a Child",
                        systemImage: "chart.line.uptrend.xyaxis",
                        description: Text("Choose a child to view EYFS progress")
                    )
                }
            }
        )
        .navigationTitle("Development Tracker")
        .onAppear { vm.keyworkerName = appState.currentUserName }
        .onChange(of: appState.currentUserName) { _, new in vm.keyworkerName = new }
    }
}

struct DevelopmentChildRow: View {
    let child: Child
    let entryCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(AppPalette.indigo.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(child.initials)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppPalette.indigo)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(child.preferredName)
                    .font(.system(size: 14, weight: .semibold))
                Text("\(child.displayAge) · \(entryCount) observations")
                    .font(.system(size: 11))
                    .foregroundStyle(AppPalette.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ChildDevelopmentDetailView: View {
    let child: Child
    let entries: [DiaryEntry]
    let eyfsAreas: [String]
    let vm: DevelopmentTrackerViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Circle()
                        .fill(AppPalette.indigo.gradient)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(child.initials)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        )
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.fullName)
                            .font(.system(size: 22, weight: .bold))
                        Text("\(child.displayAge) · \(child.room) · \(entries.count) total observations")
                            .font(.system(size: 13))
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 14) {
                    Text("EYFS Areas of Learning")
                        .font(.system(size: 16, weight: .bold))
                    ForEach(eyfsAreas, id: \.self) { area in
                        let progress = vm.progressForArea(area, entries: entries)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(area)
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(progressColor(progress))
                            }
                            ProgressView(value: progress)
                                .tint(progressColor(progress))
                        }
                        .padding(.vertical, 2)
                    }
                }
                .tileStyle()
                .padding(.horizontal, 24)

                HStack(alignment: .top, spacing: 20) {
                    activityTrendChart
                    activityBreakdownChart
                }
                .padding(.horizontal, 24)

                milestonesSection
                    .padding(.horizontal, 24)

                if !child.eyfsNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyworker Notes")
                            .font(.system(size: 14, weight: .bold))
                        Text(child.eyfsNotes)
                            .font(.system(size: 13))
                            .foregroundStyle(AppPalette.textSecondary)
                    }
                    .tileStyle()
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(AppPalette.background)
    }

    private var activityTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Observation Trend")
                .font(.system(size: 14, weight: .bold))
            Chart {
                ForEach(vm.weeklyActivityData(entries: entries), id: \.week) { item in
                    LineMark(x: .value("Week", item.week), y: .value("Count", item.count))
                        .foregroundStyle(AppPalette.indigo)
                        .interpolationMethod(.catmullRom)
                    AreaMark(x: .value("Week", item.week), y: .value("Count", item.count))
                        .foregroundStyle(AppPalette.indigo.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Week", item.week), y: .value("Count", item.count))
                        .foregroundStyle(AppPalette.indigo)
                }
            }
            .frame(height: 160)
        }
        .tileStyle()
        .frame(maxWidth: .infinity)
    }

    private var activityBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Types")
                .font(.system(size: 14, weight: .bold))
            if vm.activityBreakdown(entries: entries).isEmpty {
                Text("No data yet")
                    .font(.system(size: 12))
                    .foregroundStyle(AppPalette.textSecondary)
                    .frame(height: 160)
            } else {
                Chart {
                    ForEach(vm.activityBreakdown(entries: entries), id: \.type) { item in
                        SectorMark(
                            angle: .value("Count", item.count),
                            innerRadius: .ratio(0.5)
                        )
                        .foregroundStyle(by: .value("Type", DiaryEntry.typeLabel(item.type)))
                    }
                }
                .frame(height: 160)
            }
        }
        .tileStyle()
        .frame(maxWidth: .infinity)
    }

    private var milestonesSection: some View {
        let milestones = entries.filter { $0.entryType == "milestone" }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Milestones Achieved")
                .font(.system(size: 14, weight: .bold))
            if milestones.isEmpty {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow.opacity(0.5))
                    Text("No milestones recorded yet")
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary)
                }
            } else {
                ForEach(milestones.prefix(5)) { milestone in
                    HStack(spacing: 10) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.entryNote)
                                .font(.system(size: 13, weight: .semibold))
                            Text(milestone.timestamp.shortDateString)
                                .font(.system(size: 10))
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .tileStyle()
    }

    private func progressColor(_ value: Double) -> Color {
        if value >= 0.7 { return .green }
        if value >= 0.4 { return .orange }
        return .red
    }
}
