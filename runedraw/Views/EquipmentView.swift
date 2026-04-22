import SwiftUI

// What's currently selected — either a bag item or an equipped slot
private enum Selection {
    case inventory(Card)
    case equipped(EquipmentSlot)

    var card: Card? {
        if case .inventory(let c) = self { return c }
        return nil
    }
    var slot: EquipmentSlot? {
        if case .equipped(let s) = self { return s }
        return nil
    }
}

struct EquipmentView: View {
    let engine: GameEngine

    @State private var selection: Selection? = nil
    @State private var confirmDrop = false

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    // Height reserved for the floating panel so ScrollView content isn't hidden under it
    private let panelHeight: CGFloat = 200

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(red: 0.05, green: 0.02, blue: 0.12).ignoresSafeArea()

            // Scrollable main content + handle pinned at top
            VStack(spacing: 0) {
                DismissHandle(tint: Color(red: 0.5, green: 0.3, blue: 0.8))
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        heroHeader
                        Divider().background(.gray.opacity(0.2))
                        equippedGrid
                        inventorySection
                        // Spacer so content isn't hidden under floating panel
                        if selection != nil {
                            Color.clear.frame(height: panelHeight + 16)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }

            // Floating action panel — always at bottom, no scroll needed
            if let sel = selection {
                itemPanel(sel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: selection?.card?.id)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)   // we draw our own
        .presentationBackground(Color(red: 0.05, green: 0.02, blue: 0.12))
        .confirmationDialog(
            "Drop \(selection?.card?.name ?? "")?",
            isPresented: $confirmDrop,
            titleVisibility: .visible
        ) {
            Button("Drop Item", role: .destructive) {
                if let card = selection?.card { engine.dropFromInventory(card) }
                selection = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item will be permanently lost.")
        }
        // Tap outside panel to dismiss
        .onTapGesture {
            if selection != nil { selection = nil }
        }
        .allowsHitTesting(true)
    }

    // MARK: - Hero Header

    var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 14) {
                Text(hero.heroClass.icon).font(.system(size: 32))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(hero.heroClass.rawValue.uppercased())
                            .font(.system(size: 11, weight: .black)).foregroundStyle(.gray).tracking(3)
                        Text("LVL \(hero.level)")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.2))
                            .tracking(1)
                    }
                    HStack(spacing: 10) {
                        Label("\(hero.currentHp)/\(hero.maxHp)", systemImage: "heart.fill")
                            .font(.system(size: 12, weight: .bold)).foregroundStyle(.red)
                        if hero.attackBonus  > 0 { Text("+\(hero.attackBonus) ATK").font(.system(size: 11)).foregroundStyle(.orange) }
                        if hero.defenseBonus > 0 { Text("+\(hero.defenseBonus) DEF").font(.system(size: 11)).foregroundStyle(.cyan) }
                        let nrgBonus = hero.maxEnergy - hero.heroClass.baseEnergy
                        if nrgBonus > 0 { Text("+\(nrgBonus) NRG").font(.system(size: 11)).foregroundStyle(Color(red: 0.4, green: 0.6, blue: 1.0)) }
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("BAG").font(.system(size: 9, weight: .black)).foregroundStyle(.gray).tracking(2)
                    Text("\(hero.inventory.count) items").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                }
            }

            // EXP bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("EXP")
                        .font(.system(size: 9, weight: .black)).foregroundStyle(.gray.opacity(0.5)).tracking(2)
                    Spacer()
                    Text("\(hero.experience) / \(hero.expToNextLevel)")
                        .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.5))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.06))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.75, blue: 0.2),
                                             Color(red: 0.8, green: 0.5, blue: 0.1)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * hero.expProgress, height: 4)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
    }

    // MARK: - Equipped Slots (2-column grid)

    var equippedGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionLabel("EQUIPPED")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                    EquippedSlotTile(
                        slot: slot,
                        card: hero.equipment.equipped(in: slot),
                        isSelected: selection?.slot == .some(slot)
                    )
                    .onTapGesture {
                        if hero.equipment.equipped(in: slot) != nil {
                            let alreadySelected = selection?.slot == .some(slot)
                            withAnimation { selection = alreadySelected ? nil : .equipped(slot) }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Bag (flat item list)

    var inventorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                sectionLabel("BAG")
                Spacer()
                Text("\(hero.inventory.count) item\(hero.inventory.count == 1 ? "" : "s")")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.45))
                    .padding(.trailing, 20)
            }
            GearListView(
                bag: hero.inventory,
                selectedId: selection?.card?.id
            ) { card in
                let alreadySelected = selection?.card?.id == card.id
                withAnimation { selection = alreadySelected ? nil : .inventory(card) }
            }
            .padding(.horizontal, 16)
            .simultaneousGesture(TapGesture().onEnded { })
        }
    }

    // MARK: - Floating Item Panel

    @ViewBuilder
    fileprivate func itemPanel(_ sel: Selection) -> some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(.gray.opacity(0.35))
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            switch sel {
            case .inventory(let card):
                inventoryPanel(card)
            case .equipped(let slot):
                if let card = hero.equipment.equipped(in: slot) {
                    equippedPanel(slot: slot, card: card)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            Color(red: 0.10, green: 0.06, blue: 0.18)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(panelAccentColor(sel).opacity(0.18))
                        .frame(height: 2)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .allowsHitTesting(true)
        .onTapGesture {}   // absorb taps so they don't dismiss
    }

    func inventoryPanel(_ card: Card) -> some View {
        let canEquip = hero.meetsRequirements(for: card)
        return HStack(alignment: .top, spacing: 14) {
            // Slot icon
            Text(card.equipmentSlot?.icon ?? "🎒").font(.system(size: 36))
                .shadow(color: card.rarity.color.opacity(0.6), radius: 6)
                .frame(width: 46)

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                    rarityBadge(card)
                }
                statLines(card).lineLimit(3)
                // Stat requirements
                if let reqs = card.requirements, !reqs.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: canEquip ? "checkmark.circle.fill" : "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(canEquip ? .green : .red.opacity(0.85))
                        Text("Requires \(reqs.description)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(canEquip ? .green.opacity(0.8) : Color(red: 1.0, green: 0.35, blue: 0.35))
                    }
                }
                if let flavor = card.flavorText {
                    Text(flavor).font(.system(size: 10)).foregroundStyle(.gray.opacity(0.55)).italic().lineLimit(1)
                }
            }

            Spacer()

            // Actions
            VStack(spacing: 8) {
                Button {
                    engine.equipFromInventory(card)
                    selection = nil
                } label: {
                    Text("EQUIP")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(canEquip ? .black : .gray.opacity(0.5))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(canEquip ? AnyShapeStyle(card.rarity.color) : AnyShapeStyle(Color.white.opacity(0.07)))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canEquip)

                Button { confirmDrop = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13)).foregroundStyle(.gray)
                        .padding(8)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    func equippedPanel(slot: EquipmentSlot, card: Card) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(card.equipmentSlot?.icon ?? "🎒").font(.system(size: 36))
                .shadow(color: card.rarity.color.opacity(0.6), radius: 6)
                .frame(width: 46)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                    rarityBadge(card)
                }
                Text("Equipped in \(slot.rawValue)").font(.system(size: 10)).foregroundStyle(.gray.opacity(0.5))
                statLines(card).lineLimit(3)
                if let reqs = card.requirements, !reqs.isEmpty {
                    Text("Requires \(reqs.description)")
                        .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.45))
                }
            }

            Spacer()

            Button {
                engine.unequipToInventory(slot)
                selection = nil
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: "arrow.down.to.line").font(.system(size: 14))
                    Text("UNEQUIP").font(.system(size: 9, weight: .black)).tracking(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func panelAccentColor(_ sel: Selection) -> Color {
        switch sel {
        case .inventory(let card): return card.rarity.color
        case .equipped(let slot):  return hero.equipment.equipped(in: slot)?.rarity.color ?? .gray
        }
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black)).foregroundStyle(.gray.opacity(0.55)).tracking(3)
            .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 2)
    }
}

// MARK: - Equipped Slot Tile (compact 2-col)

struct EquippedSlotTile: View {
    let slot: EquipmentSlot
    let card: Card?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(slot.icon).font(.system(size: 18)).frame(width: 24)

            if let card {
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                        .lineLimit(1)
                    Text(card.rarity.rawValue)
                        .font(.system(size: 9)).foregroundStyle(card.rarity.color.opacity(0.7))
                }
                Spacer(minLength: 0)
                // Rarity dot
                Circle().fill(card.rarity.color).frame(width: 6, height: 6)
            } else {
                Text("Empty")
                    .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.3)).italic()
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? (card?.rarity.color ?? .gray).opacity(0.15)
                      : (card != nil ? Color(red: 0.10, green: 0.06, blue: 0.16) : Color(red: 0.06, green: 0.03, blue: 0.10)))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected
                            ? (card?.rarity.color ?? .gray).opacity(0.6)
                            : (card?.rarity.color ?? .gray).opacity(card != nil ? 0.2 : 0.07),
                            lineWidth: isSelected ? 1.5 : 1))
        )
    }
}

// MARK: - Shared helpers

private func rarityBadge(_ card: Card) -> some View {
    Text(card.rarity.rawValue.uppercased())
        .font(.system(size: 7, weight: .black)).foregroundStyle(card.rarity.color.opacity(0.9)).tracking(2)
        .padding(.horizontal, 4).padding(.vertical, 2)
        .background(card.rarity.color.opacity(0.12)).clipShape(Capsule())
}

@ViewBuilder
private func statLines(_ card: Card) -> some View {
    if !card.modifiers.isEmpty {
        Text(card.modifiers.map(\.label).joined(separator: "  ·  "))
            .font(.system(size: 11)).foregroundStyle(Color(red: 0.5, green: 0.9, blue: 0.5))
    } else if let bonus = card.statBonus, !bonus.description.isEmpty {
        Text(bonus.description.components(separatedBy: "\n").joined(separator: "  ·  "))
            .font(.system(size: 11)).foregroundStyle(.green.opacity(0.8))
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    return EquipmentView(engine: engine)
}
