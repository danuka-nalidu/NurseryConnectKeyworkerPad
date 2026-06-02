import SwiftUI

// MARK: - Keyworker Day-in-Hand palette (sage + coral, calm + warm)

enum AppPalette {
    static let primary   = Color(red: 0.247, green: 0.498, blue: 0.435)   // #3F7F6F sage
    static let secondary = Color(red: 0.290, green: 0.357, blue: 0.396)   // #4A5B65 slate
    static let accent    = Color(red: 0.949, green: 0.482, blue: 0.388)   // #F27B63 coral

    static let teal    = Color(red: 0.149, green: 0.624, blue: 0.580)     // #269F94
    static let purple  = Color(red: 0.541, green: 0.443, blue: 0.808)     // #8A71CE
    static let orange  = Color(red: 0.945, green: 0.624, blue: 0.357)     // #F19F5B
    static let pink    = Color(red: 0.918, green: 0.392, blue: 0.553)     // #EA648D
    static let red     = Color(red: 0.847, green: 0.286, blue: 0.286)     // #D84949
    static let indigo  = Color(red: 0.318, green: 0.380, blue: 0.561)     // #51618F
    static let green   = Color(red: 0.376, green: 0.682, blue: 0.471)     // #60AE78

    static let background    = Color(red: 0.965, green: 0.961, blue: 0.937) // #F6F5EF parchment
    static let tileBg        = Color.white
    static let navyBg        = Color(red: 0.137, green: 0.180, blue: 0.231) // #232E3B

    static let textPrimary   = Color(red: 0.118, green: 0.137, blue: 0.157)
    static let textSecondary = Color(red: 0.392, green: 0.420, blue: 0.439)

    static func gradient(_ color: Color) -> LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.72)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let brandGradient = LinearGradient(
        colors: [primary, teal],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - View modifiers

struct TileModifier: ViewModifier {
    var padding: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppPalette.tileBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

struct FilledButtonStyle: ButtonStyle {
    var color: Color = AppPalette.primary
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(configuration.isPressed ? 0.75 : 1.0))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    func tileStyle(padding: CGFloat = 18) -> some View {
        modifier(TileModifier(padding: padding))
    }

    func groupTitleStyle() -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppPalette.textSecondary)
            .textCase(.uppercase)
            .tracking(0.9)
    }
}

// MARK: - Date helpers

extension Date {
    var shortTimeString: String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: self)
    }
    var shortDateString: String {
        let f = DateFormatter(); f.dateStyle = .short
        return f.string(from: self)
    }
    var mediumDateString: String {
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: self)
    }
    var timeAgoString: String {
        let seconds = Int(Date().timeIntervalSince(self))
        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(seconds/60)m ago" }
        if seconds < 86400 { return "\(seconds/3600)h ago" }
        return mediumDateString
    }
    var isToday: Bool { Calendar.current.isDateInToday(self) }

    var dayMonthString: String {
        let f = DateFormatter(); f.dateFormat = "d MMMM yyyy"
        return f.string(from: self)
    }

    var timeString: String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        return f.string(from: self)
    }
}

// MARK: - Shared UI building blocks

struct StatusChip: View {
    let label: String
    let color: Color
    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color, in: Capsule())
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppPalette.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppPalette.textSecondary)
        }
        .tileStyle()
    }
}

struct HSplitContent<ListContent: View, DetailContent: View>: View {
    let list: () -> ListContent
    let detail: () -> DetailContent

    init(@ViewBuilder list: @escaping () -> ListContent,
         @ViewBuilder detail: @escaping () -> DetailContent) {
        self.list = list
        self.detail = detail
    }

    var body: some View {
        HStack(spacing: 0) {
            list()
                .frame(width: 320)
                .background(AppPalette.tileBg)
            Divider()
            detail()
                .frame(maxWidth: .infinity)
        }
    }
}
