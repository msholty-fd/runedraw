import SwiftUI

struct SkillNode: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let flavorText: String
    let tier: Int           // 1, 2, or 3
    let branch: Int         // 0, 1, or 2
    let requiresId: String? // nil for tier-1 nodes
    let cost: Int           // skill points to unlock (always 1 for now)
}

// MARK: - Hero class branch names

extension HeroClass {
    var skillBranchNames: [String] {
        switch self {
        case .barbarian: return ["Warfare", "Endurance", "Fury"]
        case .rogue:     return ["Shadow", "Poison", "Blades"]
        case .sorceress: return ["Fire", "Ice", "Lightning"]
        }
    }
    var skillBranchIcons: [String] {
        switch self {
        case .barbarian: return ["🗡️", "🛡️", "🔥"]
        case .rogue:     return ["🌑", "☠️", "🔪"]
        case .sorceress: return ["🔥", "❄️", "⚡"]
        }
    }
}

// MARK: - Database

struct SkillDatabase {

    // MARK: - Branch colors

    static func branchColor(_ branch: Int) -> Color {
        switch branch {
        case 0: return Color(red: 1.0, green: 0.35, blue: 0.2)   // orange-red
        case 1: return Color(red: 0.3, green: 0.7,  blue: 1.0)   // blue-cyan
        default: return Color(red: 0.5, green: 1.0,  blue: 0.4)  // green
        }
    }

    // MARK: - Tree definitions

    static func tree(for heroClass: HeroClass) -> [SkillNode] {
        switch heroClass {
        case .barbarian: return barbarianTree()
        case .rogue:     return rogueTree()
        case .sorceress: return sorceressTree()
        }
    }

    // MARK: - Card factory

    static func card(for nodeId: String) -> Card {
        cardMap[nodeId] ?? fallbackCard(nodeId)
    }

    // MARK: - Barbarian

    private static func barbarianTree() -> [SkillNode] {
        [
            // Branch 0 — Warfare (offense)
            SkillNode(id: "barb_w1", name: "Heavy Strike",   icon: "💥",
                      description: "Deal 12 damage.",
                      flavorText: "\"Put your back into it.\"",
                      tier: 1, branch: 0, requiresId: nil, cost: 1),
            SkillNode(id: "barb_w2", name: "Seismic Slam",   icon: "🌋",
                      description: "Deal 8 damage to ALL enemies.",
                      flavorText: "\"The ground itself fears you.\"",
                      tier: 2, branch: 0, requiresId: "barb_w1", cost: 1),
            SkillNode(id: "barb_w3", name: "Whirlwind",      icon: "🌀",
                      description: "Deal 10 damage to ALL enemies.",
                      flavorText: "\"A storm of steel.\"",
                      tier: 3, branch: 0, requiresId: "barb_w2", cost: 1),

            // Branch 1 — Endurance (defense)
            SkillNode(id: "barb_e1", name: "War Cry",        icon: "📣",
                      description: "Gain 8 block.",
                      flavorText: "\"Fear me!\"",
                      tier: 1, branch: 1, requiresId: nil, cost: 1),
            SkillNode(id: "barb_e2", name: "Iron Skin",      icon: "🪨",
                      description: "Gain 14 block.",
                      flavorText: "\"Harder than iron.\"",
                      tier: 2, branch: 1, requiresId: "barb_e1", cost: 1),
            SkillNode(id: "barb_e3", name: "Last Stand",     icon: "⛰️",
                      description: "Gain 16 block. Draw 2 cards.",
                      flavorText: "\"Not here. Not today.\"",
                      tier: 3, branch: 1, requiresId: "barb_e2", cost: 1),

            // Branch 2 — Fury (aggression)
            SkillNode(id: "barb_f1", name: "Bash",           icon: "🔨",
                      description: "Deal 6 damage. Apply 1 Vulnerable.",
                      flavorText: "\"Crack their guard open.\"",
                      tier: 1, branch: 2, requiresId: nil, cost: 1),
            SkillNode(id: "barb_f2", name: "Frenzy",         icon: "😤",
                      description: "Deal 7 damage twice.",
                      flavorText: "\"Strike before they can react.\"",
                      tier: 2, branch: 2, requiresId: "barb_f1", cost: 1),
            SkillNode(id: "barb_f3", name: "Berserk",        icon: "🩸",
                      description: "Deal 5 damage. Gain 2 energy.",
                      flavorText: "\"Pain is fuel.\"",
                      tier: 3, branch: 2, requiresId: "barb_f2", cost: 1),
        ]
    }

    // MARK: - Rogue

    private static func rogueTree() -> [SkillNode] {
        [
            // Branch 0 — Shadow (evasion/draw)
            SkillNode(id: "rog_s1", name: "Evasion",         icon: "💨",
                      description: "Gain 6 block. Draw 1.",
                      flavorText: "\"You can't hit what you can't see.\"",
                      tier: 1, branch: 0, requiresId: nil, cost: 1),
            SkillNode(id: "rog_s2", name: "Smoke Bomb",      icon: "💣",
                      description: "Gain 5 block. Apply 2 Weak.",
                      flavorText: "\"Blinded. Helpless.\"",
                      tier: 2, branch: 0, requiresId: "rog_s1", cost: 1),
            SkillNode(id: "rog_s3", name: "Vanish",          icon: "🌑",
                      description: "Gain 10 block. Draw 2 cards.",
                      flavorText: "\"Here one moment, gone the next.\"",
                      tier: 3, branch: 0, requiresId: "rog_s2", cost: 1),

            // Branch 1 — Poison (damage over time)
            SkillNode(id: "rog_p1", name: "Envenom",         icon: "🧪",
                      description: "Apply 5 poison.",
                      flavorText: "\"A slow death is still death.\"",
                      tier: 1, branch: 1, requiresId: nil, cost: 1),
            SkillNode(id: "rog_p2", name: "Toxic Strike",    icon: "☠️",
                      description: "Deal 5 damage. Apply 5 poison.",
                      flavorText: "\"Every wound festers.\"",
                      tier: 2, branch: 1, requiresId: "rog_p1", cost: 1),
            SkillNode(id: "rog_p3", name: "Plague",          icon: "🦠",
                      description: "Apply 9 poison. Draw 1.",
                      flavorText: "\"Let it spread.\"",
                      tier: 3, branch: 1, requiresId: "rog_p2", cost: 1),

            // Branch 2 — Blades (burst)
            SkillNode(id: "rog_b1", name: "Quick Strike",    icon: "⚡",
                      description: "Deal 5 damage. Draw 1.",
                      flavorText: "\"Speed is your weapon.\"",
                      tier: 1, branch: 2, requiresId: nil, cost: 1),
            SkillNode(id: "rog_b2", name: "Flurry",          icon: "🗡️",
                      description: "Deal 4 damage twice.",
                      flavorText: "\"Two wounds for the price of one.\"",
                      tier: 2, branch: 2, requiresId: "rog_b1", cost: 1),
            SkillNode(id: "rog_b3", name: "Fan of Knives",   icon: "🎯",
                      description: "Deal 5 damage to ALL enemies.",
                      flavorText: "\"Nowhere to run.\"",
                      tier: 3, branch: 2, requiresId: "rog_b2", cost: 1),
        ]
    }

    // MARK: - Sorceress

    private static func sorceressTree() -> [SkillNode] {
        [
            // Branch 0 — Fire (burst damage)
            SkillNode(id: "sor_f1", name: "Incinerate",      icon: "🔥",
                      description: "Deal 14 damage.",
                      flavorText: "\"Ash and cinders.\"",
                      tier: 1, branch: 0, requiresId: nil, cost: 1),
            SkillNode(id: "sor_f2", name: "Meteor",          icon: "☄️",
                      description: "Deal 18 damage. Apply 2 Vulnerable.",
                      flavorText: "\"Heaven's wrath made manifest.\"",
                      tier: 2, branch: 0, requiresId: "sor_f1", cost: 1),
            SkillNode(id: "sor_f3", name: "Flame Wave",      icon: "🌊",
                      description: "Deal 10 damage to ALL enemies.",
                      flavorText: "\"A tide of fire.\"",
                      tier: 3, branch: 0, requiresId: "sor_f2", cost: 1),

            // Branch 1 — Ice (control)
            SkillNode(id: "sor_i1", name: "Frost Nova",      icon: "❄️",
                      description: "Gain 5 block. Apply 2 Weak.",
                      flavorText: "\"Cold slows. Cold kills.\"",
                      tier: 1, branch: 1, requiresId: nil, cost: 1),
            SkillNode(id: "sor_i2", name: "Ice Blast",       icon: "🧊",
                      description: "Deal 8 damage. Apply 2 Weak.",
                      flavorText: "\"Crystalline. Merciless.\"",
                      tier: 2, branch: 1, requiresId: "sor_i1", cost: 1),
            SkillNode(id: "sor_i3", name: "Blizzard",        icon: "🌨️",
                      description: "Deal 6 damage to ALL. Apply 2 Weak.",
                      flavorText: "\"A storm without end.\"",
                      tier: 3, branch: 1, requiresId: "sor_i2", cost: 1),

            // Branch 2 — Lightning (multi-target)
            SkillNode(id: "sor_l1", name: "Spark",           icon: "⚡",
                      description: "Deal 8 damage.",
                      flavorText: "\"The first bolt always finds its mark.\"",
                      tier: 1, branch: 2, requiresId: nil, cost: 1),
            SkillNode(id: "sor_l2", name: "Chain Lightning",  icon: "🌩️",
                      description: "Deal 6 damage to ALL enemies.",
                      flavorText: "\"One becomes many.\"",
                      tier: 2, branch: 2, requiresId: "sor_l1", cost: 1),
            SkillNode(id: "sor_l3", name: "Thunder Clap",    icon: "💫",
                      description: "Deal 8 damage to ALL. Apply 2 Vulnerable.",
                      flavorText: "\"Deafening. Devastating.\"",
                      tier: 3, branch: 2, requiresId: "sor_l2", cost: 1),
        ]
    }

    // MARK: - Card map

    private static let cardMap: [String: Card] = [
        // Barbarian — Warfare
        "barb_w1": Card(name: "Heavy Strike",  description: "Deal 12 damage.",             cost: 2, type: .attack, heroClass: .barbarian, effect: CardEffect(damage: 12)),
        "barb_w2": Card(name: "Seismic Slam",  description: "Deal 8 damage to ALL enemies.", cost: 2, type: .attack, heroClass: .barbarian, effect: CardEffect(damage: 8, damageAllEnemies: true)),
        "barb_w3": Card(name: "Whirlwind",     description: "Deal 10 damage to ALL enemies.", cost: 3, type: .attack, heroClass: .barbarian, effect: CardEffect(damage: 10, damageAllEnemies: true)),

        // Barbarian — Endurance
        "barb_e1": Card(name: "War Cry",       description: "Gain 8 block.",                cost: 1, type: .skill, heroClass: .barbarian, effect: CardEffect(block: 8)),
        "barb_e2": Card(name: "Iron Skin",     description: "Gain 14 block.",               cost: 2, type: .skill, heroClass: .barbarian, effect: CardEffect(block: 14)),
        "barb_e3": Card(name: "Last Stand",    description: "Gain 16 block. Draw 2 cards.", cost: 2, type: .skill, heroClass: .barbarian, effect: CardEffect(block: 16, draw: 2)),

        // Barbarian — Fury
        "barb_f1": Card(name: "Bash",          description: "Deal 6 damage. Apply 1 Vulnerable.", cost: 1, type: .attack, heroClass: .barbarian, effect: CardEffect(damage: 6, vulnerableStacks: 1)),
        "barb_f2": Card(name: "Frenzy",        description: "Deal 7 damage twice.",         cost: 2, type: .attack, heroClass: .barbarian, effect: CardEffect(damage: 7, times: 2)),
        "barb_f3": Card(name: "Berserk",       description: "Deal 5 damage. Gain 2 energy.", cost: 1, type: .attack, heroClass: .barbarian, effect: CardEffect(damage: 5, energyGain: 2)),

        // Rogue — Shadow
        "rog_s1":  Card(name: "Evasion",       description: "Gain 6 block. Draw 1.",        cost: 1, type: .skill, heroClass: .rogue, effect: CardEffect(block: 6, draw: 1)),
        "rog_s2":  Card(name: "Smoke Bomb",    description: "Gain 5 block. Apply 2 Weak.",  cost: 2, type: .skill, heroClass: .rogue, effect: CardEffect(block: 5, weakStacks: 2)),
        "rog_s3":  Card(name: "Vanish",        description: "Gain 10 block. Draw 2 cards.", cost: 1, type: .skill, heroClass: .rogue, effect: CardEffect(block: 10, draw: 2)),

        // Rogue — Poison
        "rog_p1":  Card(name: "Envenom",       description: "Apply 5 poison.",              cost: 1, type: .skill, heroClass: .rogue, effect: CardEffect(poisonStacks: 5)),
        "rog_p2":  Card(name: "Toxic Strike",  description: "Deal 5 damage. Apply 5 poison.", cost: 2, type: .attack, heroClass: .rogue, effect: CardEffect(damage: 5, poisonStacks: 5)),
        "rog_p3":  Card(name: "Plague",        description: "Apply 9 poison. Draw 1.",      cost: 2, type: .skill, heroClass: .rogue, effect: CardEffect(draw: 1, poisonStacks: 9)),

        // Rogue — Blades
        "rog_b1":  Card(name: "Quick Strike",  description: "Deal 5 damage. Draw 1.",       cost: 1, type: .attack, heroClass: .rogue, effect: CardEffect(damage: 5, draw: 1)),
        "rog_b2":  Card(name: "Flurry",        description: "Deal 4 damage twice.",         cost: 1, type: .attack, heroClass: .rogue, effect: CardEffect(damage: 4, times: 2)),
        "rog_b3":  Card(name: "Fan of Knives", description: "Deal 5 damage to ALL enemies.", cost: 2, type: .attack, heroClass: .rogue, effect: CardEffect(damage: 5, damageAllEnemies: true)),

        // Sorceress — Fire
        "sor_f1":  Card(name: "Incinerate",    description: "Deal 14 damage.",              cost: 2, type: .attack, heroClass: .sorceress, effect: CardEffect(damage: 14)),
        "sor_f2":  Card(name: "Meteor",        description: "Deal 18 damage. Apply 2 Vulnerable.", cost: 3, type: .attack, heroClass: .sorceress, effect: CardEffect(damage: 18, vulnerableStacks: 2)),
        "sor_f3":  Card(name: "Flame Wave",    description: "Deal 10 damage to ALL enemies.", cost: 2, type: .attack, heroClass: .sorceress, effect: CardEffect(damage: 10, damageAllEnemies: true)),

        // Sorceress — Ice
        "sor_i1":  Card(name: "Frost Nova",    description: "Gain 5 block. Apply 2 Weak.", cost: 1, type: .skill, heroClass: .sorceress, effect: CardEffect(block: 5, weakStacks: 2)),
        "sor_i2":  Card(name: "Ice Blast",     description: "Deal 8 damage. Apply 2 Weak.", cost: 2, type: .attack, heroClass: .sorceress, effect: CardEffect(damage: 8, weakStacks: 2)),
        "sor_i3":  Card(name: "Blizzard", description: "Deal 6 damage to ALL. Apply 2 Weak.", cost: 2,
                        type: .attack, heroClass: .sorceress,
                        effect: CardEffect(damage: 6, weakStacks: 2, damageAllEnemies: true)),

        // Sorceress — Lightning
        "sor_l1":  Card(name: "Spark",         description: "Deal 8 damage.",               cost: 1, type: .attack, heroClass: .sorceress, effect: CardEffect(damage: 8)),
        "sor_l2":  Card(name: "Chain Lightning", description: "Deal 6 damage to ALL enemies.", cost: 2, type: .attack, heroClass: .sorceress, effect: CardEffect(damage: 6, damageAllEnemies: true)),
        "sor_l3":  Card(name: "Thunder Clap", description: "Deal 8 damage to ALL. Apply 2 Vulnerable.", cost: 2,
                        type: .attack, heroClass: .sorceress,
                        effect: CardEffect(damage: 8, vulnerableStacks: 2, damageAllEnemies: true)),
    ]

    private static func fallbackCard(_ id: String) -> Card {
        Card(name: id, description: "???", cost: 1, type: .skill, effect: CardEffect())
    }
}
