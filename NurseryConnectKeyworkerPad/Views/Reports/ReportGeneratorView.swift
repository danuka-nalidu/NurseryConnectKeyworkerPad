import SwiftUI
import SwiftData
import PDFKit
import UIKit

struct ReportGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query(sort: \Child.fullName) private var children: [Child]
    @Query(sort: \DiaryEntry.timestamp, order: .reverse) private var diaryEntries: [DiaryEntry]
    @Query(sort: \IncidentReport.incidentDate, order: .reverse) private var incidents: [IncidentReport]
    @Query(sort: \AttendanceRecord.date, order: .reverse) private var attendanceRecords: [AttendanceRecord]

    @State private var selectedReportType: ReportType = .dailySummary
    @State private var selectedChildId: UUID?
    @State private var selectedDate: Date = Date()
    @State private var generatedPDF: PDFDocument?
    @State private var isGenerating = false

    private var myChildren: [Child] {
        children.filter { $0.keyworkerName == appState.currentUserName }
    }

    enum ReportType: String, CaseIterable, Identifiable {
        case dailySummary   = "Daily Summary"
        case incidentReport = "Incident Report"
        case attendanceLog  = "Attendance Log"
        case childProgress  = "Child Progress"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dailySummary:   return "doc.text.fill"
            case .incidentReport: return "exclamationmark.triangle.fill"
            case .attendanceLog:  return "checkmark.circle.fill"
            case .childProgress:  return "chart.line.uptrend.xyaxis"
            }
        }

        var color: Color {
            switch self {
            case .dailySummary:   return AppPalette.purple
            case .incidentReport: return AppPalette.red
            case .attendanceLog:  return AppPalette.green
            case .childProgress:  return AppPalette.indigo
            }
        }
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

                ForEach(ReportType.allCases) { type in
                    Button {
                        selectedReportType = type
                        generatedPDF = nil
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
                            if selectedReportType == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppPalette.primary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            selectedReportType == type ? type.color.opacity(0.1) : Color.clear,
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

                DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    .font(.system(size: 14))

                if selectedReportType == .childProgress || selectedReportType == .incidentReport {
                    Picker("Child", selection: $selectedChildId) {
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
                    generateReport()
                } label: {
                    HStack(spacing: 8) {
                        if isGenerating {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "doc.badge.gearshape")
                        }
                        Text(isGenerating ? "Generating..." : "Generate PDF")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppPalette.primary, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .disabled(isGenerating)

                if let pdf = generatedPDF, let data = pdf.dataRepresentation() {
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
            if let pdf = generatedPDF {
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

    private func generateReport() {
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch selectedReportType {
            case .dailySummary:   generatedPDF = generateDailySummaryPDF()
            case .incidentReport: generatedPDF = generateIncidentReportPDF()
            case .attendanceLog:  generatedPDF = generateAttendanceLogPDF()
            case .childProgress:  generatedPDF = generateChildProgressPDF()
            }
            isGenerating = false
        }
    }

    private func generateDailySummaryPDF() -> PDFDocument? {
        let todayEntries = diaryEntries.filter { Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate) }
        let myEntries = todayEntries.filter { entry in
            myChildren.contains(where: { $0.id == entry.childId })
        }

        let data = generatePDFData { context, pageRect in
            var y = drawHeader(in: context, pageRect: pageRect, title: "Daily Summary Report", subtitle: "Date: \(selectedDate.shortDateString)")
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Keyworker:", value: appState.currentUserName)
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Room:", value: appState.assignedRoom)
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Children in care:", value: "\(myChildren.count)")
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Diary entries today:", value: "\(myEntries.count)")
            y += 20
            y = drawSectionTitle(in: context, at: y, pageRect: pageRect, title: "Diary Entries")
            if myEntries.isEmpty {
                y = drawBodyText(in: context, at: y, pageRect: pageRect, text: "No diary entries recorded for this date.")
            } else {
                for entry in myEntries.prefix(15) {
                    if y > pageRect.height - 80 { break }
                    y = drawDiaryEntryRow(in: context, at: y, pageRect: pageRect, entry: entry)
                }
            }
            drawFooter(in: context, pageRect: pageRect)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generateIncidentReportPDF() -> PDFDocument? {
        var filtered = incidents.filter { incident in
            myChildren.contains(where: { $0.fullName == incident.childName })
        }
        if let childId = selectedChildId, let child = myChildren.first(where: { $0.id == childId }) {
            filtered = filtered.filter { $0.childName == child.fullName }
        }
        let data = generatePDFData { context, pageRect in
            var y = drawHeader(in: context, pageRect: pageRect, title: "Incident Report", subtitle: "Generated: \(Date().shortDateString)")
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Reported by:", value: appState.currentUserName)
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Total incidents:", value: "\(filtered.count)")
            y += 20
            y = drawSectionTitle(in: context, at: y, pageRect: pageRect, title: "Incident Details")
            for inc in filtered.prefix(10) {
                if y > pageRect.height - 120 { break }
                y = drawIncidentRow(in: context, at: y, pageRect: pageRect, incident: inc)
            }
            drawFooter(in: context, pageRect: pageRect)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generateAttendanceLogPDF() -> PDFDocument? {
        let todayRecords = attendanceRecords.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
        let myRecords = todayRecords.filter { rec in
            myChildren.contains(where: { $0.id == rec.childId })
        }
        let data = generatePDFData { context, pageRect in
            var y = drawHeader(in: context, pageRect: pageRect, title: "Attendance Log", subtitle: "Date: \(selectedDate.shortDateString)")
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Keyworker:", value: appState.currentUserName)
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Room:", value: appState.assignedRoom)
            let presentCount = myRecords.filter { $0.checkInTime != nil }.count
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Present:", value: "\(presentCount) of \(myChildren.count)")
            y += 20
            y = drawSectionTitle(in: context, at: y, pageRect: pageRect, title: "Attendance Records")
            for child in myChildren {
                if y > pageRect.height - 80 { break }
                let rec = myRecords.first(where: { $0.childId == child.id })
                let status = rec?.checkInTime != nil ? "✓ Present" : "✗ Absent"
                let timeIn = rec?.checkInTime?.timeString ?? "—"
                y = drawAttendanceRow(in: context, at: y, pageRect: pageRect, name: child.fullName, status: status, time: timeIn)
            }
            drawFooter(in: context, pageRect: pageRect)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generateChildProgressPDF() -> PDFDocument? {
        let targets: [Child]
        if let childId = selectedChildId {
            targets = myChildren.filter { $0.id == childId }
        } else {
            targets = myChildren
        }
        let data = generatePDFData { context, pageRect in
            var y = drawHeader(in: context, pageRect: pageRect, title: "Child Progress Report", subtitle: "EYFS Development Summary")
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Keyworker:", value: appState.currentUserName)
            y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Date:", value: Date().shortDateString)
            y += 20
            for child in targets {
                if y > pageRect.height - 140 { break }
                y = drawSectionTitle(in: context, at: y, pageRect: pageRect, title: child.fullName)
                let childEntries = diaryEntries.filter { $0.childId == child.id }
                y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Age:", value: "\(child.ageMonths) months")
                y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Total observations:", value: "\(childEntries.count)")
                y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Room:", value: child.room)
                y = drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Allergies:", value: child.allergens.isEmpty ? "None" : child.allergens.joined(separator: ", "))
                y += 16
            }
            drawFooter(in: context, pageRect: pageRect)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generatePDFData(drawing: (CGContext, CGRect) -> Void) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { pdfContext in
            pdfContext.beginPage()
            guard let cg = UIGraphicsGetCurrentContext() else { return }
            drawing(cg, pageRect)
        }
    }

    private func drawHeader(in context: CGContext, pageRect: CGRect, title: String, subtitle: String) -> CGFloat {
        context.setFillColor(CGColor(red: 0.247, green: 0.498, blue: 0.435, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: 80))
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 22),
            .foregroundColor: UIColor.white
        ]
        NSAttributedString(string: title, attributes: titleAttrs).draw(at: CGPoint(x: 40, y: 20))
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.white.withAlphaComponent(0.85)
        ]
        NSAttributedString(string: subtitle, attributes: subAttrs).draw(at: CGPoint(x: 40, y: 50))
        let rightAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.white.withAlphaComponent(0.75)
        ]
        let rightString = NSAttributedString(string: appState.nurseryName, attributes: rightAttrs)
        let size = rightString.size()
        rightString.draw(at: CGPoint(x: pageRect.width - size.width - 40, y: 50))
        return 100
    }

    private func drawSectionTitle(in context: CGContext, at y: CGFloat, pageRect: CGRect, title: String) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 14),
            .foregroundColor: UIColor(red: 0.247, green: 0.498, blue: 0.435, alpha: 1)
        ]
        NSAttributedString(string: title, attributes: attrs).draw(at: CGPoint(x: 40, y: y))
        context.setStrokeColor(CGColor(red: 0.247, green: 0.498, blue: 0.435, alpha: 0.3))
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 40, y: y + 20))
        context.addLine(to: CGPoint(x: pageRect.width - 40, y: y + 20))
        context.strokePath()
        return y + 28
    }

    private func drawInfoRow(in context: CGContext, at y: CGFloat, pageRect: CGRect, label: String, value: String) -> CGFloat {
        let l: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: UIColor.darkGray]
        let v: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
        NSAttributedString(string: label, attributes: l).draw(at: CGPoint(x: 40, y: y))
        NSAttributedString(string: value, attributes: v).draw(at: CGPoint(x: 160, y: y))
        return y + 18
    }

    private func drawBodyText(in context: CGContext, at y: CGFloat, pageRect: CGRect, text: String) -> CGFloat {
        let a: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.gray]
        NSAttributedString(string: text, attributes: a).draw(at: CGPoint(x: 40, y: y))
        return y + 18
    }

    private func drawDiaryEntryRow(in context: CGContext, at y: CGFloat, pageRect: CGRect, entry: DiaryEntry) -> CGFloat {
        context.setFillColor(CGColor(red: 0.54, green: 0.44, blue: 0.80, alpha: 1.0))
        context.fillEllipse(in: CGRect(x: 44, y: y + 4, width: 6, height: 6))
        let timeA: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium), .foregroundColor: UIColor.gray]
        let titleA: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
        let subA: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
        NSAttributedString(string: entry.timestamp.timeString, attributes: timeA).draw(at: CGPoint(x: 58, y: y))
        let title = String(entry.entryNote.prefix(60)) + (entry.entryNote.count > 60 ? "…" : "")
        NSAttributedString(string: title, attributes: titleA).draw(at: CGPoint(x: 120, y: y))
        NSAttributedString(string: entry.childName, attributes: subA).draw(at: CGPoint(x: 120, y: y + 14))
        return y + 32
    }

    private func drawIncidentRow(in context: CGContext, at y: CGFloat, pageRect: CGRect, incident: IncidentReport) -> CGFloat {
        context.setFillColor(CGColor(red: 0.85, green: 0.29, blue: 0.29, alpha: 1.0))
        context.fillEllipse(in: CGRect(x: 44, y: y + 4, width: 6, height: 6))
        let a: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
        let d: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.darkGray]
        NSAttributedString(string: "\(incident.childName) — \(IncidentReport.categoryLabel(incident.category))", attributes: a).draw(at: CGPoint(x: 58, y: y))
        NSAttributedString(string: "\(incident.incidentDate.shortDateString) · \(incident.status.capitalized)", attributes: d).draw(at: CGPoint(x: 58, y: y + 14))
        let desc = String(incident.incidentDescription.prefix(80)) + (incident.incidentDescription.count > 80 ? "…" : "")
        NSAttributedString(string: desc, attributes: d).draw(at: CGPoint(x: 58, y: y + 28))
        return y + 48
    }

    private func drawAttendanceRow(in context: CGContext, at y: CGFloat, pageRect: CGRect, name: String, status: String, time: String) -> CGFloat {
        let n: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.black]
        let s: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 11), .foregroundColor: status.contains("✓") ? UIColor.systemGreen : UIColor.systemRed]
        let t: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular), .foregroundColor: UIColor.gray]
        NSAttributedString(string: name, attributes: n).draw(at: CGPoint(x: 40, y: y))
        NSAttributedString(string: status, attributes: s).draw(at: CGPoint(x: 250, y: y))
        NSAttributedString(string: time, attributes: t).draw(at: CGPoint(x: 380, y: y))
        return y + 20
    }

    private func drawFooter(in context: CGContext, pageRect: CGRect) {
        let f: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray]
        context.setStrokeColor(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0))
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 40, y: pageRect.height - 40))
        context.addLine(to: CGPoint(x: pageRect.width - 40, y: pageRect.height - 40))
        context.strokePath()
        let text = "NurseryConnect Keyworker Pad · Generated by \(appState.currentUserName) · \(Date().shortDateString) · Confidential"
        NSAttributedString(string: text, attributes: f).draw(at: CGPoint(x: 40, y: pageRect.height - 30))
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
