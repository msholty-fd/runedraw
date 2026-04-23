import Foundation

enum GameScreen {
    case characterSelect
    case classSelect
    case town
    case dungeonMap
    case combat
    case encounter
    case loot([Card])
    case gameOver(won: Bool)
}

enum LootContext: String, Codable {
    case combat
    case treasure
    case encounter
}

// MARK: - Room Types

enum RoomType: String, Codable {
    case combat
    case elite      // Tougher enemy, better loot
    case boss
    case rest
    case treasure   // Free chest, no combat
    case encounter  // Random event with choices

    var icon: String {
        switch self {
        case .combat:   return "⚔️"
        case .elite:    return "💢"
        case .boss:     return "👑"
        case .rest:     return "🔥"
        case .treasure: return "📦"
        case .encounter: return "❓"
        }
    }

    var name: String {
        switch self {
        case .combat:   return "Combat"
        case .elite:    return "Elite Enemy"
        case .boss:     return "Boss"
        case .rest:     return "Rest Site"
        case .treasure: return "Treasure"
        case .encounter: return "Encounter"
        }
    }

    var color: (Double, Double, Double) {
        switch self {
        case .combat:   return (0.8, 0.2, 0.2)
        case .elite:    return (0.85, 0.35, 0.9)
        case .boss:     return (1.0, 0.75, 0.1)
        case .rest:     return (0.2, 0.75, 0.4)
        case .treasure: return (0.9, 0.75, 0.15)
        case .encounter: return (0.3, 0.7, 1.0)
        }
    }
}

// MARK: - Dungeon Room

struct DungeonRoom: Identifiable, Codable {
    var id: UUID = UUID()
    let type: RoomType
    var isCompleted: Bool = false
    var encounterId: String?    // assigned at generation for encounter rooms

    init(type: RoomType, encounterId: String? = nil) {
        self.id          = UUID()
        self.type        = type
        self.encounterId = encounterId
    }
}

// MARK: - Dungeon Area

struct DungeonArea: Codable {
    let areaIndex: Int
    let name: String
    let icon: String
    var rooms: [DungeonRoom]
    var currentRoomIndex: Int = 0

    var currentRoom: DungeonRoom { rooms[currentRoomIndex] }
    var isComplete: Bool { currentRoomIndex >= rooms.count }
    var progress: String { "\(currentRoomIndex)/\(rooms.count)" }
}

// MARK: - Area Definition

struct AreaDefinition {
    let index: Int
    let name: String
    let icon: String
    let description: String
    let enemyTier: Int   // 1–4
    let lootTier: Int    // 1–3
}

// MARK: - Area Database

struct AreaDatabase {

    static let act1: [AreaDefinition] = [
        AreaDefinition(index: 1, name: "The Withered Vale",   icon: "🌾",
                       description: "A dying valley at the foot of the dungeon entrance.",
                       enemyTier: 1, lootTier: 1),
        AreaDefinition(index: 2, name: "Thornwood Hollow",    icon: "🌲",
                       description: "A dense forest where shadows move between the trees.",
                       enemyTier: 1, lootTier: 1),
        AreaDefinition(index: 3, name: "The Bleached Moors",  icon: "💨",
                       description: "Blighted open moorland littered with ancient bones.",
                       enemyTier: 2, lootTier: 1),
        AreaDefinition(index: 4, name: "Rotmire Caverns",     icon: "🫧",
                       description: "Flooded underground caves reeking of decay.",
                       enemyTier: 2, lootTier: 2),
        AreaDefinition(index: 5, name: "The Ashen Road",      icon: "🔥",
                       description: "A charred mountain pass scorched by ancient fire.",
                       enemyTier: 3, lootTier: 2),
        AreaDefinition(index: 6, name: "Duskfell Ruins",      icon: "🏛️",
                       description: "The crumbling remains of a once-great city.",
                       enemyTier: 3, lootTier: 2),
        AreaDefinition(index: 7, name: "The Charnel Depths",  icon: "⚰️",
                       description: "Catacombs overflowing with the restless dead.",
                       enemyTier: 4, lootTier: 3),
        AreaDefinition(index: 8, name: "The Obsidian Gate",   icon: "🌑",
                       description: "The final threshold. Something ancient stirs beyond.",
                       enemyTier: 4, lootTier: 3),
    ]

    static var totalAreas: Int { act1.count }

    static func definition(for index: Int) -> AreaDefinition? {
        act1.first { $0.index == index }
    }

    // MARK: - Procedural Generation

    static func generate(areaIndex: Int) -> DungeonArea {
        guard let def = definition(for: areaIndex) else {
            return DungeonArea(areaIndex: areaIndex, name: "Unknown", icon: "❓",
                               rooms: [DungeonRoom(type: .combat), DungeonRoom(type: .boss)])
        }

        let roomTypes = buildRoomPool(for: areaIndex)
        let rooms = roomTypes.map { type -> DungeonRoom in
            if type == .encounter {
                return DungeonRoom(type: type,
                                   encounterId: EncounterDatabase.randomId(tier: def.enemyTier))
            }
            return DungeonRoom(type: type)
        }

        return DungeonArea(areaIndex: areaIndex, name: def.name, icon: def.icon, rooms: rooms)
    }

    /// Builds a shuffled room sequence (boss always last) for the given area.
    private static func buildRoomPool(for areaIndex: Int) -> [RoomType] {
        var middle: [RoomType] = []

        switch areaIndex {
        case 1:
            // Simple intro: 2 combat, 1 rest
            middle = [.combat, .combat, .rest]

        case 2:
            // First elite appears
            middle = [.combat, .elite, .rest]
            if Bool.chance(0.4) { middle.append(.combat) }

        case 3:
            // Encounters begin
            middle = [.combat, .elite, .rest]
            middle.append(Bool.chance(0.7) ? .encounter : .combat)

        case 4:
            // Treasure unlocks
            middle = [.combat, .elite, .encounter, .rest]
            if Bool.chance(0.6) { middle.append(.treasure) }
            else { middle.append(.combat) }

        case 5:
            middle = [.combat, .combat, .elite, .rest]
            middle.append(Bool.chance(0.75) ? .encounter : .combat)
            if Bool.chance(0.65) { middle.append(.treasure) }

        case 6:
            middle = [.combat, .combat, .elite, .elite, .rest]
            middle.append(Bool.chance(0.8) ? .encounter : .combat)
            if Bool.chance(0.5) { middle.append(.treasure) }

        case 7:
            middle = [.combat, .combat, .elite, .elite, .encounter, .rest]
            middle.append(Bool.chance(0.6) ? .treasure : .combat)
            if Bool.chance(0.5) { middle.append(.combat) }

        default: // area 8
            middle = [.combat, .elite, .elite, .elite, .encounter, .rest]
            middle.append(Bool.chance(0.7) ? .treasure : .combat)
            if Bool.chance(0.6) { middle.append(.encounter) }
        }

        middle.shuffle()
        return middle + [.boss]
    }
}

// MARK: - Block Phase

struct PendingAttack: Identifiable {
    let id = UUID()
    let enemyName: String
    let rawDamage: Int      // before hero block or defense cards reduce it
}

// MARK: - Played Card Record (for the played-cards queue UI + recall)

struct PlayedCardRecord: Identifiable {
    let id: UUID = UUID()
    let card: Card
    let targetEnemyId: UUID?        // nil when no enemy targeted

    // Reversible amounts actually applied
    let damageContributions: [UUID: Int]   // enemyId → queued damage from this card
    let blockGained: Int
    let poisonApplied: Int                 // applied to targetEnemyId
    let burnApplied: Int                   // applied to targetEnemyId (single-target block)
    let burnAllApplied: Int                // applied to every enemy
    let weakApplied: Int
    let vulnerableApplied: Int
    let bleedApplied: Int                  // applied to targetEnemyId
    let chillApplied: Int                  // applied to targetEnemyId
    let strengthGained: Int
    let amplifyActivated: Bool

    // Non-reversible (display only — draw/heal stay even on recall)
    let drawCount: Int
    let healAmount: Int

    // Damage cards are non-recallable — damage already applied, can't undo HP changes.
    // Status/buff/block cards can still be recalled and their effects reversed cleanly.
    var canRecall: Bool {
        !card.effect.exhausts &&
        card.effect.damage == 0 &&
        !card.effect.damageFromBlock
    }
    var hasPersistentEffects: Bool { drawCount > 0 || healAmount > 0 }

    /// One-line summary of what this card did, e.g. "⚔️12 🛡️8"
    var effectSummary: String {
        var parts: [String] = []
        let totalDmg = damageContributions.values.reduce(0, +)
        if totalDmg > 0         { parts.append("⚔️\(totalDmg)") }
        if blockGained > 0      { parts.append("🛡️\(blockGained)") }
        if poisonApplied > 0    { parts.append("☠️\(poisonApplied)") }
        if burnApplied > 0 || burnAllApplied > 0 { parts.append("🔥") }
        if bleedApplied > 0     { parts.append("🩸\(bleedApplied)") }
        if chillApplied > 0     { parts.append("❄️\(chillApplied)") }
        if weakApplied > 0      { parts.append("💀") }
        if vulnerableApplied > 0 { parts.append("🎯") }
        if drawCount > 0        { parts.append("🃏\(drawCount)") }
        if healAmount > 0       { parts.append("❤️\(healAmount)") }
        if strengthGained > 0   { parts.append("💪\(strengthGained)") }
        if amplifyActivated     { parts.append("⚡") }
        return parts.isEmpty ? "" : parts.joined(separator: " ")
    }
}

// MARK: - Bool chance helper

private extension Bool {
    static func chance(_ probability: Double) -> Bool {
        Double.random(in: 0...1) < probability
    }
}
