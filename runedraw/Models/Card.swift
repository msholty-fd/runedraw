import SwiftUI

enum CardType: String, Codable {
    case attack = "Attack"
    case skill = "Skill"
    case power = "Power"
}

enum DamageType: String, Codable {
    case physical = "Physical"
    case fire     = "Fire"
    case ice      = "Ice"
    case arcane   = "Arcane"
    case poison   = "Poison"

    var icon: String {
        switch self {
        case .physical: return "⚔️"
        case .fire:     return "🔥"
        case .ice:      return "❄️"
        case .arcane:   return "✨"
        case .poison:   return "☠️"
        }
    }
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
    var poisonOnHit: Int = 0       // apply N poison stacks when playing physical attack cards
    var spellpowerBonus: Int = 0   // adds to spell damage (staves, wands, INT gear)

    var description: String {
        var parts: [String] = []
        if maxHp != 0         { parts.append("\(maxHp > 0 ? "+" : "")\(maxHp) Max HP") }
        if attackBonus != 0   { parts.append("\(attackBonus > 0 ? "+" : "")\(attackBonus) Attack") }
        if defenseBonus != 0  { parts.append("\(defenseBonus > 0 ? "+" : "")\(defenseBonus) Defense") }
        if energyBonus != 0   { parts.append("\(energyBonus > 0 ? "+" : "")\(energyBonus) Energy") }
        if cardDrawBonus != 0 { parts.append("\(cardDrawBonus > 0 ? "+" : "")\(cardDrawBonus) Card Draw") }
        if lifeOnKill != 0    { parts.append("+\(lifeOnKill) Life on Kill") }
        if startingBlock != 0 { parts.append("+\(startingBlock) Starting Block") }
        if poisonOnHit != 0      { parts.append("+\(poisonOnHit) Poison on Hit") }
        if spellpowerBonus != 0  { parts.append("\(spellpowerBonus > 0 ? "+" : "")\(spellpowerBonus) Spellpower") }
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
            poisonOnHit: lhs.poisonOnHit + rhs.poisonOnHit,
            spellpowerBonus: lhs.spellpowerBonus + rhs.spellpowerBonus
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
    var damageType: DamageType = .physical   // governs which stat scales damage
    var block: Int = 0
    var draw: Int = 0
    var energyGain: Int = 0
    var poisonStacks: Int = 0
    var weakStacks: Int = 0
    var vulnerableStacks: Int = 0
    var heal: Int = 0
    var damageAllEnemies: Bool = false
    var times: Int = 1
    // -- New mechanics --
    /// Card is permanently removed from the deck after use.
    var exhausts: Bool = false
    /// Grant N Strength — each stack adds +1 to all physical damage this combat.
    var strengthGain: Int = 0
    /// If the last card played this turn was an Attack, deal N bonus damage.
    var comboBonus: Int = 0
    /// Apply N burn stacks to the targeted enemy (fire DoT, ticks like poison).
    var applyBurn: Int = 0
    /// Apply `applyBurn` stacks to ALL enemies instead of just the target.
    var applyBurnAll: Bool = false
    /// Deal damage equal to hero's current block (Shield Slam style).
    var damageFromBlock: Bool = false
    /// Your next attack card this turn deals double damage.
    var amplifyNext: Bool = false
    /// Apply N bleed stacks to the target. Bleed triggers when hero hits: each physical attack
    /// hit triggers a bleed tick (deal bleedStacks damage, decrement by 1).
    var applyBleed: Int = 0
    /// Apply N chill stacks to the target. At freezeThreshold stacks, enemy is Frozen.
    var applyChillStacks: Int = 0
    /// ⚡ Arcane bonus: if this is the Nth+ card played this turn (N = skillPassives.arcaneThreshold),
    /// deal this many extra arcane damage. 0 = no arcane keyword.
    var arcaneBonus: Int = 0

    // MARK: - Custom decoder for backward compatibility

    enum CodingKeys: String, CodingKey {
        case damage, damageType, block, draw, energyGain, poisonStacks, weakStacks
        case vulnerableStacks, heal, damageAllEnemies, times
        case exhausts, strengthGain, comboBonus, applyBurn, applyBurnAll, damageFromBlock, amplifyNext
        case applyBleed, applyChillStacks, arcaneBonus
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        damage           = try c.decodeIfPresent(Int.self,       forKey: .damage) ?? 0
        damageType       = try c.decodeIfPresent(DamageType.self, forKey: .damageType) ?? .physical
        block            = try c.decodeIfPresent(Int.self,       forKey: .block) ?? 0
        draw             = try c.decodeIfPresent(Int.self,       forKey: .draw) ?? 0
        energyGain       = try c.decodeIfPresent(Int.self,       forKey: .energyGain) ?? 0
        poisonStacks     = try c.decodeIfPresent(Int.self,       forKey: .poisonStacks) ?? 0
        weakStacks       = try c.decodeIfPresent(Int.self,       forKey: .weakStacks) ?? 0
        vulnerableStacks = try c.decodeIfPresent(Int.self,       forKey: .vulnerableStacks) ?? 0
        heal             = try c.decodeIfPresent(Int.self,       forKey: .heal) ?? 0
        damageAllEnemies = try c.decodeIfPresent(Bool.self,      forKey: .damageAllEnemies) ?? false
        times            = try c.decodeIfPresent(Int.self,       forKey: .times) ?? 1
        exhausts         = try c.decodeIfPresent(Bool.self,      forKey: .exhausts) ?? false
        strengthGain     = try c.decodeIfPresent(Int.self,       forKey: .strengthGain) ?? 0
        comboBonus       = try c.decodeIfPresent(Int.self,       forKey: .comboBonus) ?? 0
        applyBurn        = try c.decodeIfPresent(Int.self,       forKey: .applyBurn) ?? 0
        applyBurnAll     = try c.decodeIfPresent(Bool.self,      forKey: .applyBurnAll) ?? false
        damageFromBlock  = try c.decodeIfPresent(Bool.self,      forKey: .damageFromBlock) ?? false
        amplifyNext      = try c.decodeIfPresent(Bool.self,      forKey: .amplifyNext) ?? false
        applyBleed       = try c.decodeIfPresent(Int.self,       forKey: .applyBleed) ?? 0
        applyChillStacks = try c.decodeIfPresent(Int.self,       forKey: .applyChillStacks) ?? 0
        arcaneBonus      = try c.decodeIfPresent(Int.self,       forKey: .arcaneBonus) ?? 0
    }

    init(damage: Int = 0, damageType: DamageType = .physical, block: Int = 0,
         draw: Int = 0, energyGain: Int = 0, poisonStacks: Int = 0,
         weakStacks: Int = 0, vulnerableStacks: Int = 0, heal: Int = 0,
         damageAllEnemies: Bool = false, times: Int = 1, exhausts: Bool = false,
         strengthGain: Int = 0, comboBonus: Int = 0, applyBurn: Int = 0,
         applyBurnAll: Bool = false, damageFromBlock: Bool = false, amplifyNext: Bool = false,
         applyBleed: Int = 0, applyChillStacks: Int = 0, arcaneBonus: Int = 0) {
        self.damage           = damage
        self.damageType       = damageType
        self.block            = block
        self.draw             = draw
        self.energyGain       = energyGain
        self.poisonStacks     = poisonStacks
        self.weakStacks       = weakStacks
        self.vulnerableStacks = vulnerableStacks
        self.heal             = heal
        self.damageAllEnemies = damageAllEnemies
        self.times            = times
        self.exhausts         = exhausts
        self.strengthGain     = strengthGain
        self.comboBonus       = comboBonus
        self.applyBurn        = applyBurn
        self.applyBurnAll     = applyBurnAll
        self.damageFromBlock  = damageFromBlock
        self.amplifyNext      = amplifyNext
        self.applyBleed       = applyBleed
        self.applyChillStacks = applyChillStacks
        self.arcaneBonus      = arcaneBonus
    }
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
    /// How much incoming damage this card absorbs when used as a block reaction.
    /// Tapping a card during the block phase commits it — card discards, damage reduced.
    var defenseValue: Int
    var activatedCost: Int = 0

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
        effect: CardEffect,
        defenseValue: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.cost = cost
        self.type = type
        self.rarity = rarity
        self.heroClass = heroClass
        self.effect = effect
        self.defenseValue = defenseValue
        self.activatedCost = 0
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
        requirements: StatRequirements? = nil,
        effect: CardEffect = CardEffect(),
        activatedCost: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.cost = 0
        self.type = .skill
        self.rarity = rarity
        self.heroClass = nil
        self.effect = effect
        self.defenseValue = 0           // equipment doesn't block in combat
        self.activatedCost = activatedCost
        self.equipmentSlot = slot
        self.statBonus = statBonus
        self.size = size
        self.modifiers = modifiers
        self.isUnique = isUnique
        self.flavorText = flavorText
        self.requirements = requirements
    }

    // MARK: - Custom Codable (decodeIfPresent for backward-compat with old saves)

    enum CodingKeys: String, CodingKey {
        case id, name, description, cost, type, rarity, heroClass, effect
        case equipmentSlot, statBonus, size, modifiers, isUnique, flavorText
        case requirements, defenseValue, activatedCost
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self,              forKey: .id)
        name          = try c.decode(String.self,            forKey: .name)
        description   = try c.decode(String.self,            forKey: .description)
        cost          = try c.decode(Int.self,               forKey: .cost)
        type          = try c.decode(CardType.self,          forKey: .type)
        rarity        = try c.decode(CardRarity.self,        forKey: .rarity)
        heroClass     = try c.decodeIfPresent(HeroClass.self,      forKey: .heroClass)
        effect        = try c.decode(CardEffect.self,        forKey: .effect)
        equipmentSlot = try c.decodeIfPresent(EquipmentSlot.self,  forKey: .equipmentSlot)
        statBonus     = try c.decodeIfPresent(StatBonus.self,      forKey: .statBonus)
        size          = try c.decodeIfPresent(ItemSize.self,       forKey: .size) ?? ItemSize(w: 1, h: 1)
        modifiers     = try c.decodeIfPresent([ItemModifier].self, forKey: .modifiers) ?? []
        isUnique      = try c.decodeIfPresent(Bool.self,           forKey: .isUnique) ?? false
        flavorText    = try c.decodeIfPresent(String.self,         forKey: .flavorText)
        requirements  = try c.decodeIfPresent(StatRequirements.self, forKey: .requirements)
        defenseValue  = try c.decodeIfPresent(Int.self,            forKey: .defenseValue) ?? 0
        activatedCost = try c.decodeIfPresent(Int.self,            forKey: .activatedCost) ?? 0
    }
}
