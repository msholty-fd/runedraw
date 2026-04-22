// swiftlint:disable function_body_length
import SwiftUI

extension HeroDrawing {

    static func drawSorceress(eq: EquipmentVisuals, ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height

        let by       = sin(t * 1.10) * h * 0.018
        let eyeG     = 0.55 + sin(t * 2.40) * 0.45
        let orbPulse = 0.88 + sin(t * 3.20) * 0.12
        let hairSway = sin(t * 0.60) * w * 0.022

        let robe     = Color(red: 0.09, green: 0.06, blue: 0.26)
        let robeLt   = Color(red: 0.30, green: 0.18, blue: 0.62)
        let robeMid  = Color(red: 0.18, green: 0.11, blue: 0.42)
        let skinCol  = Color(red: 0.84, green: 0.78, blue: 0.74)
        let skinLt   = Color(red: 0.94, green: 0.90, blue: 0.86)
        let skinDk   = Color(red: 0.64, green: 0.58, blue: 0.52)
        let hairCol  = Color(red: 0.10, green: 0.07, blue: 0.20)
        let hairLt   = Color(red: 0.26, green: 0.16, blue: 0.44)
        let eyeCol   = Color(red: 0.70, green: 0.35, blue: 1.00)
        let staffCol = Color(red: 0.28, green: 0.20, blue: 0.12)
        let staffLt  = Color(red: 0.48, green: 0.36, blue: 0.18)
        let orbCol   = Color(red: 0.36, green: 0.16, blue: 1.00)

        // Staff
        rectGrad(ctx: ctx, x: w*0.210, y: h*0.10+by, w: w*0.038, h: h*0.76,
                 top: staffLt, bottom: staffCol, cr: w*0.008)
        rectGrad(ctx: ctx, x: w*0.208, y: h*0.83+by, w: w*0.042, h: h*0.040,
                 top: staffLt, bottom: staffCol, cr: w*0.006)
        rect(ctx: ctx, x: w*0.212, y: h*0.12+by, w: w*0.010, h: h*0.70,
             color: staffLt.opacity(0.35), cr: w*0.004)

        let orbR = w * 0.062 * orbPulse
        glow(ctx: ctx, cx: w*0.229, cy: h*0.094+by, r: orbR, color: orbCol)
        ellipse(ctx: ctx, cx: w*0.216, cy: h*0.082+by,
                rx: orbR * 0.32, ry: orbR * 0.28, color: .white.opacity(0.38))

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
        ctx.fill(robePath, with: .linearGradient(
            Gradient(colors: [robeLt.opacity(0.60), robeMid, robe]),
            startPoint: CGPoint(x: w*0.17, y: h*0.37+by),
            endPoint:   CGPoint(x: w*0.83, y: h*0.91+by)
        ))

        // Robe center shadow fold
        var robeCenter = Path()
        robeCenter.move(to: CGPoint(x: w*0.44, y: h*0.39+by))
        robeCenter.addLine(to: CGPoint(x: w*0.56, y: h*0.39+by))
        robeCenter.addQuadCurve(to: CGPoint(x: w*0.58, y: h*0.88+by),
                                control: CGPoint(x: w*0.64, y: h*0.64+by))
        robeCenter.addQuadCurve(to: CGPoint(x: w*0.42, y: h*0.88+by),
                                control: CGPoint(x: w*0.50, y: h*0.95+by))
        robeCenter.addQuadCurve(to: CGPoint(x: w*0.44, y: h*0.39+by),
                                control: CGPoint(x: w*0.36, y: h*0.64+by))
        ctx.fill(robeCenter, with: .color(.black.opacity(0.24)))

        // Robe trim
        var lTrim = Path()
        lTrim.move(to: CGPoint(x: w*0.38, y: h*0.37+by))
        lTrim.addQuadCurve(to: CGPoint(x: w*0.17, y: h*0.91+by),
                           control: CGPoint(x: w*0.18, y: h*0.64+by))
        ctx.stroke(lTrim, with: .color(robeLt.opacity(0.68)), lineWidth: w*0.016)

        var rTrim = Path()
        rTrim.move(to: CGPoint(x: w*0.62, y: h*0.37+by))
        rTrim.addQuadCurve(to: CGPoint(x: w*0.83, y: h*0.91+by),
                           control: CGPoint(x: w*0.82, y: h*0.64+by))
        ctx.stroke(rTrim, with: .color(robeLt.opacity(0.38)), lineWidth: w*0.016)

        var hemTrim = Path()
        hemTrim.move(to: CGPoint(x: w*0.17, y: h*0.91+by))
        hemTrim.addQuadCurve(to: CGPoint(x: w*0.83, y: h*0.91+by),
                             control: CGPoint(x: w*0.50, y: h*0.98+by))
        ctx.stroke(hemTrim, with: .color(robeLt.opacity(0.52)), lineWidth: w*0.013)

        // Runic trim details
        for i in 0..<4 {
            let ry2 = h*(0.46 + Double(i)*0.120) + by
            var runeLine = Path()
            runeLine.move(to: CGPoint(x: w*0.21, y: ry2))
            runeLine.addLine(to: CGPoint(x: w*0.26, y: ry2))
            ctx.stroke(runeLine, with: .color(robeLt.opacity(0.45)), lineWidth: w*0.008)
            runeLine = Path()
            runeLine.move(to: CGPoint(x: w*0.74, y: ry2))
            runeLine.addLine(to: CGPoint(x: w*0.79, y: ry2))
            ctx.stroke(runeLine, with: .color(robeLt.opacity(0.28)), lineWidth: w*0.008)
        }

        // Belt gem
        rect(ctx: ctx, x: w*0.38, y: h*0.550+by, w: w*0.24, h: h*0.026,
             color: Color(red: 0.44, green: 0.26, blue: 0.78).opacity(0.88), cr: w*0.010)
        glow(ctx: ctx, cx: w*0.50, cy: h*0.563+by, r: w*0.016, color: eyeCol.opacity(0.72))

        // Neck + head
        rectGrad(ctx: ctx, x: w*0.44, y: h*0.33+by, w: w*0.12, h: h*0.06,
                 top: skinLt, bottom: skinCol, cr: w*0.01)
        let headPath = Path(ellipseIn: CGRect(x: w*0.370, y: h*0.090+by, width: w*0.260, height: w*0.290))
        ctx.fill(headPath, with: .linearGradient(
            Gradient(colors: [skinLt, skinCol, skinDk]),
            startPoint: CGPoint(x: w*0.370, y: h*0.090+by),
            endPoint:   CGPoint(x: w*0.630, y: h*0.380+by)
        ))

        // Hair
        var lHair = Path()
        lHair.move(to: CGPoint(x: w*0.39, y: h*0.155+by))
        lHair.addQuadCurve(to: CGPoint(x: w*0.265, y: h*0.500+by),
                           control: CGPoint(x: w*0.23-hairSway, y: h*0.340+by))
        ctx.stroke(lHair, with: .color(hairCol), lineWidth: w*0.044)
        ctx.stroke(lHair, with: .color(hairLt.opacity(0.35)), lineWidth: w*0.014)

        var rHair = Path()
        rHair.move(to: CGPoint(x: w*0.61, y: h*0.155+by))
        rHair.addQuadCurve(to: CGPoint(x: w*0.735, y: h*0.500+by),
                           control: CGPoint(x: w*0.77+hairSway, y: h*0.340+by))
        ctx.stroke(rHair, with: .color(hairCol), lineWidth: w*0.044)
        ctx.stroke(rHair, with: .color(hairLt.opacity(0.22)), lineWidth: w*0.014)

        let crownPath = Path(ellipseIn: CGRect(x: w*0.370, y: h*0.073+by, width: w*0.260, height: w*0.144))
        ctx.fill(crownPath, with: .linearGradient(
            Gradient(colors: [hairLt.opacity(0.70), hairCol]),
            startPoint: CGPoint(x: w*0.370, y: h*0.073+by),
            endPoint:   CGPoint(x: w*0.630, y: h*0.217+by)
        ))

        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.114+by, rx: w*0.020, ry: w*0.018, color: eyeCol.opacity(0.82))
        ellipse(ctx: ctx, cx: w*0.496, cy: h*0.110+by, rx: w*0.006, ry: w*0.005, color: .white.opacity(0.55))

        // Eyebrows
        var lBrow = Path()
        lBrow.addArc(center: CGPoint(x: w*0.43, y: h*0.225+by), radius: w*0.048,
                     startAngle: .degrees(-155), endAngle: .degrees(-30), clockwise: false)
        ctx.stroke(lBrow, with: .color(hairCol.opacity(0.72)), lineWidth: w*0.012)

        var rBrow = Path()
        rBrow.addArc(center: CGPoint(x: w*0.57, y: h*0.225+by), radius: w*0.048,
                     startAngle: .degrees(-150), endAngle: .degrees(-25), clockwise: false)
        ctx.stroke(rBrow, with: .color(hairCol.opacity(0.72)), lineWidth: w*0.012)

        // Lips
        var lips = Path()
        lips.addArc(center: CGPoint(x: w*0.50, y: h*0.294+by), radius: w*0.034,
                    startAngle: .degrees(15), endAngle: .degrees(165), clockwise: false)
        ctx.stroke(lips, with: .color(Color(red: 0.68, green: 0.32, blue: 0.38)),
                   lineWidth: w*0.011)

        glow(ctx: ctx, cx: w*0.432, cy: h*0.252+by, r: w*0.021, color: eyeCol.opacity(eyeG))
        glow(ctx: ctx, cx: w*0.568, cy: h*0.252+by, r: w*0.021, color: eyeCol.opacity(eyeG))

        // Orbiting particles
        for i in 0..<6 {
            let angle = t * 1.85 + Double(i) * (.pi / 3.0)
            let px = w * 0.50 + cos(angle) * w * 0.34
            let py = h * 0.635 + by + sin(angle) * h * 0.095
            let pr = w * (0.020 + sin(angle * 1.3) * 0.008)
            glow(ctx: ctx, cx: px, cy: py, r: pr,
                 color: orbCol.opacity(0.68 + sin(angle) * 0.28))
        }
        for i in 0..<2 {
            let angle2 = t * 1.05 + Double(i) * .pi
            let px2 = w * 0.50 + cos(angle2) * w * 0.40
            let py2 = h * 0.620 + by + sin(angle2) * h * 0.075
            glow(ctx: ctx, cx: px2, cy: py2, r: w * 0.028, color: eyeCol.opacity(0.58))
        }
    }
}
