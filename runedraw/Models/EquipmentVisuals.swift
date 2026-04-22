import Foundation

// MARK: - EquipmentVisuals
//
// Translates equipped Card names into visual tiers for portrait rendering.
// Drawing code reads these enums — it never inspects Card directly.

enum HelmVisual    { case none, cap, helm, greatHelm }
enum ChestVisual   { case none, leather, chain, plate }
enum WeaponVisual  { case none, axe, sword, greatWeapon }
enum OffHandVisual { case none, buckler, shield, towerShield }

struct EquipmentVisuals {
    let helm:    HelmVisual
    let chest:   ChestVisual
    let weapon:  WeaponVisual
    let offHand: OffHandVisual

    static func classDefault(for heroClass: HeroClass) -> EquipmentVisuals {
        switch heroClass {
        case .barbarian: return .init(helm: .helm,  chest: .none, weapon: .axe,  offHand: .none)
        case .rogue:     return .init(helm: .none,  chest: .none, weapon: .axe,  offHand: .none)
        case .sorceress: return .init(helm: .none,  chest: .none, weapon: .none, offHand: .none)
        }
    }

    init(from equipment: HeroEquipment) {
        helm    = Self.helmVisual(equipment.helm)
        chest   = Self.chestVisual(equipment.chest)
        weapon  = Self.weaponVisual(equipment.weapon)
        offHand = Self.offHandVisual(equipment.offHand)
    }

    private init(helm: HelmVisual, chest: ChestVisual, weapon: WeaponVisual, offHand: OffHandVisual) {
        self.helm = helm; self.chest = chest; self.weapon = weapon; self.offHand = offHand
    }

    private static func helmVisual(_ card: Card?) -> HelmVisual {
        guard let n = card?.name.lowercased() else { return .none }
        if n.contains("great helm") || n.contains("warlord") || n.contains("grey mantle") { return .greatHelm }
        if n.contains("helm") { return .helm }
        return .cap
    }

    private static func chestVisual(_ card: Card?) -> ChestVisual {
        guard let n = card?.name.lowercased() else { return .none }
        if n.contains("plate") || n.contains("dreadmaw") { return .plate }
        if n.contains("chain") { return .chain }
        return .leather
    }

    private static func weaponVisual(_ card: Card?) -> WeaponVisual {
        guard let n = card?.name.lowercased() else { return .none }
        if n.contains("great sword") || n.contains("rune blade") || n.contains("maul") || n.contains("forebear") { return .greatWeapon }
        if n.contains("axe") { return .axe }
        return .sword
    }

    private static func offHandVisual(_ card: Card?) -> OffHandVisual {
        guard let n = card?.name.lowercased() else { return .none }
        if n.contains("tower") { return .towerShield }
        if n.contains("kite") || n.contains("tome") || n.contains("runeseer") { return .shield }
        return .buckler
    }
}
