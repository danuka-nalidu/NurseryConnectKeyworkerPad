import SwiftUI
import SwiftData

struct AttendanceView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.fullName) private var allChildren: [Child]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var records: [AttendanceRecord]

    @State private var searchText = ""

    private var myChildren: [Child] {
        allChildren.filter { $0.keyworkerName == appState.currentUserName }
    }

    private var filteredChildren: [Child] {
        if searchText.isEmpty { return myChildren }
        return myChildren.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }

    private var checkedInCount: Int { myChildren.filter { $0.isCheckedIn }.count }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    summaryCard("Present", value: "\(checkedInCount)", total: myChildren.count, color: .green)
                    summaryCard("Absent",  value: "\(myChildren.count - checkedInCount)", total: myChildren.count, color: .red)
                    summaryCard("Total",   value: "\(myChildren.count)", total: myChildren.count, color: AppPalette.primary)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today's Register")
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        TextField("Search…", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredChildren) { child in
                            AttendanceChildCard(child: child) { toggleAttendance(child: child) }
                        }
                    }
                }
                .tileStyle()
                .padding(.horizontal, 24)

                Spacer(minLength: 40)
            }
            .padding(.top, 16)
        }
        .background(AppPalette.background)
        .navigationTitle("Attendance — \(Date().dayMonthString)")
    }

    private func summaryCard(_ title: String, value: String, total: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(value).font(.system(size: 32, weight: .bold)).foregroundStyle(color)
            Text(title).font(.system(size: 12, weight: .medium)).foregroundStyle(AppPalette.textSecondary)
            ProgressView(value: Double(Int(value) ?? 0), total: Double(max(total, 1))).tint(color)
        }
        .frame(maxWidth: .infinity)
        .tileStyle()
    }

    private func toggleAttendance(child: Child) {
        let today = Calendar.current.startOfDay(for: Date())
        if child.isCheckedIn {
            child.isCheckedIn = false
            child.checkInTime = nil
            child.checkInBy = ""
            if let record = records.first(where: { $0.childId == child.id && Calendar.current.isDate($0.date, inSameDayAs: today) }) {
                record.checkOutTime = Date()
                record.collectedBy = "Parent"
            }
            let entry = DiaryEntry(childId: child.id, childName: child.preferredName, entryType: "checkout",
                                   description: "\(child.preferredName) checked out at \(Date().timeString)",
                                   keyworkerName: appState.currentUserName)
            modelContext.insert(entry)
        } else {
            child.isCheckedIn = true
            child.checkInTime = Date()
            child.checkInBy = appState.currentUserName
            let record = AttendanceRecord(childId: child.id, childName: child.fullName)
            record.checkInTime = Date()
            record.droppedOffBy = child.parentOneName
            modelContext.insert(record)
            let entry = DiaryEntry(childId: child.id, childName: child.preferredName, entryType: "checkin",
                                   description: "\(child.preferredName) checked in at \(Date().timeString)",
                                   keyworkerName: appState.currentUserName)
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

struct AttendanceChildCard: View {
    let child: Child
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(child.isCheckedIn ? AppPalette.teal : Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(child.initials)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(child.isCheckedIn ? .white : AppPalette.textSecondary)
                )
            VStack(alignment: .leading, spacing: 3) {
                Text(child.preferredName).font(.system(size: 14, weight: .semibold))
                HStack(spacing: 4) {
                    Text(child.displayAge).font(.system(size: 11)).foregroundStyle(AppPalette.textSecondary)
                    if child.hasAllergens {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(.orange)
                    }
                }
                if child.isCheckedIn, let time = child.checkInTime {
                    Text("In at \(time.timeString)")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
            }
            Spacer()
            Button {
                withAnimation(.spring(response: 0.3)) { onToggle() }
            } label: {
                Image(systemName: child.isCheckedIn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 28))
                    .foregroundStyle(child.isCheckedIn ? .green : Color.gray.opacity(0.4))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(child.isCheckedIn ? Color.green.opacity(0.05) : Color.gray.opacity(0.03))
                .stroke(child.isCheckedIn ? Color.green.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// Backwards-compat alias
struct AttendanceCheckInView: View { var body: some View { AttendanceView() } }
