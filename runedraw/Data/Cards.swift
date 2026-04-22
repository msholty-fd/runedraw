// swiftlint:disable line_length
import Foundation

struct CardDatabase {

    static func startingDeck(for heroClass: HeroClass) -> [Card] {
        switch heroClass {
        case .barbarian: return barbarianDeck()
        case .rogue:     return rogueDeck()
        case .sorceress: return sorceressDeck()
        }
    }

    // MARK: - Droppable card pool (world drops, not skill-tree rewards)

    /// Returns a random droppable combat card of the given `rarity`.
    /// Pool is weighted: hero's own class cards appear 2× more often than off-class cards.
    /// Neutral cards are always in the pool. Off-class cards can drop — they encourage trading.
    static func droppableCard(for heroClass: HeroClass, rarity: CardRarity) -> Card? {
        var pool: [Card] = []
        // Own class: double-weight (added twice)
        let ownPool = cardPool(for: heroClass).filter { $0.rarity == rarity }
        pool += ownPool
        pool += ownPool
        // Other classes: single weight each
        for other in HeroClass.allCases where other != heroClass {
            pool += cardPool(for: other).filter { $0.rarity == rarity }
        }
        // Neutral: always available
        pool += neutralCardPool().filter { $0.rarity == rarity }

        guard let proto = pool.randomElement() else { return nil }
        // Fresh UUID so every drop is a distinct card
        return Card(id: UUID(), name: proto.name, description: proto.description,
                    cost: proto.cost, type: proto.type, rarity: proto.rarity,
                    heroClass: proto.heroClass, effect: proto.effect,
                    defenseValue: proto.defenseValue)
    }

    // MARK: - Barbarian card pool

    // swiftlint:disable function_body_length
    private static func cardPool(for heroClass: HeroClass) -> [Card] {
        switch heroClass {
        case .barbarian: return barbarianPool()
        case .rogue:     return roguePool()
        case .sorceress: return sorceressPool()
        }
    }

    private static func barbarianPool() -> [Card] {
        [
            // Common
            card("Slam",          "Deal 10 physical damage.",              cost: 1, rarity: .common, type: .attack, class: .barbarian, effect: CardEffect(damage: 10, damageType: .physical),                                 def: 3),
            card("Iron Skin",     "Gain 8 block.",                         cost: 1, rarity: .common, type: .skill,  class: .barbarian, effect: CardEffect(block: 8),                                                         def: 7),
            card("Rage",          "Gain 2 energy.",                        cost: 0, rarity: .common, type: .skill,  class: .barbarian, effect: CardEffect(energyGain: 2),                                                    def: 2),
            card("Ground Smash",  "Deal 5 damage to ALL enemies.",         cost: 1, rarity: .common, type: .attack, class: .barbarian, effect: CardEffect(damage: 5, damageType: .physical, damageAllEnemies: true),         def: 2),
            card("Endure",        "Gain 6 block. Draw 1.",                 cost: 2, rarity: .common, type: .skill,  class: .barbarian, effect: CardEffect(block: 6, draw: 1),                                                def: 5),
            card("Heavy Strike",  "Deal 12 physical damage.",              cost: 2, rarity: .common, type: .attack, class: .barbarian, effect: CardEffect(damage: 12, damageType: .physical),                                def: 3),
            // Magic
            card("Berserk",       "Draw 2. Gain 1 energy.",                cost: 1, rarity: .magic,  type: .skill,  class: .barbarian, effect: CardEffect(draw: 2, energyGain: 1),                                          def: 2),
            card("War Shout",     "Gain 5 block. Draw 1.",                 cost: 1, rarity: .magic,  type: .skill,  class: .barbarian, effect: CardEffect(block: 5, draw: 1),                                                def: 4),
            card("Pummel",        "Deal 4 physical damage twice.",         cost: 2, rarity: .magic,  type: .attack, class: .barbarian, effect: CardEffect(damage: 4, damageType: .physical, times: 2),                      def: 3),
            card("Reckless Swing","Deal 15 physical damage.",              cost: 2, rarity: .magic,  type: .attack, class: .barbarian, effect: CardEffect(damage: 15, damageType: .physical),                                def: 2),
            // Rare
            card("Whirlwind",     "Deal 8 physical damage to ALL.",        cost: 2, rarity: .rare,   type: .attack, class: .barbarian, effect: CardEffect(damage: 8, damageType: .physical, damageAllEnemies: true),         def: 3),
            card("Bloodlust",     "Deal 8 damage. Heal 4.",                cost: 2, rarity: .rare,   type: .attack, class: .barbarian, effect: CardEffect(damage: 8, damageType: .physical, heal: 4),                       def: 3),
            card("Second Wind",   "Gain 10 block. Draw 2.",                cost: 2, rarity: .rare,   type: .skill,  class: .barbarian, effect: CardEffect(block: 10, draw: 2),                                               def: 6),
            card("Crushing Blow", "Deal 18 physical damage.",              cost: 3, rarity: .rare,   type: .attack, class: .barbarian, effect: CardEffect(damage: 18, damageType: .physical),                                def: 3),
            // Unique
            card("Annihilate",    "Deal 25 physical damage.",              cost: 3, rarity: .unique, type: .attack, class: .barbarian, effect: CardEffect(damage: 25, damageType: .physical),                                def: 2),
            card("Warcry of Blood","Gain 2 energy. Draw 3.",               cost: 2, rarity: .unique, type: .skill,  class: .barbarian, effect: CardEffect(draw: 3, energyGain: 2),                                          def: 3),
        ]
    }

    // MARK: - Rogue card pool

    private static func roguePool() -> [Card] {
        [
            // Common
            card("Quick Stab",    "Deal 5 physical damage.",               cost: 0, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 5, damageType: .physical),                                     def: 3),
            card("Veil",          "Gain 6 block.",                         cost: 1, rarity: .common, type: .skill,  class: .rogue, effect: CardEffect(block: 6),                                                             def: 6),
            card("Ambush",        "Deal 7 damage. Draw 1.",                cost: 2, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 7, damageType: .physical, draw: 1),                            def: 3),
            card("Fan of Knives", "Deal 3 damage to ALL enemies.",         cost: 1, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 3, damageType: .physical, damageAllEnemies: true),             def: 2),
            card("Envenom",       "Apply 5 poison.",                       cost: 1, rarity: .common, type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 5),                                                      def: 3),
            card("Crippling Blow","Deal 6 damage. Apply 3 weak.",          cost: 2, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 6, damageType: .physical, weakStacks: 3),                      def: 3),
            // Magic
            card("Shadow Veil",   "Gain 9 block. Draw 1.",                 cost: 2, rarity: .magic,  type: .skill,  class: .rogue, effect: CardEffect(block: 9, draw: 1),                                                   def: 5),
            card("Blade Dance",   "Deal 4 physical damage twice.",         cost: 2, rarity: .magic,  type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, times: 2),                          def: 3),
            card("Smoke Bomb",    "Gain 8 block. Apply 2 weak.",           cost: 2, rarity: .magic,  type: .skill,  class: .rogue, effect: CardEffect(block: 8, weakStacks: 2),                                             def: 4),
            card("Adder's Kiss",  "Apply 8 poison.",                       cost: 1, rarity: .magic,  type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 8),                                                     def: 2),
            // Rare
            card("Death Mark",    "Deal 8 damage. Apply 6 poison.",        cost: 2, rarity: .rare,   type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical, poisonStacks: 6),                   def: 3),
            card("Shadowstrike",  "Deal 12 physical damage.",              cost: 2, rarity: .rare,   type: .attack, class: .rogue, effect: CardEffect(damage: 12, damageType: .physical),                                   def: 3),
            card("Predator",      "Deal 4 damage to all. Apply 3 poison.", cost: 3, rarity: .rare,   type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3, damageAllEnemies: true), def: 2),
            card("Evasion",       "Gain 12 block. Draw 1.",                cost: 2, rarity: .rare,   type: .skill,  class: .rogue, effect: CardEffect(block: 12, draw: 1),                                                  def: 5),
            // Unique
            card("Assassinate",   "Deal 15 damage. Apply 8 poison.",       cost: 3, rarity: .unique, type: .attack, class: .rogue, effect: CardEffect(damage: 15, damageType: .physical, poisonStacks: 8),                  def: 3),
            card("Thousand Cuts", "Deal 3 physical damage four times.",    cost: 3, rarity: .unique, type: .attack, class: .rogue, effect: CardEffect(damage: 3, damageType: .physical, times: 4),                          def: 2),
        ]
    }

    // MARK: - Sorceress card pool

    private static func sorceressPool() -> [Card] {
        [
            // Common
            card("Frost Bolt",    "Deal 7 ice damage.",                    cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 7, damageType: .ice),                                     def: 3),
            card("Static Shock",  "Deal 5 arcane damage.",                 cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .arcane),                                  def: 3),
            card("Flame Strike",  "Deal 8 fire damage.",                   cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 8, damageType: .fire),                                    def: 2),
            card("Ice Armor",     "Gain 10 block.",                        cost: 2, rarity: .common, type: .skill,  class: .sorceress, effect: CardEffect(block: 10),                                                       def: 7),
            card("Arcane Blast",  "Deal 4 arcane damage twice.",           cost: 2, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 4, damageType: .arcane, times: 2),                       def: 3),
            card("Chill Touch",   "Deal 5 ice damage. Apply 2 weak.",      cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .ice, weakStacks: 2),                     def: 3),
            // Magic
            card("Chain Lightning","Deal 5 arcane to ALL enemies.",        cost: 2, rarity: .magic,  type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .arcane, damageAllEnemies: true),          def: 2),
            card("Ice Spear",     "Deal 10 ice damage.",                   cost: 2, rarity: .magic,  type: .attack, class: .sorceress, effect: CardEffect(damage: 10, damageType: .ice),                                   def: 3),
            card("Blaze",         "Deal 6 fire damage twice.",             cost: 3, rarity: .magic,  type: .attack, class: .sorceress, effect: CardEffect(damage: 6, damageType: .fire, times: 2),                         def: 2),
            card("Mana Burst",    "Draw 3. Gain 1 energy.",                cost: 2, rarity: .magic,  type: .skill,  class: .sorceress, effect: CardEffect(draw: 3, energyGain: 1),                                         def: 2),
            // Rare
            card("Blizzard",      "Deal 8 ice damage to ALL enemies.",     cost: 3, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 8, damageType: .ice, damageAllEnemies: true),             def: 2),
            card("Meteor",        "Deal 18 fire damage.",                  cost: 3, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 18, damageType: .fire),                                  def: 2),
            card("Arcane Torrent","Deal 5 arcane damage three times.",     cost: 3, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .arcane, times: 3),                       def: 2),
            card("Glacial Prison","Deal 15 ice damage. Gain 8 block.",     cost: 3, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 15, damageType: .ice, block: 8),                         def: 4),
            // Unique
            card("Inferno",       "Deal 12 fire damage to ALL enemies.",   cost: 4, rarity: .unique, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire, damageAllEnemies: true),           def: 2),
            card("Frozen Time",   "Deal 10 ice damage. Draw 2.",           cost: 3, rarity: .unique, type: .attack, class: .sorceress, effect: CardEffect(damage: 10, damageType: .ice, draw: 2),                          def: 3),
        ]
    }
    // swiftlint:enable function_body_length

    // MARK: - Neutral card pool (any class can find these)

    static func neutralCardPool() -> [Card] {
        [
            // Common
            card("Potion Sip",    "Heal 8.",                               cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(heal: 8),                                                                def: 3),
            card("Iron Will",     "Gain 6 block.",                         cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(block: 6),                                                               def: 6),
            card("Quick Draw",    "Draw 2.",                               cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(draw: 2),                                                                def: 3),
            card("Rest",          "Heal 5. Draw 1.",                       cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(draw: 1, heal: 5),                                                       def: 3),
            // Magic
            card("Elixir",        "Heal 12.",                              cost: 2, rarity: .magic,  type: .skill,  class: nil, effect: CardEffect(heal: 12),                                                               def: 3),
            card("Momentum",      "Draw 2. Gain 1 energy.",                cost: 2, rarity: .magic,  type: .skill,  class: nil, effect: CardEffect(draw: 2, energyGain: 1),                                                def: 2),
            card("Fortify",       "Gain 10 block.",                        cost: 2, rarity: .magic,  type: .skill,  class: nil, effect: CardEffect(block: 10),                                                              def: 7),
            // Rare
            card("Ancient Scroll","Draw 3.",                               cost: 2, rarity: .rare,   type: .skill,  class: nil, effect: CardEffect(draw: 3),                                                                def: 3),
            card("Phoenix Feather","Heal 15. Draw 1.",                     cost: 3, rarity: .rare,   type: .skill,  class: nil, effect: CardEffect(draw: 1, heal: 15),                                                      def: 3),
            card("Second Chance", "Gain 8 block. Heal 6.",                 cost: 2, rarity: .rare,   type: .skill,  class: nil, effect: CardEffect(block: 8, heal: 6),                                                     def: 5),
        ]
    }

    // MARK: - Starting Decks

    private static func barbarianDeck() -> [Card] {
        unique([
            card("Strike",     "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical), def: 3),
            card("Strike",     "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical), def: 3),
            card("Strike",     "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical), def: 3),
            card("Defend",     "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                          def: 6),
            card("Defend",     "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                          def: 6),
            card("Defend",     "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                          def: 6),
            card("Cleave",     "Deal 4 damage to ALL enemies.", cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 4, damageType: .physical, damageAllEnemies: true), def: 2),
            card("Battle Cry", "Gain 3 block. Draw 1.",         cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 3, draw: 1),                 def: 4),
        ])
    }

    private static func rogueDeck() -> [Card] {
        unique([
            card("Backstab",     "Deal 8 damage.",                 cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical),                       def: 3),
            card("Backstab",     "Deal 8 damage.",                 cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical),                       def: 3),
            card("Backstab",     "Deal 8 damage.",                 cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical),                       def: 3),
            card("Shadow Step",  "Gain 5 block. Draw 1.",          cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1),                                      def: 5),
            card("Shadow Step",  "Gain 5 block. Draw 1.",          cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1),                                      def: 5),
            card("Poison Blade", "Deal 4 damage. Apply 3 poison.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3),      def: 2),
            card("Poison Blade", "Deal 4 damage. Apply 3 poison.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3),      def: 2),
            card("Preparation",  "Draw 2 cards.",                  cost: 1, type: .skill,  class: .rogue, effect: CardEffect(draw: 2),                                                def: 3),
        ])
    }

    private static func sorceressDeck() -> [Card] {
        unique([
            card("Fireball",     "Deal 12 fire damage.",         cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire),   def: 2),
            card("Fireball",     "Deal 12 fire damage.",         cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire),   def: 2),
            card("Magic Missile","Deal 6 arcane damage.",        cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane), def: 3),
            card("Magic Missile","Deal 6 arcane damage.",        cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane), def: 3),
            card("Magic Missile","Deal 6 arcane damage.",        cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane), def: 3),
            card("Mana Shield",  "Gain 8 block.",                cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8),                        def: 6),
            card("Mana Shield",  "Gain 8 block.",                cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8),                        def: 6),
            card("Arcane Surge", "Draw 2 cards. Gain 1 energy.", cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(draw: 2, energyGain: 1),          def: 2),
        ])
    }

    // MARK: - Helpers

    // swiftlint:disable function_parameter_count
    private static func card(
        _ name: String, _ desc: String,
        cost: Int, rarity: CardRarity = .common, type: CardType, class hc: HeroClass?, effect: CardEffect, def defenseValue: Int = 0
    ) -> Card {
        Card(name: name, description: desc, cost: cost, type: type, rarity: rarity,
             heroClass: hc, effect: effect, defenseValue: defenseValue)
    }
    // swiftlint:enable function_parameter_count

    // Assign a fresh UUID to every card so duplicates are distinct in the deck
    private static func unique(_ cards: [Card]) -> [Card] {
        cards.map { c in
            Card(id: UUID(), name: c.name, description: c.description,
                 cost: c.cost, type: c.type, rarity: c.rarity,
                 heroClass: c.heroClass, effect: c.effect, defenseValue: c.defenseValue)
        }
    }
}
