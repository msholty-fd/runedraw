import Foundation

struct InventoryGrid: Codable {
    static let cols = 5
    static let rows = 8

    struct Placement: Identifiable, Codable {
        let card: Card
        let row: Int
        let col: Int
        var id: UUID { card.id }
    }

    private(set) var placements: [Placement] = []

    var items: [Card] { placements.map(\.card) }
    var count: Int { placements.count }

    // 2D occupancy map — rebuilt on demand (grid is small, this is fine)
    func occupancy() -> [[UUID?]] {
        var grid = Array(repeating: Array(repeating: UUID?.none, count: Self.cols), count: Self.rows)
        for p in placements {
            for dr in 0..<p.card.size.h {
                for dc in 0..<p.card.size.w {
                    let r = p.row + dr
                    let c = p.col + dc
                    if r < Self.rows && c < Self.cols { grid[r][c] = p.card.id }
                }
            }
        }
        return grid
    }

    func canPlace(_ card: Card, row: Int, col: Int) -> Bool {
        guard row >= 0, col >= 0,
              row + card.size.h <= Self.rows,
              col + card.size.w <= Self.cols else { return false }
        let grid = occupancy()
        for dr in 0..<card.size.h {
            for dc in 0..<card.size.w {
                if grid[row + dr][col + dc] != nil { return false }
            }
        }
        return true
    }

    // Returns true if placed successfully
    @discardableResult
    mutating func autoPlace(_ card: Card) -> Bool {
        for row in 0..<Self.rows {
            for col in 0..<Self.cols {
                if canPlace(card, row: row, col: col) {
                    placements.append(Placement(card: card, row: row, col: col))
                    return true
                }
            }
        }
        return false
    }

    @discardableResult
    mutating func remove(id: UUID) -> Card? {
        guard let idx = placements.firstIndex(where: { $0.id == id }) else { return nil }
        let card = placements[idx].card
        placements.remove(at: idx)
        return card
    }

    func placement(for id: UUID) -> Placement? {
        placements.first { $0.id == id }
    }
}
