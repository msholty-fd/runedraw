import SwiftUI

enum CardType: String, Codable {
    case attack = "Attack"
    case skill = "Skill"
    case power = "Power"
}

enum CardRarity: String, Codable {
    case common = "Common"
    case magic = "Magic"
    case rare = "Rare"
    case unique = "Unique"

    var color: Color {
        switch self {
        case .common: return .white
        case .magic:  return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .rare:   return Color(red: 0.9, green: 0.7, blue: 0.1)
        case .unique: return Color(red: 0.8, green: 0.3, blue: 1.0)
        }
    }
}

enum EquipmentSlot: String, CaseIterable, Codable {
    case weapon = "Weapon"
    case offHand = "Off-Hand"
    case helm = "Helm"
    case chest = "Chest"
    case boots = "Boots"
    case ring = "Ring"
    case amulet = "Amulet"

    var icon: String {
        switch self {
        case .weapon:  return "⚔️"
        case .offHand: return "🛡️"
        case .helm:    return "⛑️"
        case .chest:   return "🧥"
        case .boots:   return "👢"
        case .ring:    return "💍"
        case .amulet:  return "📿"
        }
    }
}

// MARK: - Stat Requirements (for equipping items)

struct StatRequirements: Codable, Equatable {
    var strength: Int = 0
    var dexterity: Int = 0
    var intelligence: Int = 0

    var isEmpty: Bool { strength == 0 && dexterity == 0 && intelligence == 0 }

    var description: String {
        var parts: [String] = []
        if strength > 0     { parts.append("STR \(strength)") }
        if dexterity > 0    { parts.append("DEX \(dexterity)") }
        if intelligence > 0 { parts.append("INT \(intelligence)") }
        return parts.joined(separator: " · ")
    }
}

struct StatBonus: Codable {
    var maxHp: Int = 0
    var attackBonus: Int = 0
    var defenseBonus: Int = 0
    var energyBonus: Int = 0
    var cardDrawBonus: Int = 0
    var lifeOnKill: Int = 0        // heal X when any enemy dies this combat
    var startingBlock: Int = 0     // start each combat turn with X block
    var poisonOnHit: Int = 0       // apply N poison stacks when playing attack cards

    var description: String {
        var parts: [String] = []
        if maxHp != 0         { parts.append("\(maxHp > 0 ? "+" : "")\(maxHp) Max HP") }
        if attackBonus != 0   { parts.append("\(attackBonus > 0 ? "+" : "")\(attackBonus) Attack") }
        if defenseBonus != 0  { parts.append("\(defenseBonus > 0 ? "+" : "")\(defenseBonus) Defense") }
        if energyBonus != 0   { parts.append("\(energyBonus > 0 ? "+" : "")\(energyBonus) Energy") }
        if cardDrawBonus != 0 { parts.append("\(cardDrawBonus > 0 ? "+" : "")\(cardDrawBonus) Card Draw") }
        if lifeOnKill != 0    { parts.append("+\(lifeOnKill) Life on Kill") }
        if startingBlock != 0 { parts.append("+\(startingBlock) Starting Block") }
        if poisonOnHit != 0   { parts.append("+\(poisonOnHit) Poison on Hit") }
        return parts.joined(separator: "\n")
    }

    static func += (lhs: inout StatBonus, rhs: StatBonus) {
        lhs = lhs + rhs
    }

    static func + (lhs: StatBonus, rhs: StatBonus) -> StatBonus {
        StatBonus(
            maxHp: lhs.maxHp + rhs.maxHp,
            attackBonus: lhs.attackBonus + rhs.attackBonus,
            defenseBonus: lhs.defenseBonus + rhs.defenseBonus,
            energyBonus: lhs.energyBonus + rhs.energyBonus,
            cardDrawBonus: lhs.cardDrawBonus + rhs.cardDrawBonus,
            lifeOnKill: lhs.lifeOnKill + rhs.lifeOnKill,
            startingBlock: lhs.startingBlock + rhs.startingBlock,
            poisonOnHit: lhs.poisonOnHit + rhs.poisonOnHit
        )
    }
}

// A single affix line shown on an item (prefix or suffix)
// Grid footprint of an item in the inventory
struct ItemSize: Codable, Equatable {
    let w: Int   // columns
    let h: Int   // rows
}

// A single affix line shown on an item (prefix or suffix)
struct ItemModifier: Codable {
    let label: String
    let bonus: StatBonus
}

struct CardEffect: Codable {
    var damage: Int = 0
    var block: Int = 0
    var draw: Int = 0
    var energyGain: Int = 0
    var poisonStacks: Int = 0
    var weakStacks: Int = 0
    var vulnerableStacks: Int = 0
    var heal: Int = 0
    var damageAllEnemies: Bool = false
    var times: Int = 1
}

struct Card: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let cost: Int
    let type: CardType
    let rarity: CardRarity
    let heroClass: HeroClass?
    let effect: CardEffect
    let equipmentSlot: EquipmentSlot?
    let statBonus: StatBonus?
    let size: ItemSize                  // grid footprint (1x1 for combat cards)
    // Diablo-style affix display lines (magic/rare/unique items)
    let modifiers: [ItemModifier]
    let isUnique: Bool
    let flavorText: String?
    let requirements: StatRequirements?   // nil = no requirement

    var isEquipment: Bool { equipmentSlot != nil }

    var typeIcon: String {
        switch type {
        case .attack: return "⚔️"
        case .skill:  return "🛡️"
        case .power:  return "⚡"
        }
    }

    // MARK: - Combat card init
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        cost: Int,
        type: CardType,
        rarity: CardRarity = .common,
        heroClass: HeroClass? = nil,
        effect: CardEffect
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.cost = cost
        self.type = type
        self.rarity = rarity
        self.heroClass = heroClass
        self.effect = effect
        self.equipmentSlot = nil
        self.statBonus = nil
        self.size = ItemSize(w: 1, h: 1)
        self.modifiers = []
        self.isUnique = false
        self.flavorText = nil
        self.requirements = nil
    }

    // MARK: - Equipment card init
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        rarity: CardRarity = .common,
        slot: EquipmentSlot,
        size: ItemSize,
        statBonus: StatBonus,
        modifiers: [ItemModifier] = [],
        isUnique: Bool = false,
        flavorText: String? = nil,
        requirements: StatRequirements? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.cost = 0
        self.type = .skill
        self.rarity = rarity
        self.heroClass = nil
        self.effect = CardEffect()
        self.equipmentSlot = slot
        self.statBonus = statBonus
        self.size = size
        self.modifiers = modifiers
        self.isUnique = isUnique
        self.flavorText = flavorText
        self.requirements = requirements
    }

    // MARK: - Custom Codable (decodeIfPresent for new fields → save compat)
    // Synthesized Codable handles all fields automatically
}
