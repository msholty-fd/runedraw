import Foundation

// MARK: - Outcome

indirect enum EncounterOutcome {
    case nothing
    case heal(Int)
    case healPercent(Double)
    case damage(Int)
    case damagePercent(Double)
    case gold(Int)
    case loot(tier: Int)
    case statPoints(Int)
    case combo([EncounterOutcome])
    /// probability = 0–1 chance of `good`, otherwise `bad`
    case chance(Double, good: EncounterOutcome, bad: EncounterOutcome)
}

// MARK: - Choice

struct EncounterChoice: Identifiable {
    let id: String
    let label: String
    let subtitle: String
    let outcome: EncounterOutcome
    let isRisky: Bool

    init(_ label: String, subtitle: String = "", outcome: EncounterOutcome,
         isRisky: Bool = false, id: String? = nil) {
        self.id       = id ?? label.lowercased().replacingOccurrences(of: " ", with: "_")
        self.label    = label
        self.subtitle = subtitle
        self.outcome  = outcome
        self.isRisky  = isRisky
    }
}

// MARK: - Event

struct EncounterEvent: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let choices: [EncounterChoice]
    let tier: Int  // 1 = low areas, 2 = mid, 3 = high; 0 = any
}

// MARK: - Database

struct EncounterDatabase {

    // MARK: All events

    static let all: [EncounterEvent] = [

        // ─── Any tier ──────────────────────────────────────────────────────────

        EncounterEvent(
            id: "abandoned_cache",
            title: "Abandoned Cache",
            description: "A rotting pack sits wedged behind a collapsed pillar. Someone left in a hurry.",
            icon: "🎒",
            choices: [
                EncounterChoice("Search It",
                                subtitle: "Take whatever's inside",
                                outcome: .combo([.gold(Int.random(in: 20...35)), .loot(tier: 1)])),
                EncounterChoice("Leave It",
                                subtitle: "Could be a trap",
                                outcome: .nothing),
            ],
            tier: 0
        ),

        EncounterEvent(
            id: "campfire",
            title: "Wanderer's Campfire",
            description: "Still warm embers and a pot of stew. Whoever was here left recently.",
            icon: "🔥",
            choices: [
                EncounterChoice("Rest and Eat",
                                subtitle: "Recover 25% max HP",
                                outcome: .healPercent(0.25)),
                EncounterChoice("Grab the Rations",
                                subtitle: "Quick heal, keep moving",
                                outcome: .heal(12)),
            ],
            tier: 0
        ),

        EncounterEvent(
            id: "old_shrine",
            title: "Ancient Shrine",
            description: "A weathered stone idol hums faintly. Runes carved into its base glow with dim light.",
            icon: "🪨",
            choices: [
                EncounterChoice("Pray",
                                subtitle: "70% chance of blessing, 30% backlash",
                                outcome: .chance(0.70,
                                                 good: .healPercent(0.20),
                                                 bad: .damage(14)),
                                isRisky: true),
                EncounterChoice("Smash It",
                                subtitle: "Take damage, but claim the gold inside",
                                outcome: .combo([.damage(10), .gold(22)]),
                                isRisky: true),
                EncounterChoice("Leave It",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 0
        ),

        EncounterEvent(
            id: "eerie_mist",
            title: "Eerie Mist",
            description: "A silver fog pours from a crack in the wall. It smells of old magic.",
            icon: "🌫️",
            choices: [
                EncounterChoice("Walk Through",
                                subtitle: "60% chance: heal 20% HP. 40%: take 15% damage",
                                outcome: .chance(0.60,
                                                 good: .healPercent(0.20),
                                                 bad: .damagePercent(0.15)),
                                isRisky: true),
                EncounterChoice("Turn Back",
                                subtitle: "Nothing ventured, nothing gained",
                                outcome: .nothing),
            ],
            tier: 0
        ),

        EncounterEvent(
            id: "whispering_bones",
            title: "Whispering Bones",
            description: "A skeleton sits upright, hands clasped as if still meditating. Its jaw moves soundlessly.",
            icon: "💀",
            choices: [
                EncounterChoice("Listen",
                                subtitle: "Gain 2 stat points from the ancients' knowledge",
                                outcome: .statPoints(2)),
                EncounterChoice("Crush It",
                                subtitle: "Not in the mood",
                                outcome: .nothing),
            ],
            tier: 0
        ),

        EncounterEvent(
            id: "trap_chest",
            title: "Suspicious Chest",
            description: "A gleaming chest in the middle of an empty room. Something about this feels wrong.",
            icon: "📦",
            choices: [
                EncounterChoice("Open Carefully",
                                subtitle: "Takes time, but safe — claim the contents",
                                outcome: .loot(tier: 1)),
                EncounterChoice("Rip It Open",
                                subtitle: "Take damage, but claim better loot",
                                outcome: .combo([.damage(20), .loot(tier: 2)]),
                                isRisky: true),
                EncounterChoice("Leave It",
                                subtitle: "Not worth the risk",
                                outcome: .nothing),
            ],
            tier: 0
        ),

        // ─── Tier 1–2 ──────────────────────────────────────────────────────────

        EncounterEvent(
            id: "wounded_merc",
            title: "Wounded Mercenary",
            description: "A fighter slumped against the wall, wounds wrapped in rags. Their eyes follow you.",
            icon: "🩹",
            choices: [
                EncounterChoice("Aid Them",
                                subtitle: "Spend 25g — they share what they know",
                                outcome: .combo([.gold(-25), .statPoints(1)])),
                EncounterChoice("Take Their Purse",
                                subtitle: "They're not going to need it",
                                outcome: .gold(Int.random(in: 15...30))),
                EncounterChoice("Pass By",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 1
        ),

        EncounterEvent(
            id: "ruined_fountain",
            title: "Ruined Fountain",
            description: "A cracked stone basin, still trickling with dark water. Faint runes line the rim.",
            icon: "⛲",
            choices: [
                EncounterChoice("Drink Deep",
                                subtitle: "Restore 30% max HP",
                                outcome: .healPercent(0.30)),
                EncounterChoice("Splash Your Face",
                                subtitle: "Minor refresh — heal 10 HP",
                                outcome: .heal(10)),
            ],
            tier: 1
        ),

        EncounterEvent(
            id: "wandering_merchant",
            title: "Wandering Merchant",
            description: "A hooded figure with a battered cart waves you over. Their wares glint in the torchlight.",
            icon: "🛒",
            choices: [
                EncounterChoice("Browse Wares (20g)",
                                subtitle: "Pay gold, receive a random item",
                                outcome: .combo([.gold(-20), .loot(tier: 1)])),
                EncounterChoice("Ask About Rarer Stock (45g)",
                                subtitle: "Expensive, but higher quality",
                                outcome: .combo([.gold(-45), .loot(tier: 2)])),
                EncounterChoice("Keep Walking",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 1
        ),

        // ─── Tier 2–3 ──────────────────────────────────────────────────────────

        EncounterEvent(
            id: "corrupted_altar",
            title: "Corrupted Altar",
            description: "Black candles burn with red flame. A low chanting fills the air, though no one is present.",
            icon: "🕯️",
            choices: [
                EncounterChoice("Offer Blood",
                                subtitle: "Spend 15% HP — receive power and gold",
                                outcome: .combo([.damagePercent(0.15), .gold(30), .loot(tier: 2)])),
                EncounterChoice("Desecrate It",
                                subtitle: "Take damage, deny its power to anyone",
                                outcome: .damage(15)),
                EncounterChoice("Withdraw",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 2
        ),

        EncounterEvent(
            id: "mysterious_pool",
            title: "Mysterious Pool",
            description: "Still black water in a carved basin. Your reflection stares back — but doesn't move when you do.",
            icon: "🌊",
            choices: [
                EncounterChoice("Drink",
                                subtitle: "50% chance: +15 max HP & heal. 50%: lose 10 max HP",
                                outcome: .chance(0.50,
                                                 good: .combo([.heal(20), .statPoints(1)]),
                                                 bad: .damage(18)),
                                isRisky: true),
                EncounterChoice("Ignore It",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 2
        ),

        EncounterEvent(
            id: "illusion_child",
            title: "Crying in the Dark",
            description: "You hear sobbing from around a corner. A small figure hunches in the shadows.",
            icon: "👁️",
            choices: [
                EncounterChoice("Approach",
                                subtitle: "40% chance: scared villager who rewards you. 60%: a wraith attacks",
                                outcome: .chance(0.40,
                                                 good: .combo([.healPercent(0.15), .gold(20)]),
                                                 bad: .combo([.damage(22), .damage(8)])),
                                isRisky: true),
                EncounterChoice("Keep Your Distance",
                                subtitle: "Back away slowly",
                                outcome: .nothing),
            ],
            tier: 2
        ),

        // ─── Tier 3 ────────────────────────────────────────────────────────────

        EncounterEvent(
            id: "crumbling_relic",
            title: "Crumbling Relic",
            description: "An ancient obelisk covered in faded script. The language is old — very old — but you understand fragments.",
            icon: "🗿",
            choices: [
                EncounterChoice("Study It",
                                subtitle: "Absorb what knowledge remains",
                                outcome: .statPoints(2)),
                EncounterChoice("Extract the Core",
                                subtitle: "Take damage but claim valuable ore",
                                outcome: .combo([.damage(12), .gold(40)])),
                EncounterChoice("Leave It",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 3
        ),

        EncounterEvent(
            id: "desecrated_font",
            title: "Desecrated Font",
            description: "A holy vessel now filled with brackish water. Coins glitter at the bottom despite the filth.",
            icon: "⛪",
            choices: [
                EncounterChoice("Reach In for the Coins",
                                subtitle: "Claim the gold, accept the corruption",
                                outcome: .combo([.damagePercent(0.12), .gold(50)])),
                EncounterChoice("Purify It",
                                subtitle: "Costs your effort — minor damage — but it heals you",
                                outcome: .combo([.damage(8), .healPercent(0.20)])),
                EncounterChoice("Pass",
                                subtitle: "",
                                outcome: .nothing),
            ],
            tier: 3
        ),

        EncounterEvent(
            id: "mercenary_challenge",
            title: "The Challenger",
            description: "A scarred mercenary blocks your path. \u{201C}Pay the toll or we'll settle it in blood.\u{201D}",
            icon: "⚔️",
            choices: [
                EncounterChoice("Pay the Toll (30g)",
                                subtitle: "They let you pass and throw in something extra",
                                outcome: .combo([.gold(-30), .loot(tier: 2)])),
                EncounterChoice("Refuse and Fight",
                                subtitle: "They lash out before you're ready — you take a hit",
                                outcome: .combo([.damage(25), .gold(35)]),
                                isRisky: true),
                EncounterChoice("Intimidate",
                                subtitle: "65% chance they back down. 35% they attack anyway",
                                outcome: .chance(0.65,
                                                 good: .nothing,
                                                 bad: .damage(20)),
                                isRisky: true),
            ],
            tier: 3
        ),
    ]

    // MARK: - Lookup

    static func event(id: String) -> EncounterEvent? {
        all.first { $0.id == id }
    }

    /// Returns a random encounter ID appropriate for the given enemy tier.
    static func randomId(tier enemyTier: Int) -> String {
        let available = all.filter { $0.tier == 0 || $0.tier <= enemyTier }
        return available.randomElement()?.id ?? all.first!.id
    }
}
