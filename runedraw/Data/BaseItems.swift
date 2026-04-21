import Foundation

struct BaseItem {
    let baseName: String
    let slot: EquipmentSlot
    let baseStats: StatBonus
    let size: ItemSize
    let tier: Int
    let requirements: StatRequirements
    init(baseName: String, slot: EquipmentSlot, baseStats: StatBonus,
         size: ItemSize, tier: Int, requirements: StatRequirements = StatRequirements()) {
        self.baseName = baseName; self.slot = slot; self.baseStats = baseStats
        self.size = size; self.tier = tier; self.requirements = requirements
    }
}

struct BaseItemDatabase {

    static let all: [BaseItem] = [

        // MARK: Weapons  (tall, narrow — 1×3 or 1×4)
        BaseItem(baseName: "Short Sword", slot: .weapon, baseStats: StatBonus(attackBonus: 2), size: ItemSize(w: 1, h: 3), tier: 1,
                 requirements: StatRequirements(strength: 10)),
        BaseItem(baseName: "Axe",         slot: .weapon, baseStats: StatBonus(attackBonus: 3), size: ItemSize(w: 1, h: 3), tier: 1,
                 requirements: StatRequirements(strength: 10)),
        BaseItem(baseName: "Broad Sword", slot: .weapon, baseStats: StatBonus(attackBonus: 4), size: ItemSize(w: 1, h: 4), tier: 2,
                 requirements: StatRequirements(strength: 18)),
        BaseItem(baseName: "War Axe",     slot: .weapon, baseStats: StatBonus(attackBonus: 5), size: ItemSize(w: 1, h: 4), tier: 2,
                 requirements: StatRequirements(strength: 20)),
        BaseItem(baseName: "Great Sword", slot: .weapon, baseStats: StatBonus(attackBonus: 7), size: ItemSize(w: 2, h: 3), tier: 3,
                 requirements: StatRequirements(strength: 28)),
        BaseItem(baseName: "Rune Blade",  slot: .weapon, baseStats: StatBonus(attackBonus: 8), size: ItemSize(w: 2, h: 3), tier: 3,
                 requirements: StatRequirements(strength: 20, intelligence: 10)),

        // MARK: Off-Hand  (short: 1×2; shield: 2×2; heavy: 2×3)
        BaseItem(baseName: "Buckler",     slot: .offHand, baseStats: StatBonus(defenseBonus: 2),                size: ItemSize(w: 1, h: 2), tier: 1),
        BaseItem(baseName: "Grimoire",    slot: .offHand, baseStats: StatBonus(attackBonus: 2, defenseBonus: 1), size: ItemSize(w: 1, h: 2), tier: 1,
                 requirements: StatRequirements(intelligence: 10)),
        BaseItem(baseName: "Kite Shield", slot: .offHand, baseStats: StatBonus(defenseBonus: 4),                size: ItemSize(w: 2, h: 2), tier: 2,
                 requirements: StatRequirements(strength: 12)),
        BaseItem(baseName: "Tome",        slot: .offHand, baseStats: StatBonus(attackBonus: 3, defenseBonus: 2), size: ItemSize(w: 1, h: 2), tier: 2,
                 requirements: StatRequirements(intelligence: 15)),
        BaseItem(baseName: "Tower Shield",slot: .offHand, baseStats: StatBonus(defenseBonus: 6),                size: ItemSize(w: 2, h: 3), tier: 3,
                 requirements: StatRequirements(strength: 22)),
        BaseItem(baseName: "Arcane Orb",  slot: .offHand, baseStats: StatBonus(attackBonus: 4, defenseBonus: 3), size: ItemSize(w: 1, h: 2), tier: 3,
                 requirements: StatRequirements(intelligence: 18)),

        // MARK: Helm  (2×2)
        BaseItem(baseName: "Cap",        slot: .helm, baseStats: StatBonus(maxHp: 8),  size: ItemSize(w: 2, h: 2), tier: 1),
        BaseItem(baseName: "Helm",       slot: .helm, baseStats: StatBonus(maxHp: 14), size: ItemSize(w: 2, h: 2), tier: 2,
                 requirements: StatRequirements(strength: 10)),
        BaseItem(baseName: "Great Helm", slot: .helm, baseStats: StatBonus(maxHp: 20), size: ItemSize(w: 2, h: 2), tier: 3,
                 requirements: StatRequirements(strength: 20)),

        // MARK: Chest  (2×3 light, 2×4 heavy)
        BaseItem(baseName: "Leather Armor", slot: .chest, baseStats: StatBonus(maxHp: 5, defenseBonus: 2),   size: ItemSize(w: 2, h: 3), tier: 1),
        BaseItem(baseName: "Chain Mail",    slot: .chest, baseStats: StatBonus(maxHp: 8, defenseBonus: 4),   size: ItemSize(w: 2, h: 3), tier: 2,
                 requirements: StatRequirements(strength: 15)),
        BaseItem(baseName: "Plate Mail",    slot: .chest, baseStats: StatBonus(maxHp: 12, defenseBonus: 6),  size: ItemSize(w: 2, h: 4), tier: 3,
                 requirements: StatRequirements(strength: 25)),

        // MARK: Boots  (2×2)
        BaseItem(baseName: "Leather Boots", slot: .boots, baseStats: StatBonus(defenseBonus: 1),               size: ItemSize(w: 2, h: 2), tier: 1),
        BaseItem(baseName: "Greaves",       slot: .boots, baseStats: StatBonus(defenseBonus: 2, cardDrawBonus: 1), size: ItemSize(w: 2, h: 2), tier: 2,
                 requirements: StatRequirements(dexterity: 8)),
        BaseItem(baseName: "War Boots",     slot: .boots, baseStats: StatBonus(defenseBonus: 3, cardDrawBonus: 1), size: ItemSize(w: 2, h: 2), tier: 3,
                 requirements: StatRequirements(dexterity: 14)),

        // MARK: Ring  (1×1)
        BaseItem(baseName: "Ring",     slot: .ring, baseStats: StatBonus(attackBonus: 1), size: ItemSize(w: 1, h: 1), tier: 1),
        BaseItem(baseName: "Band",     slot: .ring, baseStats: StatBonus(maxHp: 8),       size: ItemSize(w: 1, h: 1), tier: 1),
        BaseItem(baseName: "Signet",   slot: .ring, baseStats: StatBonus(attackBonus: 2), size: ItemSize(w: 1, h: 1), tier: 2),
        BaseItem(baseName: "Rune Ring",slot: .ring, baseStats: StatBonus(energyBonus: 1), size: ItemSize(w: 1, h: 1), tier: 3),

        // MARK: Amulet  (1×1)
        BaseItem(baseName: "Amulet",    slot: .amulet, baseStats: StatBonus(attackBonus: 1, defenseBonus: 1), size: ItemSize(w: 1, h: 1), tier: 1),
        BaseItem(baseName: "Charm",     slot: .amulet, baseStats: StatBonus(maxHp: 10),                       size: ItemSize(w: 1, h: 1), tier: 1),
        BaseItem(baseName: "Talisman",  slot: .amulet, baseStats: StatBonus(attackBonus: 2, defenseBonus: 2), size: ItemSize(w: 1, h: 1), tier: 2),
        BaseItem(baseName: "Rune Stone",slot: .amulet, baseStats: StatBonus(attackBonus: 3, cardDrawBonus: 1), size: ItemSize(w: 1, h: 1), tier: 3),
    ]

    static func available(floor: Int) -> [BaseItem] {
        all.filter { $0.tier <= floor }
    }

    static func random(floor: Int, slot: EquipmentSlot? = nil) -> BaseItem? {
        var pool = available(floor: floor)
        if let slot { pool = pool.filter { $0.slot == slot } }
        return pool.randomElement()
    }
}
