import SwiftUI
import SwiftData

struct AttendanceView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Child.fullName) private var allChildren: [Child]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var records: [AttendanceRecord]

    @State private var vm = AttendanceViewModel(keyworkerName: "")

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    summaryCard("Present", value: "\(vm.checkedInCount(from: allChildren))", total: vm.myChildren(from: allChildren).count, color: .green)
                    summaryCard("Absent",  value: "\(vm.myChildren(from: allChildren).count - vm.checkedInCount(from: allChildren))", total: vm.myChildren(from: allChildren).count, color: .red)
                    summaryCard("Total",   value: "\(vm.myChildren(from: allChildren).count)", total: vm.myChildren(from: allChildren).count, color: AppPalette.primary)
                }
                .padding(.horizontal, 24)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Today's Register")
                            .font(.system(size: 18, weight: .bold))
                        Spacer()
                        TextField("Search…", text: $vm.searchText)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(vm.filteredChildren(from: allChildren)) { child in
                            AttendanceChildCard(child: child) {
                                withAnimation(.spring(response: 0.3)) {
                                    vm.toggleAttendance(child: child, records: records, context: modelContext)
                                }
                            }
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
        .onAppear { vm.keyworkerName = appState.currentUserName }
        .onChange(of: appState.currentUserName) { _, new in vm.keyworkerName = new }
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
