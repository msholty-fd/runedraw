import SwiftUI

extension HeroDrawing {

    static func drawBarbarian(eq: EquipmentVisuals, ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height

        let by       = sin(t * 1.60) * h * 0.013
        let breathe  = 0.50 + sin(t * 1.60) * 0.50
        let eyeG     = 0.65 + sin(t * 2.10) * 0.35
        let axeSway  = sin(t * 0.85) * 0.08

        let skin     = Color(red: 0.68, green: 0.44, blue: 0.29)
        let skinDk   = Color(red: 0.38, green: 0.22, blue: 0.11)
        let skinLt   = Color(red: 0.86, green: 0.62, blue: 0.44)
        let leatherD = Color(red: 0.13, green: 0.07, blue: 0.02)
        let leather  = Color(red: 0.24, green: 0.14, blue: 0.07)
        let leatherL = Color(red: 0.38, green: 0.24, blue: 0.11)
        let metalD   = Color(red: 0.18, green: 0.16, blue: 0.14)
        let metal    = Color(red: 0.46, green: 0.44, blue: 0.40)
        let metalL   = Color(red: 0.78, green: 0.76, blue: 0.70)
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

        // --- Legs ---
        var lLeg = Path()
        lLeg.move(to: CGPoint(x: w*0.31, y: h*0.64+by))
        lLeg.addLine(to: CGPoint(x: w*0.47, y: h*0.64+by))
        lLeg.addLine(to: CGPoint(x: w*0.46, y: h*0.84+by))
        lLeg.addLine(to: CGPoint(x: w*0.30, y: h*0.84+by))
        lLeg.closeSubpath()
        ctx.fill(lLeg, with: .linearGradient(
            Gradient(colors: [leatherL, leather, leatherD]),
            startPoint: CGPoint(x: w*0.31, y: h*0.64+by),
            endPoint:   CGPoint(x: w*0.46, y: h*0.84+by)
        ))

        var rLeg = Path()
        rLeg.move(to: CGPoint(x: w*0.53, y: h*0.64+by))
        rLeg.addLine(to: CGPoint(x: w*0.69, y: h*0.64+by))
        rLeg.addLine(to: CGPoint(x: w*0.70, y: h*0.84+by))
        rLeg.addLine(to: CGPoint(x: w*0.54, y: h*0.84+by))
        rLeg.closeSubpath()
        ctx.fill(rLeg, with: .linearGradient(
            Gradient(colors: [leatherL, leather, leatherD]),
            startPoint: CGPoint(x: w*0.53, y: h*0.64+by),
            endPoint:   CGPoint(x: w*0.70, y: h*0.84+by)
        ))

        var lLegS = Path()
        lLegS.move(to: CGPoint(x: w*0.43, y: h*0.64+by))
        lLegS.addLine(to: CGPoint(x: w*0.47, y: h*0.64+by))
        lLegS.addLine(to: CGPoint(x: w*0.46, y: h*0.84+by))
        lLegS.addLine(to: CGPoint(x: w*0.43, y: h*0.84+by))
        lLegS.closeSubpath()
        ctx.fill(lLegS, with: .color(.black.opacity(0.28)))

        var rLegS = Path()
        rLegS.move(to: CGPoint(x: w*0.65, y: h*0.64+by))
        rLegS.addLine(to: CGPoint(x: w*0.69, y: h*0.64+by))
        rLegS.addLine(to: CGPoint(x: w*0.70, y: h*0.84+by))
        rLegS.addLine(to: CGPoint(x: w*0.66, y: h*0.84+by))
        rLegS.closeSubpath()
        ctx.fill(rLegS, with: .color(.black.opacity(0.28)))

        ellipseGrad(ctx: ctx, cx: w*0.385, cy: h*0.822+by, rx: w*0.058, ry: w*0.038, top: skinLt, bottom: skin)
        ellipse(ctx: ctx, cx: w*0.385, cy: h*0.814+by, rx: w*0.035, ry: w*0.020, color: skinLt.opacity(0.30))
        ellipseGrad(ctx: ctx, cx: w*0.615, cy: h*0.822+by, rx: w*0.058, ry: w*0.038, top: skinLt, bottom: skin)
        ellipse(ctx: ctx, cx: w*0.615, cy: h*0.814+by, rx: w*0.035, ry: w*0.020, color: skinLt.opacity(0.30))

        // Greaves
        rectGrad(ctx: ctx, x: w*0.298, y: h*0.832+by, w: w*0.154, h: h*0.096, top: metal, bottom: metalD, cr: w*0.014)
        rect(ctx: ctx, x: w*0.308, y: h*0.834+by, w: w*0.134, h: h*0.006, color: metalL.opacity(0.55))
        rect(ctx: ctx, x: w*0.316, y: h*0.845+by, w: w*0.046, h: h*0.056, color: metalL.opacity(0.12), cr: w*0.005)
        rectGrad(ctx: ctx, x: w*0.548, y: h*0.832+by, w: w*0.154, h: h*0.096, top: metal, bottom: metalD, cr: w*0.014)
        rect(ctx: ctx, x: w*0.558, y: h*0.834+by, w: w*0.134, h: h*0.006, color: metalL.opacity(0.55))
        rect(ctx: ctx, x: w*0.566, y: h*0.845+by, w: w*0.046, h: h*0.056, color: metalL.opacity(0.12), cr: w*0.005)

        // Boots
        rectGrad(ctx: ctx, x: w*0.282, y: h*0.920+by, w: w*0.178, h: h*0.068, top: leather, bottom: leatherD, cr: w*0.018)
        rect(ctx: ctx, x: w*0.294, y: h*0.926+by, w: w*0.064, h: h*0.022, color: leatherL.opacity(0.16), cr: w*0.006)
        rectGrad(ctx: ctx, x: w*0.540, y: h*0.920+by, w: w*0.178, h: h*0.068, top: leather, bottom: leatherD, cr: w*0.018)
        rect(ctx: ctx, x: w*0.552, y: h*0.926+by, w: w*0.064, h: h*0.022, color: leatherL.opacity(0.16), cr: w*0.006)

        // --- Torso ---
        var torso = Path()
        torso.move(to: CGPoint(x: w*0.20, y: h*0.36+by))
        torso.addLine(to: CGPoint(x: w*0.80, y: h*0.36+by))
        torso.addLine(to: CGPoint(x: w*0.69, y: h*0.65+by))
        torso.addLine(to: CGPoint(x: w*0.31, y: h*0.65+by))
        torso.closeSubpath()

        switch eq.chest {
        case .none:
            ctx.fill(torso, with: .linearGradient(
                Gradient(colors: [skinLt, skin, skinDk]),
                startPoint: CGPoint(x: w*0.20, y: h*0.36+by),
                endPoint:   CGPoint(x: w*0.80, y: h*0.65+by)
            ))
            var torsoRS = Path()
            torsoRS.move(to: CGPoint(x: w*0.62, y: h*0.36+by))
            torsoRS.addLine(to: CGPoint(x: w*0.80, y: h*0.36+by))
            torsoRS.addLine(to: CGPoint(x: w*0.69, y: h*0.65+by))
            torsoRS.addLine(to: CGPoint(x: w*0.61, y: h*0.65+by))
            torsoRS.closeSubpath()
            ctx.fill(torsoRS, with: .color(skinDk.opacity(0.32)))
            var sternum = Path()
            sternum.move(to: CGPoint(x: w*0.50, y: h*0.37+by))
            sternum.addLine(to: CGPoint(x: w*0.50, y: h*0.64+by))
            ctx.stroke(sternum, with: .color(skinDk.opacity(0.38)), lineWidth: w*0.009)
            let pW = w * (0.150 + breathe * 0.010)
            let pH = h * (0.082 + breathe * 0.006)
            ellipse(ctx: ctx, cx: w*0.382, cy: h*0.445+by, rx: pW, ry: pH, color: skinLt.opacity(0.22))
            ellipse(ctx: ctx, cx: w*0.618, cy: h*0.445+by, rx: pW, ry: pH, color: skinLt.opacity(0.22))
            ellipse(ctx: ctx, cx: w*0.382, cy: h*0.478+by, rx: pW*0.78, ry: pH*0.34, color: skinDk.opacity(0.28))
            ellipse(ctx: ctx, cx: w*0.618, cy: h*0.478+by, rx: pW*0.78, ry: pH*0.34, color: skinDk.opacity(0.28))
            for (abYL, _) in [(0.502, 0.508), (0.502, 0.547), (0.502, 0.585)] as [(Double, Double)] {
                let abY = h * abYL + by
                for side in [-1.0, 1.0] {
                    let cx = w * (0.500 + side * 0.082)
                    ellipse(ctx: ctx, cx: cx, cy: abY, rx: w*0.060, ry: h*0.026, color: skinLt.opacity(0.14))
                    ellipse(ctx: ctx, cx: cx, cy: abY + h*0.016, rx: w*0.048, ry: h*0.014, color: skinDk.opacity(0.22))
                }
            }
            for i in 0..<3 {
                var abLine = Path()
                abLine.move(to: CGPoint(x: w*0.35, y: h*(0.524 + Double(i)*0.038)+by))
                abLine.addLine(to: CGPoint(x: w*0.65, y: h*(0.524 + Double(i)*0.038)+by))
                ctx.stroke(abLine, with: .color(skinDk.opacity(0.22)), lineWidth: w*0.007)
            }

        case .leather:
            ctx.fill(torso, with: .linearGradient(
                Gradient(colors: [leatherL, leather, leatherD]),
                startPoint: CGPoint(x: w*0.20, y: h*0.36+by),
                endPoint:   CGPoint(x: w*0.80, y: h*0.65+by)
            ))
            var crease = Path()
            crease.move(to: CGPoint(x: w*0.50, y: h*0.37+by))
            crease.addLine(to: CGPoint(x: w*0.50, y: h*0.64+by))
            ctx.stroke(crease, with: .color(leatherD.opacity(0.55)), lineWidth: w*0.011)
            for i in 0..<3 {
                var st = Path()
                let stitchY = h*(0.42 + Double(i)*0.072) + by
                st.move(to: CGPoint(x: w*0.38, y: stitchY))
                st.addLine(to: CGPoint(x: w*0.62, y: stitchY))
                ctx.stroke(st, with: .color(leatherD.opacity(0.35)), lineWidth: w*0.005)
            }
            rect(ctx: ctx, x: w*0.20, y: h*0.36+by, w: w*0.60, h: h*0.018, color: leatherL.opacity(0.30))

        case .chain:
            ctx.fill(torso, with: .linearGradient(
                Gradient(colors: [metal.opacity(0.72), metalD]),
                startPoint: CGPoint(x: w*0.20, y: h*0.36+by),
                endPoint:   CGPoint(x: w*0.80, y: h*0.65+by)
            ))
            for row in 0..<7 {
                for col in 0..<8 {
                    let rx2 = w * (0.25 + Double(col) * 0.072)
                    let ry2 = h * (0.38 + Double(row) * 0.040) + by
                    let offset = (row % 2 == 0) ? 0.0 : w * 0.036
                    ellipse(ctx: ctx, cx: rx2 + offset, cy: ry2, rx: w*0.018, ry: w*0.013,
                            color: metalL.opacity(0.18))
                }
            }
            rect(ctx: ctx, x: w*0.20, y: h*0.36+by, w: w*0.60, h: h*0.016, color: metalL.opacity(0.35))

        case .plate:
            ctx.fill(torso, with: .linearGradient(
                Gradient(colors: [metalL.opacity(0.90), metal, metalD]),
                startPoint: CGPoint(x: w*0.20, y: h*0.36+by),
                endPoint:   CGPoint(x: w*0.80, y: h*0.65+by)
            ))
            var ridge = Path()
            ridge.move(to: CGPoint(x: w*0.47, y: h*0.37+by))
            ridge.addLine(to: CGPoint(x: w*0.50, y: h*0.40+by))
            ridge.addLine(to: CGPoint(x: w*0.53, y: h*0.37+by))
            ctx.stroke(ridge, with: .color(metalL.opacity(0.55)), lineWidth: w*0.014)
            var ridge2 = Path()
            ridge2.move(to: CGPoint(x: w*0.50, y: h*0.40+by))
            ridge2.addLine(to: CGPoint(x: w*0.50, y: h*0.64+by))
            ctx.stroke(ridge2, with: .color(metalL.opacity(0.40)), lineWidth: w*0.012)
            for i in 0..<3 {
                let segY = h*(0.43 + Double(i)*0.072) + by
                var seg = Path()
                seg.move(to: CGPoint(x: w*0.28, y: segY))
                seg.addLine(to: CGPoint(x: w*0.72, y: segY))
                ctx.stroke(seg, with: .color(metalD.opacity(0.45)), lineWidth: w*0.006)
            }
            rect(ctx: ctx, x: w*0.22, y: h*0.36+by, w: w*0.56, h: h*0.018, color: metalL.opacity(0.50))
        }

        // Belt (always on top)
        rect(ctx: ctx, x: w*0.31, y: h*0.625+by, w: w*0.38, h: h*0.038, color: leatherD)
        for i in 0..<6 {
            ellipse(ctx: ctx, cx: w*(0.335 + Double(i)*0.062), cy: h*0.644+by,
                    rx: w*0.009, ry: w*0.009, color: metal)
        }
        rect(ctx: ctx, x: w*0.438, y: h*0.621+by, w: w*0.124, h: h*0.046, color: goldCol.opacity(0.88), cr: w*0.008)
        rect(ctx: ctx, x: w*0.458, y: h*0.629+by, w: w*0.084, h: h*0.030, color: .black.opacity(0.38), cr: w*0.005)

        // --- Fur pauldrons ---
        ellipseGrad(ctx: ctx, cx: w*0.180, cy: h*0.380+by, rx: w*0.130, ry: w*0.100, top: furL, bottom: fur)
        for i in 0..<5 {
            let fy = h * (0.338 + Double(i) * 0.030) + by
            var fs = Path()
            fs.move(to: CGPoint(x: w*0.068, y: fy))
            fs.addQuadCurve(to: CGPoint(x: w*0.295, y: fy + h*0.010),
                            control: CGPoint(x: w*0.182, y: fy - h*0.007))
            ctx.stroke(fs, with: .color(furL.opacity(0.44)), lineWidth: w*0.016)
        }
        ellipseGrad(ctx: ctx, cx: w*0.180, cy: h*0.358+by, rx: w*0.086, ry: w*0.062, top: metal, bottom: metalD)
        rect(ctx: ctx, x: w*0.104, y: h*0.346+by, w: w*0.152, h: h*0.006, color: metalL.opacity(0.55))
        ellipseGrad(ctx: ctx, cx: w*0.180, cy: h*0.364+by, rx: w*0.038, ry: w*0.028, top: metalL, bottom: metal)
        ellipse(ctx: ctx, cx: w*0.162, cy: h*0.350+by, rx: w*0.026, ry: w*0.016, color: metalL.opacity(0.40))

        ellipseGrad(ctx: ctx, cx: w*0.820, cy: h*0.380+by, rx: w*0.130, ry: w*0.100, top: furL, bottom: fur)
        for i in 0..<5 {
            let fy = h * (0.338 + Double(i) * 0.030) + by
            var fs = Path()
            fs.move(to: CGPoint(x: w*0.705, y: fy))
            fs.addQuadCurve(to: CGPoint(x: w*0.932, y: fy + h*0.010),
                            control: CGPoint(x: w*0.818, y: fy - h*0.007))
            ctx.stroke(fs, with: .color(furL.opacity(0.44)), lineWidth: w*0.016)
        }
        ellipseGrad(ctx: ctx, cx: w*0.820, cy: h*0.358+by, rx: w*0.086, ry: w*0.062, top: metal, bottom: metalD)
        rect(ctx: ctx, x: w*0.744, y: h*0.346+by, w: w*0.152, h: h*0.006, color: metalL.opacity(0.55))
        ellipseGrad(ctx: ctx, cx: w*0.820, cy: h*0.364+by, rx: w*0.038, ry: w*0.028, top: metalL, bottom: metal)
        ellipse(ctx: ctx, cx: w*0.802, cy: h*0.350+by, rx: w*0.026, ry: w*0.016, color: metalL.opacity(0.40))

        // --- Left arm ---
        rectGrad(ctx: ctx, x: w*0.138, y: h*0.44+by, w: w*0.118, h: h*0.162, top: skinLt, bottom: skin, cr: w*0.036)
        rect(ctx: ctx, x: w*0.152, y: h*0.454+by, w: w*0.050, h: h*0.082, color: skinLt.opacity(0.22), cr: w*0.018)
        rect(ctx: ctx, x: w*0.212, y: h*0.458+by, w: w*0.032, h: h*0.100, color: skinDk.opacity(0.32), cr: w*0.014)
        rectGrad(ctx: ctx, x: w*0.148, y: h*0.588+by, w: w*0.104, h: h*0.122, top: skin, bottom: skinDk, cr: w*0.024)
        var vein = Path()
        vein.move(to: CGPoint(x: w*0.176, y: h*0.600+by))
        vein.addQuadCurve(to: CGPoint(x: w*0.188, y: h*0.696+by),
                          control: CGPoint(x: w*0.162, y: h*0.648+by))
        ctx.stroke(vein, with: .color(skinDk.opacity(0.42)), lineWidth: w*0.007)
        rectGrad(ctx: ctx, x: w*0.140, y: h*0.696+by, w: w*0.120, h: h*0.040, top: leather, bottom: leatherD, cr: w*0.008)
        rect(ctx: ctx, x: w*0.148, y: h*0.698+by, w: w*0.104, h: h*0.005, color: metalL.opacity(0.50))
        rect(ctx: ctx, x: w*0.148, y: h*0.727+by, w: w*0.104, h: h*0.005, color: metalL.opacity(0.50))
        ellipseGrad(ctx: ctx, cx: w*0.200, cy: h*0.766+by, rx: w*0.064, ry: w*0.052, top: skinLt, bottom: skin)
        ellipse(ctx: ctx, cx: w*0.180, cy: h*0.756+by, rx: w*0.028, ry: w*0.020, color: skinLt.opacity(0.28))

        // --- Weapon ---
        if eq.weapon != .none {
            let axeGX = w * 0.792
            let axeGY = h * 0.572 + by
            ctx.drawLayer { layer in
                layer.translateBy(x: axeGX, y: axeGY)
                layer.rotate(by: .radians(axeSway))
                layer.translateBy(x: -axeGX, y: -axeGY)

                let handleTop    = eq.weapon == .greatWeapon ? h*0.170+by : h*0.210+by
                let handleBottom = eq.weapon == .greatWeapon ? h*0.820+by : h*0.770+by
                let handleLen    = handleBottom - handleTop

                rect(ctx: layer, x: w*0.764, y: handleTop, w: w*0.056, h: handleLen,
                     color: Color(red: 0.30, green: 0.18, blue: 0.08), cr: w*0.010)
                for i in 0..<6 {
                    var grain = Path()
                    grain.move(to: CGPoint(x: w*0.767, y: handleTop + handleLen * Double(i) * 0.14))
                    grain.addLine(to: CGPoint(x: w*0.817, y: handleTop + handleLen * Double(i) * 0.14))
                    layer.stroke(grain, with: .color(Color(red: 0.18, green: 0.10, blue: 0.03).opacity(0.45)),
                                 lineWidth: w*0.005)
                }
                for i in 0..<5 {
                    rect(ctx: layer, x: w*0.762, y: handleTop + handleLen*(0.55 + Double(i)*0.08),
                         w: w*0.060, h: handleLen*0.06, color: leatherD.opacity(0.78))
                }

                if eq.weapon == .sword {
                    var blade = Path()
                    blade.move(to: CGPoint(x: w*0.774, y: handleTop))
                    blade.addLine(to: CGPoint(x: w*0.810, y: handleTop))
                    blade.addLine(to: CGPoint(x: w*0.792, y: handleTop - h*0.220))
                    blade.closeSubpath()
                    layer.fill(blade, with: .linearGradient(
                        Gradient(colors: [metalL, metal, metalD]),
                        startPoint: CGPoint(x: w*0.774, y: handleTop),
                        endPoint:   CGPoint(x: w*0.810, y: handleTop)
                    ))
                    var edge = Path()
                    edge.move(to: CGPoint(x: w*0.774, y: handleTop))
                    edge.addLine(to: CGPoint(x: w*0.792, y: handleTop - h*0.220))
                    layer.stroke(edge, with: .color(metalL.opacity(0.70)), lineWidth: w*0.012)
                    rect(ctx: layer, x: w*0.742, y: handleTop - h*0.008, w: w*0.100, h: h*0.016, color: metalD, cr: w*0.004)
                    rect(ctx: layer, x: w*0.744, y: handleTop - h*0.006, w: w*0.096, h: h*0.006, color: metalL.opacity(0.45))
                } else {
                    let bladeScale = eq.weapon == .greatWeapon ? 1.28 : 1.0
                    var spike = Path()
                    spike.move(to: CGPoint(x: w*0.776, y: handleTop + h*0.004))
                    spike.addLine(to: CGPoint(x: w*0.792, y: handleTop - h*0.046))
                    spike.addLine(to: CGPoint(x: w*0.808, y: handleTop + h*0.004))
                    spike.closeSubpath()
                    layer.fill(spike, with: .color(metal))
                    layer.stroke(spike, with: .color(metalL.opacity(0.55)), lineWidth: w*0.007)

                    let bTop = handleTop + h*0.014
                    let bMid = bTop + h*0.144 * bladeScale
                    var upperBlade = Path()
                    upperBlade.move(to: CGPoint(x: w*0.764, y: bTop))
                    upperBlade.addLine(to: CGPoint(x: w*(0.764 - 0.212*bladeScale), y: bTop - h*0.032*bladeScale))
                    upperBlade.addQuadCurve(
                        to: CGPoint(x: w*(0.764 - 0.192*bladeScale), y: bMid),
                        control: CGPoint(x: w*(0.764 - 0.310*bladeScale), y: bTop + h*0.080*bladeScale))
                    upperBlade.addLine(to: CGPoint(x: w*0.820, y: bMid))
                    upperBlade.closeSubpath()
                    layer.fill(upperBlade, with: .linearGradient(
                        Gradient(colors: [metalL.opacity(0.80), metal, metalD]),
                        startPoint: CGPoint(x: w*(0.764 - 0.212*bladeScale), y: bTop - h*0.032*bladeScale),
                        endPoint:   CGPoint(x: w*0.820, y: bMid)
                    ))
                    var ubevel = Path()
                    ubevel.move(to: CGPoint(x: w*(0.764 - 0.212*bladeScale), y: bTop - h*0.032*bladeScale))
                    ubevel.addQuadCurve(
                        to: CGPoint(x: w*(0.764 - 0.192*bladeScale), y: bMid),
                        control: CGPoint(x: w*(0.764 - 0.310*bladeScale), y: bTop + h*0.080*bladeScale))
                    layer.stroke(ubevel, with: .color(metalL.opacity(0.65)), lineWidth: w*0.018)
                    var ubShade = Path()
                    ubShade.move(to: CGPoint(x: w*0.764, y: bTop))
                    ubShade.addLine(to: CGPoint(x: w*0.660, y: bTop + h*0.010))
                    ubShade.addLine(to: CGPoint(x: w*0.665, y: bMid))
                    ubShade.addLine(to: CGPoint(x: w*0.820, y: bMid))
                    ubShade.closeSubpath()
                    layer.fill(ubShade, with: .color(metalD.opacity(0.24)))
                    let bloodX = w*(0.764 - 0.232*bladeScale)
                    ellipse(ctx: layer, cx: bloodX, cy: bTop + h*0.088*bladeScale,
                            rx: w*0.026, ry: w*0.018, color: blood.opacity(0.58))
                    ellipse(ctx: layer, cx: bloodX + w*0.016, cy: bTop + h*0.068*bladeScale,
                            rx: w*0.014, ry: w*0.010, color: blood.opacity(0.42))
                    var lowerBlade = Path()
                    lowerBlade.move(to: CGPoint(x: w*0.820, y: bMid))
                    lowerBlade.addLine(to: CGPoint(x: w*(0.764 - 0.192*bladeScale), y: bMid))
                    lowerBlade.addQuadCurve(
                        to: CGPoint(x: w*(0.764 - 0.180*bladeScale), y: bMid + h*0.086*bladeScale),
                        control: CGPoint(x: w*(0.764 - 0.258*bladeScale), y: bMid + h*0.044*bladeScale))
                    lowerBlade.addLine(to: CGPoint(x: w*0.764, y: bMid + h*0.086*bladeScale))
                    lowerBlade.closeSubpath()
                    layer.fill(lowerBlade, with: .linearGradient(
                        Gradient(colors: [metal, metalD]),
                        startPoint: CGPoint(x: w*(0.764 - 0.192*bladeScale), y: bMid),
                        endPoint:   CGPoint(x: w*0.764, y: bMid + h*0.086*bladeScale)
                    ))
                    ellipseGrad(ctx: layer, cx: w*0.792, cy: bMid - h*0.028, rx: w*0.044, ry: w*0.044,
                                top: metal, bottom: metalD)
                    ellipseGrad(ctx: layer, cx: w*0.792, cy: bMid - h*0.028, rx: w*0.022, ry: w*0.022,
                                top: metalL, bottom: metal)
                    ellipse(ctx: layer, cx: w*0.784, cy: bMid - h*0.036, rx: w*0.010, ry: w*0.008,
                            color: metalL.opacity(0.60))
                }
            }
        }

        // --- Right arm ---
        rectGrad(ctx: ctx, x: w*0.742, y: h*0.44+by, w: w*0.118, h: h*0.162, top: skinLt, bottom: skin, cr: w*0.036)
        rect(ctx: ctx, x: w*0.752, y: h*0.454+by, w: w*0.050, h: h*0.082, color: skinLt.opacity(0.20), cr: w*0.018)
        rect(ctx: ctx, x: w*0.742, y: h*0.458+by, w: w*0.020, h: h*0.100, color: skinDk.opacity(0.28), cr: w*0.008)
        rectGrad(ctx: ctx, x: w*0.742, y: h*0.588+by, w: w*0.104, h: h*0.122, top: skin, bottom: skinDk, cr: w*0.024)
        rectGrad(ctx: ctx, x: w*0.740, y: h*0.696+by, w: w*0.120, h: h*0.040, top: leather, bottom: leatherD, cr: w*0.008)
        rect(ctx: ctx, x: w*0.748, y: h*0.698+by, w: w*0.104, h: h*0.005, color: metalL.opacity(0.50))
        rect(ctx: ctx, x: w*0.748, y: h*0.727+by, w: w*0.104, h: h*0.005, color: metalL.opacity(0.50))
        ellipseGrad(ctx: ctx, cx: w*0.794, cy: h*0.762+by, rx: w*0.060, ry: w*0.050, top: skinLt, bottom: skin)

        // --- Neck ---
        ellipse(ctx: ctx, cx: w*0.500, cy: h*0.344+by, rx: w*0.080, ry: w*0.038, color: skinDk.opacity(0.28))
        var neck = Path()
        neck.move(to: CGPoint(x: w*0.438, y: h*0.330+by))
        neck.addLine(to: CGPoint(x: w*0.562, y: h*0.330+by))
        neck.addLine(to: CGPoint(x: w*0.552, y: h*0.378+by))
        neck.addLine(to: CGPoint(x: w*0.448, y: h*0.378+by))
        neck.closeSubpath()
        ctx.fill(neck, with: .linearGradient(
            Gradient(colors: [skinLt, skin, skinDk]),
            startPoint: CGPoint(x: w*0.438, y: h*0.330+by),
            endPoint:   CGPoint(x: w*0.562, y: h*0.378+by)
        ))

        // --- Head ---
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
        ctx.fill(head, with: .linearGradient(
            Gradient(colors: [skinLt, skin, skinDk]),
            startPoint: CGPoint(x: w*0.350, y: h*0.155+by),
            endPoint:   CGPoint(x: w*0.650, y: h*0.350+by)
        ))
        var cheekS = Path()
        cheekS.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by),
                      radius: w*0.150, startAngle: .degrees(-28), endAngle: .degrees(0),
                      clockwise: false)
        cheekS.addLine(to: CGPoint(x: w*0.640, y: h*0.318+by))
        cheekS.addLine(to: CGPoint(x: w*0.618, y: h*0.256+by))
        cheekS.closeSubpath()
        ctx.fill(cheekS, with: .color(skinDk.opacity(0.26)))
        ellipse(ctx: ctx, cx: w*0.500, cy: h*0.216+by, rx: w*0.112, ry: w*0.024, color: skinDk.opacity(0.36))
        rect(ctx: ctx, x: w*0.480, y: h*0.240+by, w: w*0.040, h: h*0.048, color: skinDk.opacity(0.16), cr: w*0.010)
        ellipse(ctx: ctx, cx: w*0.408, cy: h*0.246+by, rx: w*0.046, ry: w*0.022, color: skinLt.opacity(0.28))
        ellipse(ctx: ctx, cx: w*0.592, cy: h*0.246+by, rx: w*0.046, ry: w*0.022, color: skinLt.opacity(0.14))
        ellipse(ctx: ctx, cx: w*0.468, cy: h*0.168+by, rx: w*0.060, ry: w*0.028, color: skinLt.opacity(0.22))

        // --- Hair ---
        let strandAngles: [Double] = [-1.92, -1.58, -1.24, -0.88, -0.52, -0.22]
        let strandWidths: [Double] = [0.036, 0.030, 0.028, 0.026, 0.024, 0.022]
        let strandLens:   [Double] = [0.12,  0.14,  0.13,  0.11,  0.10,  0.09 ]
        let strandPhases: [Double] = [0.55,  0.12,  0.42,  0.72,  0.90,  1.10 ]
        for i in strandAngles.indices {
            let angle  = strandAngles[i]
            let lw     = strandWidths[i]
            let len    = strandLens[i]
            let phase  = strandPhases[i]
            let sway   = sin(t * (0.55 + phase * 0.10) + phase) * 0.05
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
        for i in 0..<3 {
            let angle = -1.72 + Double(i) * 0.44
            let sx = w*0.500 + cos(angle + .pi) * w * 0.096
            let sy = h*0.144 + by + sin(angle + .pi) * h * 0.058
            var hp = Path()
            hp.move(to: CGPoint(x: sx, y: sy))
            hp.addLine(to: CGPoint(x: sx + cos(angle) * w*0.072, y: sy + sin(angle) * h*0.072))
            ctx.stroke(hp, with: .color(hairL.opacity(0.38)), lineWidth: w*0.016)
        }

        // --- Helm ---
        switch eq.helm {
        case .none:
            break

        case .cap:
            var cap = Path()
            cap.addArc(center: CGPoint(x: w*0.500, y: h*0.200+by),
                       radius: w*0.148, startAngle: .degrees(-180), endAngle: .degrees(0),
                       clockwise: false)
            cap.addLine(to: CGPoint(x: w*0.648, y: h*0.240+by))
            cap.addLine(to: CGPoint(x: w*0.352, y: h*0.240+by))
            cap.closeSubpath()
            ctx.fill(cap, with: .linearGradient(
                Gradient(colors: [leatherL, leather, leatherD]),
                startPoint: CGPoint(x: w*0.35, y: h*0.15+by),
                endPoint:   CGPoint(x: w*0.65, y: h*0.24+by)
            ))
            rect(ctx: ctx, x: w*0.350, y: h*0.234+by, w: w*0.300, h: h*0.012, color: leatherD)
            rect(ctx: ctx, x: w*0.354, y: h*0.234+by, w: w*0.292, h: h*0.005, color: leatherL.opacity(0.38))

        case .helm:
            var helm = Path()
            helm.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by),
                        radius: w*0.152, startAngle: .degrees(-182), endAngle: .degrees(6),
                        clockwise: false)
            helm.addLine(to: CGPoint(x: w*0.640, y: h*0.258+by))
            helm.addLine(to: CGPoint(x: w*0.350, y: h*0.258+by))
            helm.closeSubpath()
            ctx.fill(helm, with: .linearGradient(
                Gradient(colors: [metalL.opacity(0.75), metal, metalD]),
                startPoint: CGPoint(x: w*0.35, y: h*0.13+by),
                endPoint:   CGPoint(x: w*0.65, y: h*0.26+by)
            ))
            var helmHL = Path()
            helmHL.addArc(center: CGPoint(x: w*0.500, y: h*0.204+by), radius: w*0.152,
                          startAngle: .degrees(-158), endAngle: .degrees(-74), clockwise: false)
            ctx.stroke(helmHL, with: .color(metalL.opacity(0.22)), lineWidth: w*0.048)
            rect(ctx: ctx, x: w*0.348, y: h*0.252+by, w: w*0.304, h: h*0.015, color: metal)
            rect(ctx: ctx, x: w*0.352, y: h*0.252+by, w: w*0.296, h: h*0.006, color: metalL.opacity(0.48))
            var dent = Path()
            dent.move(to: CGPoint(x: w*0.572, y: h*0.166+by))
            dent.addLine(to: CGPoint(x: w*0.606, y: h*0.174+by))
            dent.addLine(to: CGPoint(x: w*0.596, y: h*0.190+by))
            ctx.stroke(dent, with: .color(metalD.opacity(0.72)), lineWidth: w*0.011)
            var nasal = Path()
            nasal.move(to: CGPoint(x: w*0.477, y: h*0.252+by))
            nasal.addLine(to: CGPoint(x: w*0.523, y: h*0.252+by))
            nasal.addLine(to: CGPoint(x: w*0.512, y: h*0.302+by))
            nasal.addLine(to: CGPoint(x: w*0.488, y: h*0.302+by))
            nasal.closeSubpath()
            ctx.fill(nasal, with: .linearGradient(
                Gradient(colors: [metal, metalD]),
                startPoint: CGPoint(x: w*0.477, y: h*0.252+by),
                endPoint:   CGPoint(x: w*0.523, y: h*0.302+by)
            ))
            rect(ctx: ctx, x: w*0.483, y: h*0.254+by, w: w*0.011, h: h*0.044, color: metalL.opacity(0.30))

        case .greatHelm:
            var gHelm = Path()
            gHelm.addArc(center: CGPoint(x: w*0.500, y: h*0.200+by),
                         radius: w*0.158, startAngle: .degrees(-180), endAngle: .degrees(0),
                         clockwise: false)
            gHelm.addLine(to: CGPoint(x: w*0.658, y: h*0.340+by))
            gHelm.addLine(to: CGPoint(x: w*0.342, y: h*0.340+by))
            gHelm.closeSubpath()
            ctx.fill(gHelm, with: .linearGradient(
                Gradient(colors: [metalL.opacity(0.80), metal, metalD]),
                startPoint: CGPoint(x: w*0.34, y: h*0.12+by),
                endPoint:   CGPoint(x: w*0.66, y: h*0.34+by)
            ))
            var lCheek = Path()
            lCheek.move(to: CGPoint(x: w*0.342, y: h*0.260+by))
            lCheek.addLine(to: CGPoint(x: w*0.366, y: h*0.260+by))
            lCheek.addLine(to: CGPoint(x: w*0.358, y: h*0.340+by))
            lCheek.addLine(to: CGPoint(x: w*0.342, y: h*0.340+by))
            lCheek.closeSubpath()
            ctx.fill(lCheek, with: .color(metalD.opacity(0.55)))
            var rCheek = Path()
            rCheek.move(to: CGPoint(x: w*0.634, y: h*0.260+by))
            rCheek.addLine(to: CGPoint(x: w*0.658, y: h*0.260+by))
            rCheek.addLine(to: CGPoint(x: w*0.658, y: h*0.340+by))
            rCheek.addLine(to: CGPoint(x: w*0.642, y: h*0.340+by))
            rCheek.closeSubpath()
            ctx.fill(rCheek, with: .color(metalD.opacity(0.55)))
            rect(ctx: ctx, x: w*0.366, y: h*0.244+by, w: w*0.268, h: h*0.028, color: .black.opacity(0.82), cr: w*0.006)
            for bx in [w*0.380, w*0.500, w*0.620] {
                ellipse(ctx: ctx, cx: bx, cy: h*0.258+by, rx: w*0.008, ry: w*0.008, color: metalD)
                ellipse(ctx: ctx, cx: bx, cy: h*0.258+by, rx: w*0.004, ry: w*0.004, color: metalL.opacity(0.55))
            }
            rect(ctx: ctx, x: w*0.342, y: h*0.333+by, w: w*0.316, h: h*0.014, color: metal)
            rect(ctx: ctx, x: w*0.346, y: h*0.333+by, w: w*0.308, h: h*0.006, color: metalL.opacity(0.45))
            var crest = Path()
            crest.move(to: CGPoint(x: w*0.470, y: h*0.180+by))
            crest.addLine(to: CGPoint(x: w*0.500, y: h*0.050+by))
            crest.addLine(to: CGPoint(x: w*0.530, y: h*0.180+by))
            crest.closeSubpath()
            ctx.fill(crest, with: .linearGradient(
                Gradient(colors: [metalL.opacity(0.70), metal, metalD]),
                startPoint: CGPoint(x: w*0.470, y: h*0.050+by),
                endPoint:   CGPoint(x: w*0.530, y: h*0.180+by)
            ))
        }

        // --- Beard (hidden when great helm covers face) ---
        if eq.helm != .greatHelm {
            let beardXs: [Double] = [0.372, 0.410, 0.450, 0.500, 0.548, 0.588]
            for (i, bx) in beardXs.enumerated() {
                let phase = sin(t * 0.60 + Double(i) * 0.55) * 0.016
                let ctrl  = bx + (i % 2 == 0 ? -0.014 : 0.014)
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
        }

        // --- War paint (only when face is uncovered) ---
        if eq.helm == .none || eq.helm == .cap {
            var paint = Path()
            paint.move(to: CGPoint(x: w*0.532, y: h*0.220+by))
            paint.addLine(to: CGPoint(x: w*0.608, y: h*0.260+by))
            ctx.stroke(paint, with: .color(warpaint.opacity(0.72)), lineWidth: w*0.017)
            for i in 0..<3 {
                ellipse(ctx: ctx, cx: w*(0.354 + Double(i)*0.016),
                        cy: h*(0.268 + Double(i)*0.020)+by,
                        rx: w*0.009, ry: w*0.009, color: warpaint.opacity(0.62))
            }
            var scar = Path()
            scar.move(to: CGPoint(x: w*0.410, y: h*0.308+by))
            scar.addLine(to: CGPoint(x: w*0.434, y: h*0.326+by))
            ctx.stroke(scar, with: .color(skinDk.opacity(0.52)), lineWidth: w*0.008)
        }

        // --- Eyes ---
        if eq.helm == .greatHelm {
            glow(ctx: ctx, cx: w*0.434, cy: h*0.258+by, r: w*0.014, color: eyeCol.opacity(eyeG))
            glow(ctx: ctx, cx: w*0.566, cy: h*0.258+by, r: w*0.014, color: eyeCol.opacity(eyeG))
        } else {
            ellipse(ctx: ctx, cx: w*0.428, cy: h*0.258+by, rx: w*0.048, ry: w*0.026, color: skinDk.opacity(0.44))
            ellipse(ctx: ctx, cx: w*0.572, cy: h*0.258+by, rx: w*0.048, ry: w*0.026, color: skinDk.opacity(0.44))
            ellipse(ctx: ctx, cx: w*0.428, cy: h*0.257+by, rx: w*0.030, ry: w*0.017,
                    color: Color(red: 0.90, green: 0.86, blue: 0.80))
            ellipse(ctx: ctx, cx: w*0.572, cy: h*0.257+by, rx: w*0.030, ry: w*0.017,
                    color: Color(red: 0.90, green: 0.86, blue: 0.80))
            glow(ctx: ctx, cx: w*0.428, cy: h*0.257+by, r: w*0.017, color: eyeCol.opacity(eyeG))
            glow(ctx: ctx, cx: w*0.572, cy: h*0.257+by, r: w*0.017, color: eyeCol.opacity(eyeG))
        }
    }
}
