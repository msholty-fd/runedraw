// swiftlint:disable function_body_length
import SwiftUI

extension HeroDrawing {

    static func drawRogue(eq: EquipmentVisuals, ctx: GraphicsContext, size: CGSize, t: Double) {
        let w = size.width
        let h = size.height

        let by   = sin(t * 1.40) * h * 0.012
        let eyeG = 0.50 + sin(t * 1.80) * 0.50
        let hemS = sin(t * 0.65) * w * 0.014

        let cloak   = Color(red: 0.09, green: 0.06, blue: 0.18)
        let cloakLt = Color(red: 0.22, green: 0.15, blue: 0.40)
        let shadow  = Color(red: 0.03, green: 0.02, blue: 0.08)
        let leather = Color(red: 0.16, green: 0.10, blue: 0.07)
        let silver  = Color(red: 0.60, green: 0.60, blue: 0.66)
        let silverL = Color(red: 0.88, green: 0.88, blue: 0.92)
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
        ctx.fill(cloakPath, with: .linearGradient(
            Gradient(colors: [cloakLt.opacity(0.65), cloak, shadow]),
            startPoint: CGPoint(x: w*0.16, y: h*0.31+by),
            endPoint:   CGPoint(x: w*0.84, y: h*0.87+by)
        ))

        // Inner fold
        var inner = Path()
        inner.move(to: CGPoint(x: w*0.42, y: h*0.33+by))
        inner.addLine(to: CGPoint(x: w*0.58, y: h*0.33+by))
        inner.addQuadCurve(to: CGPoint(x: w*0.60, y: h*0.84+by),
                           control: CGPoint(x: w*0.70, y: h*0.60+by))
        inner.addQuadCurve(to: CGPoint(x: w*0.40, y: h*0.84+by),
                           control: CGPoint(x: w*0.50, y: h*0.92+by))
        inner.addQuadCurve(to: CGPoint(x: w*0.42, y: h*0.33+by),
                           control: CGPoint(x: w*0.30, y: h*0.60+by))
        ctx.fill(inner, with: .color(shadow.opacity(0.55)))

        // Edge trims
        var lEdge = Path()
        lEdge.move(to: CGPoint(x: w*0.38, y: h*0.31+by))
        lEdge.addQuadCurve(to: CGPoint(x: w*0.16-hemS, y: h*0.87+by),
                           control: CGPoint(x: w*0.12, y: h*0.58+by))
        ctx.stroke(lEdge, with: .color(cloakLt.opacity(0.58)), lineWidth: w*0.014)

        var rEdge = Path()
        rEdge.move(to: CGPoint(x: w*0.62, y: h*0.31+by))
        rEdge.addQuadCurve(to: CGPoint(x: w*0.84+hemS, y: h*0.87+by),
                           control: CGPoint(x: w*0.88, y: h*0.58+by))
        ctx.stroke(rEdge, with: .color(cloakLt.opacity(0.35)), lineWidth: w*0.014)

        var hem = Path()
        hem.move(to: CGPoint(x: w*0.16-hemS, y: h*0.87+by))
        hem.addQuadCurve(to: CGPoint(x: w*0.84+hemS, y: h*0.87+by),
                         control: CGPoint(x: w*0.50, y: h*0.95+by))
        ctx.stroke(hem, with: .color(cloakLt.opacity(0.45)), lineWidth: w*0.012)

        // Shoulder clasp
        ellipseGrad(ctx: ctx, cx: w*0.50, cy: h*0.33+by, rx: w*0.040, ry: w*0.033,
                    top: Color(red: 0.80, green: 0.62, blue: 0.20),
                    bottom: Color(red: 0.44, green: 0.30, blue: 0.08))
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.33+by, rx: w*0.022, ry: w*0.018,
                color: Color(red: 0.90, green: 0.74, blue: 0.28))
        ellipse(ctx: ctx, cx: w*0.492, cy: h*0.322+by, rx: w*0.008, ry: w*0.006,
                color: .white.opacity(0.45))

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
            layer.fill(bl, with: .linearGradient(
                Gradient(colors: [silverL, silver, silver.opacity(0.55)]),
                startPoint: CGPoint(x: w*0.285, y: h*0.495+by),
                endPoint:   CGPoint(x: w*0.315, y: h*0.495+by)
            ))
            var eg = Path()
            eg.move(to: CGPoint(x: w*0.300, y: h*0.495+by))
            eg.addLine(to: CGPoint(x: w*0.300, y: h*0.660+by))
            layer.stroke(eg, with: .color(eyeCol.opacity(0.40)), lineWidth: w*0.010)
            rect(ctx: layer, x: w*0.264, y: h*0.510+by, w: w*0.072, h: h*0.022, color: leather)
            rect(ctx: layer, x: w*0.284, y: h*0.530+by, w: w*0.032, h: h*0.048, color: leather, cr: w*0.008)
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
            layer.fill(bl, with: .linearGradient(
                Gradient(colors: [silverL, silver, silver.opacity(0.55)]),
                startPoint: CGPoint(x: w*0.685, y: h*0.495+by),
                endPoint:   CGPoint(x: w*0.715, y: h*0.495+by)
            ))
            var eg = Path()
            eg.move(to: CGPoint(x: w*0.700, y: h*0.495+by))
            eg.addLine(to: CGPoint(x: w*0.700, y: h*0.660+by))
            layer.stroke(eg, with: .color(eyeCol.opacity(0.40)), lineWidth: w*0.010)
            rect(ctx: layer, x: w*0.664, y: h*0.510+by, w: w*0.072, h: h*0.022, color: leather)
            rect(ctx: layer, x: w*0.684, y: h*0.530+by, w: w*0.032, h: h*0.048, color: leather, cr: w*0.008)
        }

        // Hood
        ctx.fill(Path(ellipseIn: CGRect(x: w*0.50-w*0.205, y: h*0.210+by-w*0.205,
                                        width: w*0.410, height: w*0.410)),
                 with: .linearGradient(
                    Gradient(colors: [cloakLt.opacity(0.55), cloak, shadow]),
                    startPoint: CGPoint(x: w*0.295, y: h*0.005+by),
                    endPoint:   CGPoint(x: w*0.705, y: h*0.415+by)
                 ))
        ellipse(ctx: ctx, cx: w*0.50, cy: h*0.240+by, rx: w*0.148, ry: w*0.138, color: shadow)

        var hoodRim = Path()
        hoodRim.addArc(center: CGPoint(x: w*0.50, y: h*0.210+by),
                       radius: w*0.205,
                       startAngle: .degrees(-200), endAngle: .degrees(-10),
                       clockwise: false)
        ctx.stroke(hoodRim, with: .color(cloakLt.opacity(0.48)), lineWidth: w*0.016)

        glow(ctx: ctx, cx: w*0.435, cy: h*0.245+by, r: w*0.020, color: eyeCol.opacity(eyeG))
        glow(ctx: ctx, cx: w*0.565, cy: h*0.245+by, r: w*0.020, color: eyeCol.opacity(eyeG))
    }
}
