import SwiftUI

// MARK: - Hero Stats

struct HeroStats: Codable {
    var strength: Int = 0
    var dexterity: Int = 0
    var vitality: Int = 0
    var intelligence: Int = 0

    subscript(key: StatKey) -> Int {
        get {
            switch key {
            case .strength:     return strength
            case .dexterity:    return dexterity
            case .vitality:     return vitality
            case .intelligence: return intelligence
            }
        }
        set {
            switch key {
            case .strength:     strength     = newValue
            case .dexterity:    dexterity    = newValue
            case .vitality:     vitality     = newValue
            case .intelligence: intelligence = newValue
            }
        }
    }
}

enum StatKey: String, CaseIterable, Codable {
    case strength     = "Strength"
    case dexterity    = "Dexterity"
    case vitality     = "Vitality"
    case intelligence = "Intelligence"

    var icon: String {
        switch self {
        case .strength:     return "⚔️"
        case .dexterity:    return "🏃"
        case .vitality:     return "❤️"
        case .intelligence: return "🔮"
        }
    }

    var shortName: String {
        switch self {
        case .strength:     return "STR"
        case .dexterity:    return "DEX"
        case .vitality:     return "VIT"
        case .intelligence: return "INT"
        }
    }

    var effectDescription: String {
        switch self {
        case .strength:     return "+1 Attack per 5 pts · unlocks heavy gear"
        case .dexterity:    return "+1 Defense per 5 pts · unlocks light gear"
        case .vitality:     return "+1 card restored per 3 VIT · physical resilience"
        case .intelligence: return "+1 Spellpower per 4 pts · +1 Energy per 10 pts · unlocks magic gear"
        }
    }

    var themeColor: Color {
        switch self {
        case .strength:     return Color(red: 1.0, green: 0.45, blue: 0.2)
        case .dexterity:    return Color(red: 0.2, green: 0.85, blue: 0.6)
        case .vitality:     return Color(red: 1.0, green: 0.3,  blue: 0.3)
        case .intelligence: return Color(red: 0.55, green: 0.4, blue: 1.0)
        }
    }
}

// MARK: - HeroClass

enum HeroClass: String, CaseIterable, Identifiable, Codable {
    case barbarian = "Barbarian"
    case rogue     = "Rogue"
    case sorceress = "Sorceress"

    var id: String { rawValue }

    var lore: String {
        switch self {
        case .barbarian: return "A mighty warrior from the northern highlands. Deals heavy damage and absorbs punishment."
        case .rogue:     return "A cunning assassin who strikes from the shadows. Masters of poison and deception."
        case .sorceress: return "A scholar of the arcane arts who commands powerful elemental magic."
        }
    }

    /// Short mechanic summary shown on the class select screen and the character profile.
    /// Add a case here for each new class introduced.
    var playstyle: String {
        switch self {
        case .barbarian:
            return "When your deck runs out, all Strength built up this combat is lost."
        case .rogue:
            return "Cycling through your full deck carries no penalty."
        case .sorceress:
            return "Each time your deck runs out, you take arcane backlash damage — and it increases with every recycle."
        }
    }

    /// One-line recycle penalty description shown in the profile.
    var recyclePenaltyLabel: String {
        switch self {
        case .barbarian: return "Deck exhaustion: lose all Strength"
        case .rogue:     return "Deck exhaustion: no penalty"
        case .sorceress: return "Deck exhaustion: arcane backlash (escalating)"
        }
    }

    var baseMaxHp: Int {
        switch self {
        case .barbarian: return 80
        case .rogue:     return 65
        case .sorceress: return 55
        }
    }

    var baseEnergy: Int { 3 }
    var baseCardDraw: Int { 5 }

    // Stat growth per level
    var hpPerLevel: Int {
        switch self {
        case .barbarian: return 8
        case .rogue:     return 5
        case .sorceress: return 4
        }
    }
    var attackPerLevel: Int {
        switch self {
        case .barbarian: return 1
        case .rogue:     return 1
        case .sorceress: return 0
        }
    }
    var defensePerLevel: Int {
        switch self {
        case .barbarian: return 0
        case .rogue:     return 0
        case .sorceress: return 1
        }
    }

    var icon: String {
        switch self {
        case .barbarian: return "⚔️"
        case .rogue:     return "🗡️"
        case .sorceress: return "🔮"
        }
    }

    var themeColor: Color {
        switch self {
        case .barbarian: return .red
        case .rogue:     return .green
        case .sorceress: return .purple
        }
    }

    var statsLabel: String {
        "HP: \(baseMaxHp)  •  Energy: \(baseEnergy)"
    }

    // Starting attribute points (before any allocation)
    var startingStats: HeroStats {
        switch self {
        case .barbarian: return HeroStats(strength: 10, dexterity: 5, vitality: 5, intelligence: 0)
        case .rogue:     return HeroStats(strength: 5, dexterity: 10, vitality: 5, intelligence: 5)
        case .sorceress: return HeroStats(strength: 0, dexterity: 5, vitality: 5, intelligence: 10)
        }
    }
}

// HeroEquipment — kept as an empty stub so old save files decode without crashing.
// Equipment has been removed from gameplay; this type is never populated at runtime.
struct HeroEquipment: Codable {}

// MARK: - Skill Passives

struct SkillPassives: Codable {
    // ── Numeric bonuses (additive) ──────────────────────────────────────────
    var attackBonus: Int = 0
    var defenseBonus: Int = 0
    var spellpowerBonus: Int = 0
    var drawPerTurn: Int = 0
    var maxEnergyBonus: Int = 0
    var lifeOnKill: Int = 0
    var startingBlock: Int = 0
    var poisonOnHit: Int = 0
    var energyOnKill: Int = 0
    // maxHpBonus is NOT stored here — it's applied directly to hero.maxHp on unlock

    // ── Barbarian keywords ──────────────────────────────────────────────────
    /// +N Strength each time hero takes damage in the block phase.
    var rageOnHit: Int = 0
    /// Heal N HP for each physical attack queued (per logical hit, respects `times`).
    var lifeStealPerHit: Int = 0
    /// After killing an enemy, the next card you play this turn costs 0.
    var hasBloodlust: Bool = false
    /// After a kill, draw 1 card.
    var hasRampage: Bool = false
    /// After a kill, gain +3 Strength this combat.
    var hasWarlordGambit: Bool = false
    /// Once per combat: survive a lethal blow at 1 HP instead of dying.
    var hasEndure: Bool = false
    /// Block does not reset between turns; instead startingBlock is added to leftover block.
    var hasJuggernaut: Bool = false

    // ── Rogue keywords ──────────────────────────────────────────────────────
    /// Start each combat with N dodge charges. Each charge auto-blocks one incoming attack.
    var evasionCharges: Int = 0
    /// After using an evasion dodge, gain +2 Strength this combat.
    var hasUntouchable: Bool = false
    /// Physical attacks apply N Bleed stacks. Bleed ticks on every physical hit.
    var bleedOnHit: Int = 0
    /// Attacks deal +N damage per status effect stack on the targeted enemy.
    var backstabPerStack: Int = 0
    /// Applying any status effect to an enemy also applies 1 Vulnerable.
    var hasShadowMark: Bool = false
    /// When a target has 4+ total status stacks, your next attack this turn costs 0.
    var hasAssassinate: Bool = false
    /// When an enemy dies with Bleed stacks, those stacks transfer to a random living enemy.
    var hasDeathCuts: Bool = false

    // ── Sorceress keywords ──────────────────────────────────────────────────
    /// Ice attacks apply N Chill stacks. At freezeThreshold stacks, enemy is Frozen.
    var chillOnHit: Int = 0
    /// Chill stacks needed to freeze an enemy. 0 = chill mechanic not yet unlocked.
    var freezeThreshold: Int = 0
    /// Attacking a Frozen enemy deals 2× damage and consumes the Freeze.
    var hasShatter: Bool = false
    /// Frozen enemies stay frozen for 2 turns instead of 1; chill doesn't reset after freeze.
    var hasPermafrost: Bool = false
    /// When any enemy's burn stacks reach this value, they explode for AoE damage. 0 = disabled.
    var igniteBurstThreshold: Int = 0
    /// When an enemy dies while burning, spread 5 burn stacks to all remaining enemies.
    var hasConflagration: Bool = false
    /// ⚡ Arcane threshold: cards with arcaneBonus > 0 trigger when this is the Nth+ card played
    /// this turn. 0 = Arcane keyword disabled. Decreasing this (e.g. to 2) upgrades the mechanic.
    var arcaneThreshold: Int = 0
    /// Multiplier applied to a card's arcaneBonus when Arcane triggers. Default 1.0.
    var arcaneMultiplier: Double = 1.0

    // MARK: - Custom Codable (decodeIfPresent for all fields — save compat)

    enum CodingKeys: String, CodingKey {
        case attackBonus, defenseBonus, spellpowerBonus, drawPerTurn, maxEnergyBonus
        case lifeOnKill, startingBlock, poisonOnHit, energyOnKill
        case rageOnHit, lifeStealPerHit, hasBloodlust, hasRampage, hasWarlordGambit
        case hasEndure, hasJuggernaut
        case evasionCharges, hasUntouchable, bleedOnHit, backstabPerStack
        case hasShadowMark, hasAssassinate, hasDeathCuts
        case chillOnHit, freezeThreshold, hasShatter, hasPermafrost
        case igniteBurstThreshold, hasConflagration, arcaneThreshold, arcaneMultiplier
    }

    init() {}   // memberwise default

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        attackBonus      = try c.decodeIfPresent(Int.self,    forKey: .attackBonus) ?? 0
        defenseBonus     = try c.decodeIfPresent(Int.self,    forKey: .defenseBonus) ?? 0
        spellpowerBonus  = try c.decodeIfPresent(Int.self,    forKey: .spellpowerBonus) ?? 0
        drawPerTurn      = try c.decodeIfPresent(Int.self,    forKey: .drawPerTurn) ?? 0
        maxEnergyBonus   = try c.decodeIfPresent(Int.self,    forKey: .maxEnergyBonus) ?? 0
        lifeOnKill       = try c.decodeIfPresent(Int.self,    forKey: .lifeOnKill) ?? 0
        startingBlock    = try c.decodeIfPresent(Int.self,    forKey: .startingBlock) ?? 0
        poisonOnHit      = try c.decodeIfPresent(Int.self,    forKey: .poisonOnHit) ?? 0
        energyOnKill     = try c.decodeIfPresent(Int.self,    forKey: .energyOnKill) ?? 0
        rageOnHit        = try c.decodeIfPresent(Int.self,    forKey: .rageOnHit) ?? 0
        lifeStealPerHit  = try c.decodeIfPresent(Int.self,    forKey: .lifeStealPerHit) ?? 0
        hasBloodlust     = try c.decodeIfPresent(Bool.self,   forKey: .hasBloodlust) ?? false
        hasRampage       = try c.decodeIfPresent(Bool.self,   forKey: .hasRampage) ?? false
        hasWarlordGambit = try c.decodeIfPresent(Bool.self,   forKey: .hasWarlordGambit) ?? false
        hasEndure        = try c.decodeIfPresent(Bool.self,   forKey: .hasEndure) ?? false
        hasJuggernaut    = try c.decodeIfPresent(Bool.self,   forKey: .hasJuggernaut) ?? false
        evasionCharges   = try c.decodeIfPresent(Int.self,    forKey: .evasionCharges) ?? 0
        hasUntouchable   = try c.decodeIfPresent(Bool.self,   forKey: .hasUntouchable) ?? false
        bleedOnHit       = try c.decodeIfPresent(Int.self,    forKey: .bleedOnHit) ?? 0
        backstabPerStack = try c.decodeIfPresent(Int.self,    forKey: .backstabPerStack) ?? 0
        hasShadowMark    = try c.decodeIfPresent(Bool.self,   forKey: .hasShadowMark) ?? false
        hasAssassinate   = try c.decodeIfPresent(Bool.self,   forKey: .hasAssassinate) ?? false
        hasDeathCuts     = try c.decodeIfPresent(Bool.self,   forKey: .hasDeathCuts) ?? false
        chillOnHit       = try c.decodeIfPresent(Int.self,    forKey: .chillOnHit) ?? 0
        freezeThreshold  = try c.decodeIfPresent(Int.self,    forKey: .freezeThreshold) ?? 0
        hasShatter       = try c.decodeIfPresent(Bool.self,   forKey: .hasShatter) ?? false
        hasPermafrost    = try c.decodeIfPresent(Bool.self,   forKey: .hasPermafrost) ?? false
        igniteBurstThreshold = try c.decodeIfPresent(Int.self, forKey: .igniteBurstThreshold) ?? 0
        hasConflagration = try c.decodeIfPresent(Bool.self,   forKey: .hasConflagration) ?? false
        arcaneThreshold  = try c.decodeIfPresent(Int.self,    forKey: .arcaneThreshold) ?? 0
        arcaneMultiplier = try c.decodeIfPresent(Double.self,  forKey: .arcaneMultiplier) ?? 1.0
    }
}

// MARK: - Hero

struct Hero: Codable {
    let heroClass: HeroClass
    var deck: [Card]
    var hand: [Card]
    var discardPile: [Card]
    var exiledCards: [Card] = []

    // Leveling
    var level: Int = 1
    var experience: Int = 0
    var baseAttackBonus: Int = 0      // legacy: kept for save compat, new games stay at 0
    var baseDefenseBonus: Int = 0     // legacy: kept for save compat

    // Attributes
    var stats: HeroStats = HeroStats()
    var statPoints: Int = 0            // unspent points gained on level-up

    // Skill tree
    var skillPoints: Int = 0
    var unlockedSkills: [String] = []
    var skillPassives: SkillPassives = SkillPassives()

    // Combat buffs — accumulate during a fight, reset when combat ends
    var combatStrength: Int = 0

    // Waypoints (area indices with discovered waypoints)
    var unlockedWaypoints: [Int] = []

    // Card collection — all cards the player owns but hasn't put in their active deck
    var cardCollection: [Card] = []

    // Deck-size limits
    static let minDeckSize = 20
    static let maxDeckSize = 60

    // Combat state
    var currentEnergy: Int
    var block: Int = 0
    var poisonStacks: Int = 0
    var weakStacks: Int = 0
    var vulnerableStacks: Int = 0

    // Explicit CodingKeys for all stored properties.
    // Old save files may contain extra keys (e.g. "equipment", "inventory") that are
    // no longer stored here; JSONDecoder ignores unknown keys by default so those are
    // silently discarded without needing to list them.
    enum CodingKeys: String, CodingKey {
        case heroClass, deck, hand, discardPile, exiledCards
        case currentEnergy, block, poisonStacks, weakStacks, vulnerableStacks
        case level, experience, baseAttackBonus, baseDefenseBonus
        case stats, statPoints
        // Note: gold and townPortals have been removed from gameplay.
        // JSONDecoder silently ignores unknown keys, so old saves that still contain
        // "gold" or "townPortals" JSON fields will load without crashing.
        case skillPoints, unlockedSkills, skillPassives
        case combatStrength, unlockedWaypoints, cardCollection
    }

    init(heroClass: HeroClass, startingDeck: [Card]) {
        self.heroClass        = heroClass
        self.deck             = startingDeck.shuffled()
        self.hand             = []
        self.discardPile      = []
        self.exiledCards      = []
        self.currentEnergy    = heroClass.baseEnergy
        self.level            = 1
        self.experience       = 0
        self.baseAttackBonus  = 0
        self.baseDefenseBonus = 0
        self.stats            = heroClass.startingStats
        self.statPoints       = 0
        self.skillPoints        = 0
        self.unlockedSkills     = []
        self.unlockedWaypoints  = []
    }

    // Custom decode so old saves without new fields still load
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        heroClass        = try c.decode(HeroClass.self,       forKey: .heroClass)
        // Old saves had "equipment" and "inventory" keys — JSONDecoder ignores them automatically.
        deck             = try c.decode([Card].self,          forKey: .deck)
        hand             = try c.decode([Card].self,          forKey: .hand)
        discardPile      = try c.decode([Card].self,          forKey: .discardPile)
        exiledCards      = try c.decodeIfPresent([Card].self, forKey: .exiledCards) ?? []
        currentEnergy    = try c.decode(Int.self,             forKey: .currentEnergy)
        block            = try c.decodeIfPresent(Int.self,    forKey: .block) ?? 0
        poisonStacks     = try c.decodeIfPresent(Int.self,    forKey: .poisonStacks) ?? 0
        weakStacks       = try c.decodeIfPresent(Int.self,    forKey: .weakStacks) ?? 0
        vulnerableStacks = try c.decodeIfPresent(Int.self,    forKey: .vulnerableStacks) ?? 0
        level            = try c.decodeIfPresent(Int.self,       forKey: .level) ?? 1
        experience       = try c.decodeIfPresent(Int.self,       forKey: .experience) ?? 0
        baseAttackBonus  = try c.decodeIfPresent(Int.self,       forKey: .baseAttackBonus) ?? 0
        baseDefenseBonus = try c.decodeIfPresent(Int.self,       forKey: .baseDefenseBonus) ?? 0
        stats            = try c.decodeIfPresent(HeroStats.self, forKey: .stats) ?? heroClass.startingStats
        statPoints       = try c.decodeIfPresent(Int.self,       forKey: .statPoints) ?? 0
        // gold and townPortals removed — JSONDecoder ignores unknown keys automatically.
        skillPoints         = try c.decodeIfPresent(Int.self,    forKey: .skillPoints) ?? 0
        unlockedSkills      = try c.decodeIfPresent([String].self, forKey: .unlockedSkills) ?? []
        unlockedWaypoints   = try c.decodeIfPresent([Int].self,  forKey: .unlockedWaypoints) ?? []
        cardCollection      = try c.decodeIfPresent([Card].self, forKey: .cardCollection) ?? []
        combatStrength      = try c.decodeIfPresent(Int.self,    forKey: .combatStrength) ?? 0
        skillPassives       = try c.decodeIfPresent(SkillPassives.self, forKey: .skillPassives) ?? SkillPassives()
    }

    var maxEnergy: Int      { heroClass.baseEnergy + stats.intelligence / 10 + skillPassives.maxEnergyBonus }
    var cardDrawCount: Int  { heroClass.baseCardDraw + skillPassives.drawPerTurn }
    var attackBonus: Int    { baseAttackBonus + stats.strength / 5 + skillPassives.attackBonus }
    var defenseBonus: Int   { baseDefenseBonus + stats.dexterity / 5 + skillPassives.defenseBonus }
    var spellpower: Int     { stats.intelligence / 4 + skillPassives.spellpowerBonus }
    var lifeOnKill: Int     { skillPassives.lifeOnKill }
    var startingBlock: Int  { skillPassives.startingBlock }
    var poisonOnHit: Int    { skillPassives.poisonOnHit }
    var energyOnKill: Int   { skillPassives.energyOnKill }
    var totalCardPool: Int  { deck.count + hand.count + discardPile.count }
    var isAlive: Bool       { totalCardPool > 0 }

    // Stat bonuses from attributes (for display)
    var statAttackBonus: Int      { stats.strength / 5 }
    var statDefenseBonus: Int     { stats.dexterity / 5 }
    var statSpellpowerBonus: Int  { stats.intelligence / 4 }
    var statEnergyBonus: Int      { stats.intelligence / 10 }

    func meetsRequirements(for card: Card) -> Bool {
        guard let reqs = card.requirements, !reqs.isEmpty else { return true }
        return stats.strength >= reqs.strength &&
               stats.dexterity >= reqs.dexterity &&
               stats.intelligence >= reqs.intelligence
    }

    // Leveling
    var expToNextLevel: Int { level * 100 }
    var expProgress: Double { Double(experience) / Double(expToNextLevel) }

    @discardableResult
    mutating func gainExp(_ amount: Int) -> Bool {
        experience += amount
        if experience >= expToNextLevel {
            experience -= expToNextLevel
            levelUp()
            return true
        }
        return false
    }

    private mutating func levelUp() {
        level += 1
        skillPoints += 1
        statPoints  += 3
        // attack/defense now come from STR/DEX allocation — no auto-grants
        // HP is no longer tracked — deck is your life total
    }

    /// Exile `count` cards from the top of the draw pile (or discard if deck is empty).
    /// This is how the hero "takes damage" — their card pool shrinks.
    mutating func exileCards(count: Int) {
        var remaining = count
        while remaining > 0 && !deck.isEmpty {
            exiledCards.append(deck.removeFirst())
            remaining -= 1
        }
        while remaining > 0 && !discardPile.isEmpty {
            exiledCards.append(discardPile.removeFirst())
            remaining -= 1
        }
        // If remaining > 0 and no cards left anywhere, hero is dead (totalCardPool == 0)
    }

    /// Restore `count` cards from exile back into the deck (shuffled in). Potion effect.
    mutating func restoreExiledCards(count: Int) {
        let toRestore = min(count, exiledCards.count)
        guard toRestore > 0 else { return }
        let restored = Array(exiledCards.prefix(toRestore))
        exiledCards.removeFirst(toRestore)
        deck.append(contentsOf: restored.shuffled())
    }

    mutating func startNewTurn() {
        currentEnergy = maxEnergy
        block = startingBlock          // startingBlock equipment resets block each turn
        if weakStacks > 0        { weakStacks -= 1 }
        if vulnerableStacks > 0  { vulnerableStacks -= 1 }
        if poisonStacks > 0      { exileCards(count: max(1, poisonStacks / 5)); poisonStacks -= 1 }
    }
}
