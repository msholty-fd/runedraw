import Foundation

struct LootDatabase {

    // MARK: - Drop rate tables

    struct DropRates {
        let unique: Double
        let rare: Double
        let magic: Double
        // common = remainder

        static func rates(floor: Int, isBoss: Bool) -> DropRates {
            if isBoss {
                return DropRates(unique: 0.08, rare: 0.30, magic: 0.42)
            }
            switch floor {
            case 1:  return DropRates(unique: 0.005, rare: 0.045, magic: 0.25)
            case 2:  return DropRates(unique: 0.015, rare: 0.12,  magic: 0.35)
            default: return DropRates(unique: 0.03,  rare: 0.20,  magic: 0.40)
            }
        }

        func roll() -> CardRarity {
            let r = Double.random(in: 0..<1)
            if r < unique         { return .unique }
            if r < unique + rare  { return .rare }
            if r < unique + rare + magic { return .magic }
            return .common
        }
    }

    // MARK: - Main entry point

    /// Generates `count` loot items — a mix of equipment and combat cards.
    /// Pass `heroClass` so class-specific cards can drop alongside neutral ones.
    static func generateLoot(floorNumber: Int, isBoss: Bool, count: Int,
                             heroClass: HeroClass? = nil) -> [Card] {
        let rates = DropRates.rates(floor: floorNumber, isBoss: isBoss)
        var items: [Card] = []
        var attempts = 0
        while items.count < count && attempts < count * 10 {
            attempts += 1
            let rarity = rates.roll()
            // ~35% of drops are combat cards; bosses lean card-heavy at 55%
            let cardChance: Double = isBoss ? 0.55 : 0.35
            if Double.random(in: 0..<1) < cardChance, let hc = heroClass {
                if let card = CardDatabase.droppableCard(for: hc, rarity: rarity) {
                    items.append(card)
                }
            } else if let card = generate(rarity: rarity, floor: floorNumber) {
                items.append(card)
            }
        }
        return items
    }

    // MARK: - Item generators

    private static func generate(rarity: CardRarity, floor: Int) -> Card? {
        switch rarity {
        case .unique:  return generateUnique(floor: floor)
        case .rare:    return generateRare(floor: floor)
        case .magic:   return generateMagic(floor: floor)
        case .common:  return generateCommon(floor: floor)
        }
    }

    // Common — base item, no affixes
    private static func generateCommon(floor: Int) -> Card? {
        guard let base = BaseItemDatabase.random(floor: floor) else { return nil }
        return Card(name: base.baseName, description: base.activatedDescription, rarity: .common, slot: base.slot,
                    size: base.size, statBonus: base.baseStats,
                    requirements: base.requirements.isEmpty ? nil : base.requirements,
                    effect: base.activatedEffect, activatedCost: base.activatedCost)
    }

    // Magic — base item + 1 prefix OR suffix
    private static func generateMagic(floor: Int) -> Card? {
        guard let base = BaseItemDatabase.random(floor: floor) else { return nil }
        let reqs: StatRequirements? = base.requirements.isEmpty ? nil : base.requirements
        if Bool.random() {
            guard let pre = AffixDatabase.availablePrefixes(floor: floor).randomElement() else {
                return generateCommon(floor: floor)
            }
            let mod = ItemModifier(label: pre.label, bonus: pre.bonus)
            return Card(name: "\(prefixName(pre.label)) \(base.baseName)", description: base.activatedDescription,
                        rarity: .magic, slot: base.slot, size: base.size, statBonus: base.baseStats + pre.bonus,
                        modifiers: [mod], requirements: reqs,
                        effect: base.activatedEffect, activatedCost: base.activatedCost)
        } else {
            guard let suf = AffixDatabase.availableSuffixes(floor: floor).randomElement() else {
                return generateCommon(floor: floor)
            }
            let mod = ItemModifier(label: suf.label, bonus: suf.bonus)
            return Card(name: "\(base.baseName) \(suffixName(suf.label))", description: base.activatedDescription,
                        rarity: .magic, slot: base.slot, size: base.size, statBonus: base.baseStats + suf.bonus,
                        modifiers: [mod], requirements: reqs,
                        effect: base.activatedEffect, activatedCost: base.activatedCost)
        }
    }

    // Rare — base item + 2-4 affixes (mix of prefixes and suffixes)
    private static func generateRare(floor: Int) -> Card? {
        guard let base = BaseItemDatabase.random(floor: floor) else { return nil }
        let reqs: StatRequirements? = base.requirements.isEmpty ? nil : base.requirements
        let affixCount = Int.random(in: 2...4)
        var mods: [ItemModifier] = []
        var total = base.baseStats
        var prefixesUsed = 0
        var suffixesUsed = 0
        let avPre = AffixDatabase.availablePrefixes(floor: floor)
        let avSuf = AffixDatabase.availableSuffixes(floor: floor)

        for _ in 0..<affixCount {
            let usePre = Bool.random() && prefixesUsed < 3 && !avPre.isEmpty
            if usePre {
                guard let aff = avPre.randomElement() else { continue }
                // Avoid duplicate labels
                guard !mods.contains(where: { $0.label == aff.label }) else { continue }
                mods.append(ItemModifier(label: aff.label, bonus: aff.bonus))
                total += aff.bonus
                prefixesUsed += 1
            } else {
                guard suffixesUsed < 3 && !avSuf.isEmpty,
                      let aff = avSuf.randomElement() else { continue }
                guard !mods.contains(where: { $0.label == aff.label }) else { continue }
                mods.append(ItemModifier(label: aff.label, bonus: aff.bonus))
                total += aff.bonus
                suffixesUsed += 1
            }
        }

        let rareName = rareItemName()
        return Card(name: "\(rareName) \(base.baseName)", description: base.activatedDescription,
                    rarity: .rare, slot: base.slot, size: base.size, statBonus: total,
                    modifiers: mods, requirements: reqs,
                    effect: base.activatedEffect, activatedCost: base.activatedCost)
    }

    // Unique — pull from UniqueItemDatabase
    private static func generateUnique(floor: Int) -> Card? {
        guard let template = UniqueItemDatabase.random(floor: floor) else { return nil }
        let mods = template.modifierLabels.map { ItemModifier(label: $0, bonus: StatBonus()) }
        return Card(name: template.name, description: template.activatedDescription,
                    rarity: .unique, slot: template.slot, size: template.size, statBonus: template.stats,
                    modifiers: mods, isUnique: true, flavorText: template.flavorText,
                    effect: template.activatedEffect, activatedCost: template.activatedCost)
    }

    // MARK: - Naming helpers

    private static func prefixName(_ label: String) -> String {
        // Map bonus label → prefix adjective
        let map: [String: String] = [
            "+2 Attack": "Sharp",        "+4 Attack": "Cruel",     "+7 Attack": "Merciless",
            "+2 Defense": "Sturdy",      "+4 Defense": "Fortified","+7 Defense": "Impenetrable",
            "+10 Max HP": "Hale",        "+18 Max HP": "Vital",    "+28 Max HP": "Stalwart",
            "+2 Life on Kill": "Vampiric","+2 Starting Block": "Warding",
            "+3 Poison on Hit": "Corrupt",
        ]
        return map[label] ?? "Runed"
    }

    private static func suffixName(_ label: String) -> String {
        let map: [String: String] = [
            "+2 Attack": "of Strength",    "+10 Max HP": "of the Bear",  "+2 Defense": "of Blocking",
            "+2 Life on Kill": "of the Vampire", "+1 Card Draw": "of Speed",
            "+2 Starting Block": "of Warding",  "+1 Energy": "of Power",
            "+30 Max HP": "of the Colossus", "+3 Poison on Hit": "of Venom",
        ]
        return map[label] ?? "of the Rune"
    }

    private static let rareFirstWords = [
        "Death", "Doom", "Storm", "Blood", "Iron", "Shadow", "Grim", "Dark",
        "Ancient", "Bone", "Crow", "Dire", "Fell", "Ghost", "Hell", "Vile",
    ]
    private static let rareSecondWords = [
        "Bane", "Brand", "Crest", "Edge", "Fang", "Guard", "Mark", "Scar",
        "Toll", "Touch", "Veil", "Ward", "Web", "Wing", "Wrath", "Rune",
    ]

    private static func rareItemName() -> String {
        "\(rareFirstWords.randomElement()!)\(rareSecondWords.randomElement()!)"
    }
}
