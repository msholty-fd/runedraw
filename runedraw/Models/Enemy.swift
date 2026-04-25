import Foundation

// MARK: - Enemy Block Card

struct EnemyCard: Identifiable, Codable {
    let id: UUID
    let name: String
    let defenseValue: Int

    init(name: String, defenseValue: Int) {
        self.id           = UUID()
        self.name         = name
        self.defenseValue = defenseValue
    }
}

// MARK: - Enemy Intent

enum EnemyIntent: Codable {
    case attack(Int)
    case defend(Int)
    case poison(Int)
    case weaken

    var icon: String {
        switch self {
        case .attack:  return "⚔️"
        case .defend:  return "🛡️"
        case .poison:  return "☠️"
        case .weaken:  return "💀"
        }
    }

    var label: String {
        switch self {
        case .attack(let dmg):    return "Attack \(dmg)"
        case .defend(let block):  return "Block \(block)"
        case .poison(let stacks): return "Poison \(stacks)"
        case .weaken:             return "Weaken"
        }
    }

    // Custom Codable — needed because of associated values
    private enum CodingKeys: String, CodingKey { case type, value }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .attack(let v): try c.encode("attack", forKey: .type); try c.encode(v, forKey: .value)
        case .defend(let v): try c.encode("defend", forKey: .type); try c.encode(v, forKey: .value)
        case .poison(let v): try c.encode("poison", forKey: .type); try c.encode(v, forKey: .value)
        case .weaken:        try c.encode("weaken", forKey: .type)
        }
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .type) {
        case "attack": self = .attack(try c.decodeIfPresent(Int.self, forKey: .value) ?? 0)
        case "defend": self = .defend(try c.decodeIfPresent(Int.self, forKey: .value) ?? 0)
        case "poison": self = .poison(try c.decodeIfPresent(Int.self, forKey: .value) ?? 0)
        default:       self = .weaken
        }
    }
}

struct Enemy: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let maxLifeCards: Int
    var lifeCards: Int
    var block: Int = 0
    var poisonStacks: Int = 0
    var burnStacks: Int = 0      // fire DoT: ticks each turn, decrements by 1
    var weakStacks: Int = 0
    var vulnerableStacks: Int = 0
    var bleedStacks: Int = 0     // physical DoT: ticks when hero hits this enemy
    var chillStacks: Int = 0     // ice buildup: at freezeThreshold → frozen
    var frozenTurnsLeft: Int = 0 // >0 means enemy skips their next attack(s)

    var isFrozen: Bool { frozenTurnsLeft > 0 }
    let actions: [EnemyIntent]
    var actionIndex: Int = 0

    /// Block cards currently in hand — drawn fresh each turn, visible to the player.
    var blockHand: [EnemyCard] = []
    /// How many block cards this enemy draws per turn.
    let blockHandSize: Int
    /// Base defense value per card (randomised ±1 when drawing).
    let blockCardValue: Int

    var isAlive: Bool { lifeCards > 0 }

    var currentIntent: EnemyIntent {
        actions[actionIndex % actions.count]
    }

    /// Total defense available this turn from remaining block cards.
    var totalBlockAvailable: Int { blockHand.map(\.defenseValue).reduce(0, +) }

    init(id: UUID = UUID(), name: String, icon: String = "👹", lifeCards: Int,
         actions: [EnemyIntent], blockHandSize: Int = 2, blockCardValue: Int = 3) {
        self.id             = id
        self.name           = name
        self.icon           = icon
        self.maxLifeCards   = lifeCards
        self.lifeCards      = lifeCards
        self.actions        = actions
        self.blockHandSize  = blockHandSize
        self.blockCardValue = blockCardValue
        self.blockHand      = []
    }

    /// Draw a fresh hand of block cards (called at the start of each new turn).
    mutating func drawBlockHand() {
        let cardNames = ["Guard", "Parry", "Brace", "Deflect", "Ward"]
        blockHand = (0..<blockHandSize).map { _ in
            let variance = Int.random(in: -1...1)
            let value    = max(1, blockCardValue + variance)
            return EnemyCard(name: cardNames.randomElement()!, defenseValue: value)
        }
    }

    /// Greedy auto-block: use as few cards as needed to cover `incoming` damage.
    /// Returns total amount blocked and removes used cards from hand.
    mutating func autoBlock(incoming: Int) -> Int {
        let sorted = blockHand.sorted { $0.defenseValue > $1.defenseValue }
        var blocked  = 0
        var usedIDs  = Set<UUID>()

        for card in sorted {
            guard blocked < incoming else { break }
            usedIDs.insert(card.id)
            blocked += card.defenseValue
        }

        blockHand.removeAll { usedIDs.contains($0.id) }
        return min(incoming, blocked)
    }

    mutating func takeDamage(_ amount: Int) {
        var dmg = amount
        if vulnerableStacks > 0 { dmg = Int(Double(dmg) * 1.5) }
        if block > 0 {
            let absorbed = min(block, dmg)
            block -= absorbed
            dmg   -= absorbed
        }
        lifeCards = max(0, lifeCards - dmg)
    }

    mutating func advanceAction() {
        actionIndex = (actionIndex + 1) % actions.count
    }

    mutating func startNewTurn() {
        block = 0
        if poisonStacks > 0     { lifeCards = max(0, lifeCards - max(1, poisonStacks / 5)); poisonStacks -= 1 }
        if burnStacks > 0       { lifeCards = max(0, lifeCards - max(1, burnStacks / 5));   burnStacks -= 1 }
        if weakStacks > 0       { weakStacks -= 1 }
        if vulnerableStacks > 0 { vulnerableStacks -= 1 }
        if frozenTurnsLeft > 0  { frozenTurnsLeft -= 1 }
        drawBlockHand()
    }

    // MARK: - Custom Codable (decodeIfPresent for new fields)

    enum CodingKeys: String, CodingKey {
        case id, name, icon, maxLifeCards, lifeCards, block, poisonStacks, burnStacks, weakStacks
        case vulnerableStacks, actions, actionIndex, blockHand, blockHandSize, blockCardValue
        case bleedStacks, chillStacks, frozenTurnsLeft
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,           forKey: .id)
        name             = try c.decode(String.self,         forKey: .name)
        icon             = try c.decode(String.self,         forKey: .icon)
        maxLifeCards     = try c.decodeIfPresent(Int.self,   forKey: .maxLifeCards) ?? 10
        lifeCards        = try c.decodeIfPresent(Int.self,   forKey: .lifeCards) ?? 10
        block            = try c.decodeIfPresent(Int.self,   forKey: .block) ?? 0
        poisonStacks     = try c.decodeIfPresent(Int.self,   forKey: .poisonStacks) ?? 0
        burnStacks       = try c.decodeIfPresent(Int.self,   forKey: .burnStacks) ?? 0
        weakStacks       = try c.decodeIfPresent(Int.self,   forKey: .weakStacks) ?? 0
        vulnerableStacks = try c.decodeIfPresent(Int.self,   forKey: .vulnerableStacks) ?? 0
        actions          = try c.decode([EnemyIntent].self,  forKey: .actions)
        actionIndex      = try c.decodeIfPresent(Int.self,   forKey: .actionIndex) ?? 0
        blockHand        = try c.decodeIfPresent([EnemyCard].self, forKey: .blockHand) ?? []
        blockHandSize    = try c.decodeIfPresent(Int.self,   forKey: .blockHandSize) ?? 2
        blockCardValue   = try c.decodeIfPresent(Int.self,   forKey: .blockCardValue) ?? 3
        bleedStacks      = try c.decodeIfPresent(Int.self,   forKey: .bleedStacks) ?? 0
        chillStacks      = try c.decodeIfPresent(Int.self,   forKey: .chillStacks) ?? 0
        frozenTurnsLeft  = try c.decodeIfPresent(Int.self,   forKey: .frozenTurnsLeft) ?? 0
    }
}
