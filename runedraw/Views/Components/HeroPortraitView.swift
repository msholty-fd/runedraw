import SwiftUI

struct HeroPortraitView: View {
    let heroClass: HeroClass
    var equipment: HeroEquipment? = nil
    var size: CGFloat = 200

    private var visuals: EquipmentVisuals {
        if let eq = equipment { return EquipmentVisuals(from: eq) }
        return EquipmentVisuals.classDefault(for: heroClass)
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: bgColors, startPoint: .top, endPoint: .bottom)

            TimelineView(.animation) { tl in
                Canvas { ctx, sz in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    HeroDrawing.draw(heroClass, equipment: visuals, ctx: ctx, size: sz, t: t)
                }
            }

            RadialGradient(
                colors: [.clear, .black.opacity(0.52)],
                center: .center,
                startRadius: size * 0.28,
                endRadius: size * 0.68
            )
            .allowsHitTesting(false)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.12)
                .stroke(borderGradient, lineWidth: 1.5)
        )
    }

    private var bgColors: [Color] {
        switch heroClass {
        case .barbarian:
            return [Color(red: 0.22, green: 0.07, blue: 0.04),
                    Color(red: 0.05, green: 0.02, blue: 0.01)]
        case .rogue:
            return [Color(red: 0.07, green: 0.05, blue: 0.16),
                    Color(red: 0.02, green: 0.01, blue: 0.05)]
        case .sorceress:
            return [Color(red: 0.05, green: 0.04, blue: 0.20),
                    Color(red: 0.01, green: 0.01, blue: 0.07)]
        }
    }

    private var borderGradient: LinearGradient {
        switch heroClass {
        case .barbarian:
            return LinearGradient(
                colors: [Color(red: 0.80, green: 0.44, blue: 0.10).opacity(0.70),
                         Color(red: 0.48, green: 0.24, blue: 0.05).opacity(0.35)],
                startPoint: .top, endPoint: .bottom)
        case .rogue:
            return LinearGradient(
                colors: [Color(red: 0.14, green: 0.86, blue: 0.64).opacity(0.60),
                         Color(red: 0.07, green: 0.44, blue: 0.34).opacity(0.30)],
                startPoint: .top, endPoint: .bottom)
        case .sorceress:
            return LinearGradient(
                colors: [Color(red: 0.64, green: 0.34, blue: 1.00).opacity(0.65),
                         Color(red: 0.34, green: 0.14, blue: 0.70).opacity(0.32)],
                startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Preview

#Preview("All Classes") {
    HStack(spacing: 16) {
        HeroPortraitView(heroClass: .barbarian, size: 180)
        HeroPortraitView(heroClass: .rogue, size: 180)
        HeroPortraitView(heroClass: .sorceress, size: 180)
    }
    .padding(24)
    .background(Color(red: 0.05, green: 0.04, blue: 0.08))
}
