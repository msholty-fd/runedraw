import Foundation

struct CardDatabase {

    static func startingDeck(for heroClass: HeroClass) -> [Card] {
        switch heroClass {
        case .barbarian: return barbarianDeck()
        case .rogue:     return rogueDeck()
        case .sorceress: return sorceressDeck()
        }
    }

    // MARK: - Barbarian

    private static func barbarianDeck() -> [Card] {
        unique([
            card("Strike",     "Deal 6 damage.",              cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical)),
            card("Strike",     "Deal 6 damage.",              cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical)),
            card("Strike",     "Deal 6 damage.",              cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 6,  damageType: .physical)),
            card("Defend",     "Gain 5 block.",               cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5)),
            card("Defend",     "Gain 5 block.",               cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5)),
            card("Defend",     "Gain 5 block.",               cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 5)),
            card("Cleave",     "Deal 4 damage to ALL enemies.", cost: 1, type: .attack, class: .barbarian, effect: CardEffect(damage: 4, damageType: .physical, damageAllEnemies: true)),
            card("Battle Cry", "Gain 3 block. Draw 1.",       cost: 1, type: .skill,  class: .barbarian, effect: CardEffect(block: 3, draw: 1)),
        ])
    }

    // MARK: - Rogue

    private static func rogueDeck() -> [Card] {
        unique([
            card("Backstab",     "Deal 8 damage.",                cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical)),
            card("Backstab",     "Deal 8 damage.",                cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical)),
            card("Backstab",     "Deal 8 damage.",                cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 8, damageType: .physical)),
            card("Shadow Step",  "Gain 5 block. Draw 1.",         cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1)),
            card("Shadow Step",  "Gain 5 block. Draw 1.",         cost: 1, type: .skill,  class: .rogue, effect: CardEffect(block: 5, draw: 1)),
            card("Poison Blade", "Deal 4 damage. Apply 3 poison.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3)),
            card("Poison Blade", "Deal 4 damage. Apply 3 poison.", cost: 1, type: .attack, class: .rogue, effect: CardEffect(damage: 4, damageType: .physical, poisonStacks: 3)),
            card("Preparation",  "Draw 2 cards.",                 cost: 1, type: .skill,  class: .rogue, effect: CardEffect(draw: 2)),
        ])
    }

    // MARK: - Sorceress

    private static func sorceressDeck() -> [Card] {
        unique([
            card("Fireball",     "Deal 12 fire damage.",             cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire)),
            card("Fireball",     "Deal 12 fire damage.",             cost: 2, type: .attack, class: .sorceress, effect: CardEffect(damage: 12, damageType: .fire)),
            card("Magic Missile","Deal 6 arcane damage.",            cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane)),
            card("Magic Missile","Deal 6 arcane damage.",            cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane)),
            card("Magic Missile","Deal 6 arcane damage.",            cost: 1, type: .attack, class: .sorceress, effect: CardEffect(damage: 6,  damageType: .arcane)),
            card("Mana Shield",  "Gain 8 block.",                    cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8)),
            card("Mana Shield",  "Gain 8 block.",                    cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(block: 8)),
            card("Arcane Surge", "Draw 2 cards. Gain 1 energy.",     cost: 1, type: .skill,  class: .sorceress, effect: CardEffect(draw: 2, energyGain: 1)),
        ])
    }

    // MARK: - Helpers

    private static func card(
        _ name: String, _ desc: String,
        cost: Int, type: CardType, class hc: HeroClass, effect: CardEffect
    ) -> Card {
        Card(name: name, description: desc, cost: cost, type: type, heroClass: hc, effect: effect)
    }

    // Assign a fresh UUID to every card so duplicates are distinct in the deck
    private static func unique(_ cards: [Card]) -> [Card] {
        cards.map { c in
            Card(id: UUID(), name: c.name, description: c.description,
                 cost: c.cost, type: c.type, rarity: c.rarity,
                 heroClass: c.heroClass, effect: c.effect)
        }
    }
}
