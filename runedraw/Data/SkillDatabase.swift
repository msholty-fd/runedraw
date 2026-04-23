import SwiftUI

// MARK: - Skill Mechanic

struct SkillMechanic: Codable {
    // ── Numeric additive ────────────────────────────────────────────────────
    var attackBonus: Int = 0
    var defenseBonus: Int = 0
    var spellpowerBonus: Int = 0
    var drawPerTurn: Int = 0
    var maxEnergyBonus: Int = 0
    var lifeOnKill: Int = 0
    var startingBlock: Int = 0
    var poisonOnHit: Int = 0
    var energyOnKill: Int = 0
    var maxHpBonus: Int = 0
    var rageOnHit: Int = 0
    var lifeStealPerHit: Int = 0
    var evasionCharges: Int = 0
    var bleedOnHit: Int = 0
    var backstabPerStack: Int = 0
    var chillOnHit: Int = 0
    var freezeThreshold: Int = 0
    var igniteBurstThreshold: Int = 0
    var arcaneThreshold: Int = 0
    var arcaneMultiplierBonus: Double = 0.0  // added to skillPassives.arcaneMultiplier (base 1.0)
    // ── Boolean keywords ────────────────────────────────────────────────────
    var hasBloodlust: Bool = false
    var hasRampage: Bool = false
    var hasWarlordGambit: Bool = false
    var hasEndure: Bool = false
    var hasJuggernaut: Bool = false
    var hasUntouchable: Bool = false
    var hasShadowMark: Bool = false
    var hasAssassinate: Bool = false
    var hasDeathCuts: Bool = false
    var hasShatter: Bool = false
    var hasPermafrost: Bool = false
    var hasConflagration: Bool = false

    // MARK: - Human-readable summary for the skill tree UI
    var summary: String {
        var parts: [String] = []
        if attackBonus > 0          { parts.append("+\(attackBonus) ATK") }
        if defenseBonus > 0         { parts.append("+\(defenseBonus) DEF") }
        if spellpowerBonus > 0      { parts.append("+\(spellpowerBonus) SP") }
        if drawPerTurn > 0          { parts.append("Draw +\(drawPerTurn)/turn") }
        if maxEnergyBonus > 0       { parts.append("+\(maxEnergyBonus) Energy") }
        if lifeOnKill > 0           { parts.append("+\(lifeOnKill) HP/kill") }
        if startingBlock > 0        { parts.append("+\(startingBlock) Block/turn") }
        if poisonOnHit > 0          { parts.append("+\(poisonOnHit) Poison/hit") }
        if energyOnKill > 0         { parts.append("+\(energyOnKill) ⚡/kill") }
        if maxHpBonus > 0           { parts.append("+\(maxHpBonus) Max HP") }
        if rageOnHit > 0            { parts.append("Rage: +\(rageOnHit) STR/hit taken") }
        if lifeStealPerHit > 0      { parts.append("Lifelink: +\(lifeStealPerHit) HP/hit") }
        if evasionCharges > 0       { parts.append("+\(evasionCharges) Evasion charges") }
        if bleedOnHit > 0           { parts.append("+\(bleedOnHit) Bleed/hit") }
        if backstabPerStack > 0     { parts.append("Backstab: +\(backstabPerStack) dmg/stack") }
        if chillOnHit > 0           { parts.append("+\(chillOnHit) Chill/hit") }
        if freezeThreshold > 0      { parts.append("Freeze at \(freezeThreshold) Chill") }
        if igniteBurstThreshold > 0 { parts.append("Ignite Burst at \(igniteBurstThreshold) burn") }
        if arcaneThreshold > 0      { parts.append("⚡ Arcane triggers at card #\(arcaneThreshold)") }
        if arcaneThreshold < 0      { parts.append("⚡ Arcane triggers 1 card earlier") }
        if arcaneMultiplierBonus > 0 { parts.append("⚡ Arcane bonus ×\(String(format: "%.1f", 1.0 + arcaneMultiplierBonus))") }
        if hasBloodlust     { parts.append("Bloodlust: kill → free card") }
        if hasRampage       { parts.append("Rampage: kill → draw 1") }
        if hasWarlordGambit { parts.append("Warlord's Gambit: kill → +3 STR") }
        if hasEndure        { parts.append("Endure: survive lethal once") }
        if hasJuggernaut    { parts.append("Juggernaut: block carries over") }
        if hasUntouchable   { parts.append("Untouchable: dodge → +2 ATK") }
        if hasShadowMark    { parts.append("Shadow Mark: status → +1 Vulnerable") }
        if hasAssassinate   { parts.append("Assassinate: 4+ stacks → free attack") }
        if hasDeathCuts     { parts.append("Death Cuts: bleed spreads on kill") }
        if hasShatter       { parts.append("Shatter: 2× on Frozen enemy") }
        if hasPermafrost    { parts.append("Permafrost: Frozen lasts 2 turns") }
        if hasConflagration { parts.append("Conflagration: kill with burn spreads fire") }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Skill Node

struct SkillNode: Identifiable, Codable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let flavorText: String
    let tier: Int           // 1–4
    let branch: Int         // 0, 1, or 2
    let requiresId: String? // nil for tier-1 nodes
    let cost: Int
    let mechanic: SkillMechanic
}

// MARK: - Hero class branch names

extension HeroClass {
    var skillBranchNames: [String] {
        switch self {
        case .barbarian: return ["Rage", "Fortitude", "Warlord"]
        case .rogue:     return ["Agility", "Venom", "Shadow"]
        case .sorceress: return ["Pyromancer", "Frost Mage", "Arcane"]
        }
    }
    var skillBranchIcons: [String] {
        switch self {
        case .barbarian: return ["🩸", "🛡️", "🪖"]
        case .rogue:     return ["💨", "☠️", "🌑"]
        case .sorceress: return ["🔥", "❄️", "⚡"]
        }
    }
}

// MARK: - Database

struct SkillDatabase {

    static func branchColor(_ branch: Int) -> Color {
        switch branch {
        case 0: return Color(red: 1.0, green: 0.35, blue: 0.2)
        case 1: return Color(red: 0.3, green: 0.7,  blue: 1.0)
        default: return Color(red: 0.5, green: 1.0, blue: 0.4)
        }
    }

    static func tree(for heroClass: HeroClass) -> [SkillNode] {
        switch heroClass {
        case .barbarian: return barbarianTree()
        case .rogue:     return rogueTree()
        case .sorceress: return sorceressTree()
        }
    }

    // MARK: - Barbarian (4 tiers × 3 branches)
    // Branch 0 — Rage:      Take damage → gain Strength. Reward not blocking.
    // Branch 1 — Fortitude: Lifelink + Endure + Juggernaut. Unkillable sustain.
    // Branch 2 — Warlord:   Bloodlust + Rampage + Warlord's Gambit. Kill-chain engine.

    private static func barbarianTree() -> [SkillNode] {
        [
            // ── Branch 0 — Rage ──────────────────────────────────────────
            SkillNode(id: "barb_r1", name: "Battle Scars",       icon: "🩸",
                      description: "Each time you take damage in the block phase, gain +1 Strength this combat. Run low defense and get hit — you'll hit back harder.",
                      flavorText: "\"Pain is fuel.\"",
                      tier: 1, branch: 0, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(attackBonus: 2, rageOnHit: 1)),

            SkillNode(id: "barb_r2", name: "Bloodied Fury",       icon: "💢",
                      description: "+3 ATK and Rage now gives +2 STR per hit taken. A few blocked hits becomes massive attack power.",
                      flavorText: "\"The wounds make me stronger.\"",
                      tier: 2, branch: 0, requiresId: "barb_r1", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 3, rageOnHit: 1)),

            SkillNode(id: "barb_r3", name: "Wrath Incarnate",     icon: "🌋",
                      description: "+4 ATK. Rage now gives +3 STR per hit. Stack high-damage attacks and let enemies punish you into godhood.",
                      flavorText: "\"Every scar is a power I earned.\"",
                      tier: 3, branch: 0, requiresId: "barb_r2", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 4, rageOnHit: 1)),

            SkillNode(id: "barb_r4", name: "Undying Rage",        icon: "👹",
                      description: "[CAPSTONE] Killing an enemy grants +3 Strength this combat. The more you kill, the harder every subsequent hit lands.",
                      flavorText: "\"Death is just another source of power.\"",
                      tier: 4, branch: 0, requiresId: "barb_r3", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 2, hasWarlordGambit: true)),

            // ── Branch 1 — Fortitude ─────────────────────────────────────
            SkillNode(id: "barb_e1", name: "Iron Constitution",   icon: "🪨",
                      description: "+25 Max HP, +4 block every turn. The foundation of an unkillable wall — survive long enough to win.",
                      flavorText: "\"I do not fall.\"",
                      tier: 1, branch: 1, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(startingBlock: 4, maxHpBonus: 25)),

            SkillNode(id: "barb_e2", name: "Lifelink",            icon: "❤️‍🔥",
                      description: "Physical attacks heal 2 HP per hit. Multi-hit cards like Pummel become a healing engine. Forgo block cards entirely.",
                      flavorText: "\"Every wound I give closes one I have.\"",
                      tier: 2, branch: 1, requiresId: "barb_e1", cost: 1,
                      mechanic: SkillMechanic(lifeStealPerHit: 2)),

            SkillNode(id: "barb_e3", name: "Endure",              icon: "⛰️",
                      description: "Once per combat, survive a lethal blow at 1 HP. One free life — use it to push aggressive plays you couldn't otherwise risk.",
                      flavorText: "\"Not here. Not today.\"",
                      tier: 3, branch: 1, requiresId: "barb_e2", cost: 1,
                      mechanic: SkillMechanic(lifeOnKill: 3, hasEndure: true)),

            SkillNode(id: "barb_e4", name: "Juggernaut",          icon: "🏔️",
                      description: "[CAPSTONE] Block no longer resets between turns. Leftover block from last turn stacks with new block this turn. A towering defence that grows every round.",
                      flavorText: "\"I am the wall.\"",
                      tier: 4, branch: 1, requiresId: "barb_e3", cost: 1,
                      mechanic: SkillMechanic(defenseBonus: 2, hasJuggernaut: true)),

            // ── Branch 2 — Warlord ───────────────────────────────────────
            SkillNode(id: "barb_w1", name: "Battle Rush",         icon: "⚡",
                      description: "+1 energy per kill. Chain enemies in the same turn for free card plays. Powerful in rooms with multiple weak enemies.",
                      flavorText: "\"Never stop moving.\"",
                      tier: 1, branch: 2, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(energyOnKill: 1)),

            SkillNode(id: "barb_w2", name: "Bloodlust",           icon: "🗡️",
                      description: "After killing an enemy, the next card you play this turn costs 0. Kill-chain momentum — finish one enemy and immediately threaten the next.",
                      flavorText: "\"The hunt never ends.\"",
                      tier: 2, branch: 2, requiresId: "barb_w1", cost: 1,
                      mechanic: SkillMechanic(hasBloodlust: true)),

            SkillNode(id: "barb_w3", name: "Rampage",             icon: "😤",
                      description: "After each kill, draw 1 card. Keep your hand full through waves of enemies. Pairs with Bloodlust for draw + free play combos.",
                      flavorText: "\"Every kill feeds the frenzy.\"",
                      tier: 3, branch: 2, requiresId: "barb_w2", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 2, hasRampage: true)),

            SkillNode(id: "barb_w4", name: "Warchief",            icon: "🌀",
                      description: "[CAPSTONE] +2 Energy/turn, +2 ATK, draw +1/turn. Sustained aggression. You'll see more cards, play more cards, and hit harder every turn.",
                      flavorText: "\"A storm of steel without end.\"",
                      tier: 4, branch: 2, requiresId: "barb_w3", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 2, drawPerTurn: 1, maxEnergyBonus: 2)),
        ]
    }

    // MARK: - Rogue (4 tiers × 3 branches)
    // Branch 0 — Agility:   Evasion charges + Untouchable. Never need block cards.
    // Branch 1 — Venom:     Poison + Bleed dual DoT. Multi-hit cards = massive stacks.
    // Branch 2 — Shadow:    Backstab + Shadow Mark + Assassinate. Set up, then delete.

    private static func rogueTree() -> [SkillNode] {
        [
            // ── Branch 0 — Agility ───────────────────────────────────────
            SkillNode(id: "rog_a1", name: "Light Feet",           icon: "💨",
                      description: "Draw +1 card/turn and start combat with 2 Evasion charges. Each charge auto-blocks one incoming attack — no card needed.",
                      flavorText: "\"Speed is the only armor I need.\"",
                      tier: 1, branch: 0, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(drawPerTurn: 1, evasionCharges: 2)),

            SkillNode(id: "rog_a2", name: "Phantom Step",         icon: "🌫️",
                      description: "+3 more Evasion charges (5 total). With 5 charges, you can run a pure offense deck — zero block cards.",
                      flavorText: "\"Strike before they react.\"",
                      tier: 2, branch: 0, requiresId: "rog_a1", cost: 1,
                      mechanic: SkillMechanic(evasionCharges: 3)),

            SkillNode(id: "rog_a3", name: "Ghost",                icon: "👻",
                      description: "Draw +2/turn total, +1 max energy. Run a 20-card deck. You'll cycle through it twice per combat with this many draws.",
                      flavorText: "\"Now you see me...\"",
                      tier: 3, branch: 0, requiresId: "rog_a2", cost: 1,
                      mechanic: SkillMechanic(drawPerTurn: 1, maxEnergyBonus: 1)),

            SkillNode(id: "rog_a4", name: "Untouchable",          icon: "🌑",
                      description: "[CAPSTONE] Each time you use an Evasion charge to dodge an attack, gain +2 Strength this combat. Dodging becomes both defense and offense.",
                      flavorText: "\"You can't hit what you can't see.\"",
                      tier: 4, branch: 0, requiresId: "rog_a3", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 2, hasUntouchable: true)),

            // ── Branch 1 — Venom ─────────────────────────────────────────
            SkillNode(id: "rog_v1", name: "Venom Glands",         icon: "🧪",
                      description: "+2 poison on every physical hit. Multi-hit cards like Blade Dance or Thousand Cuts apply poison per hit. Stack fast.",
                      flavorText: "\"Every wound festers.\"",
                      tier: 1, branch: 1, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(poisonOnHit: 2)),

            SkillNode(id: "rog_v2", name: "Hemorrhage",           icon: "🩸",
                      description: "Physical attacks apply 3 Bleed stacks. Bleed triggers on every physical hit — multi-hit cards drain it fast for huge bonus damage.",
                      flavorText: "\"A slow death is still death.\"",
                      tier: 2, branch: 1, requiresId: "rog_v1", cost: 1,
                      mechanic: SkillMechanic(lifeOnKill: 2, bleedOnHit: 3)),

            SkillNode(id: "rog_v3", name: "Plague Lord",          icon: "🦠",
                      description: "+2 more Bleed/hit (5 total), +4 more Poison/hit. One Flurry card can now deliver enormous stacked DoT damage.",
                      flavorText: "\"Let it spread.\"",
                      tier: 3, branch: 1, requiresId: "rog_v2", cost: 1,
                      mechanic: SkillMechanic(startingBlock: 3, poisonOnHit: 4, bleedOnHit: 2)),

            SkillNode(id: "rog_v4", name: "Death by 1000 Cuts",   icon: "☠️",
                      description: "[CAPSTONE] When an enemy dies with Bleed stacks, those stacks transfer to a random living enemy. Bleed chains through the entire fight.",
                      flavorText: "\"The wound follows you.\"",
                      tier: 4, branch: 1, requiresId: "rog_v3", cost: 1,
                      mechanic: SkillMechanic(poisonOnHit: 2, bleedOnHit: 2, hasDeathCuts: true)),

            // ── Branch 2 — Shadow ────────────────────────────────────────
            SkillNode(id: "rog_s1", name: "Sharpened",            icon: "🗡️",
                      description: "+3 ATK. The foundation of a burst damage build. Every attack card hits harder, making Backstab payoffs even bigger.",
                      flavorText: "\"A razor's edge.\"",
                      tier: 1, branch: 2, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(attackBonus: 3)),

            SkillNode(id: "rog_s2", name: "Backstab",             icon: "⚡",
                      description: "Attacks deal +3 damage per status effect stack on the target. Poison, Bleed, Weak, Vulnerable — every stack counts. Set up first, then detonate.",
                      flavorText: "\"Choose the right moment.\"",
                      tier: 2, branch: 2, requiresId: "rog_s1", cost: 1,
                      mechanic: SkillMechanic(backstabPerStack: 3)),

            SkillNode(id: "rog_s3", name: "Shadow Mark",          icon: "🌒",
                      description: "Whenever you apply any status effect to an enemy, also apply 1 Vulnerable. Every debuff card now stacks Vulnerable for Backstab.",
                      flavorText: "\"Mark them. Then strike.\"",
                      tier: 3, branch: 2, requiresId: "rog_s2", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 2, hasShadowMark: true)),

            SkillNode(id: "rog_s4", name: "Assassinate",          icon: "🎯",
                      description: "[CAPSTONE] When a target has 4+ total status stacks, your next attack against them costs 0. Load up debuffs, then finish for free.",
                      flavorText: "\"You were already dead.\"",
                      tier: 4, branch: 2, requiresId: "rog_s3", cost: 1,
                      mechanic: SkillMechanic(attackBonus: 3, hasAssassinate: true)),
        ]
    }

    // MARK: - Sorceress (4 tiers × 3 branches)
    // Branch 0 — Pyromancer: Burn DoT + Ignite Burst AoE + Conflagration spread.
    // Branch 1 — Frost Mage: Chill → Freeze → Shatter 2×. Control deck.
    // Branch 2 — Arcane:     ⚡ Arcane keyword triggers on 3rd (then 2nd) card played.

    private static func sorceressTree() -> [SkillNode] {
        [
            // ── Branch 0 — Pyromancer ────────────────────────────────────
            SkillNode(id: "sor_p1", name: "Kindling",             icon: "🔥",
                      description: "+3 Spellpower — all fire cards hit harder. The foundation of a burn-stack deck. Scorch, Ignite, Inferno all benefit immediately.",
                      flavorText: "\"Ash and cinders.\"",
                      tier: 1, branch: 0, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 3)),

            SkillNode(id: "sor_p2", name: "Fan the Flames",       icon: "☄️",
                      description: "+5 SP total. Fire cards hit significantly harder and burn DoT ramps faster. Build a deck that applies burn every turn.",
                      flavorText: "\"Feed the inferno.\"",
                      tier: 2, branch: 0, requiresId: "sor_p1", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 4, drawPerTurn: 1)),

            SkillNode(id: "sor_p3", name: "Ignite Burst",         icon: "💥",
                      description: "When an enemy's burn stacks reach 10, they EXPLODE — dealing burn-stack AoE damage to all enemies. Focus one target to trigger a devastating nuke.",
                      flavorText: "\"Let them burn. All of them.\"",
                      tier: 3, branch: 0, requiresId: "sor_p2", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 2, igniteBurstThreshold: 10)),

            SkillNode(id: "sor_p4", name: "Conflagration",        icon: "🌊",
                      description: "[CAPSTONE] When an enemy dies while burning, spread 5 burn stacks to all remaining enemies. Chain-explode entire rooms.",
                      flavorText: "\"A tide of fire.\"",
                      tier: 4, branch: 0, requiresId: "sor_p3", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 3, hasConflagration: true)),

            // ── Branch 1 — Frost Mage ────────────────────────────────────
            SkillNode(id: "sor_i1", name: "Arctic Mantle",        icon: "❄️",
                      description: "+4 block/turn, +2 SP. The defensive foundation — survive long enough to build Chill stacks and lock down enemies.",
                      flavorText: "\"Cold slows. Cold kills.\"",
                      tier: 1, branch: 1, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 2, startingBlock: 4)),

            SkillNode(id: "sor_i2", name: "Chill",                icon: "🧊",
                      description: "Ice attacks now apply 2 Chill stacks. At 6 stacks, the enemy is FROZEN and skips their next attack. Control at its finest.",
                      flavorText: "\"Crystalline. Merciless.\"",
                      tier: 2, branch: 1, requiresId: "sor_i1", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 2, chillOnHit: 2, freezeThreshold: 6)),

            SkillNode(id: "sor_i3", name: "Shatter",              icon: "💎",
                      description: "Attacking a Frozen enemy deals 2× damage and consumes the Freeze. Freeze them with ice cards, then follow up with your hardest hitting spell.",
                      flavorText: "\"Still, then gone.\"",
                      tier: 3, branch: 1, requiresId: "sor_i2", cost: 1,
                      mechanic: SkillMechanic(defenseBonus: 2, hasShatter: true)),

            SkillNode(id: "sor_i4", name: "Permafrost",           icon: "🌨️",
                      description: "[CAPSTONE] Frozen enemies remain frozen for 2 turns instead of 1, and Chill stacks don't reset after freezing. Perpetual lockdown.",
                      flavorText: "\"A storm without end.\"",
                      tier: 4, branch: 1, requiresId: "sor_i3", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 3, hasPermafrost: true)),

            // ── Branch 2 — Arcane ────────────────────────────────────────
            SkillNode(id: "sor_l1", name: "Mana Well",            icon: "💧",
                      description: "+1 max energy. Unlocks the ⚡ Arcane keyword — cards with Arcane deal bonus damage when they are the 3rd card you play in a turn.",
                      flavorText: "\"The reservoir runs deep.\"",
                      tier: 1, branch: 2, requiresId: nil, cost: 1,
                      mechanic: SkillMechanic(maxEnergyBonus: 1, arcaneThreshold: 3)),

            SkillNode(id: "sor_l2", name: "Arcane Resonance",     icon: "🌩️",
                      description: "+3 SP. Arcane bonuses now deal 50% more. Save your Arcane cards for the 3rd slot to maximize their payoff.",
                      flavorText: "\"The surge is deafening.\"",
                      tier: 2, branch: 2, requiresId: "sor_l1", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 3, arcaneMultiplierBonus: 0.5)),

            SkillNode(id: "sor_l3", name: "Surge",                icon: "⚡",
                      description: "+1 max energy. Arcane now triggers on the 2nd card played instead of the 3rd. Every other card is now an Arcane trigger.",
                      flavorText: "\"Power beyond measure.\"",
                      tier: 3, branch: 2, requiresId: "sor_l2", cost: 1,
                      mechanic: SkillMechanic(maxEnergyBonus: 1, arcaneThreshold: -1)),

            SkillNode(id: "sor_l4", name: "Overchannel",          icon: "💫",
                      description: "[CAPSTONE] +3 SP, draw +1/turn, Arcane bonus ×2 total. Meteor + Pyroclasm in one turn is now achievable. Peak arcane mastery.",
                      flavorText: "\"Burn everything.\"",
                      tier: 4, branch: 2, requiresId: "sor_l3", cost: 1,
                      mechanic: SkillMechanic(spellpowerBonus: 3, drawPerTurn: 1, arcaneMultiplierBonus: 0.5)),
        ]
    }
}
