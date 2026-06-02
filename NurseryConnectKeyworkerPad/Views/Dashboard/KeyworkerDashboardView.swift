import SwiftUI
import SwiftData
import Charts

struct KeyworkerDashboardView: View {
    @Environment(AppState.self) private var appState
    @Query private var allChildren: [Child]
    @Query(sort: \DiaryEntry.timestamp, order: .reverse) private var recentDiary: [DiaryEntry]
    @Query(sort: \IncidentReport.incidentDate, order: .reverse) private var recentIncidents: [IncidentReport]
    @Query(filter: #Predicate<Message> { !$0.isRead }) private var unreadMessages: [Message]
    @Query private var attendanceRecords: [AttendanceRecord]

    private var myChildren: [Child] {
        allChildren.filter { $0.keyworkerName == appState.currentUserName }
    }
    private var checkedInCount: Int { myChildren.filter { $0.isCheckedIn }.count }
    private var allergenChildren: Int { myChildren.filter { $0.hasAllergens }.count }

    private var todaysDiaryEntries: [DiaryEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return recentDiary.filter { entry in
            Calendar.current.isDate(entry.timestamp, inSameDayAs: today) &&
            myChildren.contains(where: { $0.id == entry.childId })
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                metricsGrid

                HStack(alignment: .top, spacing: 20) {
                    attendanceChartSection
                    todaysActivitySection
                }
                .padding(.horizontal, 24)

                HStack(alignment: .top, spacing: 20) {
                    myChildrenOverview
                    quickActionsSection
                }
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
        }
        .background(AppPalette.background)
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        appState.showNewDiaryEntry = true
                    } label: {
                        Label("New Diary Entry", systemImage: "square.and.pencil")
                    }
                    .keyboardShortcut("d", modifiers: [.command, .shift])

                    Button {
                        appState.showNewIncident = true
                    } label: {
                        Label("Report Incident", systemImage: "exclamationmark.triangle")
                    }
                    .keyboardShortcut("i", modifiers: [.command, .shift])
                }
            }
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good \(greetingTime), \(appState.currentUserName.components(separatedBy: " ").last ?? "")")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppPalette.textPrimary)
                Text("\(appState.assignedRoom) · \(appState.nurseryName) · \(Date().dayMonthString)")
                    .font(.system(size: 15))
                    .foregroundStyle(AppPalette.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var greetingTime: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Morning" }
        if hour < 17 { return "Afternoon" }
        return "Evening"
    }

    private var metricsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
            MetricCard(title: "My Children", value: "\(checkedInCount)/\(myChildren.count)", icon: "person.fill.checkmark", color: .green)
            MetricCard(title: "Diary Entries Today", value: "\(todaysDiaryEntries.count)", icon: "book.fill", color: AppPalette.purple)
            MetricCard(title: "Allergen Alerts", value: "\(allergenChildren)", icon: "exclamationmark.triangle.fill", color: allergenChildren > 0 ? .orange : .green)
            MetricCard(title: "Unread Messages", value: "\(unreadMessages.count)", icon: "message.fill", color: AppPalette.pink)
        }
        .padding(.horizontal, 24)
    }

    private var attendanceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Attendance — My Children")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppPalette.textPrimary)

            Chart {
                ForEach(weeklyAttendanceData, id: \.day) { item in
                    BarMark(x: .value("Day", item.day), y: .value("Present", item.present))
                        .foregroundStyle(AppPalette.teal.gradient)
                        .cornerRadius(4)
                    BarMark(x: .value("Day", item.day), y: .value("Absent", item.absent))
                        .foregroundStyle(AppPalette.red.opacity(0.6).gradient)
                        .cornerRadius(4)
                }
            }
            .chartLegend(position: .bottom)
            .frame(height: 200)
        }
        .tileStyle()
        .frame(maxWidth: .infinity)
    }

    private var weeklyAttendanceData: [(day: String, present: Int, absent: Int)] {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let total = myChildren.count
        let childIds = Set(myChildren.map { $0.id })
        return days.enumerated().map { index, day in
            let records = attendanceRecords.filter { record in
                let weekday = Calendar.current.component(.weekday, from: record.date)
                let adjustedDay = weekday == 1 ? 6 : weekday - 2
                return adjustedDay == index && record.checkInTime != nil && childIds.contains(record.childId)
            }
            let uniquePresent = Set(records.map { $0.childId }).count
            let present = min(uniquePresent, total)
            return (day: day, present: present, absent: max(0, total - present))
        }
    }

    private var todaysActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Diary")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppPalette.textPrimary)

            if todaysDiaryEntries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 28))
                        .foregroundStyle(AppPalette.textSecondary)
                    Text("No entries yet today")
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                VStack(spacing: 8) {
                    ForEach(todaysDiaryEntries.prefix(5)) { entry in
                        HStack(spacing: 10) {
                            Image(systemName: entry.entryIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(entry.entryColor)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.childName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(entry.entryNote)
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppPalette.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(entry.timestamp.timeString)
                                .font(.system(size: 10))
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                        .padding(.vertical, 4)
                        if entry.id != todaysDiaryEntries.prefix(5).last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .tileStyle()
        .frame(maxWidth: .infinity)
    }

    private var myChildrenOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Key Children")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppPalette.textPrimary)

            ForEach(myChildren.prefix(6)) { child in
                HStack(spacing: 10) {
                    Circle()
                        .fill(child.isCheckedIn ? AppPalette.teal : Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(child.initials)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(child.isCheckedIn ? .white : AppPalette.textSecondary)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(child.preferredName)
                            .font(.system(size: 13, weight: .semibold))
                        HStack(spacing: 6) {
                            Text(child.displayAge)
                                .font(.system(size: 10))
                                .foregroundStyle(AppPalette.textSecondary)
                            if child.hasAllergens {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    Spacer()
                    StatusChip(
                        label: child.isCheckedIn ? "Present" : "Absent",
                        color: child.isCheckedIn ? .green : .gray
                    )
                }
                .padding(.vertical, 3)
            }
        }
        .tileStyle()
        .frame(maxWidth: .infinity)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppPalette.textPrimary)

            VStack(spacing: 10) {
                quickActionButton("Record Activity", icon: "figure.play", color: AppPalette.teal) {
                    appState.showNewDiaryEntry = true
                }
                quickActionButton("Log Meal", icon: "fork.knife", color: AppPalette.orange) {
                    appState.selectedSection = .meal
                }
                quickActionButton("Check Attendance", icon: "checkmark.circle", color: AppPalette.green) {
                    appState.selectedSection = .attendance
                }
                quickActionButton("Report Incident", icon: "exclamationmark.triangle", color: AppPalette.red) {
                    appState.showNewIncident = true
                }
                quickActionButton("Generate Report", icon: "doc.richtext", color: AppPalette.indigo) {
                    appState.selectedSection = .reports
                }
            }
        }
        .tileStyle()
        .frame(maxWidth: .infinity)
    }

    private func quickActionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(AppPalette.textSecondary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
