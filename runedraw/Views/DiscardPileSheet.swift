import SwiftUI

struct DiscardPileSheet: View {
    let cards: [Card]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.04, blue: 0.14).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DISCARD PILE")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .tracking(2)
                        Text("\(cards.count) card\(cards.count == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray.opacity(0.5))
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Text("♻️").font(.system(size: 11))
                        Text("Shuffles back when draw pile empties")
                            .font(.system(size: 10))
                            .foregroundStyle(.gray.opacity(0.4))
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                Divider().background(.white.opacity(0.07))

                if cards.isEmpty {
                    Spacer()
                    Text("Nothing discarded yet.")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray.opacity(0.35))
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(cards) { card in
                                discardRow(card)
                                Divider().background(.white.opacity(0.05))
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func discardRow(_ card: Card) -> some View {
        HStack(spacing: 12) {
            // Cost badge
            ZStack {
                Circle()
                    .fill(card.rarity.color.opacity(0.15))
                    .frame(width: 30, height: 30)
                Text("\(card.cost)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(card.rarity.color.opacity(0.9))
            }

            // Damage type icon
            Text(card.effect.damageType.icon)
                .font(.system(size: 16))

            // Name + description
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(card.rarity == .common ? .white : card.rarity.color)
                    if card.rarity != .common {
                        Text(card.rarity.rawValue.uppercased())
                            .font(.system(size: 6, weight: .black)).tracking(1.5)
                            .foregroundStyle(card.rarity.color.opacity(0.8))
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(card.rarity.color.opacity(0.12)).clipShape(Capsule())
                    }
                }
                Text(card.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray.opacity(0.5))
                    .lineLimit(2)
            }

            Spacer()

            // Damage-type color swatch on the right edge
            RoundedRectangle(cornerRadius: 3)
                .fill(card.effect.damageType.effectColor.opacity(0.5))
                .frame(width: 4, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}
