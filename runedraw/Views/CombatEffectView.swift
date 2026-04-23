import SwiftUI

// MARK: - Data

struct CombatEffectData: Identifiable, Equatable {
    let id: UUID = UUID()
    let damageType: DamageType
    let targetIndex: Int         // which enemy was hit (for future multi-target support)
}

// MARK: - Effect colors and icons

extension DamageType {
    var effectColor: Color {
        switch self {
        case .physical: return Color(red: 1.00, green: 0.85, blue: 0.30)
        case .fire:     return Color(red: 1.00, green: 0.40, blue: 0.08)
        case .ice:      return Color(red: 0.45, green: 0.88, blue: 1.00)
        case .arcane:   return Color(red: 0.72, green: 0.40, blue: 1.00)
        case .poison:   return Color(red: 0.30, green: 0.92, blue: 0.35)
        }
    }

    var effectIcon: String {
        switch self {
        case .physical: return "⚔️"
        case .fire:     return "🔥"
        case .ice:      return "❄️"
        case .arcane:   return "⚡"
        case .poison:   return "☠️"
        }
    }
}

// MARK: - Main effect view

struct CombatEffectView: View {
    let data: CombatEffectData
    /// `animating` drives all sub-animations from false → true.
    @State private var animating = false
    /// Secondary pulse (fire, arcane) on a slight delay.
    @State private var animating2 = false

    var body: some View {
        ZStack {
            sharedImpactRing
            switch data.damageType {
            case .physical: physicalEffect
            case .fire:     fireEffect
            case .ice:      iceEffect
            case .arcane:   arcaneEffect
            case .poison:   poisonEffect
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            // Primary phase — snappy
            withAnimation(.easeOut(duration: 0.12)) { animating = true }
            // Secondary phase — expand and fade
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.easeOut(duration: 0.50)) { animating2 = true }
            }
        }
    }

    // MARK: Shared: expanding ring on every hit

    var sharedImpactRing: some View {
        Circle()
            .stroke(data.damageType.effectColor.opacity(animating2 ? 0 : 0.9),
                    lineWidth: animating2 ? 1 : 7)
            .frame(width: animating2 ? 160 : 14)
            .animation(.easeOut(duration: 0.50), value: animating2)
    }

    // MARK: Physical — three gold slash marks fan out

    var physicalEffect: some View {
        ZStack {
            // Central white flash
            Circle()
                .fill(Color.white.opacity(animating ? 0 : 0.95))
                .frame(width: animating2 ? 40 : 16)
                .animation(.easeOut(duration: 0.18), value: animating2)

            // Three staggered slashes
            ForEach(0..<3, id: \.self) { i in
                let rotation: Double = -50 + Double(i) * 20
                let yOff: CGFloat   = CGFloat(i - 1) * 14
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95),
                                     data.damageType.effectColor.opacity(0.8)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: animating2 ? 110 + CGFloat(i) * 18 : 6, height: 4)
                    .rotationEffect(.degrees(rotation))
                    .offset(x: animating2 ? CGFloat(i - 1) * 22 : 0, y: yOff)
                    .opacity(animating2 ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.32).delay(Double(i) * 0.06),
                        value: animating2
                    )
            }

            // Small spark particles at the impact point
            ForEach(0..<6, id: \.self) { i in
                let angle = Double(i) / 6.0 * .pi * 2
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: animating2 ? 4 : 8)
                    .offset(x: animating2 ? cos(angle) * 44 : 0,
                            y: animating2 ? sin(angle) * 44 : 0)
                    .opacity(animating2 ? 0 : 1)
                    .animation(
                        .easeOut(duration: 0.30).delay(Double(i) * 0.03),
                        value: animating2
                    )
            }
        }
    }

    // MARK: Fire — explosion burst + rising cinders

    var fireEffect: some View {
        ZStack {
            // Inner glow blob
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(animating ? 0 : 0.95),
                                 Color(red: 1.0, green: 0.55, blue: 0.0).opacity(animating2 ? 0 : 0.7)],
                        center: .center, startRadius: 0, endRadius: animating2 ? 55 : 8
                    )
                )
                .frame(width: animating2 ? 80 : 16)
                .animation(.easeOut(duration: 0.30), value: animating2)

            // 10 cinder particles — all scatter upward with varied arc
            ForEach(0..<10, id: \.self) { i in
                let frac  = Double(i) / 10.0
                let angle = -(.pi * 0.8) + frac * .pi * 1.6   // upward arc -144° to +144°
                let dist: CGFloat = 55 + CGFloat(i % 3) * 18
                Circle()
                    .fill(i.isMultiple(of: 2)
                          ? Color(red: 1.0, green: 0.50, blue: 0.08)
                          : Color(red: 1.0, green: 0.80, blue: 0.20))
                    .frame(width: animating2 ? 5 : 11)
                    .offset(x: animating2 ? cos(angle) * dist : 0,
                            y: animating2 ? sin(angle) * dist : 0)
                    .opacity(animating2 ? 0 : 0.95)
                    .animation(
                        .easeOut(duration: 0.48).delay(Double(i) * 0.028),
                        value: animating2
                    )
            }

            // "🔥" label that pulses and fades
            Text("🔥")
                .font(.system(size: 42))
                .scaleEffect(animating2 ? 1.9 : 0.7)
                .opacity(animating2 ? 0 : 0.95)
                .animation(.easeOut(duration: 0.40), value: animating2)
        }
    }

    // MARK: Ice — shatter burst + crystal shards

    var iceEffect: some View {
        ZStack {
            // Frost core flash
            Circle()
                .fill(Color.white.opacity(animating ? 0 : 0.9))
                .frame(width: animating2 ? 56 : 10)
                .animation(.easeOut(duration: 0.20), value: animating2)

            // 8 crystal shard capsules radiating out
            ForEach(0..<8, id: \.self) { i in
                let angle: Double = Double(i) / 8.0 * .pi * 2
                let dist: CGFloat = 48 + CGFloat(i % 2) * 16
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95),
                                     data.damageType.effectColor],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: animating2 ? 54 : 6, height: 3)
                    .offset(x: animating2 ? cos(angle) * dist : 0,
                            y: animating2 ? sin(angle) * dist : 0)
                    .rotationEffect(.degrees(angle * 180 / .pi))
                    .opacity(animating2 ? 0 : 0.95)
                    .animation(
                        .easeOut(duration: 0.40).delay(Double(i) * 0.03),
                        value: animating2
                    )
            }

            // Small ice chips — second ring, offset phase
            ForEach(0..<6, id: \.self) { i in
                let angle: Double = Double(i) / 6.0 * .pi * 2 + .pi / 6
                Circle()
                    .fill(data.damageType.effectColor.opacity(0.85))
                    .frame(width: animating2 ? 4 : 9)
                    .offset(x: animating2 ? cos(angle) * 70 : 0,
                            y: animating2 ? sin(angle) * 70 : 0)
                    .opacity(animating2 ? 0 : 0.9)
                    .animation(
                        .easeOut(duration: 0.42).delay(Double(i) * 0.04 + 0.06),
                        value: animating2
                    )
            }

            // Snowflake icon
            Text("❄️")
                .font(.system(size: 40))
                .scaleEffect(animating2 ? 2.0 : 0.6)
                .opacity(animating2 ? 0 : 0.95)
                .animation(.easeOut(duration: 0.42), value: animating2)
        }
    }

    // MARK: Arcane — concentric rings + lightning sparks

    var arcaneEffect: some View {
        ZStack {
            // Three expanding rings, staggered
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(data.damageType.effectColor.opacity(animating2 ? 0 : 0.85),
                            lineWidth: animating2 ? 1 : 4)
                    .frame(width: animating2 ? CGFloat(70 + i * 44) : 10)
                    .animation(
                        .easeOut(duration: 0.48).delay(Double(i) * 0.07),
                        value: animating2
                    )
            }

            // Six spark lines radiating from center
            ForEach(0..<6, id: \.self) { i in
                let angle: Double = Double(i) / 6.0 * .pi * 2
                Capsule()
                    .fill(Color(red: 0.88, green: 0.72, blue: 1.0).opacity(0.95))
                    .frame(width: animating2 ? 22 : 4, height: 2.5)
                    .offset(x: animating2 ? cos(angle) * 60 : 0,
                            y: animating2 ? sin(angle) * 60 : 0)
                    .rotationEffect(.degrees(angle * 180 / .pi))
                    .opacity(animating2 ? 0 : 0.95)
                    .animation(
                        .easeOut(duration: 0.38).delay(Double(i) * 0.04),
                        value: animating2
                    )
            }

            // Central arcane burst
            Circle()
                .fill(data.damageType.effectColor.opacity(animating ? 0 : 0.7))
                .frame(width: animating2 ? 48 : 10)
                .animation(.easeOut(duration: 0.22), value: animating2)

            Text("⚡")
                .font(.system(size: 38))
                .scaleEffect(animating2 ? 1.8 : 0.7)
                .opacity(animating2 ? 0 : 0.95)
                .animation(.easeOut(duration: 0.38), value: animating2)
        }
    }

    // MARK: Poison — green bubbles rising + skull

    var poisonEffect: some View {
        let xPositions: [CGFloat] = [-32, 12, -8, 28, -22, 5, 18, -15]
        let sizes:      [CGFloat] = [14, 10, 12,  8, 11, 9, 13, 7]

        return ZStack {
            // Toxic cloud core
            Circle()
                .fill(data.damageType.effectColor.opacity(animating2 ? 0 : 0.35))
                .frame(width: animating2 ? 70 : 14)
                .blur(radius: 8)
                .animation(.easeOut(duration: 0.45), value: animating2)

            // Bubbles float upward with stagger
            ForEach(0..<8, id: \.self) { i in
                Circle()
                    .strokeBorder(data.damageType.effectColor.opacity(0.8), lineWidth: 1.5)
                    .background(Circle().fill(data.damageType.effectColor.opacity(0.25)))
                    .frame(width: sizes[i], height: sizes[i])
                    .offset(x: animating2 ? xPositions[i] : 0,
                            y: animating2 ? -75 - CGFloat(i) * 9 : 0)
                    .opacity(animating2 ? 0 : 0.95)
                    .animation(
                        .easeOut(duration: 0.58).delay(Double(i) * 0.06),
                        value: animating2
                    )
            }

            // Skull flash
            Text("☠️")
                .font(.system(size: 40))
                .scaleEffect(animating2 ? 1.7 : 0.7)
                .opacity(animating2 ? 0 : 0.90)
                .animation(.easeOut(duration: 0.40), value: animating2)
        }
    }
}
