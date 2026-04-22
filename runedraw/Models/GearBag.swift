import Foundation

/// A flat, ordered collection of equipment items carried by the hero.
///
/// Replaces the old Diablo-style 5×8 spatial grid. In a card game every item
/// is the same logical size; grid-position bookkeeping adds friction without
/// adding meaning.
struct GearBag: Codable {
    var items: [Card] = []

    var count: Int   { items.count }
    var isEmpty: Bool { items.isEmpty }

    mutating func add(_ card: Card) {
        items.append(card)
    }

    @discardableResult
    mutating func remove(id: UUID) -> Card? {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return nil }
        return items.remove(at: idx)
    }

    func contains(id: UUID) -> Bool {
        items.contains(where: { $0.id == id })
    }

    // MARK: - Save-compat: read both new GearBag JSON and old InventoryGrid JSON

    enum CodingKeys: String, CodingKey { case items, placements }

    // Old InventoryGrid encoded each item as { card, row, col }
    private struct LegacyPlacement: Decodable { let card: Card }

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        if let items = try c.decodeIfPresent([Card].self, forKey: .items) {
            self.items = items
        } else if let old = try c.decodeIfPresent([LegacyPlacement].self, forKey: .placements) {
            self.items = old.map(\.card)
        } else {
            self.items = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(items, forKey: .items)
    }
}
