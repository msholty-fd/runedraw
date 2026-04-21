import Foundation

struct ShopItem: Identifiable {
    let id: UUID = UUID()
    let card: Card
    let price: Int
    var isPurchased: Bool = false
}

struct Shop: Identifiable {
    let id: UUID = UUID()
    let name: String
    let icon: String
    let speciality: String
    var items: [ShopItem]
}

struct ShopDatabase {

    static let portalPrice = 100

    // MARK: - Generate all town shops

    static func generateShops(floorNumber: Int) -> [Shop] {
        [
            Shop(name: "The Ember Forge",   icon: "⚔️", speciality: "Weapons & Off-Hands",
                 items: filtered([.weapon, .offHand], floor: floorNumber, count: 5)),
            Shop(name: "The Wardkeeper",    icon: "🛡️", speciality: "Armor & Footwear",
                 items: filtered([.helm, .chest, .boots], floor: floorNumber, count: 5)),
            Shop(name: "Curio Corner",      icon: "💍", speciality: "Rings & Amulets",
                 items: filtered([.ring, .amulet], floor: floorNumber, count: 5)),
        ]
    }

    // MARK: - Pricing

    static func randomPrice(_ rarity: CardRarity) -> Int {
        switch rarity {
        case .common: return Int.random(in: 50...90)
        case .magic:  return Int.random(in: 150...280)
        case .rare:   return Int.random(in: 400...700)
        case .unique: return Int.random(in: 1200...2000)
        }
    }

    /// Sell-back value is 25% of buy price, minimum 5g.
    static func sellPrice(for card: Card) -> Int {
        max(5, randomPrice(card.rarity) / 4)
    }

    // MARK: - Private helpers

    private static func filtered(_ slots: [EquipmentSlot], floor: Int, count: Int) -> [ShopItem] {
        var results: [ShopItem] = []
        var seen = Set<String>()
        var attempts = 0
        while results.count < count && attempts < 100 {
            attempts += 1
            guard let card = LootDatabase.generateLoot(floorNumber: floor, isBoss: false, count: 1).first,
                  let slot = card.equipmentSlot,
                  slots.contains(slot),
                  !seen.contains(card.name) else { continue }
            seen.insert(card.name)
            results.append(ShopItem(card: card, price: randomPrice(card.rarity)))
        }
        return results
    }
}
