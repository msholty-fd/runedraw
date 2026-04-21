import SwiftUI

struct CardView: View {
    let card: Card
    var isPlayable: Bool = true
    var isSelected: Bool = false
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

                // Border
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ? Color.yellow : card.rarity.color.opacity(0.55),
                        lineWidth: isSelected ? 2 : 1
                    )

                // Glow when selected
                if isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 6)
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
                            EnergyCrystal(cost: card.cost)
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

                    // Type badge
                    if !card.isEquipment {
                        Text(card.type.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(card.rarity.color.opacity(0.7))
                            .tracking(1)
                            .padding(.bottom, 5)
                    }
                }
                .frame(width: cardWidth, height: cardHeight)
            }
        }
        .buttonStyle(.plain)
        .frame(width: cardWidth, height: cardHeight)
        .opacity(isPlayable ? 1.0 : 0.45)
        .scaleEffect(isSelected ? 1.06 : 1.0)
        .animation(.spring(response: 0.18, dampingFraction: 0.7), value: isSelected)
    }

    private var centerIcon: String {
        if let slot = card.equipmentSlot { return slot.icon }
        return card.typeIcon
    }
}

struct EnergyCrystal: View {
    let cost: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.15, green: 0.25, blue: 0.75))
                .frame(width: 20, height: 20)
            Text("\(cost)")
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(.white)
        }
    }
}

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
