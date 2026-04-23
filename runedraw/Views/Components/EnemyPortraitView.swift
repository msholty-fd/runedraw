import SwiftUI

// MARK: - Archetype

enum EnemyArchetype {
    case skeleton, zombie, knight, mage, ghoul, golem, wraith

    static func detect(name: String) -> EnemyArchetype {
        let n = name.lowercased()
        if n.contains("skeleton") || n.contains("skeletal") { return .skeleton }
        if n.contains("bone wraith") || n.contains("abyssal wraith") { return .wraith }
        if n.contains("rot") || n.contains("zombie") || n.contains("shambler") ||
            n.contains("thrall") || n.contains("plague") || n.contains("brute") { return .zombie }
        if n.contains("knight") || n.contains("herald") || n.contains("warden") ||
            n.contains("champion") { return .knight }
        if n.contains("mage") || n.contains("cultist") || n.contains("witch") ||
            n.contains("lich") || n.contains("apostle") || n.contains("bloodlord") { return .mage }
        if n.contains("ghoul") { return .ghoul }
        if n.contains("golem") || n.contains("iron") || n.contains("stone") ||
            n.contains("sentinel") { return .golem }
        if n.contains("stalker") || n.contains("wraith") || n.contains("shadow") ||
            n.contains("void") || n.contains("abyssal") || n.contains("tyrant") ||
            n.contains("obsidian") || n.contains("shadowlord") { return .wraith }
        return .skeleton
    }

    var bgColors: (Color, Color) {
        switch self {
        case .skeleton: return (Color(red: 0.05, green: 0.04, blue: 0.16), Color(red: 0.12, green: 0.10, blue: 0.26))
        case .zombie:   return (Color(red: 0.03, green: 0.10, blue: 0.03), Color(red: 0.07, green: 0.18, blue: 0.06))
        case .knight:   return (Color(red: 0.04, green: 0.05, blue: 0.14), Color(red: 0.10, green: 0.12, blue: 0.26))
        case .mage:     return (Color(red: 0.12, green: 0.03, blue: 0.20), Color(red: 0.20, green: 0.06, blue: 0.32))
        case .ghoul:    return (Color(red: 0.11, green: 0.09, blue: 0.03), Color(red: 0.20, green: 0.16, blue: 0.05))
        case .golem:    return (Color(red: 0.10, green: 0.08, blue: 0.05), Color(red: 0.18, green: 0.14, blue: 0.09))
        case .wraith:   return (Color(red: 0.02, green: 0.01, blue: 0.08), Color(red: 0.06, green: 0.04, blue: 0.18))
        }
    }

    var glowColor: Color {
        switch self {
        case .skeleton: return Color(red: 0.55, green: 0.65, blue: 1.00)
        case .zombie:   return Color(red: 0.25, green: 0.90, blue: 0.25)
        case .knight:   return Color(red: 1.00, green: 0.45, blue: 0.10)
        case .mage:     return Color(red: 0.80, green: 0.30, blue: 1.00)
        case .ghoul:    return Color(red: 0.90, green: 0.82, blue: 0.20)
        case .golem:    return Color(red: 1.00, green: 0.45, blue: 0.10)
        case .wraith:   return Color(red: 0.40, green: 0.85, blue: 1.00)
        }
    }

    // Approximate normalized center of eyes for animated glow
    var eyeCenter: UnitPoint {
        switch self {
        case .skeleton: return .init(x: 0.5, y: 0.26)
        case .zombie:   return .init(x: 0.5, y: 0.27)
        case .knight:   return .init(x: 0.5, y: 0.36)
        case .mage:     return .init(x: 0.5, y: 0.30)
        case .ghoul:    return .init(x: 0.5, y: 0.32)
        case .golem:    return .init(x: 0.5, y: 0.28)
        case .wraith:   return .init(x: 0.5, y: 0.31)
        }
    }
}

// MARK: - Portrait View

struct EnemyPortraitView: View {
    let enemy: Enemy
    var size: CGFloat = 68
    var isBoss: Bool = false
    var isElite: Bool = false

    @State private var glowPulse = false

    private var archetype: EnemyArchetype { EnemyArchetype.detect(name: enemy.name) }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [archetype.bgColors.0, archetype.bgColors.1],
                startPoint: .top, endPoint: .bottom
            )

            // Drawn figure
            Canvas { ctx, sz in
                EnemyDrawing.draw(archetype: archetype, ctx: ctx, size: sz, isBoss: isBoss)
            }

            // Animated glow (eye region)
            RadialGradient(
                colors: [archetype.glowColor.opacity(glowPulse ? 0.28 : 0.10), .clear],
                center: archetype.eyeCenter,
                startRadius: 0,
                endRadius: size * 0.38
            )
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: glowPulse)

            // Vignette — dark edges for painted feel
            RadialGradient(
                colors: [.clear, Color.black.opacity(0.55)],
                center: .center,
                startRadius: size * 0.22,
                endRadius: size * 0.72
            )
            .allowsHitTesting(false)

            // Boss crown
            if isBoss {
                VStack {
                    HStack(spacing: size * 0.05) {
                        ForEach([0, 1, 2], id: \.self) { i in
                            EnemyCrownSpike(
                                width: size * 0.08,
                                height: i == 1 ? size * 0.16 : size * 0.11,
                                color: Color(red: 1.0, green: 0.78, blue: 0.18)
                            )
                        }
                    }
                    .padding(.top, 2)
                    Spacer()
                }
            }

            // Elite star
            if isElite && !isBoss {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "star.fill")
                            .font(.system(size: size * 0.16))
                            .foregroundStyle(Color(red: 0.85, green: 0.35, blue: 0.9))
                            .shadow(color: Color(red: 0.85, green: 0.35, blue: 0.9), radius: 4)
                            .padding(3)
                    }
                    Spacer()
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.18))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.18)
                .stroke(borderColor, lineWidth: borderWidth)
        )
        .shadow(color: archetype.glowColor.opacity(isBoss ? 0.5 : 0.28), radius: isBoss ? 14 : 8)
        .onAppear { glowPulse = true }
    }

    private var borderColor: Color {
        if isBoss  { return Color(red: 1.0, green: 0.78, blue: 0.18).opacity(0.75) }
        if isElite { return Color(red: 0.85, green: 0.35, blue: 0.9).opacity(0.55) }
        return archetype.glowColor.opacity(0.32)
    }

    private var borderWidth: CGFloat { isBoss ? 2.0 : 1.5 }
}

// MARK: - Crown Spike

private struct EnemyCrownSpike: View {
    let width: CGFloat
    let height: CGFloat
    let color: Color

    var body: some View {
        CrownTriangle()
            .fill(color)
            .frame(width: width, height: height)
            .shadow(color: color.opacity(0.8), radius: 3)
    }
}

private struct CrownTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Drawing Engine

struct EnemyDrawing {
    static func draw(archetype: EnemyArchetype, ctx: GraphicsContext,
                     size: CGSize, isBoss: Bool) {
        switch archetype {
        case .skeleton: skeleton(ctx, size, isBoss)
        case .zombie:   zombie(ctx, size, isBoss)
        case .knight:   knight(ctx, size, isBoss)
        case .mage:     mage(ctx, size, isBoss)
        case .ghoul:    ghoul(ctx, size, isBoss)
        case .golem:    golem(ctx, size, isBoss)
        case .wraith:   wraith(ctx, size, isBoss)
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static func ellipse(_ ctx: GraphicsContext, _ size: CGSize,
                                 x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                                 color: Color) {
        ctx.fill(Path(ellipseIn: CGRect(
            x: x * size.width, y: y * size.height,
            width: w * size.width, height: h * size.height
        )), with: .color(color))
    }

    private static func rect(_ ctx: GraphicsContext, _ size: CGSize,
                              x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                              color: Color, radius: CGFloat = 3) {
        ctx.fill(Path(roundedRect: CGRect(
            x: x * size.width, y: y * size.height,
            width: w * size.width, height: h * size.height
        ), cornerRadius: radius), with: .color(color))
    }

    private static func glow(_ ctx: GraphicsContext, _ size: CGSize,
                              x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat,
                              color: Color, radius: CGFloat = 4) {
        let eRect = CGRect(
            x: x * size.width, y: y * size.height,
            width: w * size.width, height: h * size.height
        )
        // Outer halo
        for i in 0..<3 {
            let inset = CGFloat(i) * (-radius * 0.5)
            ctx.fill(Path(ellipseIn: eRect.insetBy(dx: inset, dy: inset)),
                     with: .color(color.opacity(Double(3 - i) * 0.12)))
        }
        // Core
        ctx.fill(Path(ellipseIn: eRect), with: .color(color))
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Skeleton
    // ─────────────────────────────────────────────────────────────────────────

    private static func skeleton(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let bone  = Color(white: 0.82)
        let dark  = Color(red: 0.03, green: 0.02, blue: 0.10)
        let eyes  = Color(red: 0.55, green: 0.65, blue: 1.0)

        // Skull dome
        ellipse(ctx, s, x: 0.22, y: 0.05, w: 0.56, h: 0.42, color: bone)

        // Eye sockets
        ellipse(ctx, s, x: 0.26, y: 0.15, w: 0.17, h: 0.19, color: dark)
        ellipse(ctx, s, x: 0.57, y: 0.15, w: 0.17, h: 0.19, color: dark)
        // Eye glows
        glow(ctx, s, x: 0.29, y: 0.18, w: 0.11, h: 0.13, color: eyes, radius: 3)
        glow(ctx, s, x: 0.60, y: 0.18, w: 0.11, h: 0.13, color: eyes, radius: 3)

        // Nasal cavity (diamond)
        var nose = Path()
        nose.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.30))
        nose.addLine(to: CGPoint(x: s.width * 0.55, y: s.height * 0.35))
        nose.addLine(to: CGPoint(x: s.width * 0.50, y: s.height * 0.40))
        nose.addLine(to: CGPoint(x: s.width * 0.45, y: s.height * 0.35))
        nose.closeSubpath()
        ctx.fill(nose, with: .color(dark))

        // Jaw
        ellipse(ctx, s, x: 0.27, y: 0.38, w: 0.46, h: 0.13, color: Color(white: 0.76))
        // Tooth gaps
        let style = StrokeStyle(lineWidth: 2)
        for i in 0..<3 {
            let gx = s.width * (0.36 + CGFloat(i) * 0.10)
            var gap = Path()
            gap.move(to: CGPoint(x: gx, y: s.height * 0.38))
            gap.addLine(to: CGPoint(x: gx, y: s.height * 0.50))
            ctx.stroke(gap, with: .color(dark), style: style)
        }

        // Neck
        rect(ctx, s, x: 0.41, y: 0.50, w: 0.18, h: 0.07, color: Color(white: 0.72))

        // Spine
        var spine = Path()
        spine.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.57))
        spine.addLine(to: CGPoint(x: s.width * 0.50, y: s.height * 0.93))
        ctx.stroke(spine, with: .color(Color(white: 0.66)), style: StrokeStyle(lineWidth: 2.5))

        // Clavicles
        let clavStyle = StrokeStyle(lineWidth: 1.8)
        var lc = Path()
        lc.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.57))
        lc.addLine(to: CGPoint(x: s.width * 0.16, y: s.height * 0.64))
        ctx.stroke(lc, with: .color(bone), style: clavStyle)
        var rc = Path()
        rc.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.57))
        rc.addLine(to: CGPoint(x: s.width * 0.84, y: s.height * 0.64))
        ctx.stroke(rc, with: .color(bone), style: clavStyle)

        // Rib pairs (3)
        let ribStyle = StrokeStyle(lineWidth: 1.8)
        let ribColor = Color(white: 0.65)
        for i in 0..<3 {
            let ty = s.height * (0.60 + CGFloat(i) * 0.11)
            var lr = Path()
            lr.move(to: CGPoint(x: s.width * 0.50, y: ty))
            lr.addQuadCurve(to: CGPoint(x: s.width * 0.15, y: ty + s.height * 0.07),
                            control: CGPoint(x: s.width * 0.22, y: ty - s.height * 0.03))
            ctx.stroke(lr, with: .color(ribColor), style: ribStyle)
            var rr = Path()
            rr.move(to: CGPoint(x: s.width * 0.50, y: ty))
            rr.addQuadCurve(to: CGPoint(x: s.width * 0.85, y: ty + s.height * 0.07),
                            control: CGPoint(x: s.width * 0.78, y: ty - s.height * 0.03))
            ctx.stroke(rr, with: .color(ribColor), style: ribStyle)
        }

        if boss {
            // Enhanced glow on eye sockets for boss
            glow(ctx, s, x: 0.27, y: 0.15, w: 0.17, h: 0.19, color: eyes.opacity(0.35), radius: 6)
            glow(ctx, s, x: 0.57, y: 0.15, w: 0.17, h: 0.19, color: eyes.opacity(0.35), radius: 6)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Zombie
    // ─────────────────────────────────────────────────────────────────────────

    private static func zombie(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let skin   = Color(red: 0.42, green: 0.52, blue: 0.34)
        let dark   = Color(red: 0.04, green: 0.06, blue: 0.04)
        let eyeCol = Color(red: 0.55, green: 0.95, blue: 0.30)

        // Body — large hulking oval
        ellipse(ctx, s, x: 0.14, y: 0.40, w: 0.72, h: 0.58, color: Color(red: 0.36, green: 0.44, blue: 0.29))

        // Head — slightly tilted/off-center
        ellipse(ctx, s, x: 0.22, y: 0.04, w: 0.56, h: 0.44, color: skin)

        // Neck shadow
        ellipse(ctx, s, x: 0.36, y: 0.40, w: 0.28, h: 0.12, color: Color(red: 0.30, green: 0.38, blue: 0.24))

        // Eyes — horizontal glowing slits
        glow(ctx, s, x: 0.26, y: 0.19, w: 0.16, h: 0.07, color: eyeCol, radius: 3)
        glow(ctx, s, x: 0.58, y: 0.19, w: 0.16, h: 0.07, color: eyeCol, radius: 3)
        // Dark eye surround
        ellipse(ctx, s, x: 0.21, y: 0.16, w: 0.22, h: 0.13, color: dark.opacity(0.55))
        ellipse(ctx, s, x: 0.57, y: 0.16, w: 0.22, h: 0.13, color: dark.opacity(0.55))
        // Re-draw glow on top
        glow(ctx, s, x: 0.27, y: 0.19, w: 0.14, h: 0.07, color: eyeCol.opacity(0.9), radius: 2)
        glow(ctx, s, x: 0.59, y: 0.19, w: 0.14, h: 0.07, color: eyeCol.opacity(0.9), radius: 2)

        // Mouth — ragged slit
        rect(ctx, s, x: 0.32, y: 0.33, w: 0.36, h: 0.06, color: dark, radius: 2)
        // Uneven teeth
        for i in 0..<4 {
            let tx = 0.34 + CGFloat(i) * 0.076
            let ty: CGFloat = i % 2 == 0 ? 0.33 : 0.35
            rect(ctx, s, x: tx, y: ty, w: 0.04, h: 0.04,
                 color: Color(white: 0.80), radius: 1)
        }

        // Arms — reaching forward (left arm)
        var lArm = Path()
        lArm.move(to: CGPoint(x: s.width * 0.22, y: s.height * 0.58))
        lArm.addQuadCurve(to: CGPoint(x: s.width * 0.04, y: s.height * 0.78),
                          control: CGPoint(x: s.width * 0.08, y: s.height * 0.58))
        ctx.stroke(lArm, with: .color(skin), style: StrokeStyle(lineWidth: s.width * 0.10, lineCap: .round))

        // Right arm
        var rArm = Path()
        rArm.move(to: CGPoint(x: s.width * 0.78, y: s.height * 0.58))
        rArm.addQuadCurve(to: CGPoint(x: s.width * 0.96, y: s.height * 0.78),
                          control: CGPoint(x: s.width * 0.92, y: s.height * 0.58))
        ctx.stroke(rArm, with: .color(skin), style: StrokeStyle(lineWidth: s.width * 0.10, lineCap: .round))

        // Skin cracks / decay lines
        let decayStyle = StrokeStyle(lineWidth: 1)
        var d1 = Path()
        d1.move(to: CGPoint(x: s.width * 0.38, y: s.height * 0.10))
        d1.addLine(to: CGPoint(x: s.width * 0.45, y: s.height * 0.22))
        ctx.stroke(d1, with: .color(dark.opacity(0.5)), style: decayStyle)
        var d2 = Path()
        d2.move(to: CGPoint(x: s.width * 0.62, y: s.height * 0.12))
        d2.addLine(to: CGPoint(x: s.width * 0.55, y: s.height * 0.26))
        ctx.stroke(d2, with: .color(dark.opacity(0.5)), style: decayStyle)
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Knight
    // ─────────────────────────────────────────────────────────────────────────

    private static func knight(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let steel    = Color(red: 0.28, green: 0.32, blue: 0.42)
        let steelDk  = Color(red: 0.16, green: 0.18, blue: 0.26)
        let steelLt  = Color(red: 0.44, green: 0.50, blue: 0.62)
        let visor    = Color(red: 1.00, green: 0.45, blue: 0.08)
        let dark     = Color(red: 0.02, green: 0.02, blue: 0.06)

        // Pauldrons (shoulders)
        rect(ctx, s, x: 0.03, y: 0.46, w: 0.20, h: 0.22, color: steelDk, radius: 4)
        rect(ctx, s, x: 0.77, y: 0.46, w: 0.20, h: 0.22, color: steelDk, radius: 4)
        // Pauldron highlights
        rect(ctx, s, x: 0.05, y: 0.47, w: 0.07, h: 0.03, color: steelLt.opacity(0.5), radius: 1)
        rect(ctx, s, x: 0.88, y: 0.47, w: 0.07, h: 0.03, color: steelLt.opacity(0.5), radius: 1)

        // Breastplate
        rect(ctx, s, x: 0.22, y: 0.50, w: 0.56, h: 0.46, color: steelDk, radius: 5)
        // Breastplate center line
        var cl = Path()
        cl.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.51))
        cl.addLine(to: CGPoint(x: s.width * 0.50, y: s.height * 0.93))
        ctx.stroke(cl, with: .color(steelLt.opacity(0.4)), style: StrokeStyle(lineWidth: 1.5))
        // Breastplate highlight band
        rect(ctx, s, x: 0.24, y: 0.51, w: 0.52, h: 0.05, color: steelLt.opacity(0.25), radius: 3)

        // Helmet body (trapezoid-ish: wider at top)
        var helm = Path()
        helm.move(to: CGPoint(x: s.width * 0.20, y: s.height * 0.50))
        helm.addLine(to: CGPoint(x: s.width * 0.24, y: s.height * 0.10))
        helm.addLine(to: CGPoint(x: s.width * 0.76, y: s.height * 0.10))
        helm.addLine(to: CGPoint(x: s.width * 0.80, y: s.height * 0.50))
        helm.closeSubpath()
        ctx.fill(helm, with: .color(steel))

        // Helmet top rounded cap
        ellipse(ctx, s, x: 0.22, y: 0.04, w: 0.56, h: 0.14, color: steelLt.opacity(0.7))
        // Re-draw main helmet to cover bottom of cap
        var helmTop = Path()
        helmTop.move(to: CGPoint(x: s.width * 0.22, y: s.height * 0.11))
        helmTop.addLine(to: CGPoint(x: s.width * 0.78, y: s.height * 0.11))
        helmTop.addLine(to: CGPoint(x: s.width * 0.80, y: s.height * 0.50))
        helmTop.addLine(to: CGPoint(x: s.width * 0.20, y: s.height * 0.50))
        helmTop.closeSubpath()
        ctx.fill(helmTop, with: .color(steel))

        // Visor slot (dark base + glowing slit)
        rect(ctx, s, x: 0.20, y: 0.31, w: 0.60, h: 0.11, color: dark, radius: 2)
        // Glow emanating from visor
        for i in 0..<3 {
            let inset = CGFloat(i) * 1.5
            let alpha = Double(3 - i) * 0.18
            rect(ctx, s,
                 x: 0.20 - (inset / s.width), y: 0.31 - (inset / s.height),
                 w: 0.60 + (2 * inset / s.width), h: 0.11 + (2 * inset / s.height),
                 color: visor.opacity(alpha), radius: 3)
        }
        rect(ctx, s, x: 0.23, y: 0.33, w: 0.54, h: 0.07, color: visor.opacity(0.85), radius: 1)

        // Helmet edge highlight
        var edgeLeft = Path()
        edgeLeft.move(to: CGPoint(x: s.width * 0.24, y: s.height * 0.12))
        edgeLeft.addLine(to: CGPoint(x: s.width * 0.21, y: s.height * 0.50))
        ctx.stroke(edgeLeft, with: .color(steelLt.opacity(0.45)), style: StrokeStyle(lineWidth: 2))
        var edgeRight = Path()
        edgeRight.move(to: CGPoint(x: s.width * 0.76, y: s.height * 0.12))
        edgeRight.addLine(to: CGPoint(x: s.width * 0.79, y: s.height * 0.50))
        ctx.stroke(edgeRight, with: .color(steelLt.opacity(0.45)), style: StrokeStyle(lineWidth: 2))

        if boss {
            // Extra visor intensity
            rect(ctx, s, x: 0.23, y: 0.33, w: 0.54, h: 0.07, color: visor, radius: 1)
            glow(ctx, s, x: 0.23, y: 0.33, w: 0.54, h: 0.07, color: visor.opacity(0.5), radius: 6)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Mage
    // ─────────────────────────────────────────────────────────────────────────

    private static func mage(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let robeCol  = Color(red: 0.32, green: 0.08, blue: 0.48)
        let robeShadow = Color(red: 0.14, green: 0.03, blue: 0.22)
        let eyes     = Color(red: 0.85, green: 0.30, blue: 1.00)
        let orb      = Color(red: 0.90, green: 0.60, blue: 1.00)
        let dark     = Color(red: 0.06, green: 0.02, blue: 0.12)

        // Robe body — large triangle
        var robe = Path()
        robe.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.02))
        robe.addLine(to: CGPoint(x: s.width * 0.04, y: s.height * 0.97))
        robe.addLine(to: CGPoint(x: s.width * 0.96, y: s.height * 0.97))
        robe.closeSubpath()
        ctx.fill(robe, with: .color(robeCol))

        // Robe shadow (inner darker triangle for depth)
        var robeInner = Path()
        robeInner.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.08))
        robeInner.addLine(to: CGPoint(x: s.width * 0.14, y: s.height * 0.97))
        robeInner.addLine(to: CGPoint(x: s.width * 0.86, y: s.height * 0.97))
        robeInner.closeSubpath()
        ctx.fill(robeInner, with: .color(robeShadow))

        // Hood cap circle
        ellipse(ctx, s, x: 0.28, y: 0.02, w: 0.44, h: 0.36, color: robeCol)

        // Face shadow inside hood
        ellipse(ctx, s, x: 0.30, y: 0.06, w: 0.40, h: 0.30, color: dark)

        // Eyes
        glow(ctx, s, x: 0.33, y: 0.16, w: 0.12, h: 0.10, color: eyes, radius: 4)
        glow(ctx, s, x: 0.55, y: 0.16, w: 0.12, h: 0.10, color: eyes, radius: 4)

        // Robe edge trim
        var trimL = Path()
        trimL.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.02))
        trimL.addLine(to: CGPoint(x: s.width * 0.04, y: s.height * 0.97))
        ctx.stroke(trimL, with: .color(eyes.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5))
        var trimR = Path()
        trimR.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.02))
        trimR.addLine(to: CGPoint(x: s.width * 0.96, y: s.height * 0.97))
        ctx.stroke(trimR, with: .color(eyes.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5))

        // Glowing orb (floating near bottom of robe)
        glow(ctx, s, x: 0.40, y: 0.64, w: 0.20, h: 0.20, color: orb.opacity(0.45), radius: 8)
        ellipse(ctx, s, x: 0.40, y: 0.64, w: 0.20, h: 0.20, color: orb)
        // Orb inner shine
        ellipse(ctx, s, x: 0.44, y: 0.66, w: 0.06, h: 0.06, color: Color.white.opacity(0.75))

        // Rune ring around orb
        for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
            let rad = CGFloat(angle * .pi / 180.0)
            let ox = 0.50 + 0.18 * cos(rad)
            let oy = 0.74 + 0.14 * sin(rad)
            ellipse(ctx, s, x: ox - 0.02, y: oy - 0.02, w: 0.04, h: 0.04,
                    color: eyes.opacity(0.55))
        }

        if boss {
            glow(ctx, s, x: 0.38, y: 0.62, w: 0.24, h: 0.24, color: orb.opacity(0.5), radius: 10)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Ghoul
    // ─────────────────────────────────────────────────────────────────────────

    private static func ghoul(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let skin   = Color(red: 0.60, green: 0.58, blue: 0.44)
        let skinDk = Color(red: 0.38, green: 0.36, blue: 0.26)
        let dark   = Color(red: 0.06, green: 0.05, blue: 0.02)
        let eyes   = Color(red: 0.92, green: 0.84, blue: 0.18)
        let blood  = Color(red: 0.55, green: 0.05, blue: 0.05)

        // Very wide face
        ellipse(ctx, s, x: 0.04, y: 0.08, w: 0.92, h: 0.52, color: skin)

        // Brow shadow
        ellipse(ctx, s, x: 0.04, y: 0.08, w: 0.92, h: 0.20, color: skinDk)

        // Left eye (large, sunken)
        ellipse(ctx, s, x: 0.08, y: 0.14, w: 0.26, h: 0.22, color: dark)
        glow(ctx, s, x: 0.12, y: 0.18, w: 0.17, h: 0.14, color: eyes, radius: 4)

        // Right eye
        ellipse(ctx, s, x: 0.66, y: 0.14, w: 0.26, h: 0.22, color: dark)
        glow(ctx, s, x: 0.70, y: 0.18, w: 0.17, h: 0.14, color: eyes, radius: 4)

        // Nose ridge (flat, wide)
        ellipse(ctx, s, x: 0.40, y: 0.30, w: 0.20, h: 0.10, color: skinDk)

        // Wide jagged mouth
        rect(ctx, s, x: 0.18, y: 0.44, w: 0.64, h: 0.12, color: dark, radius: 2)
        // Teeth (jagged)
        for i in 0..<6 {
            let tx = 0.20 + CGFloat(i) * 0.100
            let ty: CGFloat = i % 2 == 0 ? 0.44 : 0.48
            rect(ctx, s, x: tx, y: ty, w: 0.055, h: 0.06,
                 color: Color(white: 0.85), radius: 1)
        }
        // Blood in mouth
        ellipse(ctx, s, x: 0.25, y: 0.50, w: 0.50, h: 0.06, color: blood.opacity(0.60))

        // Body (hunched lower form)
        ellipse(ctx, s, x: 0.20, y: 0.56, w: 0.60, h: 0.40, color: skinDk)

        // Reaching claws (3 fingers)
        for i in 0..<3 {
            let cx = 0.35 + CGFloat(i) * 0.13
            var claw = Path()
            claw.move(to: CGPoint(x: s.width * cx, y: s.height * 0.72))
            claw.addLine(to: CGPoint(x: s.width * (cx - 0.04), y: s.height * 0.62))
            claw.addLine(to: CGPoint(x: s.width * (cx + 0.04), y: s.height * 0.62))
            claw.closeSubpath()
            ctx.fill(claw, with: .color(skin))
        }

        if boss {
            glow(ctx, s, x: 0.10, y: 0.16, w: 0.20, h: 0.16, color: eyes.opacity(0.5), radius: 5)
            glow(ctx, s, x: 0.70, y: 0.16, w: 0.20, h: 0.16, color: eyes.opacity(0.5), radius: 5)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Golem
    // ─────────────────────────────────────────────────────────────────────────

    private static func golem(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let stone  = Color(red: 0.44, green: 0.38, blue: 0.30)
        let stoneDk = Color(red: 0.28, green: 0.24, blue: 0.18)
        let stoneLt = Color(red: 0.58, green: 0.52, blue: 0.44)
        let lava   = Color(red: 1.00, green: 0.46, blue: 0.06)
        let dark   = Color(red: 0.06, green: 0.04, blue: 0.02)

        // Body block
        rect(ctx, s, x: 0.16, y: 0.46, w: 0.68, h: 0.50, color: stone, radius: 4)
        // Body highlight top
        rect(ctx, s, x: 0.18, y: 0.47, w: 0.64, h: 0.05, color: stoneLt.opacity(0.5), radius: 2)
        // Left shoulder block
        rect(ctx, s, x: 0.04, y: 0.44, w: 0.14, h: 0.26, color: stoneDk, radius: 3)
        // Right shoulder block
        rect(ctx, s, x: 0.82, y: 0.44, w: 0.14, h: 0.26, color: stoneDk, radius: 3)

        // Head block
        rect(ctx, s, x: 0.24, y: 0.08, w: 0.52, h: 0.42, color: stone, radius: 4)
        // Head highlight
        rect(ctx, s, x: 0.26, y: 0.09, w: 0.48, h: 0.05, color: stoneLt.opacity(0.55), radius: 2)
        // Head sides darker
        rect(ctx, s, x: 0.24, y: 0.08, w: 0.06, h: 0.42, color: stoneDk.opacity(0.6), radius: 2)
        rect(ctx, s, x: 0.70, y: 0.08, w: 0.06, h: 0.42, color: stoneDk.opacity(0.6), radius: 2)

        // Eye slots
        rect(ctx, s, x: 0.28, y: 0.18, w: 0.16, h: 0.10, color: dark, radius: 1)
        rect(ctx, s, x: 0.56, y: 0.18, w: 0.16, h: 0.10, color: dark, radius: 1)
        // Eye glow
        glow(ctx, s, x: 0.29, y: 0.19, w: 0.14, h: 0.08, color: lava.opacity(0.9), radius: 4)
        glow(ctx, s, x: 0.57, y: 0.19, w: 0.14, h: 0.08, color: lava.opacity(0.9), radius: 4)

        // Mouth slot
        rect(ctx, s, x: 0.34, y: 0.34, w: 0.32, h: 0.07, color: dark, radius: 1)
        glow(ctx, s, x: 0.36, y: 0.355, w: 0.28, h: 0.04, color: lava.opacity(0.6), radius: 3)

        // Main crack (center body vertical)
        var crack = Path()
        crack.move(to: CGPoint(x: s.width * 0.50, y: s.height * 0.46))
        crack.addLine(to: CGPoint(x: s.width * 0.46, y: s.height * 0.60))
        crack.addLine(to: CGPoint(x: s.width * 0.52, y: s.height * 0.72))
        crack.addLine(to: CGPoint(x: s.width * 0.48, y: s.height * 0.92))
        ctx.stroke(crack, with: .color(lava), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        // Crack glow
        ctx.stroke(crack, with: .color(lava.opacity(0.35)), style: StrokeStyle(lineWidth: 6, lineCap: .round))

        // Diagonal crack on head
        var headCrack = Path()
        headCrack.move(to: CGPoint(x: s.width * 0.38, y: s.height * 0.10))
        headCrack.addLine(to: CGPoint(x: s.width * 0.44, y: s.height * 0.28))
        ctx.stroke(headCrack, with: .color(lava.opacity(0.7)), style: StrokeStyle(lineWidth: 1.5))

        // Stone texture lines on body
        var tex = Path()
        tex.move(to: CGPoint(x: s.width * 0.22, y: s.height * 0.60))
        tex.addLine(to: CGPoint(x: s.width * 0.42, y: s.height * 0.65))
        ctx.stroke(tex, with: .color(stoneDk.opacity(0.7)), style: StrokeStyle(lineWidth: 1))

        if boss {
            // Enhanced cracks + eye intensity
            ctx.stroke(crack, with: .color(lava.opacity(0.6)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
            ctx.stroke(crack, with: .color(lava), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: Wraith
    // ─────────────────────────────────────────────────────────────────────────

    private static func wraith(_ ctx: GraphicsContext, _ s: CGSize, _ boss: Bool) {
        let mistCol = Color(red: 0.20, green: 0.14, blue: 0.38)
        let eyeCol  = Color(red: 0.55, green: 0.92, blue: 1.00)
        let dark    = Color.black

        // Main form — very dark oval, barely there
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: s.width * 0.08))
            layer.fill(Path(ellipseIn: CGRect(
                x: s.width * 0.28, y: s.height * 0.04,
                width: s.width * 0.44, height: s.height * 0.72
            )), with: .color(mistCol))
        }

        // Slightly visible upper torso
        ellipse(ctx, s, x: 0.30, y: 0.10, w: 0.40, h: 0.50, color: mistCol.opacity(0.50))
        ellipse(ctx, s, x: 0.34, y: 0.14, w: 0.32, h: 0.36, color: mistCol.opacity(0.40))

        // Eyes — the most visible element
        glow(ctx, s, x: 0.30, y: 0.25, w: 0.14, h: 0.12, color: eyeCol, radius: 6)
        glow(ctx, s, x: 0.56, y: 0.25, w: 0.14, h: 0.12, color: eyeCol, radius: 6)
        // Eye bright cores
        ellipse(ctx, s, x: 0.34, y: 0.27, w: 0.06, h: 0.08, color: Color.white)
        ellipse(ctx, s, x: 0.60, y: 0.27, w: 0.06, h: 0.08, color: Color.white)

        // Wisps trailing downward
        let wispStyle = StrokeStyle(lineWidth: 2, lineCap: .round)
        for i in 0..<4 {
            let wx = 0.30 + CGFloat(i) * 0.12
            var wisp = Path()
            wisp.move(to: CGPoint(x: s.width * wx, y: s.height * 0.60))
            wisp.addQuadCurve(
                to: CGPoint(x: s.width * (wx + CGFloat(i % 2 == 0 ? -0.08 : 0.08)), y: s.height * 0.95),
                control: CGPoint(x: s.width * (wx + 0.04), y: s.height * 0.78)
            )
            ctx.stroke(wisp, with: .color(mistCol.opacity(0.7 - CGFloat(i) * 0.15)),
                       style: wispStyle)
        }

        // Side tendrils
        var lt = Path()
        lt.move(to: CGPoint(x: s.width * 0.32, y: s.height * 0.42))
        lt.addQuadCurve(to: CGPoint(x: s.width * 0.06, y: s.height * 0.65),
                        control: CGPoint(x: s.width * 0.12, y: s.height * 0.48))
        ctx.stroke(lt, with: .color(eyeCol.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5))
        var rt = Path()
        rt.move(to: CGPoint(x: s.width * 0.68, y: s.height * 0.42))
        rt.addQuadCurve(to: CGPoint(x: s.width * 0.94, y: s.height * 0.65),
                        control: CGPoint(x: s.width * 0.88, y: s.height * 0.48))
        ctx.stroke(rt, with: .color(eyeCol.opacity(0.35)), style: StrokeStyle(lineWidth: 1.5))

        if boss {
            glow(ctx, s, x: 0.28, y: 0.22, w: 0.18, h: 0.18, color: eyeCol.opacity(0.45), radius: 8)
            glow(ctx, s, x: 0.54, y: 0.22, w: 0.18, h: 0.18, color: eyeCol.opacity(0.45), radius: 8)
        }
    }
}

#Preview {
    let enemies = [
        Enemy(name: "Skeleton",      icon: "💀", maxHp: 20,  actions: [.attack(6)]),
        Enemy(name: "Rotwalker",     icon: "🧟", maxHp: 28,  actions: [.attack(7)]),
        Enemy(name: "Dark Knight",   icon: "🛡️", maxHp: 42,  actions: [.attack(10)]),
        Enemy(name: "Bog Cultist",   icon: "🧙", maxHp: 34,  actions: [.attack(8)]),
        Enemy(name: "Ghoul",         icon: "👻", maxHp: 28,  actions: [.attack(9)]),
        Enemy(name: "Stone Golem",   icon: "🗿", maxHp: 58,  actions: [.defend(10)]),
        Enemy(name: "Shadow Stalker",icon: "🌑", maxHp: 44,  actions: [.weaken]),
        Enemy(name: "The Warden",    icon: "⚰️", maxHp: 65,  actions: [.attack(12)]),
    ]
    return ZStack {
        Color(red: 0.06, green: 0.02, blue: 0.10).ignoresSafeArea()
        VStack(spacing: 20) {
            Text("Enemy Portraits").foregroundStyle(.white).font(.headline)
            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 12) {
                ForEach(Array(enemies.enumerated()), id: \.offset) { idx, e in
                    VStack(spacing: 4) {
                        EnemyPortraitView(enemy: e, size: 70,
                                          isBoss: idx == 7, isElite: idx == 2)
                        Text(e.name.components(separatedBy: " ").last ?? e.name)
                            .font(.system(size: 8))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding()
        }
    }
}
