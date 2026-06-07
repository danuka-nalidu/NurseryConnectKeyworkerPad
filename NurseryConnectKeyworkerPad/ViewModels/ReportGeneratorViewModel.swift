import SwiftUI
import SwiftData
import PDFKit
import UIKit
import Observation

@Observable
class ReportGeneratorViewModel {
    var selectedReportType: ReportType = .dailySummary
    var selectedChildId: UUID?
    var selectedDate: Date = Date()
    var generatedPDF: PDFDocument?
    var isGenerating: Bool = false

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

    func myChildren(from all: [Child], keyworkerName: String) -> [Child] {
        all.filter { $0.keyworkerName == keyworkerName }
    }

    func generateReport(
        children: [Child],
        diaryEntries: [DiaryEntry],
        incidents: [IncidentReport],
        attendanceRecords: [AttendanceRecord],
        keyworkerName: String,
        assignedRoom: String,
        nurseryName: String
    ) {
        isGenerating = true
        let mine = myChildren(from: children, keyworkerName: keyworkerName)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            switch self.selectedReportType {
            case .dailySummary:
                self.generatedPDF = self.generateDailySummaryPDF(mine, diaryEntries, keyworkerName: keyworkerName, assignedRoom: assignedRoom, nurseryName: nurseryName)
            case .incidentReport:
                self.generatedPDF = self.generateIncidentReportPDF(mine, incidents, keyworkerName: keyworkerName, nurseryName: nurseryName)
            case .attendanceLog:
                self.generatedPDF = self.generateAttendanceLogPDF(mine, attendanceRecords, keyworkerName: keyworkerName, assignedRoom: assignedRoom, nurseryName: nurseryName)
            case .childProgress:
                self.generatedPDF = self.generateChildProgressPDF(mine, diaryEntries, keyworkerName: keyworkerName, nurseryName: nurseryName)
            }
            self.isGenerating = false
        }
    }

    // MARK: - PDF Generators

    private func generateDailySummaryPDF(_ myChildren: [Child], _ diaryEntries: [DiaryEntry], keyworkerName: String, assignedRoom: String, nurseryName: String) -> PDFDocument? {
        let myEntries = diaryEntries.filter { entry in
            Calendar.current.isDate(entry.timestamp, inSameDayAs: selectedDate) &&
            myChildren.contains(where: { $0.id == entry.childId })
        }
        let data = generatePDFData(nurseryName: nurseryName) { context, pageRect in
            var y = self.drawHeader(in: context, pageRect: pageRect, title: "Daily Summary Report", subtitle: "Date: \(self.selectedDate.shortDateString)", nurseryName: nurseryName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Keyworker:", value: keyworkerName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Room:", value: assignedRoom)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Children in care:", value: "\(myChildren.count)")
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Diary entries today:", value: "\(myEntries.count)")
            y += 20
            y = self.drawSectionTitle(in: context, at: y, pageRect: pageRect, title: "Diary Entries")
            if myEntries.isEmpty {
                y = self.drawBodyText(in: context, at: y, pageRect: pageRect, text: "No diary entries recorded for this date.")
            } else {
                for entry in myEntries.prefix(15) {
                    if y > pageRect.height - 80 { break }
                    y = self.drawDiaryEntryRow(in: context, at: y, pageRect: pageRect, entry: entry)
                }
            }
            self.drawFooter(in: context, pageRect: pageRect, keyworkerName: keyworkerName)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generateIncidentReportPDF(_ myChildren: [Child], _ incidents: [IncidentReport], keyworkerName: String, nurseryName: String) -> PDFDocument? {
        var filtered = incidents.filter { inc in myChildren.contains(where: { $0.fullName == inc.childName }) }
        if let childId = selectedChildId, let child = myChildren.first(where: { $0.id == childId }) {
            filtered = filtered.filter { $0.childName == child.fullName }
        }
        let data = generatePDFData(nurseryName: nurseryName) { context, pageRect in
            var y = self.drawHeader(in: context, pageRect: pageRect, title: "Incident Report", subtitle: "Generated: \(Date().shortDateString)", nurseryName: nurseryName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Reported by:", value: keyworkerName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Total incidents:", value: "\(filtered.count)")
            y += 20
            y = self.drawSectionTitle(in: context, at: y, pageRect: pageRect, title: "Incident Details")
            for inc in filtered.prefix(10) {
                if y > pageRect.height - 120 { break }
                y = self.drawIncidentRow(in: context, at: y, pageRect: pageRect, incident: inc)
            }
            self.drawFooter(in: context, pageRect: pageRect, keyworkerName: keyworkerName)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generateAttendanceLogPDF(_ myChildren: [Child], _ attendanceRecords: [AttendanceRecord], keyworkerName: String, assignedRoom: String, nurseryName: String) -> PDFDocument? {
        let myRecords = attendanceRecords.filter { rec in
            Calendar.current.isDate(rec.date, inSameDayAs: selectedDate) &&
            myChildren.contains(where: { $0.id == rec.childId })
        }
        let data = generatePDFData(nurseryName: nurseryName) { context, pageRect in
            var y = self.drawHeader(in: context, pageRect: pageRect, title: "Attendance Log", subtitle: "Date: \(self.selectedDate.shortDateString)", nurseryName: nurseryName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Keyworker:", value: keyworkerName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Room:", value: assignedRoom)
            let presentCount = myRecords.filter { $0.checkInTime != nil }.count
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Present:", value: "\(presentCount) of \(myChildren.count)")
            y += 20
            y = self.drawSectionTitle(in: context, at: y, pageRect: pageRect, title: "Attendance Records")
            for child in myChildren {
                if y > pageRect.height - 80 { break }
                let rec = myRecords.first(where: { $0.childId == child.id })
                let status = rec?.checkInTime != nil ? "✓ Present" : "✗ Absent"
                let timeIn = rec?.checkInTime?.timeString ?? "—"
                y = self.drawAttendanceRow(in: context, at: y, pageRect: pageRect, name: child.fullName, status: status, time: timeIn)
            }
            self.drawFooter(in: context, pageRect: pageRect, keyworkerName: keyworkerName)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    private func generateChildProgressPDF(_ myChildren: [Child], _ diaryEntries: [DiaryEntry], keyworkerName: String, nurseryName: String) -> PDFDocument? {
        let targets: [Child] = selectedChildId.flatMap { id in myChildren.filter { $0.id == id } } ?? myChildren
        let data = generatePDFData(nurseryName: nurseryName) { context, pageRect in
            var y = self.drawHeader(in: context, pageRect: pageRect, title: "Child Progress Report", subtitle: "EYFS Development Summary", nurseryName: nurseryName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Keyworker:", value: keyworkerName)
            y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Date:", value: Date().shortDateString)
            y += 20
            for child in targets {
                if y > pageRect.height - 140 { break }
                y = self.drawSectionTitle(in: context, at: y, pageRect: pageRect, title: child.fullName)
                let childEntries = diaryEntries.filter { $0.childId == child.id }
                y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Age:", value: "\(child.ageMonths) months")
                y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Total observations:", value: "\(childEntries.count)")
                y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Room:", value: child.room)
                y = self.drawInfoRow(in: context, at: y, pageRect: pageRect, label: "Allergies:", value: child.allergens.isEmpty ? "None" : child.allergens.joined(separator: ", "))
                y += 16
            }
            self.drawFooter(in: context, pageRect: pageRect, keyworkerName: keyworkerName)
        }
        guard let data else { return nil }
        return PDFDocument(data: data)
    }

    // MARK: - PDF Drawing Helpers

    private func generatePDFData(nurseryName: String, drawing: (CGContext, CGRect) -> Void) -> Data? {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        return renderer.pdfData { pdfContext in
            pdfContext.beginPage()
            guard let cg = UIGraphicsGetCurrentContext() else { return }
            drawing(cg, pageRect)
        }
    }

    private func drawHeader(in context: CGContext, pageRect: CGRect, title: String, subtitle: String, nurseryName: String) -> CGFloat {
        context.setFillColor(CGColor(red: 0.247, green: 0.498, blue: 0.435, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: pageRect.width, height: 80))
        let titleAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 22), .foregroundColor: UIColor.white]
        NSAttributedString(string: title, attributes: titleAttrs).draw(at: CGPoint(x: 40, y: 20))
        let subAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.white.withAlphaComponent(0.85)]
        NSAttributedString(string: subtitle, attributes: subAttrs).draw(at: CGPoint(x: 40, y: 50))
        let rightAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.white.withAlphaComponent(0.75)]
        let rightString = NSAttributedString(string: nurseryName, attributes: rightAttrs)
        rightString.draw(at: CGPoint(x: pageRect.width - rightString.size().width - 40, y: 50))
        return 100
    }

    private func drawSectionTitle(in context: CGContext, at y: CGFloat, pageRect: CGRect, title: String) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: UIColor(red: 0.247, green: 0.498, blue: 0.435, alpha: 1)]
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

    private func drawFooter(in context: CGContext, pageRect: CGRect, keyworkerName: String) {
        let f: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 9), .foregroundColor: UIColor.gray]
        context.setStrokeColor(CGColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0))
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: 40, y: pageRect.height - 40))
        context.addLine(to: CGPoint(x: pageRect.width - 40, y: pageRect.height - 40))
        context.strokePath()
        let text = "NurseryConnect Keyworker Pad · Generated by \(keyworkerName) · \(Date().shortDateString) · Confidential"
        NSAttributedString(string: text, attributes: f).draw(at: CGPoint(x: 40, y: pageRect.height - 30))
    }
}
