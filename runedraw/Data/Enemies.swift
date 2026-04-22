import Foundation

struct EnemyDatabase {

    /// Spawn enemies appropriate for the given area (1–8).
    static func enemies(for areaIndex: Int, isBoss: Bool, isElite: Bool = false) -> [Enemy] {
        let tier = AreaDatabase.definition(for: areaIndex)?.enemyTier ?? 1
        if isBoss  { return [boss(for: areaIndex)] }
        if isElite { return [elite(for: tier)] }
        return regular(for: tier)
    }

    // MARK: - Regular enemies by tier

    private static func regular(for tier: Int) -> [Enemy] {
        switch tier {

        // ── Tier 1: The Withered Vale / Thornwood Hollow ──────────────────
        case 1:
            switch Int.random(in: 0..<3) {
            case 0:
                return [Enemy(name: "Skeleton",  icon: "💀", maxHp: 20,
                              actions: [.attack(6), .attack(8)],
                              blockHandSize: 2, blockCardValue: 2)]
            case 1:
                return [Enemy(name: "Rotwalker", icon: "🧟", maxHp: 28,
                              actions: [.attack(7), .defend(5), .attack(7)],
                              blockHandSize: 2, blockCardValue: 3)]
            default:
                return [
                    Enemy(name: "Skeleton", icon: "💀", maxHp: 16, actions: [.attack(5)], blockHandSize: 1, blockCardValue: 2),
                    Enemy(name: "Skeleton", icon: "💀", maxHp: 16, actions: [.attack(6)], blockHandSize: 1, blockCardValue: 2),
                ]
            }

        // ── Tier 2: The Bleached Moors / Rotmire Caverns ──────────────────
        case 2:
            switch Int.random(in: 0..<3) {
            case 0:
                return [Enemy(name: "Dark Knight", icon: "🛡️", maxHp: 42,
                              actions: [.attack(10), .defend(8), .attack(12)],
                              blockHandSize: 3, blockCardValue: 5)]     // tank
            case 1:
                return [Enemy(name: "Bog Cultist", icon: "🧙", maxHp: 34,
                              actions: [.attack(8), .poison(3), .attack(8)],
                              blockHandSize: 2, blockCardValue: 3)]     // caster, fragile
            default:
                return [
                    Enemy(name: "Ghoul", icon: "👻", maxHp: 28, actions: [.attack(9)],          blockHandSize: 2, blockCardValue: 3),
                    Enemy(name: "Ghoul", icon: "👻", maxHp: 28, actions: [.attack(6), .weaken], blockHandSize: 2, blockCardValue: 3),
                ]
            }

        // ── Tier 3: The Ashen Road / Duskfell Ruins ───────────────────────
        case 3:
            switch Int.random(in: 0..<3) {
            case 0:
                return [Enemy(name: "Blood Mage",     icon: "🧛", maxHp: 50,
                              actions: [.attack(11), .poison(4), .attack(13)],
                              blockHandSize: 2, blockCardValue: 4)]
            case 1:
                return [Enemy(name: "Stone Golem",    icon: "🗿", maxHp: 58,
                              actions: [.defend(10), .attack(15), .attack(12)],
                              blockHandSize: 3, blockCardValue: 6)]     // heavy blocker
            default:
                return [Enemy(name: "Shadow Stalker", icon: "🌑", maxHp: 44,
                              actions: [.weaken, .attack(13), .attack(10), .weaken],
                              blockHandSize: 2, blockCardValue: 4)]
            }

        // ── Tier 4: The Charnel Depths / Obsidian Gate ────────────────────
        default:
            switch Int.random(in: 0..<3) {
            case 0:
                return [Enemy(name: "Doom Knight",  icon: "⚔️", maxHp: 68,
                              actions: [.attack(16), .defend(12), .attack(20), .weaken],
                              blockHandSize: 3, blockCardValue: 7)]
            case 1:
                return [Enemy(name: "Bone Wraith",  icon: "💀", maxHp: 56,
                              actions: [.poison(5), .attack(14), .weaken, .attack(16)],
                              blockHandSize: 2, blockCardValue: 5)]
            default:
                return [
                    Enemy(name: "Plague Thrall", icon: "🧟", maxHp: 28,
                          actions: [.attack(8), .poison(3)], blockHandSize: 2, blockCardValue: 4),
                    Enemy(name: "Plague Thrall", icon: "🧟", maxHp: 28,
                          actions: [.poison(3), .attack(8)], blockHandSize: 2, blockCardValue: 4),
                    Enemy(name: "Plague Thrall", icon: "🧟", maxHp: 28,
                          actions: [.attack(8), .weaken],    blockHandSize: 2, blockCardValue: 4),
                ]
            }
        }
    }

    // MARK: - Elite enemies by tier
    // Elites are named champions — 1.6× HP, boosted attacks, possible extra status moves.

    private static func elite(for tier: Int) -> Enemy {
        switch tier {

        case 1:
            return [
                Enemy(name: "Cursed Rotwalker",  icon: "🧟", maxHp: 46, actions: [.attack(10), .defend(7), .attack(13), .weaken], blockHandSize: 2, blockCardValue: 4),
                Enemy(name: "Skeletal Champion", icon: "💀", maxHp: 42, actions: [.attack(9), .attack(12), .defend(6), .attack(9)], blockHandSize: 2, blockCardValue: 3),
                Enemy(name: "Plagued Shambler",  icon: "🧟", maxHp: 50, actions: [.poison(3), .attack(11), .attack(11), .defend(5)], blockHandSize: 2, blockCardValue: 4),
            ].randomElement()!

        case 2:
            return [
                Enemy(name: "Vile Dark Knight", icon: "🛡️", maxHp: 66, actions: [.attack(14), .defend(10), .attack(18), .weaken], blockHandSize: 3, blockCardValue: 6),
                Enemy(name: "Bog Witch",        icon: "🧙", maxHp: 58, actions: [.poison(5), .weaken, .attack(12), .poison(4)],   blockHandSize: 2, blockCardValue: 4),
                Enemy(name: "Ravager Ghoul",    icon: "👻", maxHp: 54, actions: [.attack(13), .attack(11), .weaken, .attack(15)], blockHandSize: 2, blockCardValue: 4),
            ].randomElement()!

        case 3:
            return [
                Enemy(name: "Bloodlord Mage", icon: "🧛", maxHp: 80, actions: [.attack(15), .poison(6), .weaken, .attack(18)],           blockHandSize: 2, blockCardValue: 5),
                Enemy(name: "Iron Golem",     icon: "🗿", maxHp: 92, actions: [.defend(14), .attack(20), .defend(10), .attack(18)],       blockHandSize: 4, blockCardValue: 7),
                Enemy(name: "Void Stalker",   icon: "🌑", maxHp: 72, actions: [.weaken, .attack(17), .weaken, .attack(14), .attack(17)], blockHandSize: 2, blockCardValue: 5),
            ].randomElement()!

        default: // tier 4
            return [
                Enemy(name: "Doom Herald",    icon: "⚔️", maxHp: 106, actions: [.attack(20), .defend(14), .attack(25), .weaken, .attack(20)],     blockHandSize: 3, blockCardValue: 8),
                Enemy(name: "Abyssal Wraith", icon: "💀", maxHp: 90,  actions: [.poison(7), .attack(18), .weaken, .attack(20), .poison(5)],        blockHandSize: 2, blockCardValue: 6),
                Enemy(name: "Dread Champion", icon: "🧟", maxHp: 100, actions: [.attack(18), .weaken, .attack(22), .defend(12), .attack(20)],      blockHandSize: 3, blockCardValue: 7),
            ].randomElement()!
        }
    }

    // MARK: - Bosses (one per area, 1–8)

    private static func boss(for areaIndex: Int) -> Enemy {
        switch areaIndex {
        case 1:
            return Enemy(name: "The Warden",          icon: "⚰️", maxHp: 65,
                         actions: [.attack(12), .defend(8), .attack(16), .attack(12)],
                         blockHandSize: 3, blockCardValue: 4)
        case 2:
            return Enemy(name: "Rotwood Brute",       icon: "🧟", maxHp: 88,
                         actions: [.attack(14), .defend(10), .attack(18), .attack(14)],
                         blockHandSize: 3, blockCardValue: 5)
        case 3:
            return Enemy(name: "The Bog Witch",       icon: "🧙", maxHp: 95,
                         actions: [.poison(4), .attack(12), .weaken, .poison(5), .attack(14)],
                         blockHandSize: 2, blockCardValue: 5)
        case 4:
            return Enemy(name: "Lich Mage",           icon: "🦴", maxHp: 105,
                         actions: [.attack(14), .poison(5), .attack(18), .defend(10), .attack(14)],
                         blockHandSize: 3, blockCardValue: 6)
        case 5:
            return Enemy(name: "Stone Sentinel",      icon: "🗿", maxHp: 120,
                         actions: [.defend(12), .attack(18), .attack(15), .defend(10), .attack(20)],
                         blockHandSize: 4, blockCardValue: 7)
        case 6:
            return Enemy(name: "Shadowlord",          icon: "🌑", maxHp: 130,
                         actions: [.attack(18), .weaken, .attack(20), .poison(6), .attack(18), .defend(12)],
                         blockHandSize: 3, blockCardValue: 7)
        case 7:
            return Enemy(name: "The Plague Apostle",  icon: "☠️", maxHp: 150,
                         actions: [.poison(6), .weaken, .attack(20), .poison(8), .attack(24), .weaken],
                         blockHandSize: 3, blockCardValue: 8)
        default: // area 8
            return Enemy(name: "The Obsidian Tyrant", icon: "👁️", maxHp: 185,
                         actions: [.attack(22), .weaken, .attack(25), .poison(8), .defend(15), .attack(28)],
                         blockHandSize: 4, blockCardValue: 9)
        }
    }
}
