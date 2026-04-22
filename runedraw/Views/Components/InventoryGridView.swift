import SwiftUI

// MARK: - Gear List View
// Replaces the old InventoryGridView (Diablo-style 5×8 spatial grid).
// Equipment cards are all the same logical size in a card game, so a flat
// list is clearer and less friction-y.

struct GearListView: View {
    let bag: GearBag
    var selectedId: UUID? = nil
    var onTapItem: ((Card) -> Void)? = nil

    var body: some View {
        if bag.isEmpty {
            HStack {
                Image(systemName: "bag")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray.opacity(0.3))
                Text("Bag is empty")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray.opacity(0.35))
                    .italic()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 20)
        } else {
            VStack(spacing: 4) {
                ForEach(bag.items) { card in
                    GearRow(card: card, isSelected: card.id == selectedId)
                        .onTapGesture { onTapItem?(card) }
                }
            }
        }
    }
}

// MARK: - Single Gear Row

struct GearRow: View {
    let card: Card
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            // Slot icon
            Text(card.equipmentSlot?.icon ?? "🎒")
                .font(.system(size: 20))
                .frame(width: 30)

            // Name + stat summary
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                    .lineLimit(1)

                if !card.modifiers.isEmpty {
                    Text(card.modifiers.map(\.label).joined(separator: "  ·  "))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.45, green: 0.85, blue: 0.5).opacity(0.85))
                        .lineLimit(1)
                } else if let bonus = card.statBonus, !bonus.description.isEmpty {
                    Text(bonus.description.components(separatedBy: "\n").joined(separator: "  ·  "))
                        .font(.system(size: 11))
                        .foregroundStyle(.green.opacity(0.75))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Rarity pip + slot label
            VStack(alignment: .trailing, spacing: 3) {
                Text(card.rarity.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(card.rarity.color.opacity(0.8))
                    .tracking(1)
                Circle()
                    .fill(card.rarity.color)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? card.rarity.color.opacity(0.12)
                      : Color(red: 0.09, green: 0.05, blue: 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(card.rarity.color.opacity(isSelected ? 0.65 : 0.2),
                                lineWidth: isSelected ? 1.5 : 1)
                )
        )
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Compact Bag Strip (used in LootPickupView)

struct GearBagStrip: View {
    let bag: GearBag

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bag.fill")
                .font(.system(size: 11))
                .foregroundStyle(.gray.opacity(0.5))
            if bag.isEmpty {
                Text("Bag empty")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray.opacity(0.35))
                    .italic()
            } else {
                Text("\(bag.count) item\(bag.count == 1 ? "" : "s") in bag")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray.opacity(0.5))
                // Show last 5 slot icons as a quick visual
                HStack(spacing: 2) {
                    ForEach(bag.items.suffix(5)) { card in
                        Text(card.equipmentSlot?.icon ?? "🎒")
                            .font(.system(size: 13))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20).padding(.vertical, 8)
    }
}

#Preview {
    var bag = GearBag()
    bag.add(Card(name: "Iron Sword", rarity: .common, slot: .weapon,
                 size: ItemSize(w: 1, h: 1), statBonus: StatBonus(attackBonus: 3)))
    bag.add(Card(name: "Shako", rarity: .unique, slot: .helm,
                 size: ItemSize(w: 1, h: 1), statBonus: StatBonus(maxHp: 30), isUnique: true))
    bag.add(Card(name: "Sharp Ring", rarity: .magic, slot: .ring,
                 size: ItemSize(w: 1, h: 1), statBonus: StatBonus(attackBonus: 2),
                 modifiers: [ItemModifier(label: "+2 Attack", bonus: StatBonus(attackBonus: 2))]))
    return VStack(spacing: 12) {
        GearListView(bag: bag)
        Divider()
        GearBagStrip(bag: bag)
    }
    .padding()
    .background(Color.black)
}
