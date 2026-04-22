import SwiftUI

// MARK: - HeroDrawing
//
// Dispatches to per-character drawing extensions.
// Shared helpers are internal (not private) so extensions in other files can call them.

struct HeroDrawing {

    static func draw(_ heroClass: HeroClass, equipment: EquipmentVisuals,
                     ctx: GraphicsContext, size: CGSize, t: Double) {
        switch heroClass {
        case .barbarian: drawBarbarian(eq: equipment, ctx: ctx, size: size, t: t)
        case .rogue:     drawRogue(eq: equipment, ctx: ctx, size: size, t: t)
        case .sorceress: drawSorceress(eq: equipment, ctx: ctx, size: size, t: t)
        }
    }

    // MARK: - Shared drawing helpers

    static func ellipse(ctx: GraphicsContext,
                        cx: Double, cy: Double, rx: Double, ry: Double,
                        color: Color) {
        let path = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        ctx.fill(path, with: .color(color))
    }

    static func ellipseGrad(ctx: GraphicsContext,
                             cx: Double, cy: Double, rx: Double, ry: Double,
                             top: Color, bottom: Color) {
        let path = Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
        ctx.fill(path, with: .linearGradient(
            Gradient(colors: [top, bottom]),
            startPoint: CGPoint(x: cx - rx * 0.6, y: cy - ry),
            endPoint:   CGPoint(x: cx + rx * 0.6, y: cy + ry)
        ))
    }

    static func rect(ctx: GraphicsContext,
                     x: Double, y: Double, w: Double, h: Double,
                     color: Color, cr: Double = 0) {
        let path = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: cr)
        ctx.fill(path, with: .color(color))
    }

    static func rectGrad(ctx: GraphicsContext,
                          x: Double, y: Double, w: Double, h: Double,
                          top: Color, bottom: Color, cr: Double = 0) {
        let path = Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: cr)
        ctx.fill(path, with: .linearGradient(
            Gradient(colors: [top, bottom]),
            startPoint: CGPoint(x: x + w * 0.25, y: y),
            endPoint:   CGPoint(x: x + w * 0.75, y: y + h)
        ))
    }

    static func glow(ctx: GraphicsContext,
                     cx: Double, cy: Double, r: Double, color: Color) {
        ellipse(ctx: ctx, cx: cx, cy: cy, rx: r * 2.6, ry: r * 2.6, color: color.opacity(0.10))
        ellipse(ctx: ctx, cx: cx, cy: cy, rx: r * 1.5, ry: r * 1.5, color: color.opacity(0.28))
        ellipse(ctx: ctx, cx: cx, cy: cy, rx: r,       ry: r,       color: color.opacity(0.92))
    }
}
