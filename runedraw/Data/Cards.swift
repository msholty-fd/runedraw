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
                    defenseValue: proto.defenseValue, pitchValue: proto.pitchValue)
    }

    // MARK: - Barbarian card pool

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
            card("Slam",          "Deal 10 physical damage.",                      cost: 1, rarity: .common, type: .attack, class: .barbarian, effect: CardEffect(damage: 10, damageType: .physical),                                    def: 3, pitch: 2),
            card("Iron Skin",     "Gain 8 block.",                                 cost: 1, rarity: .common, type: .skill,  class: .barbarian, effect: CardEffect(block: 8),                                                            def: 7, pitch: 3),
            card("Rage",          "Pitch for 3. Gain 2 energy.",                   cost: 0, rarity: .common, type: .skill,  class: .barbarian, effect: CardEffect(energyGain: 2),                                                       def: 2, pitch: 3),
            card("Ground Smash",  "Deal 5 damage to ALL enemies.",                 cost: 1, rarity: .common, type: .attack, class: .barbarian, effect: CardEffect(damage: 5, damageType: .physical, damageAllEnemies: true),            def: 2, pitch: 3),
            card("Battle Stance", "Gain 2 Strength. Draw 1.",                      cost: 1, rarity: .common, type: .skill,  class: .barbarian, effect: CardEffect(draw: 1, strengthGain: 2),                                           def: 3, pitch: 2),
            card("Heavy Strike",  "Deal 12 physical damage.",                      cost: 2, rarity: .common, type: .attack, class: .barbarian, effect: CardEffect(damage: 12, damageType: .physical),                                   def: 3, pitch: 2),
            // Magic
            card("Berserk",       "Draw 2. Gain 1 energy.",                        cost: 1, rarity: .magic,  type: .skill,  class: .barbarian, effect: CardEffect(draw: 2, energyGain: 1),                                             def: 2, pitch: 3),
            card("Shield Slam",   "Deal damage equal to your current block.",       cost: 1, rarity: .magic,  type: .attack, class: .barbarian, effect: CardEffect(damageType: .physical, damageFromBlock: true),                       def: 2, pitch: 2),
            card("War Shout",     "Gain 3 Strength. Gain 5 block.",                cost: 2, rarity: .magic,  type: .skill,  class: .barbarian, effect: CardEffect(block: 5, strengthGain: 3),                                          def: 4, pitch: 2),
            card("Pummel",        "Deal 4 physical damage twice.",                  cost: 2, rarity: .magic,  type: .attack, class: .barbarian, effect: CardEffect(damage: 4, damageType: .physical, times: 2),                         def: 3, pitch: 2),
            // Rare
            card("Rampage",       "Deal 15 damage. Gain 3 Strength. Exhausts.",    cost: 2, rarity: .rare,   type: .attack, class: .barbarian, effect: CardEffect(damage: 15, damageType: .physical, exhausts: true, strengthGain: 3), def: 3, pitch: 1),
            card("Whirlwind",     "Deal 8 physical damage to ALL enemies.",         cost: 2, rarity: .rare,   type: .attack, class: .barbarian, effect: CardEffect(damage: 8, damageType: .physical, damageAllEnemies: true),           def: 3, pitch: 1),
            card("Bloodlust",     "Deal 10 damage. Heal 5.",                        cost: 2, rarity: .rare,   type: .attack, class: .barbarian, effect: CardEffect(damage: 10, damageType: .physical, heal: 5),                        def: 3, pitch: 1),
            card("Last Stand",    "Gain 14 block. Gain 3 Strength. Exhausts.",      cost: 2, rarity: .rare,   type: .skill,  class: .barbarian, effect: CardEffect(block: 14, exhausts: true, strengthGain: 3),                        def: 6, pitch: 1),
            // Unique
            card("Annihilate",    "Deal 30 physical damage. Exhausts.",             cost: 3, rarity: .unique, type: .attack, class: .barbarian, effect: CardEffect(damage: 30, damageType: .physical, exhausts: true),                  def: 2, pitch: 1),
            card("Warcry of Blood","Gain 4 Strength. Draw 3. Exhausts.",            cost: 2, rarity: .unique, type: .skill,  class: .barbarian, effect: CardEffect(draw: 3, exhausts: true, strengthGain: 4),                          def: 3, pitch: 1),
        ]
    }

    // MARK: - Rogue card pool

    private static func roguePool() -> [Card] {
        [
            // Common
            card("Quick Stab",    "Deal 5 physical damage.",                              cost: 0, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 5, damageType: .physical),                                                     def: 3, pitch: 3),
            card("Veil",          "Gain 6 block.",                                        cost: 1, rarity: .common, type: .skill,  class: .rogue, effect: CardEffect(block: 6),                                                                             def: 6, pitch: 3),
            card("Expose",        "Deal 6 damage. Apply 3 vulnerable.",                   cost: 1, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 6, damageType: .physical, vulnerableStacks: 3),                                def: 3, pitch: 2),
            card("Fan of Knives", "Deal 3 damage to ALL enemies.",                        cost: 1, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 3, damageType: .physical, damageAllEnemies: true),                             def: 2, pitch: 3),
            card("Envenom",       "Apply 5 poison.",                                      cost: 1, rarity: .common, type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 5),                                                                      def: 3, pitch: 3),
            card("Serrated Blade","Deal 6 physical damage. Apply 5 Bleed.",               cost: 1, rarity: .common, type: .attack, class: .rogue, effect: CardEffect(damage: 6, damageType: .physical, applyBleed: 5),                                      def: 3, pitch: 2),
            // Magic
            card("Crippling Blow","Deal 6 damage. Apply 3 weak.",                         cost: 2, rarity: .magic,  type: .attack, class: .rogue, effect: CardEffect(damage: 6, damageType: .physical, weakStacks: 3),                                      def: 3, pitch: 2),
            card("Finisher",      "Deal 5 damage. Combo: deal 10 more.",                  cost: 2, rarity: .magic,  type: .attack, class: .rogue, effect: CardEffect(damage: 5, damageType: .physical, comboBonus: 10),                                     def: 3, pitch: 2),
            card("Blade Dance",   "Deal 4 damage twice. Combo: +3 per hit.",              cost: 2, rarity: .magic,  type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, times: 2, comboBonus: 6),                            def: 3, pitch: 2),
            card("Smoke Bomb",    "Gain 8 block. Apply 2 weak.",                          cost: 2, rarity: .magic,  type: .skill,  class: .rogue, effect: CardEffect(block: 8, weakStacks: 2),                                                             def: 4, pitch: 2),
            card("Adder's Kiss",  "Apply 8 poison.",                                      cost: 1, rarity: .magic,  type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 8),                                                                      def: 2, pitch: 2),
            card("Hemorrhage",    "Deal 4 physical damage. Apply 8 Bleed. Draw 1.",       cost: 2, rarity: .magic,  type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, draw: 1, applyBleed: 8),                             def: 3, pitch: 2),
            // Rare
            card("Death Blow",    "Deal 8 damage. Combo: +12. Apply 3 poison.",           cost: 2, rarity: .rare,   type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical, poisonStacks: 3, comboBonus: 12),                    def: 3, pitch: 1),
            card("Marked for Death","Apply 5 vulnerable. Apply 5 poison.",                cost: 1, rarity: .rare,   type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 5, vulnerableStacks: 5),                                                 def: 3, pitch: 2),
            card("Open Wounds",   "Apply 6 Bleed to ALL enemies.",                        cost: 2, rarity: .rare,   type: .skill,  class: .rogue, effect: CardEffect(damageAllEnemies: true, applyBleed: 6),                                                def: 2, pitch: 2),
            card("Predator",      "Deal 4 damage to all. Apply 3 poison.",                cost: 3, rarity: .rare,   type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3, damageAllEnemies: true),             def: 2, pitch: 2),
            // Unique
            card("Assassinate",   "Deal 15 damage. Combo: +10. Apply 8 poison.",          cost: 3, rarity: .unique, type: .attack, class: .rogue, effect: CardEffect(damage: 15, damageType: .physical, poisonStacks: 8, comboBonus: 10),                   def: 3, pitch: 1),
            card("Thousand Cuts", "Deal 3 physical damage four times.",                   cost: 3, rarity: .unique, type: .attack, class: .rogue, effect: CardEffect(damage: 3, damageType: .physical, times: 4),                                           def: 2, pitch: 1),
        ]
    }

    // MARK: - Sorceress card pool

    private static func sorceressPool() -> [Card] {
        [
            // Common
            card("Frost Bolt",    "Deal 7 ice damage. Apply 2 Chill.",              cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 7, damageType: .ice, applyChillStacks: 2),                                    def: 3, pitch: 2),
            card("Static Shock",  "Deal 5 arcane. ⚡Arcane: deal 8 more.",          cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .arcane, arcaneBonus: 8),                                      def: 3, pitch: 3),
            card("Scorch",        "Deal 5 fire damage. Apply 3 burn.",               cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .fire, applyBurn: 3),                                          def: 2, pitch: 3),
            card("Ice Armor",     "Gain 10 block.",                                  cost: 2, rarity: .common, type: .skill,  class: .sorceress, effect: CardEffect(block: 10),                                                                           def: 7, pitch: 3),
            card("Arcane Blast",  "Deal 4 arcane twice. ⚡Arcane: deal 8 more.",    cost: 2, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 4, damageType: .arcane, times: 2, arcaneBonus: 8),                            def: 3, pitch: 2),
            card("Chill Touch",   "Deal 5 ice damage. Apply 3 Chill. Apply 2 weak.", cost: 1, rarity: .common, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .ice, weakStacks: 2, applyChillStacks: 3),                    def: 3, pitch: 2),
            // Magic
            card("Chain Lightning","Deal 5 arcane to ALL. ⚡Arcane: +5 to all.",    cost: 2, rarity: .magic,  type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .arcane, damageAllEnemies: true, arcaneBonus: 5),              def: 2, pitch: 2),
            card("Amplify",       "Your next attack deals double damage.",            cost: 1, rarity: .magic,  type: .skill,  class: .sorceress, effect: CardEffect(amplifyNext: true),                                                                  def: 2, pitch: 3),
            card("Ignite",        "Apply 5 burn to ALL enemies.",                    cost: 2, rarity: .magic,  type: .skill,  class: .sorceress, effect: CardEffect(applyBurn: 5, applyBurnAll: true),                                                   def: 2, pitch: 2),
            card("Mana Burst",    "Draw 3. Gain 1 energy.",                          cost: 2, rarity: .magic,  type: .skill,  class: .sorceress, effect: CardEffect(draw: 3, energyGain: 1),                                                             def: 2, pitch: 3),
            // Rare
            card("Blizzard",      "Deal 8 ice to ALL. Apply 3 Chill to ALL.",       cost: 3, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 8, damageType: .ice, damageAllEnemies: true, applyChillStacks: 3),            def: 2, pitch: 1),
            card("Pyroclasm",     "Deal 20 fire damage. Exhausts.",                  cost: 2, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 20, damageType: .fire, exhausts: true),                                       def: 2, pitch: 1),
            card("Frost Nova",    "Apply 4 Chill to ALL enemies.",                  cost: 2, rarity: .rare,   type: .skill,  class: .sorceress, effect: CardEffect(damageAllEnemies: true, applyChillStacks: 4),                                         def: 3, pitch: 2),
            card("Arcane Torrent","Deal 5 arcane 3×. ⚡Arcane: deal 12 more.",      cost: 3, rarity: .rare,   type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .arcane, times: 3, arcaneBonus: 12),                           def: 2, pitch: 1),
            // Unique
            card("Inferno",       "Deal 12 fire to ALL. Apply 4 burn to ALL.",      cost: 4, rarity: .unique, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire, damageAllEnemies: true, applyBurn: 4, applyBurnAll: true), def: 2, pitch: 1),
            card("Frozen Time",   "Deal 10 ice. Apply 5 Chill. Draw 2.",            cost: 3, rarity: .unique, type: .attack, class: .sorceress, effect: CardEffect(damage: 10, damageType: .ice, draw: 2, applyChillStacks: 5),                          def: 3, pitch: 1),
        ]
    }

    // MARK: - Neutral card pool (any class can find these)

    static func neutralCardPool() -> [Card] {
        [
            // Common
            card("Potion Sip",    "Heal 8.",                               cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(heal: 8),                                                                def: 3, pitch: 3),
            card("Iron Will",     "Gain 6 block.",                         cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(block: 6),                                                               def: 6, pitch: 3),
            card("Quick Draw",    "Draw 2.",                               cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(draw: 2),                                                                def: 3, pitch: 3),
            card("Rest",          "Heal 5. Draw 1.",                       cost: 1, rarity: .common, type: .skill,  class: nil, effect: CardEffect(draw: 1, heal: 5),                                                       def: 3, pitch: 3),
            // Magic
            card("Elixir",        "Heal 12.",                              cost: 2, rarity: .magic,  type: .skill,  class: nil, effect: CardEffect(heal: 12),                                                               def: 3, pitch: 2),
            card("Momentum",      "Draw 2. Gain 1 energy.",                cost: 2, rarity: .magic,  type: .skill,  class: nil, effect: CardEffect(draw: 2, energyGain: 1),                                                def: 2, pitch: 3),
            card("Fortify",       "Gain 10 block.",                        cost: 2, rarity: .magic,  type: .skill,  class: nil, effect: CardEffect(block: 10),                                                              def: 7, pitch: 3),
            // Rare
            card("Ancient Scroll","Draw 3.",                               cost: 2, rarity: .rare,   type: .skill,  class: nil, effect: CardEffect(draw: 3),                                                                def: 3, pitch: 3),
            card("Phoenix Feather","Heal 15. Draw 1.",                     cost: 3, rarity: .rare,   type: .skill,  class: nil, effect: CardEffect(draw: 1, heal: 15),                                                      def: 3, pitch: 2),
            card("Second Chance", "Gain 8 block. Heal 6.",                 cost: 2, rarity: .rare,   type: .skill,  class: nil, effect: CardEffect(block: 8, heal: 6),                                                     def: 5, pitch: 2),
        ]
    }

    // MARK: - Starting Decks

    private static func barbarianDeck() -> [Card] {
        unique([
            // Core attacks — bread-and-butter physical damage
            card("Strike",       "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical),                           def: 3, pitch: 3),
            card("Strike",       "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical),                           def: 3, pitch: 3),
            card("Strike",       "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical),                           def: 3, pitch: 3),
            card("Strike",       "Deal 6 damage.",                cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical),                           def: 3, pitch: 3),
            // Stronger hits — introduces the heavier swing feel
            card("Slam",         "Deal 10 physical damage.",      cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 10, damageType: .physical),                           def: 3, pitch: 2),
            card("Slam",         "Deal 10 physical damage.",      cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 10, damageType: .physical),                           def: 3, pitch: 2),
            // Defence — blocks physical attacks, also great pitch fodder
            card("Defend",       "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                                                    def: 6, pitch: 3),
            card("Defend",       "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                                                    def: 6, pitch: 3),
            card("Defend",       "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                                                    def: 6, pitch: 3),
            card("Defend",       "Gain 5 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5),                                                    def: 6, pitch: 3),
            card("Iron Skin",    "Gain 8 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 8),                                                    def: 7, pitch: 3),
            card("Iron Skin",    "Gain 8 block.",                 cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 8),                                                    def: 7, pitch: 3),
            // Area — introduces multi-target (only one enemy now but good for future)
            card("Cleave",       "Deal 4 damage to ALL enemies.", cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 4, damageType: .physical, damageAllEnemies: true),    def: 2, pitch: 3),
            card("Ground Smash", "Deal 5 damage to ALL enemies.", cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 5, damageType: .physical, damageAllEnemies: true),    def: 2, pitch: 3),
            // Utility — introduces draw and the Strength mechanic
            card("Battle Cry",   "Gain 3 block. Draw 1.",         cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 3, draw: 1),                                          def: 4, pitch: 3),
            card("Battle Cry",   "Gain 3 block. Draw 1.",         cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 3, draw: 1),                                          def: 4, pitch: 3),
            card("Battle Stance","Gain 2 Strength. Draw 1.",      cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(draw: 1, strengthGain: 2),                                   def: 3, pitch: 2),
            card("Battle Stance","Gain 2 Strength. Draw 1.",      cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(draw: 1, strengthGain: 2),                                   def: 3, pitch: 2),
            card("Rage",         "Pitch for 3. Gain 2 energy.",   cost: 0, type: .skill,  class: .barbarian, effect: CardEffect(energyGain: 2),                                              def: 2, pitch: 3),
            card("Rage",         "Pitch for 3. Gain 2 energy.",   cost: 0, type: .skill,  class: .barbarian, effect: CardEffect(energyGain: 2),                                              def: 2, pitch: 3),
        ])
    }

    private static func rogueDeck() -> [Card] {
        unique([
            // Core attacks
            card("Backstab",     "Deal 8 damage.",                 cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical),                             def: 3, pitch: 3),
            card("Backstab",     "Deal 8 damage.",                 cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical),                             def: 3, pitch: 3),
            card("Backstab",     "Deal 8 damage.",                 cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical),                             def: 3, pitch: 3),
            // Free attacks — zero-cost is the Rogue's signature; pitch value still useful
            card("Quick Stab",   "Deal 5 physical damage.",        cost: 0, type: .attack, class: .rogue, effect: CardEffect(damage: 5, damageType: .physical),                             def: 3, pitch: 3),
            card("Quick Stab",   "Deal 5 physical damage.",        cost: 0, type: .attack, class: .rogue, effect: CardEffect(damage: 5, damageType: .physical),                             def: 3, pitch: 3),
            card("Quick Stab",   "Deal 5 physical damage.",        cost: 0, type: .attack, class: .rogue, effect: CardEffect(damage: 5, damageType: .physical),                             def: 3, pitch: 3),
            // Poison — the Rogue's damage-over-time identity
            card("Poison Blade", "Deal 4 damage. Apply 3 poison.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3),            def: 2, pitch: 3),
            card("Poison Blade", "Deal 4 damage. Apply 3 poison.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3),            def: 2, pitch: 3),
            card("Envenom",      "Apply 5 poison.",                cost: 1, type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 5),                                              def: 3, pitch: 3),
            card("Envenom",      "Apply 5 poison.",                cost: 1, type: .skill,  class: .rogue, effect: CardEffect(poisonStacks: 5),                                              def: 3, pitch: 3),
            // Defence + draw
            card("Shadow Step",  "Gain 5 block. Draw 1.",          cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1),                                            def: 5, pitch: 3),
            card("Shadow Step",  "Gain 5 block. Draw 1.",          cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1),                                            def: 5, pitch: 3),
            card("Shadow Step",  "Gain 5 block. Draw 1.",          cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1),                                            def: 5, pitch: 3),
            card("Veil",         "Gain 6 block.",                  cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 6),                                                     def: 6, pitch: 3),
            card("Veil",         "Gain 6 block.",                  cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 6),                                                     def: 6, pitch: 3),
            // Draw engine
            card("Preparation",  "Draw 2 cards.",                  cost: 1, type: .skill,  class: .rogue, effect: CardEffect(draw: 2),                                                      def: 3, pitch: 3),
            card("Preparation",  "Draw 2 cards.",                  cost: 1, type: .skill,  class: .rogue, effect: CardEffect(draw: 2),                                                      def: 3, pitch: 3),
            // Debuff — introduces the vulnerability/expose mechanic
            card("Expose",       "Deal 6 damage. Apply 3 vulnerable.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 6, damageType: .physical, vulnerableStacks: 3),   def: 3, pitch: 2),
            card("Expose",       "Deal 6 damage. Apply 3 vulnerable.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 6, damageType: .physical, vulnerableStacks: 3),   def: 3, pitch: 2),
            card("Fan of Knives","Deal 3 damage to ALL enemies.",  cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 3, damageType: .physical, damageAllEnemies: true),     def: 2, pitch: 3),
        ])
    }

    private static func sorceressDeck() -> [Card] {
        unique([
            // Signature spell — expensive but hits hard; teaches pitch math
            card("Fireball",     "Deal 12 fire damage.",              cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire),                         def: 2, pitch: 2),
            card("Fireball",     "Deal 12 fire damage.",              cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire),                         def: 2, pitch: 2),
            card("Fireball",     "Deal 12 fire damage.",              cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire),                         def: 2, pitch: 2),
            // Cheap arcane damage — free to pitch or play
            card("Magic Missile","Deal 6 arcane damage.",             cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane),                       def: 3, pitch: 3),
            card("Magic Missile","Deal 6 arcane damage.",             cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane),                       def: 3, pitch: 3),
            card("Magic Missile","Deal 6 arcane damage.",             cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane),                       def: 3, pitch: 3),
            card("Magic Missile","Deal 6 arcane damage.",             cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane),                       def: 3, pitch: 3),
            // Burn — introduces DoT, cheap enough to pitch
            card("Scorch",       "Deal 5 fire damage. Apply 3 burn.", cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .fire, applyBurn: 3),            def: 2, pitch: 3),
            card("Scorch",       "Deal 5 fire damage. Apply 3 burn.", cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .fire, applyBurn: 3),            def: 2, pitch: 3),
            card("Scorch",       "Deal 5 fire damage. Apply 3 burn.", cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 5, damageType: .fire, applyBurn: 3),            def: 2, pitch: 3),
            // Defence
            card("Mana Shield",  "Gain 8 block.",                     cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8),                                              def: 6, pitch: 3),
            card("Mana Shield",  "Gain 8 block.",                     cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8),                                              def: 6, pitch: 3),
            card("Mana Shield",  "Gain 8 block.",                     cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8),                                              def: 6, pitch: 3),
            // Draw + setup
            card("Arcane Surge", "Draw 2 cards. Gain 1 energy.",      cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(draw: 2, energyGain: 1),                               def: 2, pitch: 3),
            card("Arcane Surge", "Draw 2 cards. Gain 1 energy.",      cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(draw: 2, energyGain: 1),                               def: 2, pitch: 3),
            // Amplify — introduces the double-damage mechanic
            card("Amplify",      "Your next attack deals double damage.", cost: 1, type: .skill, class: .sorceress, effect: CardEffect(amplifyNext: true),                                  def: 2, pitch: 3),
            card("Amplify",      "Your next attack deals double damage.", cost: 1, type: .skill, class: .sorceress, effect: CardEffect(amplifyNext: true),                                  def: 2, pitch: 3),
            // Chill — introduces crowd control
            card("Frost Bolt",   "Deal 7 ice damage. Apply 2 Chill.", cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 7, damageType: .ice, applyChillStacks: 2),     def: 3, pitch: 2),
            card("Frost Bolt",   "Deal 7 ice damage. Apply 2 Chill.", cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 7, damageType: .ice, applyChillStacks: 2),     def: 3, pitch: 2),
        ])
    }

    // MARK: - Helpers

    private static func card(
        _ name: String, _ desc: String,
        cost: Int, rarity: CardRarity = .common, type: CardType, class hc: HeroClass?,
        effect: CardEffect, def defenseValue: Int = 0, pitch: Int = 2
    ) -> Card {
        Card(name: name, description: desc, cost: cost, type: type, rarity: rarity,
             heroClass: hc, effect: effect, defenseValue: defenseValue, pitchValue: pitch)
    }

    // Assign a fresh UUID to every card so duplicates are distinct in the deck
    private static func unique(_ cards: [Card]) -> [Card] {
        cards.map { c in
            Card(id: UUID(), name: c.name, description: c.description,
                 cost: c.cost, type: c.type, rarity: c.rarity,
                 heroClass: c.heroClass, effect: c.effect, defenseValue: c.defenseValue,
                 pitchValue: c.pitchValue)
        }
    }
}
