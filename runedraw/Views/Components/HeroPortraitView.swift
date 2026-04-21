// swiftlint:disable function_body_length type_body_length
import SwiftUI

// MARK: - HeroPortraitView

struct HeroPortraitView: View {
    let heroClass: HeroClass
    var size: CGFloat = 200

    var body: some View {
        ZStack {
            LinearGradient(colors: bgColors, startPoint: .top, endPoint: .bottom)

            TimelineView(.animation) { tl in
                Canvas { ctx, sz in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    HeroDrawing.draw(heroClass, ctx: ctx, size: sz, t: t)
                }
            }

            // Edge vignette for depth
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

// MARK: - HeroDrawing

struct HeroDrawing {

    static func draw(_ heroClass: HeroClass, ctx: GraphicsContext, size: CGSize, t: Double) {
        switch heroClass {
        case .barbarian: drawBarbarian(ctx: ctx, size: size, t: t)
        case .rogue:     drawRogue(ctx: ctx, size: size, t: t)
        case .sorceress: drawSorceress(ctx: ctx, size: size, t: t)
        }
    }

    // MARK: - Helpers

    private static func ellipse(ctx: GraphicsContext,
                                cx: Double, cy: Double, rx: Double, ry: Double,
                                color: Color) {
        let path = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        ctx.fill(path, with: .color(color))
    }

    private static func rect(ctx: GraphicsContext,
                              x: Double, y: Double, w: Double, h: Double,
                              color: Color, cr: Double = 0) {
        let path = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: cr)
        ctx.fill(path, with: .color(color))
    }

    private static func glow(ctx: GraphicsContext,
                              cx: Double, cy: Double, r: Double, color: Color) {
        ellipse(ctx: ctx, cx: cx, cy: cy, rx: r * 2.6, ry: r * 2.6, color: color.opacity(0.10))
        ellipse(ctx: ctx, cx: cx, cy: cy, rx: r * 1.5, ry: r * 1.5, color: color.opacity(0.28))
        ellipse(ctx: ctx, cx: cx, cy: cy, rx: r,       ry: r,       color: color.opacity(0.92))
    }

    // MARK: - Barbarian

    private static func drawBarbarian(ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height

        let by       = sin(t * 1.60) * h * 0.013
        let breathe  = 0.50 + sin(t * 1.60) * 0.50
        let eyeG     = 0.65 + sin(t * 2.10) * 0.35
        let axeSway  = sin(t * 0.85) * 0.08

        let skin     = Color(red: 0.68, green: 0.44, blue: 0.29)
        let skinDk   = Color(red: 0.44, green: 0.26, blue: 0.14)
        let skinLt   = Color(red: 0.82, green: 0.58, blue: 0.40)
        let leatherD = Color(red: 0.15, green: 0.08, blue: 0.03)
        let leather  = Color(red: 0.24, green: 0.14, blue: 0.07)
        let leatherL = Color(red: 0.36, green: 0.22, blue: 0.10)
        let metalD   = Color(red: 0.22, green: 0.20, blue: 0.18)
        let metal    = Color(red: 0.46, green: 0.44, blue: 0.40)
        let metalL   = Color(red: 0.72, green: 0.70, blue: 0.65)
        let fur      = Color(red: 0.32, green: 0.22, blue: 0.10)
        let furL     = Color(red: 0.54, green: 0.38, blue: 0.18)
        let hair     = Color(red: 0.26, green: 0.10, blue: 0.04)
        let hairL    = Color(red: 0.42, green: 0.18, blue: 0.06)
        let eyeCol   = Color(red: 1.00, green: 0.42, blue: 0.04)
        let warpaint = Color(red: 0.75, green: 0.08, blue: 0.04)
        let goldCol  = Color(red: 0.75, green: 0.58, blue: 0.12)
        let blood    = Color(red: 0.52, green: 0.04, blue: 0.04)

        // --- Floating embers ---
        for i in 0..<6 {
            let fi = Double(i)
            let phase = (t * 0.14 + fi * 0.17).truncatingRemainder(dividingBy: 1.0)
            let ex = w * (0.28 + fi * 0.09 + sin(t * 1.8 + fi * 1.1) * 0.04)
            let ey = h * (0.96 - phase * 0.92)
            let alpha = phase < 0.15 ? phase / 0.15 : phase > 0.80 ? (1.0 - phase) / 0.20 : 1.0
            ellipse(ctx: ctx, cx: ex, cy: ey, rx: w*0.007, ry: w*0.007,
                    color: Color(red: 1.0, green: 0.50, blue: 0.10).opacity(alpha * 0.55))
        }

        // --- Legs (leather pants + greaves) ---
        var lLeg = Path()
        lLeg.move(to: CGPoint(x: w*0.31, y: h*0.64+by))
        lLeg.addLine(to: CGPoint(x: w*0.47, y: h*0.64+by))
        lLeg.addLine(to: CGPoint(x: w*0.46, y: h*0.84+by))
        lLeg.addLine(to: CGPoint(x: w*0.30, y: h*0.84+by))
        lLeg.closeSubpath()
        ctx.fill(lLeg, with: .color(leather))
        // Left leg shadow (inner edge)
        var lLegS = Path()
        lLegS.move(to: CGPoint(x: w*0.43, y: h*0.64+by))
        lLegS.addLine(to: CGPoint(x: w*0.47, y: h*0.64+by))
        lLegS.addLine(to: CGPoint(x: w*0.46, y: h*0.84+by))
        lLegS.addLine(to: CGPoint(x: w*0.43, y: h*0.84+by))
        lLegS.closeSubpath()
        ctx.fill(lLegS, with: .color(.black.opacity(0.22)))
        // Left leg highlight (outer edge)
        var lLegH = Path()
        lLegH.move(to: CGPoint(x: w*0.31, y: h*0.64+by))
        lLegH.addLine(to: CGPoint(x: w*0.34, y: h*0.64+by))
        lLegH.addLine(to: CGPoint(x: w*0.33, y: h*0.84+by))
        lLegH.addLine(to: CGPoint(x: w*0.30, y: h*0.84+by))
        lLegH.closeSubpath()
        ctx.fill(lLegH, with: .color(leatherL.opacity(0.28)))

        var rLeg = Path()
        rLeg.move(to: CGPoint(x: w*0.53, y: h*0.64+by))
        rLeg.addLine(to: CGPoint(x: w*0.69, y: h*0.64+by))
        rLeg.addLine(to: CGPoint(x: w*0.70, y: h*0.84+by))
        rLeg.addLine(to: CGPoint(x: w*0.54, y: h*0.84+by))
        rLeg.closeSubpath()
        ctx.fill(rLeg, with: .color(leather))
        var rLegS = Path()
        rLegS.move(to: CGPoint(x: w*0.65, y: h*0.64+by))
        rLegS.addLine(to: CGPoint(x: w*0.69, y: h*0.64+by))
        rLegS.addLine(to: CGPoint(x: w*0.70, y: h*0.84+by))
        rLegS.addLine(to: CGPoint(x: w*0.66, y: h*0.84+by))
        rLegS.closeSubpath()
        ctx.fill(rLegS, with: .color(.black.opacity(0.22)))

        // Knee caps (skin showing through)
        ellipse(ctx: ctx, cx: w*0.385, cy: h*0.822+by, rx: w*0.058, ry: w*0.038, color: skin)
        ellipse(ctx: ctx, cx: w*0.385, cy: h*0.814+by, rx: w*0.035, ry: w*0.020,
                color: skinLt.opacity(0.35))
        ellipse(ctx: ctx, cx: w*0.615, cy: h*0.822+by, rx: w*0.058, ry: w*0.038, color: skin)
        ellipse(ctx: ctx, cx: w*0.615, cy: h*0.814+by, rx: w*0.035, ry: w*0.020,
                color: skinLt.opacity(0.35))

        // Greaves
        rect(ctx: ctx, x: w*0.298, y: h*0.832+by, w: w*0.154, h: h*0.096, color: metalD, cr: w*0.014)
        rect(ctx: ctx, x: w*0.308, y: h*0.834+by, w: w*0.134, h: h*0.006, color: metal)
        rect(ctx: ctx, x: w*0.316, y: h*0.845+by, w: w*0.046, h: h*0.056, color: metalL.opacity(0.15), cr: w*0.005)
        rect(ctx: ctx, x: w*0.548, y: h*0.832+by, w: w*0.154, h: h*0.096, color: metalD, cr: w*0.014)
        rect(ctx: ctx, x: w*0.558, y: h*0.834+by, w: w*0.134, h: h*0.006, color: metal)
        rect(ctx: ctx, x: w*0.566, y: h*0.845+by, w: w*0.046, h: h*0.056, color: metalL.opacity(0.15), cr: w*0.005)

        // Boots
        rect(ctx: ctx, x: w*0.282, y: h*0.920+by, w: w*0.178, h: h*0.068, color: leatherD, cr: w*0.018)
        rect(ctx: ctx, x: w*0.294, y: h*0.926+by, w: w*0.064, h: h*0.022, color: leatherL.opacity(0.18), cr: w*0.006)
        rect(ctx: ctx, x: w*0.540, y: h*0.920+by, w: w*0.178, h: h*0.068, color: leatherD, cr: w*0.018)
        rect(ctx: ctx, x: w*0.552, y: h*0.926+by, w: w*0.064, h: h*0.022, color: leatherL.opacity(0.18), cr: w*0.006)

        // --- Torso (bare skin, muscular) ---
        var torso = Path()
        torso.move(to: CGPoint(x: w*0.20, y: h*0.36+by))
        torso.addLine(to: CGPoint(x: w*0.80, y: h*0.36+by))
        torso.addLine(to: CGPoint(x: w*0.69, y: h*0.65+by))
        torso.addLine(to: CGPoint(x: w*0.31, y: h*0.65+by))
        torso.closeSubpath()
        ctx.fill(torso, with: .color(skin))

        // Torso right shadow
        var torsoRS = Path()
        torsoRS.move(to: CGPoint(x: w*0.62, y: h*0.36+by))
        torsoRS.addLine(to: CGPoint(x: w*0.80, y: h*0.36+by))
        torsoRS.addLine(to: CGPoint(x: w*0.69, y: h*0.65+by))
        torsoRS.addLine(to: CGPoint(x: w*0.61, y: h*0.65+by))
        torsoRS.closeSubpath()
        ctx.fill(torsoRS, with: .color(skinDk.opacity(0.30)))

        // Center sternum line
        var sternum = Path()
        sternum.move(to: CGPoint(x: w*0.50, y: h*0.37+by))
        sternum.addLine(to: CGPoint(x: w*0.50, y: h*0.64+by))
        ctx.stroke(sternum, with: .color(skinDk.opacity(0.40)), lineWidth: w*0.009)

        // Pectoral muscles (expand with breath)
        let pW = w * (0.150 + breathe * 0.010)
        let pH = h * (0.082 + breathe * 0.006)
        ellipse(ctx: ctx, cx: w*0.382, cy: h*0.445+by, rx: pW, ry: pH, color: skinLt.opacity(0.20))
        ellipse(ctx: ctx, cx: w*0.618, cy: h*0.445+by, rx: pW, ry: pH, color: skinLt.opacity(0.20))
        ellipse(ctx: ctx, cx: w*0.382, cy: h*0.478+by, rx: pW*0.78, ry: pH*0.34, color: skinDk.opacity(0.25))
        ellipse(ctx: ctx, cx: w*0.618, cy: h*0.478+by, rx: pW*0.78, ry: pH*0.34, color: skinDk.opacity(0.25))

        // Ab definition
        let abPairs: [(Double, Double)] = [(0.502, 0.508), (0.502, 0.547), (0.502, 0.585)]
        for (abYL, _) in abPairs {
            let abY = h * abYL + by
            for side in [-1.0, 1.0] {
                let cx = w * (0.500 + side * 0.082)
                ellipse(ctx: ctx, cx: cx, cy: abY, rx: w*0.060, ry: h*0.026, color: skinLt.opacity(0.16))
                ellipse(ctx: ctx, cx: cx, cy: abY + h*0.016, rx: w*0.048, ry: h*0.014,
                        color: skinDk.opacity(0.20))
            }
        }
        for i in 0..<3 {
            var abLine = Path()
            abLine.move(to: CGPoint(x: w*0.35, y: h*(0.524 + Double(i)*0.038)+by))
            abLine.addLine(to: CGPoint(x: w*0.65, y: h*(0.524 + Double(i)*0.038)+by))
            ctx.stroke(abLine, with: .color(skinDk.opacity(0.25)), lineWidth: w*0.007)
        }

        // Belt
        rect(ctx: ctx, x: w*0.31, y: h*0.625+by, w: w*0.38, h: h*0.038, color: leatherD)
        for i in 0..<6 {
            ellipse(ctx: ctx, cx: w*(0.335 + Double(i)*0.062), cy: h*0.644+by,
                    rx: w*0.009, ry: w*0.009, color: metal)
        }
        rect(ctx: ctx, x: w*0.438, y: h*0.621+by, w: w*0.124, h: h*0.046, color: goldCol.opacity(0.88), cr: w*0.008)
        rect(ctx: ctx, x: w*0.458, y: h*0.629+by, w: w*0.084, h: h*0.030, color: .black.opacity(0.38), cr: w*0.005)

        // --- Fur pauldrons with metal caps ---
        // Left pauldron
        ellipse(ctx: ctx, cx: w*0.180, cy: h*0.380+by, rx: w*0.130, ry: w*0.100, color: fur)
        for i in 0..<5 {
            let fy = h * (0.338 + Double(i) * 0.030) + by
            var fs = Path()
            fs.move(to: CGPoint(x: w*0.068, y: fy))
            fs.addQuadCurve(to: CGPoint(x: w*0.295, y: fy + h*0.010),
                            control: CGPoint(x: w*0.182, y: fy - h*0.007))
            ctx.stroke(fs, with: .color(furL.opacity(0.42)), lineWidth: w*0.016)
        }
        ellipse(ctx: ctx, cx: w*0.180, cy: h*0.358+by, rx: w*0.086, ry: w*0.062, color: metalD)
        rect(ctx: ctx, x: w*0.104, y: h*0.346+by, w: w*0.152, h: h*0.006, color: metal)
        ellipse(ctx: ctx, cx: w*0.180, cy: h*0.364+by, rx: w*0.038, ry: w*0.028, color: metal)
        ellipse(ctx: ctx, cx: w*0.162, cy: h*0.350+by, rx: w*0.026, ry: w*0.016, color: metalL.opacity(0.38))

        // Right pauldron
        ellipse(ctx: ctx, cx: w*0.820, cy: h*0.380+by, rx: w*0.130, ry: w*0.100, color: fur)
        for i in 0..<5 {
            let fy = h * (0.338 + Double(i) * 0.030) + by
            var fs = Path()
            fs.move(to: CGPoint(x: w*0.705, y: fy))
            fs.addQuadCurve(to: CGPoint(x: w*0.932, y: fy + h*0.010),
                            control: CGPoint(x: w*0.818, y: fy - h*0.007))
            ctx.stroke(fs, with: .color(furL.opacity(0.42)), lineWidth: w*0.016)
        }
        ellipse(ctx: ctx, cx: w*0.820, cy: h*0.358+by, rx: w*0.086, ry: w*0.062, color: metalD)
        rect(ctx: ctx, x: w*0.744, y: h*0.346+by, w: w*0.152, h: h*0.006, color: metal)
        ellipse(ctx: ctx, cx: w*0.820, cy: h*0.364+by, rx: w*0.038, ry: w*0.028, color: metal)
        ellipse(ctx: ctx, cx: w*0.802, cy: h*0.350+by, rx: w*0.026, ry: w*0.016, color: metalL.opacity(0.38))

        // --- Left arm (bare, muscular) ---
        rect(ctx: ctx, x: w*0.138, y: h*0.44+by, w: w*0.118, h: h*0.162, color: skin, cr: w*0.036)
        rect(ctx: ctx, x: w*0.152, y: h*0.454+by, w: w*0.050, h: h*0.082, color: skinLt.opacity(0.22), cr: w*0.018)
        rect(ctx: ctx, x: w*0.212, y: h*0.458+by, w: w*0.032, h: h*0.100, color: skinDk.opacity(0.28), cr: w*0.014)
        rect(ctx: ctx, x: w*0.148, y: h*0.588+by, w: w*0.104, h: h*0.122, color: skin, cr: w*0.024)
        // Vein
        var vein = Path()
        vein.move(to: CGPoint(x: w*0.176, y: h*0.600+by))
        vein.addQuadCurve(to: CGPoint(x: w*0.188, y: h*0.696+by),
                          control: CGPoint(x: w*0.162, y: h*0.648+by))
        ctx.stroke(vein, with: .color(skinDk.opacity(0.38)), lineWidth: w*0.007)
        // Left bracer
        rect(ctx: ctx, x: w*0.140, y: h*0.696+by, w: w*0.120, h: h*0.040, color: leatherD, cr: w*0.008)
        rect(ctx: ctx, x: w*0.148, y: h*0.698+by, w: w*0.104, h: h*0.005, color: metal)
        rect(ctx: ctx, x: w*0.148, y: h*0.727+by, w: w*0.104, h: h*0.005, color: metal)
        // Left fist
        ellipse(ctx: ctx, cx: w*0.200, cy: h*0.766+by, rx: w*0.064, ry: w*0.052, color: skin)
        ellipse(ctx: ctx, cx: w*0.180, cy: h*0.756+by, rx: w*0.028, ry: w*0.020, color: skinLt.opacity(0.28))

        // --- Axe (right hand, rotating from grip) ---
        let axeGX = w * 0.792
        let axeGY = h * 0.572 + by
        ctx.drawLayer { layer in
            layer.translateBy(x: axeGX, y: axeGY)
            layer.rotate(by: .radians(axeSway))
            layer.translateBy(x: -axeGX, y: -axeGY)

            // Wooden handle with grain
            rect(ctx: layer, x: w*0.764, y: h*0.210+by, w: w*0.056, h: h*0.560,
                 color: Color(red: 0.30, green: 0.18, blue: 0.08), cr: w*0.010)
            for i in 0..<6 {
                var grain = Path()
                grain.move(to: CGPoint(x: w*0.767, y: h*(0.248 + Double(i)*0.082)+by))
                grain.addLine(to: CGPoint(x: w*0.817, y: h*(0.248 + Double(i)*0.082)+by))
                layer.stroke(grain, with: .color(Color(red: 0.20, green: 0.11, blue: 0.04).opacity(0.45)),
                             lineWidth: w*0.005)
            }
            // Leather grip wraps (lower half of handle)
            for i in 0..<5 {
                rect(ctx: layer, x: w*0.762, y: h*(0.510 + Double(i)*0.024)+by,
                     w: w*0.060, h: h*0.016, color: leatherD.opacity(0.78))
            }

            // Top spike
            var spike = Path()
            spike.move(to: CGPoint(x: w*0.776, y: h*0.214+by))
            spike.addLine(to: CGPoint(x: w*0.792, y: h*0.168+by))
            spike.addLine(to: CGPoint(x: w*0.808, y: h*0.214+by))
            spike.closeSubpath()
            layer.fill(spike, with: .color(metal))
            layer.stroke(spike, with: .color(metalL.opacity(0.55)), lineWidth: w*0.007)

            // Upper axe blade
            var upperBlade = Path()
            upperBlade.move(to: CGPoint(x: w*0.764, y: h*0.224+by))
            upperBlade.addLine(to: CGPoint(x: w*0.552, y: h*0.192+by))
            upperBlade.addQuadCurve(to: CGPoint(x: w*0.572, y: h*0.368+by),
                                    control: CGPoint(x: w*0.482, y: h*0.288+by))
            upperBlade.addLine(to: CGPoint(x: w*0.820, y: h*0.368+by))
            upperBlade.closeSubpath()
            layer.fill(upperBlade, with: .color(metal))

            // Upper blade bevel (sharp edge highlight)
            var ubevel = Path()
            ubevel.move(to: CGPoint(x: w*0.552, y: h*0.192+by))
            ubevel.addQuadCurve(to: CGPoint(x: w*0.572, y: h*0.368+by),
                                control: CGPoint(x: w*0.482, y: h*0.288+by))
            layer.stroke(ubevel, with: .color(metalL.opacity(0.65)), lineWidth: w*0.018)

            // Surface shading on upper blade
            var ubShade = Path()
            ubShade.move(to: CGPoint(x: w*0.764, y: h*0.224+by))
            ubShade.addLine(to: CGPoint(x: w*0.650, y: h*0.210+by))
            ubShade.addLine(to: CGPoint(x: w*0.660, y: h*0.368+by))
            ubShade.addLine(to: CGPoint(x: w*0.820, y: h*0.368+by))
            ubShade.closeSubpath()
            layer.fill(ubShade, with: .color(metalD.opacity(0.22)))

            // Blood on blade edge
            ellipse(ctx: layer, cx: w*0.532, cy: h*0.312+by, rx: w*0.026, ry: w*0.018,
                    color: blood.opacity(0.58))
            ellipse(ctx: layer, cx: w*0.548, cy: h*0.294+by, rx: w*0.014, ry: w*0.010,
                    color: blood.opacity(0.44))

            // Lower axe blade
            var lowerBlade = Path()
            lowerBlade.move(to: CGPoint(x: w*0.820, y: h*0.368+by))
            lowerBlade.addLine(to: CGPoint(x: w*0.572, y: h*0.368+by))
            lowerBlade.addQuadCurve(to: CGPoint(x: w*0.584, y: h*0.454+by),
                                    control: CGPoint(x: w*0.506, y: h*0.412+by))
            lowerBlade.addLine(to: CGPoint(x: w*0.764, y: h*0.454+by))
            lowerBlade.closeSubpath()
            layer.fill(lowerBlade, with: .color(metal.opacity(0.78)))
            var lbevel = Path()
            lbevel.move(to: CGPoint(x: w*0.572, y: h*0.368+by))
            lbevel.addQuadCurve(to: CGPoint(x: w*0.584, y: h*0.454+by),
                                control: CGPoint(x: w*0.506, y: h*0.412+by))
            layer.stroke(lbevel, with: .color(metalL.opacity(0.55)), lineWidth: w*0.016)

            // Axe boss (center disc)
            ellipse(ctx: layer, cx: w*0.792, cy: h*0.338+by, rx: w*0.044, ry: w*0.044, color: metalD)
            ellipse(ctx: layer, cx: w*0.792, cy: h*0.338+by, rx: w*0.022, ry: w*0.022, color: metal)
            ellipse(ctx: layer, cx: w*0.784, cy: h*0.330+by, rx: w*0.010, ry: w*0.008, color: metalL.opacity(0.58))
        }

        // --- Right arm (holding axe) ---
        rect(ctx: ctx, x: w*0.742, y: h*0.44+by, w: w*0.118, h: h*0.162, color: skin, cr: w*0.036)
        rect(ctx: ctx, x: w*0.752, y: h*0.454+by, w: w*0.050, h: h*0.082, color: skinLt.opacity(0.20), cr: w*0.018)
        rect(ctx: ctx, x: w*0.742, y: h*0.588+by, w: w*0.104, h: h*0.122, color: skin, cr: w*0.024)
        rect(ctx: ctx, x: w*0.740, y: h*0.696+by, w: w*0.120, h: h*0.040, color: leatherD, cr: w*0.008)
        rect(ctx: ctx, x: w*0.748, y: h*0.698+by, w: w*0.104, h: h*0.005, color: metal)
        rect(ctx: ctx, x: w*0.748, y: h*0.727+by, w: w*0.104, h: h*0.005, color: metal)
        ellipse(ctx: ctx, cx: w*0.794, cy: h*0.762+by, rx: w*0.060, ry: w*0.050, color: skin)

        // --- Neck ---
        ellipse(ctx: ctx, cx: w*0.500, cy: h*0.344+by, rx: w*0.080, ry: w*0.038, color: skinDk.opacity(0.28))
        var neck = Path()
        neck.move(to: CGPoint(x: w*0.438, y: h*0.330+by))
        neck.addLine(to: CGPoint(x: w*0.562, y: h*0.330+by))
        neck.addLine(to: CGPoint(x: w*0.552, y: h*0.378+by))
        neck.addLine(to: CGPoint(x: w*0.448, y: h*0.378+by))
        neck.closeSubpath()
        ctx.fill(neck, with: .color(skin))
        var neckS = Path()
        neckS.move(to: CGPoint(x: w*0.528, y: h*0.330+by))
        neckS.addLine(to: CGPoint(x: w*0.562, y: h*0.330+by))
        neckS.addLine(to: CGPoint(x: w*0.552, y: h*0.378+by))
        neckS.addLine(to: CGPoint(x: w*0.524, y: h*0.378+by))
        neckS.closeSubpath()
        ctx.fill(neckS, with: .color(skinDk.opacity(0.32)))

        // --- Head (angled jaw) ---
        var head = Path()
        head.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by),
                    radius: w*0.150, startAngle: .degrees(-180), endAngle: .degrees(0),
                    clockwise: false)
        head.addLine(to: CGPoint(x: w*0.640, y: h*0.318+by))
        head.addLine(to: CGPoint(x: w*0.598, y: h*0.340+by))
        head.addLine(to: CGPoint(x: w*0.500, y: h*0.352+by))
        head.addLine(to: CGPoint(x: w*0.402, y: h*0.340+by))
        head.addLine(to: CGPoint(x: w*0.360, y: h*0.318+by))
        head.closeSubpath()
        ctx.fill(head, with: .color(skin))

        // Cheek shadow (right side)
        var cheekS = Path()
        cheekS.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by),
                      radius: w*0.150, startAngle: .degrees(-28), endAngle: .degrees(0),
                      clockwise: false)
        cheekS.addLine(to: CGPoint(x: w*0.640, y: h*0.318+by))
        cheekS.addLine(to: CGPoint(x: w*0.618, y: h*0.256+by))
        cheekS.closeSubpath()
        ctx.fill(cheekS, with: .color(skinDk.opacity(0.24)))

        // Brow ridge shadow
        ellipse(ctx: ctx, cx: w*0.500, cy: h*0.216+by, rx: w*0.112, ry: w*0.024, color: skinDk.opacity(0.38))
        // Nose bridge
        rect(ctx: ctx, x: w*0.480, y: h*0.240+by, w: w*0.040, h: h*0.048, color: skinDk.opacity(0.18), cr: w*0.010)
        // Cheekbone highlights
        ellipse(ctx: ctx, cx: w*0.408, cy: h*0.246+by, rx: w*0.046, ry: w*0.022, color: skinLt.opacity(0.26))
        ellipse(ctx: ctx, cx: w*0.592, cy: h*0.246+by, rx: w*0.046, ry: w*0.022, color: skinLt.opacity(0.26))
        // Forehead highlight
        ellipse(ctx: ctx, cx: w*0.480, cy: h*0.168+by, rx: w*0.052, ry: w*0.026, color: skinLt.opacity(0.20))

        // --- Hair (wild curving strands) ---
        let strandAngles: [Double] = [-1.92, -1.58, -1.24, -0.88, -0.52, -0.22]
        let strandWidths: [Double] = [0.036, 0.030, 0.028, 0.026, 0.024, 0.022]
        let strandLens:   [Double] = [0.12,  0.14,  0.13,  0.11,  0.10,  0.09 ]
        let strandPhases: [Double] = [0.55,  0.12,  0.42,  0.72,  0.90,  1.10 ]
        for i in strandAngles.indices {
            let angle = strandAngles[i]
            let lw    = strandWidths[i]
            let len   = strandLens[i]
            let phase = strandPhases[i]
            let sway = sin(t * (0.55 + phase * 0.10) + phase) * 0.05
            let sx = w*0.500 + cos(angle + .pi) * w * 0.126
            let sy = h*0.152 + by + sin(angle + .pi) * h * 0.076
            let tx = sx + cos(angle + sway) * w * len
            let ty = sy + sin(angle + sway) * h * len * 1.22
            let mx = (sx + tx) / 2 + sin(t * 0.8 + phase) * w * 0.018
            var hp = Path()
            hp.move(to: CGPoint(x: sx, y: sy))
            hp.addQuadCurve(to: CGPoint(x: tx, y: ty), control: CGPoint(x: mx, y: (sy + ty) / 2))
            ctx.stroke(hp, with: .color(hair), lineWidth: w * lw)
        }
        // Hair highlight strands
        for i in 0..<3 {
            let angle = -1.72 + Double(i) * 0.44
            let sx = w*0.500 + cos(angle + .pi) * w * 0.096
            let sy = h*0.144 + by + sin(angle + .pi) * h * 0.058
            var hp = Path()
            hp.move(to: CGPoint(x: sx, y: sy))
            hp.addLine(to: CGPoint(x: sx + cos(angle) * w*0.072, y: sy + sin(angle) * h*0.072))
            ctx.stroke(hp, with: .color(hairL.opacity(0.38)), lineWidth: w*0.016)
        }

        // --- Helmet (battle-worn iron cap) ---
        var helm = Path()
        helm.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by),
                    radius: w*0.152, startAngle: .degrees(-182), endAngle: .degrees(6),
                    clockwise: false)
        helm.addLine(to: CGPoint(x: w*0.640, y: h*0.258+by))
        helm.addLine(to: CGPoint(x: w*0.350, y: h*0.258+by))
        helm.closeSubpath()
        ctx.fill(helm, with: .color(metalD))

        // Helmet surface sheen
        var helmHL = Path()
        helmHL.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by), radius: w*0.152,
                      startAngle: .degrees(-158), endAngle: .degrees(-74), clockwise: false)
        ctx.stroke(helmHL, with: .color(metalL.opacity(0.20)), lineWidth: w*0.048)

        // Rim band
        rect(ctx: ctx, x: w*0.348, y: h*0.252+by, w: w*0.304, h: h*0.015, color: metal)
        rect(ctx: ctx, x: w*0.352, y: h*0.252+by, w: w*0.296, h: h*0.006, color: metalL.opacity(0.46))

        // Battle dent
        var dent = Path()
        dent.move(to: CGPoint(x: w*0.572, y: h*0.166+by))
        dent.addLine(to: CGPoint(x: w*0.606, y: h*0.174+by))
        dent.addLine(to: CGPoint(x: w*0.596, y: h*0.190+by))
        ctx.stroke(dent, with: .color(metalD.opacity(0.68)), lineWidth: w*0.011)

        // Nasal guard
        var nasal = Path()
        nasal.move(to: CGPoint(x: w*0.477, y: h*0.252+by))
        nasal.addLine(to: CGPoint(x: w*0.523, y: h*0.252+by))
        nasal.addLine(to: CGPoint(x: w*0.512, y: h*0.302+by))
        nasal.addLine(to: CGPoint(x: w*0.488, y: h*0.302+by))
        nasal.closeSubpath()
        ctx.fill(nasal, with: .color(metalD))
        rect(ctx: ctx, x: w*0.483, y: h*0.254+by, w: w*0.011, h: h*0.044, color: metalL.opacity(0.28))

        // --- Beard (thick chunky strands) ---
        let beardXs: [Double] = [0.372, 0.410, 0.450, 0.500, 0.548, 0.588]
        for (i, bx) in beardXs.enumerated() {
            let phase = sin(t * 0.60 + Double(i) * 0.55) * 0.016
            let ctrl = bx + (i % 2 == 0 ? -0.014 : 0.014)
            var bp = Path()
            bp.move(to: CGPoint(x: w*bx, y: h*0.320+by))
            bp.addQuadCurve(
                to: CGPoint(x: w*(bx + phase), y: h*0.418+by),
                control: CGPoint(x: w*ctrl, y: h*0.370+by)
            )
            ctx.stroke(bp, with: .color(hair), lineWidth: w*0.028)
        }
        for i in 0..<3 {
            let bx = w * (0.406 + Double(i) * 0.086)
            var hl = Path()
            hl.move(to: CGPoint(x: bx, y: h*0.325+by))
            hl.addLine(to: CGPoint(x: bx + w*0.004, y: h*0.400+by))
            ctx.stroke(hl, with: .color(hairL.opacity(0.34)), lineWidth: w*0.011)
        }

        // --- War paint ---
        // Red diagonal stripe across right eye area
        var paint = Path()
        paint.move(to: CGPoint(x: w*0.532, y: h*0.220+by))
        paint.addLine(to: CGPoint(x: w*0.608, y: h*0.260+by))
        ctx.stroke(paint, with: .color(warpaint.opacity(0.72)), lineWidth: w*0.017)
        // Three dots on left cheek
        for i in 0..<3 {
            ellipse(ctx: ctx, cx: w*(0.354 + Double(i)*0.016),
                    cy: h*(0.268 + Double(i)*0.020)+by,
                    rx: w*0.009, ry: w*0.009, color: warpaint.opacity(0.62))
        }

        // Jaw scar
        var scar = Path()
        scar.move(to: CGPoint(x: w*0.410, y: h*0.308+by))
        scar.addLine(to: CGPoint(x: w*0.434, y: h*0.326+by))
        ctx.stroke(scar, with: .color(skinDk.opacity(0.52)), lineWidth: w*0.008)

        // --- Eyes (socket shadow + whites + fire glow) ---
        ellipse(ctx: ctx, cx: w*0.428, cy: h*0.258+by, rx: w*0.048, ry: w*0.026, color: skinDk.opacity(0.44))
        ellipse(ctx: ctx, cx: w*0.572, cy: h*0.258+by, rx: w*0.048, ry: w*0.026, color: skinDk.opacity(0.44))
        ellipse(ctx: ctx, cx: w*0.428, cy: h*0.257+by, rx: w*0.030, ry: w*0.017,
                color: Color(red: 0.90, green: 0.86, blue: 0.80))
        ellipse(ctx: ctx, cx: w*0.572, cy: h*0.257+by, rx: w*0.030, ry: w*0.017,
                color: Color(red: 0.90, green: 0.86, blue: 0.80))
        glow(ctx: ctx, cx: w*0.428, cy: h*0.257+by, r: w*0.017, color: eyeCol.opacity(eyeG))
        glow(ctx: ctx, cx: w*0.572, cy: h*0.257+by, r: w*0.017, color: eyeCol.opacity(eyeG))
    }

    // MARK: - Rogue

    private static func drawRogue(ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height

        let by   = sin(t * 1.40) * h * 0.012
        let eyeG = 0.50 + sin(t * 1.80) * 0.50
        let hemS = sin(t * 0.65) * w * 0.014

        let cloak   = Color(red: 0.09, green: 0.06, blue: 0.18)
        let cloakLt = Color(red: 0.20, green: 0.14, blue: 0.36)
        let shadow  = Color(red: 0.03, green: 0.02, blue: 0.08)
        let leather = Color(red: 0.16, green: 0.10, blue: 0.07)
        let silver  = Color(red: 0.60, green: 0.60, blue: 0.66)
        let eyeCol  = Color(red: 0.12, green: 0.88, blue: 0.68)

        // Cloak body
        var cloakPath = Path()
        cloakPath.move(to: CGPoint(x: w*0.38, y: h*0.31+by))
        cloakPath.addLine(to: CGPoint(x: w*0.62, y: h*0.31+by))
        cloakPath.addQuadCurve(to: CGPoint(x: w*0.84+hemS, y: h*0.87+by),
                               control: CGPoint(x: w*0.88, y: h*0.58+by))
        cloakPath.addQuadCurve(to: CGPoint(x: w*0.16-hemS, y: h*0.87+by),
                               control: CGPoint(x: w*0.50, y: h*0.95+by))
        cloakPath.addQuadCurve(to: CGPoint(x: w*0.38, y: h*0.31+by),
                               control: CGPoint(x: w*0.12, y: h*0.58+by))
        ctx.fill(cloakPath, with: .color(cloak))

        // Cloak inner fold (darker center)
        var inner = Path()
        inner.move(to: CGPoint(x: w*0.42, y: h*0.33+by))
        inner.addLine(to: CGPoint(x: w*0.58, y: h*0.33+by))
        inner.addQuadCurve(to: CGPoint(x: w*0.60, y: h*0.84+by),
                           control: CGPoint(x: w*0.70, y: h*0.60+by))
        inner.addQuadCurve(to: CGPoint(x: w*0.40, y: h*0.84+by),
                           control: CGPoint(x: w*0.50, y: h*0.92+by))
        inner.addQuadCurve(to: CGPoint(x: w*0.42, y: h*0.33+by),
                           control: CGPoint(x: w*0.30, y: h*0.60+by))
        ctx.fill(inner, with: .color(shadow.opacity(0.50)))

        // Edge trims
        var lEdge = Path()
        lEdge.move(to: CGPoint(x: w*0.38, y: h*0.31+by))
        lEdge.addQuadCurve(to: CGPoint(x: w*0.16-hemS, y: h*0.87+by),
                           control: CGPoint(x: w*0.12, y: h*0.58+by))
        ctx.stroke(lEdge, with: .color(cloakLt.opacity(0.55)), lineWidth: w*0.014)

        var rEdge = Path()
        rEdge.move(to: CGPoint(x: w*0.62, y: h*0.31+by))
        rEdge.addQuadCurve(to: CGPoint(x: w*0.84+hemS, y: h*0.87+by),
                           control: CGPoint(x: w*0.88, y: h*0.58+by))
        ctx.stroke(rEdge, with: .color(cloakLt.opacity(0.55)), lineWidth: w*0.014)

        var hem = Path()
        hem.move(to: CGPoint(x: w*0.16-hemS, y: h*0.87+by))
        hem.addQuadCurve(to: CGPoint(x: w*0.84+hemS, y: h*0.87+by),
                         control: CGPoint(x: w*0.50, y: h*0.95+by))
        ctx.stroke(hem, with: .color(cloakLt.opacity(0.45)), lineWidth: w*0.012)

        // Shoulder clasp
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.33+by, rx: w*0.040, ry: w*0.033,
                color: Color(red: 0.55, green: 0.40, blue: 0.12))
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.33+by, rx: w*0.022, ry: w*0.018,
                color: Color(red: 0.80, green: 0.62, blue: 0.20))

        // Left dagger
        ctx.drawLayer { layer in
            let px = w * 0.30; let py = h * 0.58 + by
            layer.translateBy(x: px, y: py)
            layer.rotate(by: .degrees(-38))
            layer.translateBy(x: -px, y: -py)

            var bl = Path()
            bl.move(to: CGPoint(x: w*0.285, y: h*0.495+by))
            bl.addLine(to: CGPoint(x: w*0.315, y: h*0.495+by))
            bl.addLine(to: CGPoint(x: w*0.300, y: h*0.660+by))
            bl.closeSubpath()
            layer.fill(bl, with: .color(silver))

            var eg = Path()
            eg.move(to: CGPoint(x: w*0.300, y: h*0.495+by))
            eg.addLine(to: CGPoint(x: w*0.300, y: h*0.660+by))
            layer.stroke(eg, with: .color(eyeCol.opacity(0.40)), lineWidth: w*0.010)

            rect(ctx: layer, x: w*0.264, y: h*0.510+by, w: w*0.072, h: h*0.022, color: leather)
            rect(ctx: layer, x: w*0.284, y: h*0.530+by, w: w*0.032, h: h*0.048,
                 color: leather, cr: w*0.008)
        }

        // Right dagger
        ctx.drawLayer { layer in
            let px = w * 0.70; let py = h * 0.58 + by
            layer.translateBy(x: px, y: py)
            layer.rotate(by: .degrees(38))
            layer.translateBy(x: -px, y: -py)

            var bl = Path()
            bl.move(to: CGPoint(x: w*0.685, y: h*0.495+by))
            bl.addLine(to: CGPoint(x: w*0.715, y: h*0.495+by))
            bl.addLine(to: CGPoint(x: w*0.700, y: h*0.660+by))
            bl.closeSubpath()
            layer.fill(bl, with: .color(silver))

            var eg = Path()
            eg.move(to: CGPoint(x: w*0.700, y: h*0.495+by))
            eg.addLine(to: CGPoint(x: w*0.700, y: h*0.660+by))
            layer.stroke(eg, with: .color(eyeCol.opacity(0.40)), lineWidth: w*0.010)

            rect(ctx: layer, x: w*0.664, y: h*0.510+by, w: w*0.072, h: h*0.022, color: leather)
            rect(ctx: layer, x: w*0.684, y: h*0.530+by, w: w*0.032, h: h*0.048,
                 color: leather, cr: w*0.008)
        }

        // Hood
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.210+by, rx: w*0.205, ry: w*0.185, color: cloak)
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.240+by, rx: w*0.148, ry: w*0.138, color: shadow)

        var hoodRim = Path()
        hoodRim.addArc(center: CGPoint(x: w*0.50, y: h*0.210+by),
                       radius: w*0.205,
                       startAngle: .degrees(-200), endAngle: .degrees(-10),
                       clockwise: false)
        ctx.stroke(hoodRim, with: .color(cloakLt.opacity(0.45)), lineWidth: w*0.016)

        // Eyes
        glow(ctx: ctx, cx: w*0.435, cy: h*0.245+by, r: w*0.020, color: eyeCol.opacity(eyeG))
        glow(ctx: ctx, cx: w*0.565, cy: h*0.245+by, r: w*0.020, color: eyeCol.opacity(eyeG))
    }

    // MARK: - Sorceress

    private static func drawSorceress(ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height

        let by       = sin(t * 1.10) * h * 0.018
        let eyeG     = 0.55 + sin(t * 2.40) * 0.45
        let orbPulse = 0.88 + sin(t * 3.20) * 0.12
        let hairSway = sin(t * 0.60) * w * 0.022

        let robe    = Color(red: 0.09, green: 0.06, blue: 0.26)
        let robeLt  = Color(red: 0.28, green: 0.16, blue: 0.58)
        let skinCol = Color(red: 0.84, green: 0.78, blue: 0.74)
        let hairCol = Color(red: 0.10, green: 0.07, blue: 0.20)
        let eyeCol  = Color(red: 0.70, green: 0.35, blue: 1.00)
        let staffCol = Color(red: 0.28, green: 0.20, blue: 0.12)
        let orbCol  = Color(red: 0.36, green: 0.16, blue: 1.00)

        // Staff
        rect(ctx: ctx, x: w*0.210, y: h*0.10+by, w: w*0.038, h: h*0.76,
             color: staffCol, cr: w*0.008)
        rect(ctx: ctx, x: w*0.208, y: h*0.83+by, w: w*0.042, h: h*0.040,
             color: Color(red: 0.48, green: 0.36, blue: 0.18), cr: w*0.006)

        let orbR = w * 0.062 * orbPulse
        glow(ctx: ctx, cx: w*0.229, cy: h*0.094+by, r: orbR, color: orbCol)
        ellipse(ctx: ctx, cx: w*0.216, cy: h*0.082+by,
                rx: orbR * 0.32, ry: orbR * 0.28, color: .white.opacity(0.35))

        // Robe
        var robePath = Path()
        robePath.move(to: CGPoint(x: w*0.38, y: h*0.37+by))
        robePath.addLine(to: CGPoint(x: w*0.62, y: h*0.37+by))
        robePath.addQuadCurve(to: CGPoint(x: w*0.83, y: h*0.91+by),
                              control: CGPoint(x: w*0.82, y: h*0.64+by))
        robePath.addQuadCurve(to: CGPoint(x: w*0.17, y: h*0.91+by),
                              control: CGPoint(x: w*0.50, y: h*0.98+by))
        robePath.addQuadCurve(to: CGPoint(x: w*0.38, y: h*0.37+by),
                              control: CGPoint(x: w*0.18, y: h*0.64+by))
        ctx.fill(robePath, with: .color(robe))

        // Robe center shading
        var robeCenter = Path()
        robeCenter.move(to: CGPoint(x: w*0.44, y: h*0.39+by))
        robeCenter.addLine(to: CGPoint(x: w*0.56, y: h*0.39+by))
        robeCenter.addQuadCurve(to: CGPoint(x: w*0.58, y: h*0.88+by),
                                control: CGPoint(x: w*0.64, y: h*0.64+by))
        robeCenter.addQuadCurve(to: CGPoint(x: w*0.42, y: h*0.88+by),
                                control: CGPoint(x: w*0.50, y: h*0.95+by))
        robeCenter.addQuadCurve(to: CGPoint(x: w*0.44, y: h*0.39+by),
                                control: CGPoint(x: w*0.36, y: h*0.64+by))
        ctx.fill(robeCenter, with: .color(.black.opacity(0.22)))

        // Robe trim
        var lTrim = Path()
        lTrim.move(to: CGPoint(x: w*0.38, y: h*0.37+by))
        lTrim.addQuadCurve(to: CGPoint(x: w*0.17, y: h*0.91+by),
                           control: CGPoint(x: w*0.18, y: h*0.64+by))
        ctx.stroke(lTrim, with: .color(robeLt.opacity(0.65)), lineWidth: w*0.016)

        var rTrim = Path()
        rTrim.move(to: CGPoint(x: w*0.62, y: h*0.37+by))
        rTrim.addQuadCurve(to: CGPoint(x: w*0.83, y: h*0.91+by),
                           control: CGPoint(x: w*0.82, y: h*0.64+by))
        ctx.stroke(rTrim, with: .color(robeLt.opacity(0.65)), lineWidth: w*0.016)

        var hemTrim = Path()
        hemTrim.move(to: CGPoint(x: w*0.17, y: h*0.91+by))
        hemTrim.addQuadCurve(to: CGPoint(x: w*0.83, y: h*0.91+by),
                             control: CGPoint(x: w*0.50, y: h*0.98+by))
        ctx.stroke(hemTrim, with: .color(robeLt.opacity(0.50)), lineWidth: w*0.013)

        // Belt gem
        rect(ctx: ctx, x: w*0.38, y: h*0.550+by, w: w*0.24, h: h*0.026,
             color: Color(red: 0.44, green: 0.26, blue: 0.78).opacity(0.85), cr: w*0.010)
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.563+by,
                rx: w*0.025, ry: w*0.020, color: eyeCol.opacity(0.75))

        // Neck + head
        rect(ctx: ctx, x: w*0.44, y: h*0.33+by, w: w*0.12, h: h*0.06, color: skinCol, cr: w*0.01)
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.235+by, rx: w*0.130, ry: w*0.145, color: skinCol)

        // Hair
        var lHair = Path()
        lHair.move(to: CGPoint(x: w*0.39, y: h*0.155+by))
        lHair.addQuadCurve(to: CGPoint(x: w*0.265, y: h*0.500+by),
                           control: CGPoint(x: w*0.23-hairSway, y: h*0.340+by))
        ctx.stroke(lHair, with: .color(hairCol), lineWidth: w*0.042)

        var rHair = Path()
        rHair.move(to: CGPoint(x: w*0.61, y: h*0.155+by))
        rHair.addQuadCurve(to: CGPoint(x: w*0.735, y: h*0.500+by),
                           control: CGPoint(x: w*0.77+hairSway, y: h*0.340+by))
        ctx.stroke(rHair, with: .color(hairCol), lineWidth: w*0.042)

        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.145+by, rx: w*0.130, ry: w*0.072, color: hairCol)
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.114+by,
                rx: w*0.020, ry: w*0.018, color: eyeCol.opacity(0.80))

        // Eyebrows
        var lBrow = Path()
        lBrow.addArc(center: CGPoint(x: w*0.43, y: h*0.225+by), radius: w*0.048,
                     startAngle: .degrees(-155), endAngle: .degrees(-30), clockwise: false)
        ctx.stroke(lBrow, with: .color(hairCol.opacity(0.70)), lineWidth: w*0.012)

        var rBrow = Path()
        rBrow.addArc(center: CGPoint(x: w*0.57, y: h*0.225+by), radius: w*0.048,
                     startAngle: .degrees(-150), endAngle: .degrees(-25), clockwise: false)
        ctx.stroke(rBrow, with: .color(hairCol.opacity(0.70)), lineWidth: w*0.012)

        // Lips
        var lips = Path()
        lips.addArc(center: CGPoint(x: w*0.50, y: h*0.294+by), radius: w*0.034,
                    startAngle: .degrees(15), endAngle: .degrees(165), clockwise: false)
        ctx.stroke(lips, with: .color(Color(red: 0.62, green: 0.32, blue: 0.36)),
                   lineWidth: w*0.011)

        // Eyes
        glow(ctx: ctx, cx: w*0.432, cy: h*0.252+by, r: w*0.021, color: eyeCol.opacity(eyeG))
        glow(ctx: ctx, cx: w*0.568, cy: h*0.252+by, r: w*0.021, color: eyeCol.opacity(eyeG))

        // Orbiting particles (6 inner)
        for i in 0..<6 {
            let angle = t * 1.85 + Double(i) * (.pi / 3.0)
            let px = w * 0.50 + cos(angle) * w * 0.34
            let py = h * 0.635 + by + sin(angle) * h * 0.095
            let pr = w * (0.020 + sin(angle * 1.3) * 0.008)
            glow(ctx: ctx, cx: px, cy: py, r: pr,
                 color: orbCol.opacity(0.68 + sin(angle) * 0.28))
        }

        // 2 slower outer particles
        for i in 0..<2 {
            let angle2 = t * 1.05 + Double(i) * .pi
            let px2 = w * 0.50 + cos(angle2) * w * 0.40
            let py2 = h * 0.620 + by + sin(angle2) * h * 0.075
            glow(ctx: ctx, cx: px2, cy: py2, r: w * 0.028, color: eyeCol.opacity(0.58))
        }
    }
}

// MARK: - Preview

#Preview("Barbarian") {
    HStack(spacing: 16) {
        HeroPortraitView(heroClass: .barbarian, size: 180)
        HeroPortraitView(heroClass: .rogue, size: 180)
        HeroPortraitView(heroClass: .sorceress, size: 180)
    }
    .padding(24)
    .background(Color(red: 0.05, green: 0.04, blue: 0.08))
}
