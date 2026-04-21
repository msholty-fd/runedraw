import Foundation

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
    let maxHp: Int
    var currentHp: Int
    var block: Int = 0
    var poisonStacks: Int = 0
    var weakStacks: Int = 0
    var vulnerableStacks: Int = 0
    let actions: [EnemyIntent]
    var actionIndex: Int = 0

    var isAlive: Bool { currentHp > 0 }

    var currentIntent: EnemyIntent {
        actions[actionIndex % actions.count]
    }

    init(id: UUID = UUID(), name: String, icon: String = "👹", maxHp: Int, actions: [EnemyIntent]) {
        self.id        = id
        self.name      = name
        self.icon      = icon
        self.maxHp     = maxHp
        self.currentHp = maxHp
        self.actions   = actions
    }

    mutating func takeDamage(_ amount: Int) {
        var dmg = amount
        if vulnerableStacks > 0 { dmg = Int(Double(dmg) * 1.5) }
        if block > 0 {
            let absorbed = min(block, dmg)
            block -= absorbed
            dmg   -= absorbed
        }
        currentHp = max(0, currentHp - dmg)
    }

    mutating func advanceAction() {
        actionIndex = (actionIndex + 1) % actions.count
    }

    mutating func startNewTurn() {
        block = 0
        if poisonStacks > 0     { currentHp -= poisonStacks; poisonStacks -= 1 }
        if weakStacks > 0       { weakStacks -= 1 }
        if vulnerableStacks > 0 { vulnerableStacks -= 1 }
    }
}
