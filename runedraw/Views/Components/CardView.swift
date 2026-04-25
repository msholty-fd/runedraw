import SwiftUI

struct CardView: View {
    let card: Card
    var isPlayable: Bool = true
    var isSelected: Bool = false
    /// When non-nil, the card is being pitched: show pitch mode styling + pitch value badge.
    var isPitched: Bool = false
    var onTap: (() -> Void)? = nil

    private let cardWidth: CGFloat = 100
    private let cardHeight: CGFloat = 148

    var body: some View {
        Button { onTap?() } label: {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.13, green: 0.10, blue: 0.20),
                                     Color(red: 0.08, green: 0.06, blue: 0.14)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                // Border — staged = orange, pitched = teal, selected = yellow, default = rarity
                RoundedRectangle(cornerRadius: 10)
                    .stroke(borderColor, lineWidth: isSelected || isPitched ? 2 : 1)

                // Glow when selected (staged)
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 8)
                        .blur(radius: 5)
                }
                // Teal glow when pitched
                if isPitched {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.teal.opacity(0.4), lineWidth: 6)
                        .blur(radius: 4)
                }

                // Content
                VStack(spacing: 0) {
                    // Name row
                    HStack(alignment: .top, spacing: 4) {
                        Text(card.name)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()

                        if !card.isEquipment {
                            CostCrystal(cost: card.cost)
                        }
                    }
                    .padding([.top, .horizontal], 7)

                    Spacer()

                    // Center icon
                    Text(centerIcon)
                        .font(.system(size: 30))

                    Spacer()

                    // Description
                    Text(card.isEquipment ? (card.statBonus?.description ?? "") : card.description)
                        .font(.system(size: 9))
                        .foregroundStyle(Color.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .padding([.horizontal, .bottom], 6)

                    // Bottom row: type badge + pitch gem
                    if !card.isEquipment {
                        HStack(alignment: .bottom) {
                            Text(card.type.rawValue.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(card.rarity.color.opacity(0.7))
                                .tracking(1)
                            Spacer()
                            PitchGem(value: card.pitchValue)
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 5)
                    }
                }
                .frame(width: cardWidth, height: cardHeight)

                // Pitched overlay: dim + big pitch number
                if isPitched {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.teal.opacity(0.18))
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text("+\(card.pitchValue)")
                                .font(.system(size: 26, weight: .black))
                                .foregroundStyle(Color.teal)
                                .shadow(color: .teal, radius: 6)
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(width: cardWidth, height: cardHeight)
        .opacity(isPlayable ? 1.0 : 0.4)
        .scaleEffect(isSelected ? 1.06 : (isPitched ? 0.95 : 1.0))
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isSelected)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isPitched)
    }

    private var borderColor: Color {
        if isSelected { return .orange }
        if isPitched  { return .teal }
        return card.rarity.color.opacity(0.55)
    }

    private var centerIcon: String {
        if let slot = card.equipmentSlot { return slot.icon }
        return card.typeIcon
    }
}

/// The cost indicator — replaces the old "energy crystal" branding with a neutral gem look.
struct CostCrystal: View {
    let cost: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(cost == 0 ? Color(red: 0.15, green: 0.45, blue: 0.25)
                                : Color(red: 0.15, green: 0.25, blue: 0.75))
                .frame(width: 20, height: 20)
            Text("\(cost)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
        }
    }
}

/// Small pitch-value gem shown in the bottom-right of every combat card.
struct PitchGem: View {
    let value: Int   // 1, 2, or 3

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(gemColor)
                .frame(width: 16, height: 16)
            Text("\(value)")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.white)
        }
    }

    private var gemColor: Color {
        switch value {
        case 1: return Color(red: 0.8, green: 0.2, blue: 0.2)   // red  — protect this card
        case 2: return Color(red: 0.6, green: 0.45, blue: 0.1)  // amber — flexible
        default: return Color(red: 0.25, green: 0.55, blue: 0.3) // green — good pitch fodder
        }
    }
}

/// Legacy alias so old call sites compile unchanged.
typealias EnergyCrystal = CostCrystal

#Preview {
    HStack(spacing: 12) {
        CardView(card: Card(
            name: "Strike", description: "Deal 6 damage.",
            cost: 1, type: .attack,
            effect: CardEffect(damage: 6)
        ), isPlayable: true)

        CardView(card: Card(
            name: "Iron Sword", description: "+3 Attack",
            rarity: .magic, slot: .weapon,
            size: ItemSize(w: 1, h: 3),
            statBonus: StatBonus(attackBonus: 3)
        ))
    }
    .padding()
    .background(Color.black)
}
