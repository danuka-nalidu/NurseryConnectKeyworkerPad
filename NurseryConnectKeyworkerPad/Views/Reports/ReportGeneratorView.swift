import SwiftUI
import SwiftData
import PDFKit
import UIKit

struct ReportGeneratorView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Child.fullName) private var children: [Child]
    @Query(sort: \DiaryEntry.timestamp, order: .reverse) private var diaryEntries: [DiaryEntry]
    @Query(sort: \IncidentReport.incidentDate, order: .reverse) private var incidents: [IncidentReport]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var attendanceRecords: [AttendanceRecord]

    @State private var vm = ReportGeneratorViewModel()

    private var myChildren: [Child] {
        vm.myChildren(from: children, keyworkerName: appState.currentUserName)
    }

    var body: some View {
        HSplitContent {
            reportConfigPanel
        } detail: {
            pdfPreviewPanel
        }
        .navigationTitle("Reports")
    }

    private var reportConfigPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Report Type")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppPalette.textSecondary)
                    .textCase(.uppercase)

                ForEach(ReportGeneratorViewModel.ReportType.allCases) { type in
                    Button {
                        vm.selectedReportType = type
                        vm.generatedPDF = nil
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.system(size: 16))
                                .foregroundStyle(type.color)
                                .frame(width: 32)
                            Text(type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppPalette.textPrimary)
                            Spacer()
                            if vm.selectedReportType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppPalette.primary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            vm.selectedReportType == type ? type.color.opacity(0.1) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Filters")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppPalette.textSecondary)
                    .textCase(.uppercase)

                DatePicker("Date", selection: $vm.selectedDate, displayedComponents: .date)
                    .font(.system(size: 14))

                if vm.selectedReportType == .childProgress || vm.selectedReportType == .incidentReport {
                    Picker("Child", selection: $vm.selectedChildId) {
                        Text("All My Children").tag(nil as UUID?)
                        ForEach(myChildren) { child in
                            Text(child.fullName).tag(child.id as UUID?)
                        }
                    }
                    .font(.system(size: 14))
                }
            }
            .padding(16)

            Divider()

            VStack(spacing: 12) {
                Button {
                    vm.generateReport(
                        children: children,
                        diaryEntries: diaryEntries,
                        incidents: incidents,
                        attendanceRecords: attendanceRecords,
                        keyworkerName: appState.currentUserName,
                        assignedRoom: appState.assignedRoom,
                        nurseryName: appState.nurseryName
                    )
                } label: {
                    HStack(spacing: 8) {
                        if vm.isGenerating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "doc.badge.gearshape")
                        }
                        Text(vm.isGenerating ? "Generating..." : "Generate PDF")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppPalette.primary, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .disabled(vm.isGenerating)

                if let pdf = vm.generatedPDF, let data = pdf.dataRepresentation() {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("NurseryConnect_Report.pdf")
                    let _ = try? data.write(to: url)
                    ShareLink(item: url, preview: SharePreview("NurseryConnect Report", image: Image(systemName: "doc.fill"))) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share PDF")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppPalette.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(AppPalette.teal)
                    }
                }
            }
            .padding(16)

            Spacer()
        }
        .background(AppPalette.tileBg)
    }

    private var pdfPreviewPanel: some View {
        VStack {
            if let pdf = vm.generatedPDF {
                PDFKitView(document: pdf)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    .padding(20)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(AppPalette.textSecondary.opacity(0.5))
                    Text("Select a report type and tap Generate")
                        .font(.system(size: 15))
                        .foregroundStyle(AppPalette.textSecondary)
                    Text("PDF preview will appear here")
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppPalette.tileBg, in: RoundedRectangle(cornerRadius: 12))
                .padding(20)
            }
        }
        .background(AppPalette.background)
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.displayDirection = .vertical
        v.document = document
        v.backgroundColor = .systemGray6
        return v
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}
