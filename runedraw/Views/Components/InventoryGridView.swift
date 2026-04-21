import SwiftUI

struct InventoryGridView: View {
    let grid: InventoryGrid
    var selectedId: UUID? = nil
    var onTapItem: ((Card) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let cellSize = geo.size.width / CGFloat(InventoryGrid.cols)
            ZStack(alignment: .topLeading) {
                GridBackground(cellSize: cellSize)
                ForEach(grid.placements) { placement in
                    ItemTile(
                        card: placement.card,
                        cellSize: cellSize,
                        isSelected: placement.card.id == selectedId
                    )
                    .frame(
                        width: CGFloat(placement.card.size.w) * cellSize - 2,
                        height: CGFloat(placement.card.size.h) * cellSize - 2
                    )
                    .offset(
                        x: CGFloat(placement.col) * cellSize + 1,
                        y: CGFloat(placement.row) * cellSize + 1
                    )
                    .onTapGesture { onTapItem?(placement.card) }
                }
            }
        }
        .aspectRatio(
            CGFloat(InventoryGrid.cols) / CGFloat(InventoryGrid.rows),
            contentMode: .fit
        )
    }
}

// MARK: - Grid Background

private struct GridBackground: View {
    let cellSize: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let cols = InventoryGrid.cols
            let rows = InventoryGrid.rows
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .color(Color(red: 0.07, green: 0.04, blue: 0.12)))

            var path = Path()
            for col in 0...cols {
                let x = CGFloat(col) * cellSize
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for row in 0...rows {
                let y = CGFloat(row) * cellSize
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            ctx.stroke(path, with: .color(.gray.opacity(0.18)), style: StrokeStyle(lineWidth: 0.5))
        }
    }
}

// MARK: - Item Tile

struct ItemTile: View {
    let card: Card
    let cellSize: CGFloat
    var isSelected: Bool = false

    private var isWide: Bool { card.size.w >= 2 }
    private var isTall: Bool { card.size.h >= 2 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: card.isUnique
                            ? [card.rarity.color.opacity(0.35), card.rarity.color.opacity(0.12)]
                            : [Color(red: 0.15, green: 0.10, blue: 0.24), Color(red: 0.09, green: 0.06, blue: 0.16)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    card.rarity.color.opacity(isSelected ? 1.0 : 0.55),
                    lineWidth: isSelected ? 2 : 1
                )

            VStack(spacing: 1) {
                Text(card.equipmentSlot?.icon ?? "")
                    .font(.system(size: iconSize))

                if isTall {
                    Text(card.name)
                        .font(.system(size: labelSize, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(card.size.h)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 2)
                }
            }
        }
    }

    private var iconSize: CGFloat {
        cellSize * CGFloat(min(card.size.w, card.size.h)) * 0.3
    }

    private var labelSize: CGFloat {
        max(7, cellSize * 0.16)
    }
}

#Preview {
    var grid = InventoryGrid()
    grid.autoPlace(Card(
        name: "Iron Sword", rarity: .common, slot: .weapon, size: ItemSize(w: 1, h: 3),
        statBonus: StatBonus(attackBonus: 3)
    ))
    grid.autoPlace(Card(
        name: "Shako", rarity: .unique, slot: .helm, size: ItemSize(w: 2, h: 2),
        statBonus: StatBonus(maxHp: 30), isUnique: true
    ))
    grid.autoPlace(Card(
        name: "Ring", rarity: .magic, slot: .ring, size: ItemSize(w: 1, h: 1),
        statBonus: StatBonus(attackBonus: 2)
    ))
    return InventoryGridView(grid: grid)
        .padding()
        .background(Color.black)
}
