import SwiftUI
import SwiftData
import Observation

// MARK: - Role Definition

enum UserRole: String, CaseIterable, Identifiable {
    case administrator   = "Administrator"
    case settingManager  = "Nursery Manager"
    case keyworker       = "Keyworker"
    case roomLeader      = "Room Leader"
    case driver          = "Driver"
    case parent          = "Parent / Guardian"
    case catering        = "Catering Staff"
    case marketing       = "Marketing Coordinator"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .administrator:  return "gearshape.2.fill"
        case .settingManager: return "building.2.fill"
        case .keyworker:      return "person.fill.checkmark"
        case .roomLeader:     return "person.badge.shield.checkmark.fill"
        case .driver:         return "bus.fill"
        case .parent:         return "house.fill"
        case .catering:       return "fork.knife"
        case .marketing:      return "megaphone.fill"
        }
    }

    var color: Color {
        switch self {
        case .administrator:  return Color.gray
        case .settingManager: return AppPalette.primary
        case .keyworker:      return AppPalette.teal
        case .roomLeader:     return AppPalette.purple
        case .driver:         return AppPalette.orange
        case .parent:         return AppPalette.pink
        case .catering:       return AppPalette.red
        case .marketing:      return AppPalette.indigo
        }
    }

    var description: String {
        switch self {
        case .administrator:  return "Platform setup System configuration & compliance governance"
        case .settingManager: return "Centre management Operational oversight & reporting oversight"
        case .keyworker:      return "Child observation Daily child monitoring & care daily logging"
        case .roomLeader:     return "Room coordination Room oversight & staff supervision supervision"
        case .driver:         return "Vehicle tracking Transport & school collections pick-ups"
        case .parent:         return "Child updates View child diary & notifications alerts"
        case .catering:       return "Kitchen planning Meal planning & allergen management dietary safety"
        case .marketing:      return "Content publishing Social media & GDPR-safe content compliance"
        }
    }
}

// MARK: - Data Entities

@Model
final class Child {
    var id: UUID = UUID()
    var fullName: String = ""
    var preferredName: String = ""
    var dateOfBirth: Date = Date()
    var keyworkerName: String = ""
    var secondaryKeyworker: String = ""
    var room: String = ""
    var sessionTimes: String = "08:00 - 17:00"
    // Family
    var parentOneName: String = ""
    var parentOnePhone: String = ""
    var parentOneEmail: String = ""
    var parentTwoName: String = ""
    var parentTwoPhone: String = ""
    var emergencyContactName: String = ""
    var emergencyContactPhone: String = ""
    var emergencyContactRelationship: String = ""
    // Health
    var nhsNumber: String = ""
    var address: String = ""
    var medicalConditions: String = ""
    var medications: String = ""
    var gpName: String = ""
    var gpPhone: String = ""
    // Diet & Allergies
    var dietaryRequirements: String = ""
    var allergenList: String = ""          // comma-separated allergens
    var allergenSeverity: String = "none"  // none, intolerance, allergy, anaphylactic
    var dietaryNotes: String = ""
    // Attendance
    var isCheckedIn: Bool = false
    var checkInTime: Date?
    var checkInBy: String = ""
    var isTransportChild: Bool = false
    var school: String = ""
    // Consent
    var photographyConsent: Bool = true
    var socialMediaConsent: Bool = false
    var dataProcessingConsent: Bool = true
    var gpsConsent: Bool = true
    var videoConsent: Bool = false
    var medicalTreatmentConsent: Bool = true
    // EYFS
    var eyfsNotes: String = ""
    var sendFlag: Bool = false
    var registrationDate: Date = Date()
    var notes: String = ""
    // Authorised collectors (comma-separated "Name (Relationship)")
    var authorisedCollectors: String = ""

    init(
        fullName: String,
        preferredName: String = "",
        dateOfBirth: Date,
        keyworkerName: String,
        room: String
    ) {
        self.id = UUID()
        self.fullName = fullName
        self.preferredName = preferredName.isEmpty
            ? (fullName.components(separatedBy: " ").first ?? fullName)
            : preferredName
        self.dateOfBirth = dateOfBirth
        self.keyworkerName = keyworkerName
        self.room = room
        self.registrationDate = Date()
    }

    var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    var ageMonths: Int {
        Calendar.current.dateComponents([.month], from: dateOfBirth, to: Date()).month ?? 0
    }

    var displayAge: String {
        let years = age
        let months = ageMonths % 12
        if years == 0 { return "\(months) months" }
        if months == 0 { return "\(years) yr" }
        return "\(years) yr \(months) mo"
    }

    var initials: String {
        let parts = fullName.components(separatedBy: " ")
        let i = parts.compactMap { $0.first }.prefix(2).map { String($0) }.joined()
        return i.uppercased()
    }

    var allergens: [String] {
        allergenList.isEmpty ? [] : allergenList.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var hasAllergens: Bool { !allergenList.isEmpty }
}

@Model
final class DiaryEntry {
    var id: UUID = UUID()
    var childId: UUID = UUID()
    var childName: String = ""
    var timestamp: Date = Date()
    var entryType: String = "activity"
    var entryNote: String = ""
    var duration: Int = 0
    var moodRating: String = ""
    var eyfsArea: String = ""
    var keyworkerName: String = ""
    var isReadByParent: Bool = false
    // Sleep
    var sleepStart: Date?
    var sleepEnd: Date?
    var sleepPosition: String = "back"
    // Nappy
    var nappyType: String = ""
    var creamApplied: Bool = false
    // Meal
    var mealType: String = ""
    var foodConsumed: String = ""
    var fluidType: String = ""
    var fluidAmount: Int = 0
    // Photo
    var photoCaption: String = ""

    init(childId: UUID, childName: String, entryType: String, description: String, keyworkerName: String) {
        self.id = UUID()
        self.childId = childId
        self.childName = childName
        self.timestamp = Date()
        self.entryType = entryType
        self.entryNote = description
        self.keyworkerName = keyworkerName
    }

    var entryTypeDisplay: String {
        switch entryType {
        case "activity":   return "Activity"
        case "sleep":      return "Sleep / Nap"
        case "nappy":      return "Nappy"
        case "meal":       return "Meal"
        case "wellbeing":  return "Wellbeing"
        case "milestone":  return "Milestone"
        case "photo":      return "Photo"
        case "checkin":    return "Check-In"
        case "checkout":   return "Check-Out"
        default:           return entryType.capitalized
        }
    }

    var entryIcon: String {
        switch entryType {
        case "activity":   return "figure.play"
        case "sleep":      return "moon.fill"
        case "nappy":      return "drop.fill"
        case "meal":       return "fork.knife"
        case "wellbeing":  return "heart.fill"
        case "milestone":  return "star.fill"
        case "photo":      return "camera.fill"
        case "checkin":    return "arrow.right.circle.fill"
        case "checkout":   return "arrow.left.circle.fill"
        default:           return "note.text"
        }
    }

    var entryColor: Color {
        switch entryType {
        case "activity":   return AppPalette.teal
        case "sleep":      return AppPalette.indigo
        case "nappy":      return AppPalette.orange
        case "meal":       return AppPalette.primary
        case "wellbeing":  return AppPalette.pink
        case "milestone":  return .yellow
        case "photo":      return AppPalette.purple
        case "checkin":    return .green
        case "checkout":   return .gray
        default:           return AppPalette.primary
        }
    }
}

@Model
final class IncidentReport {
    var id: UUID = UUID()
    var childId: UUID = UUID()
    var childName: String = ""
    var reportedBy: String = ""
    var incidentDate: Date = Date()
    var location: String = ""
    var category: String = "minor_accident"
    var categoryDisplay: String { IncidentReport.categoryLabel(category) }
    var incidentDescription: String = ""
    var immediateAction: String = ""
    var witnesses: String = ""
    var injuryBodyLocation: String = ""
    var status: String = "pending"
    var managerNotes: String = ""
    var managerName: String = ""
    var managerReviewDate: Date?
    var parentNotified: Bool = false
    var parentNotifiedTime: Date?
    var parentAcknowledged: Bool = false
    var parentAcknowledgeDate: Date?
    var isSerious: Bool = false
    var ofstedNotified: Bool = false
    var riddorRequired: Bool = false

    init(childId: UUID, childName: String, reportedBy: String, category: String, description: String) {
        self.id = UUID()
        self.childId = childId
        self.childName = childName
        self.reportedBy = reportedBy
        self.incidentDate = Date()
        self.category = category
        self.incidentDescription = description
        self.status = "pending"
    }

    static func categoryLabel(_ key: String) -> String {
        switch key {
        case "minor_accident":    return "Minor Accident"
        case "first_aid":         return "First Aid Required"
        case "safeguarding":      return "Safeguarding Concern"
        case "near_miss":         return "Near Miss"
        case "allergic_reaction": return "Allergic Reaction"
        case "medical":           return "Medical Incident"
        default:                  return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    var severityColor: Color {
        switch category {
        case "safeguarding", "allergic_reaction": return .red
        case "first_aid", "medical":              return .orange
        default:                                  return AppPalette.primary
        }
    }

    var statusColor: Color {
        switch status {
        case "pending":   return .orange
        case "reviewed":  return AppPalette.primary
        case "finalised": return .green
        default:          return .gray
        }
    }
}

@Model
final class AttendanceRecord {
    var id: UUID = UUID()
    var childId: UUID = UUID()
    var childName: String = ""
    var date: Date = Date()
    var checkInTime: Date?
    var checkOutTime: Date?
    var droppedOffBy: String = ""
    var collectedBy: String = ""
    var collectorRelationship: String = ""
    var isTransportPickup: Bool = false
    var transportPickupTime: Date?
    var notes: String = ""

    init(childId: UUID, childName: String) {
        self.id = UUID()
        self.childId = childId
        self.childName = childName
        self.date = Date()
    }
}

@Model
final class MealRecord {
    var id: UUID = UUID()
    var childId: UUID = UUID()
    var childName: String = ""
    var date: Date = Date()
    var mealType: String = "lunch"
    var foodOffered: String = ""
    var foodConsumed: String = "most"
    var fluidType: String = "water"
    var fluidAmount: Int = 150
    var notes: String = ""
    var keyworkerName: String = ""

    init(childId: UUID, childName: String, mealType: String) {
        self.id = UUID()
        self.childId = childId
        self.childName = childName
        self.date = Date()
        self.mealType = mealType
    }

    var consumptionColor: Color {
        switch foodConsumed {
        case "all", "most":           return .green
        case "half":                  return .orange
        case "little", "none", "refused": return .red
        default:                      return .gray
        }
    }
}

@Model
final class Message {
    var id: UUID = UUID()
    var senderName: String = ""
    var senderRole: String = ""
    var recipientName: String = ""
    var recipientRole: String = ""
    var content: String = ""
    var timestamp: Date = Date()
    var isRead: Bool = false
    var childName: String = ""
    var threadId: String = ""

    init(senderName: String, senderRole: String, recipientName: String, recipientRole: String, content: String, childName: String = "") {
        self.id = UUID()
        self.senderName = senderName
        self.senderRole = senderRole
        self.recipientName = recipientName
        self.recipientRole = recipientRole
        self.content = content
        self.timestamp = Date()
        self.childName = childName
        self.threadId = UUID().uuidString
    }
}

@Model
final class MealPlanItem {
    var id: UUID = UUID()
    var weekStartDate: Date = Date()
    var dayOfWeek: Int = 0   // 0=Mon ... 4=Fri
    var mealType: String = "lunch"
    var foodItem: String = ""
    var allergens: String = ""
    var isPublished: Bool = false
    var nutritionNotes: String = ""

    init(weekStartDate: Date, dayOfWeek: Int, mealType: String, foodItem: String, allergens: String = "") {
        self.id = UUID()
        self.weekStartDate = weekStartDate
        self.dayOfWeek = dayOfWeek
        self.mealType = mealType
        self.foodItem = foodItem
        self.allergens = allergens
        self.isPublished = true
    }
}

@Model
final class TransportRun {
    var id: UUID = UUID()
    var date: Date = Date()
    var driverName: String = ""
    var isActive: Bool = false
    var isComplete: Bool = false
    var startTime: Date?
    var endTime: Date?
    var manifestChildren: String = ""   // comma-separated child names
    var boardedChildren: String = ""    // comma-separated boarded names
    var currentLatitude: Double = 51.5074
    var currentLongitude: Double = -0.1278
    var estimatedArrival: String = "3:45 PM"
    var routeNotes: String = ""

    init(driverName: String, children: [String]) {
        self.id = UUID()
        self.date = Date()
        self.driverName = driverName
        self.manifestChildren = children.joined(separator: ",")
    }

    var manifestList: [String] {
        manifestChildren.isEmpty ? [] : manifestChildren.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var boardedList: [String] {
        boardedChildren.isEmpty ? [] : boardedChildren.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    func isBoarded(_ name: String) -> Bool { boardedList.contains(name) }

    func boardChild(_ name: String) {
        var list = boardedList
        if !list.contains(name) { list.append(name) }
        boardedChildren = list.joined(separator: ",")
    }
}

@Model
final class StockItem {
    var id: UUID = UUID()
    var name: String = ""
    var category: String = ""
    var currentLevel: Double = 0
    var minimumLevel: Double = 0
    var unit: String = "kg"
    var lastRestocked: Date = Date()
    var supplierName: String = ""
    var isLowStock: Bool { currentLevel <= minimumLevel }

    init(name: String, category: String, currentLevel: Double, minimumLevel: Double, unit: String) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.currentLevel = currentLevel
        self.minimumLevel = minimumLevel
        self.unit = unit
        self.lastRestocked = Date()
    }
}

@Model
final class MediaPhoto {
    var id: UUID = UUID()
    var captureDate: Date = Date()
    var activityTag: String = ""
    var isBlurred: Bool = true
    var isApprovedForSocial: Bool = false
    var approvedByManager: String = ""
    var approvalDate: Date?
    var caption: String = ""
    var postedToSocial: Bool = false
    var postDate: Date?
    var keyworkerName: String = ""

    init(activityTag: String, caption: String, keyworkerName: String) {
        self.id = UUID()
        self.captureDate = Date()
        self.activityTag = activityTag
        self.caption = caption
        self.keyworkerName = keyworkerName
        self.isBlurred = true
    }
}

// MARK: - Helper Extensions

extension DiaryEntry {
    static func typeLabel(_ type: String) -> String {
        switch type {
        case "activity":  return "Activity"
        case "sleep":     return "Sleep"
        case "nappy":     return "Nappy"
        case "meal":      return "Meal"
        case "wellbeing": return "Wellbeing"
        case "milestone": return "Milestone"
        case "photo":     return "Photo"
        case "checkin":   return "Check-In"
        case "checkout":  return "Check-Out"
        default:          return type.capitalized
        }
    }
}
