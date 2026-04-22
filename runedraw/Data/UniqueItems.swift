import Foundation

struct UniqueItemTemplate {
    let name: String
    let slot: EquipmentSlot
    let size: ItemSize
    let stats: StatBonus
    let modifierLabels: [String]
    let flavorText: String
    let minFloor: Int
    let activatedDescription: String
    let activatedEffect: CardEffect
    let activatedCost: Int

    init(name: String, slot: EquipmentSlot, size: ItemSize, stats: StatBonus,
         modifierLabels: [String], flavorText: String, minFloor: Int,
         activatedDescription: String = "", activatedEffect: CardEffect = CardEffect(),
         activatedCost: Int = 0) {
        self.name = name
        self.slot = slot
        self.size = size
        self.stats = stats
        self.modifierLabels = modifierLabels
        self.flavorText = flavorText
        self.minFloor = minFloor
        self.activatedDescription = activatedDescription
        self.activatedEffect = activatedEffect
        self.activatedCost = activatedCost
    }
}

struct UniqueItemDatabase {

    static let all: [UniqueItemTemplate] = [

        UniqueItemTemplate(
            name: "The Forebear",
            slot: .weapon, size: ItemSize(w: 2, h: 3),
            stats: StatBonus(maxHp: 15, attackBonus: 12),
            modifierLabels: ["+12 Attack", "+15 Max HP", "Cannot be Disarmed"],
            flavorText: "\"Passed from warrior to warrior across forgotten ages.\"",
            minFloor: 2,
            activatedDescription: "Activate: Deal 12 physical damage.",
            activatedEffect: CardEffect(damage: 12, damageType: .physical)
        ),

        UniqueItemTemplate(
            name: "The Grey Mantle",
            slot: .helm, size: ItemSize(w: 2, h: 2),
            stats: StatBonus(maxHp: 30, attackBonus: 2, defenseBonus: 2, cardDrawBonus: 1),
            modifierLabels: ["+30 Max HP", "+2 Attack", "+2 Defense", "+1 Card Draw"],
            flavorText: "\"A plain-looking helm hiding immeasurable power.\"",
            minFloor: 2,
            activatedDescription: "Activate: Draw 2 cards. Heal 5.",
            activatedEffect: CardEffect(draw: 2, heal: 5),
            activatedCost: 1
        ),

        UniqueItemTemplate(
            name: "The Runeseer",
            slot: .offHand, size: ItemSize(w: 1, h: 2),
            stats: StatBonus(attackBonus: 6, defenseBonus: 4, energyBonus: 1),
            modifierLabels: ["+6 Attack", "+4 Defense", "+1 Energy"],
            flavorText: "\"The crystallized focus of a long-dead archmage.\"",
            minFloor: 2,
            activatedDescription: "Activate: Amplify your next spell. Draw 1.",
            activatedEffect: CardEffect(draw: 1, amplifyNext: true)
        ),

        UniqueItemTemplate(
            name: "Warlord's Visage",
            slot: .helm, size: ItemSize(w: 2, h: 2),
            stats: StatBonus(maxHp: 20, attackBonus: 6, lifeOnKill: 4),
            modifierLabels: ["+6 Attack", "+20 Max HP", "+4 Life on Kill"],
            flavorText: "\"Forged for the warlord who never fell in battle.\"",
            minFloor: 2,
            activatedDescription: "Activate: Gain 4 Strength this combat.",
            activatedEffect: CardEffect(strengthGain: 4)
        ),

        UniqueItemTemplate(
            name: "Nightstride",
            slot: .boots, size: ItemSize(w: 2, h: 2),
            stats: StatBonus(attackBonus: 3, defenseBonus: 4, cardDrawBonus: 2),
            modifierLabels: ["+3 Attack", "+4 Defense", "+2 Card Draw"],
            flavorText: "\"Silent as shadow, swift as death.\"",
            minFloor: 2,
            activatedDescription: "Activate: Draw 2 cards. Gain 1 energy.",
            activatedEffect: CardEffect(draw: 2, energyGain: 1)
        ),

        UniqueItemTemplate(
            name: "The Grim Tally",
            slot: .amulet, size: ItemSize(w: 1, h: 1),
            stats: StatBonus(maxHp: 12, defenseBonus: 6, lifeOnKill: 3),
            modifierLabels: ["+6 Defense", "+3 Life on Kill", "+12 Max HP"],
            flavorText: "\"A grisly trophy from a hundred fallen foes.\"",
            minFloor: 1,
            activatedDescription: "Activate: Apply 5 poison to all enemies.",
            activatedEffect: CardEffect(poisonStacks: 5, damageAllEnemies: true),
            activatedCost: 1
        ),

        UniqueItemTemplate(
            name: "Hallowed Treads",
            slot: .boots, size: ItemSize(w: 2, h: 2),
            stats: StatBonus(maxHp: 10, defenseBonus: 3, startingBlock: 4),
            modifierLabels: ["+3 Defense", "+4 Starting Block", "+10 Max HP"],
            flavorText: "\"Consecrated by a forgotten order of wandering monks.\"",
            minFloor: 1,
            activatedDescription: "Activate: Gain 10 block.",
            activatedEffect: CardEffect(block: 10)
        ),

        UniqueItemTemplate(
            name: "Dreadmaw's Hide",
            slot: .chest, size: ItemSize(w: 2, h: 3),
            stats: StatBonus(maxHp: 20, defenseBonus: 8, cardDrawBonus: 1),
            modifierLabels: ["+8 Defense", "+20 Max HP", "+1 Card Draw"],
            flavorText: "\"Carved from the hide of the beast that cannot die.\"",
            minFloor: 2,
            activatedDescription: "Activate: Gain 14 block. Heal 6.",
            activatedEffect: CardEffect(block: 14, heal: 6),
            activatedCost: 2
        ),

        UniqueItemTemplate(
            name: "The Undying Maul",
            slot: .weapon, size: ItemSize(w: 2, h: 3),
            stats: StatBonus(maxHp: 25, attackBonus: 15, lifeOnKill: 5),
            modifierLabels: ["+15 Attack", "+25 Max HP", "+5 Life on Kill"],
            flavorText: "\"The hammer of the unkillable king, unbroken across ages.\"",
            minFloor: 3,
            activatedDescription: "Activate: Deal 15 damage. Heal 5.",
            activatedEffect: CardEffect(damage: 15, damageType: .physical, heal: 5),
            activatedCost: 1
        ),

        UniqueItemTemplate(
            name: "Grimhallow Orb",
            slot: .offHand, size: ItemSize(w: 1, h: 2),
            stats: StatBonus(attackBonus: 8, energyBonus: 1, cardDrawBonus: 1, poisonOnHit: 3),
            modifierLabels: ["+8 Attack", "+1 Energy", "+3 Poison on Hit", "+1 Card Draw"],
            flavorText: "\"Said to have sealed a greater demon at the world's end.\"",
            minFloor: 3,
            activatedDescription: "Activate: Apply 8 poison. Draw 1.",
            activatedEffect: CardEffect(draw: 1, poisonStacks: 8)
        ),
    ]

    static func available(floor: Int) -> [UniqueItemTemplate] {
        all.filter { $0.minFloor <= floor }
    }

    static func random(floor: Int) -> UniqueItemTemplate? {
        available(floor: floor).randomElement()
    }
}
