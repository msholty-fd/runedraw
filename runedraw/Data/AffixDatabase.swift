import Foundation

// A prefix or suffix that can be rolled onto magic/rare items
struct Affix {
    let label: String        // displayed on the card, e.g. "+5 Attack"
    let bonus: StatBonus
    let tier: Int            // 1 = floor 1+, 2 = floor 2+, 3 = floor 3+
}

struct AffixDatabase {

    // MARK: - Prefixes (go before the base item name)

    static let prefixes: [Affix] = [
        // T1
        Affix(label: "+2 Attack",          bonus: StatBonus(attackBonus: 2),                tier: 1),
        Affix(label: "+2 Defense",         bonus: StatBonus(defenseBonus: 2),              tier: 1),
        Affix(label: "+10 Max HP",         bonus: StatBonus(maxHp: 10),                    tier: 1),
        // T2
        Affix(label: "+4 Attack",          bonus: StatBonus(attackBonus: 4),                tier: 2),
        Affix(label: "+4 Defense",         bonus: StatBonus(defenseBonus: 4),              tier: 2),
        Affix(label: "+18 Max HP",         bonus: StatBonus(maxHp: 18),                    tier: 2),
        Affix(label: "+2 Life on Kill",    bonus: StatBonus(lifeOnKill: 2),                tier: 2),
        Affix(label: "+2 Starting Block",  bonus: StatBonus(startingBlock: 2),             tier: 2),
        // T3
        Affix(label: "+7 Attack",          bonus: StatBonus(attackBonus: 7),                tier: 3),
        Affix(label: "+7 Defense",         bonus: StatBonus(defenseBonus: 7),              tier: 3),
        Affix(label: "+28 Max HP",         bonus: StatBonus(maxHp: 28),                    tier: 3),
        Affix(label: "+3 Poison on Hit",   bonus: StatBonus(poisonOnHit: 3),               tier: 3),
    ]

    // MARK: - Suffixes (go after the base item name)

    static let suffixes: [Affix] = [
        // T1
        Affix(label: "+2 Attack",          bonus: StatBonus(attackBonus: 2),                tier: 1),
        Affix(label: "+10 Max HP",         bonus: StatBonus(maxHp: 10),                    tier: 1),
        Affix(label: "+2 Defense",         bonus: StatBonus(defenseBonus: 2),              tier: 1),
        // T2
        Affix(label: "+2 Life on Kill",    bonus: StatBonus(lifeOnKill: 2),                tier: 2),
        Affix(label: "+1 Card Draw",       bonus: StatBonus(cardDrawBonus: 1),             tier: 2),
        Affix(label: "+2 Starting Block",  bonus: StatBonus(startingBlock: 2),             tier: 2),
        // T3
        Affix(label: "+1 Energy",          bonus: StatBonus(energyBonus: 1),               tier: 3),
        Affix(label: "+30 Max HP",         bonus: StatBonus(maxHp: 30),                    tier: 3),
        Affix(label: "+3 Poison on Hit",   bonus: StatBonus(poisonOnHit: 3),               tier: 3),
    ]

    // MARK: - Helpers

    static func availablePrefixes(floor: Int) -> [Affix] {
        prefixes.filter { $0.tier <= floor }
    }

    static func availableSuffixes(floor: Int) -> [Affix] {
        suffixes.filter { $0.tier <= floor }
    }
}
