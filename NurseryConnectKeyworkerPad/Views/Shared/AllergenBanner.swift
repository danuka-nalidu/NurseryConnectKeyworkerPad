import SwiftUI

struct AllergenBanner: View {
    let child: Child

    var body: some View {
        if child.hasAllergens {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 2) {
                    Text(child.allergens.joined(separator: " · ").uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                    Text(child.allergenSeverity.capitalized)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(severityColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var severityColor: Color {
        switch child.allergenSeverity {
        case "anaphylactic": return AppPalette.red
        case "allergy":      return AppPalette.orange
        case "intolerance":  return AppPalette.accent
        default:             return AppPalette.secondary
        }
    }
}
