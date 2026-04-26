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
            Shop(name: "The Card Merchant", icon: "🃏", speciality: "Combat Cards",
                 items: cardItems(floor: floorNumber, count: 5, heroClass: .barbarian)),
            Shop(name: "The Arcane Market", icon: "🔮", speciality: "Spell Cards",
                 items: cardItems(floor: floorNumber, count: 5, heroClass: .sorceress)),
            Shop(name: "Shadow Exchange",   icon: "🗡️", speciality: "Rogue Cards",
                 items: cardItems(floor: floorNumber, count: 5, heroClass: .rogue)),
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

    private static func cardItems(floor: Int, count: Int, heroClass: HeroClass) -> [ShopItem] {
        var results: [ShopItem] = []
        var seen = Set<String>()
        var attempts = 0
        while results.count < count && attempts < 100 {
            attempts += 1
            guard let card = CardDatabase.droppableCard(for: heroClass, rarity: rarityForShop(floor: floor)),
                  !seen.contains(card.name) else { continue }
            seen.insert(card.name)
            results.append(ShopItem(card: card, price: randomPrice(card.rarity)))
        }
        return results
    }

    private static func rarityForShop(floor: Int) -> CardRarity {
        let r = Double.random(in: 0..<1)
        switch floor {
        case 1:  return r < 0.05 ? .rare : r < 0.30 ? .magic : .common
        case 2:  return r < 0.10 ? .rare : r < 0.45 ? .magic : .common
        default: return r < 0.20 ? .rare : r < 0.60 ? .magic : .common
        }
    }
}
