import SwiftUI

struct ShopView: View {
    let engine: GameEngine
    let shopIndex: Int

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }
    private var shop: Shop { engine.shops[shopIndex] }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.10, green: 0.07, blue: 0.03), Color(red: 0.04, green: 0.03, blue: 0.01)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                DismissHandle(tint: Color(red: 0.7, green: 0.5, blue: 0.15))

                // Header
                shopHeader
                Divider().background(Color(red: 0.6, green: 0.4, blue: 0.1).opacity(0.3))

                ScrollView {
                    VStack(spacing: 20) {
                        // Items for sale
                        forSaleSection
                        // Sell your items
                        sellSection
                    }
                    .padding(16)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)   // we draw our own
        .presentationBackground(Color(red: 0.08, green: 0.05, blue: 0.02))
    }

    // MARK: - Header

    var shopHeader: some View {
        HStack(spacing: 12) {
            Text(shop.icon).font(.system(size: 30))
            VStack(alignment: .leading, spacing: 2) {
                Text(shop.name)
                    .font(.system(size: 16, weight: .black)).foregroundStyle(.white)
                Text(shop.speciality)
                    .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.6))
            }
            Spacer()
            HStack(spacing: 5) {
                Text("💰").font(.system(size: 14))
                Text("\(hero.gold)g")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.black.opacity(0.4))
    }

    // MARK: - For Sale

    var forSaleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionLabel("FOR SALE")
            ForEach(shop.items.indices, id: \.self) { idx in
                ShopItemRow(
                    item: shop.items[idx],
                    heroGold: hero.gold,
                    heroStats: hero.stats,
                    onBuy: { engine.buyItem(at: idx, in: shopIndex) }
                )
            }
        }
    }

    // MARK: - Sell Section

    var sellSection: some View {
        let inventory = hero.inventory.placements
        guard !inventory.isEmpty else {
            return AnyView(EmptyView())
        }
        return AnyView(
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("SELL ITEMS")
                ForEach(inventory) { placement in
                    SellItemRow(
                        card: placement.card,
                        sellPrice: ShopDatabase.sellPrice(for: placement.card),
                        onSell: { engine.sellItem(placement.card) }
                    )
                }
            }
        )
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black)).foregroundStyle(.gray.opacity(0.5)).tracking(3)
    }
}

// MARK: - Shop Item Row

private struct ShopItemRow: View {
    let item: ShopItem
    let heroGold: Int
    let heroStats: HeroStats
    let onBuy: () -> Void

    private var canAfford: Bool { heroGold >= item.price && !item.isPurchased }
    private var card: Card { item.card }
    private var meetsReqs: Bool {
        guard let reqs = card.requirements, !reqs.isEmpty else { return true }
        return heroStats.strength >= reqs.strength &&
               heroStats.dexterity >= reqs.dexterity &&
               heroStats.intelligence >= reqs.intelligence
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(card.rarity.color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(card.equipmentSlot?.icon ?? "🎒")
                    .font(.system(size: 24))
                    .opacity(item.isPurchased ? 0.35 : 1.0)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(card.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(item.isPurchased ? .gray : (card.isUnique ? card.rarity.color : .white))
                    rarityBadge(card)
                }
                if !card.modifiers.isEmpty {
                    Text(card.modifiers.map(\.label).joined(separator: "  ·  "))
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 0.5, green: 0.9, blue: 0.5).opacity(item.isPurchased ? 0.4 : 1.0))
                        .lineLimit(2)
                } else if let bonus = card.statBonus {
                    Text(bonus.description.components(separatedBy: "\n").joined(separator: "  ·  "))
                        .font(.system(size: 11))
                        .foregroundStyle(.green.opacity(item.isPurchased ? 0.3 : 0.8))
                        .lineLimit(2)
                }
                if let reqs = card.requirements, !reqs.isEmpty {
                    HStack(spacing: 3) {
                        Image(systemName: meetsReqs ? "checkmark.circle.fill" : "lock.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(meetsReqs ? .green : .red.opacity(0.8))
                        Text("Requires \(reqs.description)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(meetsReqs ? .green.opacity(0.7) : Color(red: 1.0, green: 0.35, blue: 0.35))
                    }
                }
                Text("\(card.size.w)×\(card.size.h) · \(card.equipmentSlot?.rawValue ?? "")")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.45))
            }

            Spacer(minLength: 0)

            // Buy / Sold
            if item.isPurchased {
                Text("SOLD")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.gray.opacity(0.5))
                    .tracking(1)
                    .frame(width: 60, alignment: .center)
            } else {
                VStack(spacing: 4) {
                    Text("\(item.price)g")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(canAfford
                                         ? Color(red: 1.0, green: 0.82, blue: 0.25)
                                         : .gray.opacity(0.5))
                    Button(action: onBuy) {
                        Text("BUY")
                            .font(.system(size: 11, weight: .black)).tracking(1)
                            .foregroundStyle(canAfford ? .black : .gray)
                            .frame(width: 52, height: 28)
                            .background(canAfford
                                        ? AnyShapeStyle(LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                                                     Color(red: 0.7, green: 0.5, blue: 0.1)],
                                            startPoint: .top, endPoint: .bottom))
                                        : AnyShapeStyle(Color.white.opacity(0.07)))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canAfford)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.12, green: 0.08, blue: 0.03).opacity(item.isPurchased ? 0.5 : 1.0))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(card.rarity.color.opacity(item.isPurchased ? 0.1 : 0.25), lineWidth: 1))
        )
        .opacity(item.isPurchased ? 0.6 : 1.0)
    }
}

// MARK: - Sell Item Row

private struct SellItemRow: View {
    let card: Card
    let sellPrice: Int
    let onSell: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(card.rarity.color.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(card.equipmentSlot?.icon ?? "🎒").font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                Text(card.rarity.rawValue).font(.system(size: 10)).foregroundStyle(card.rarity.color.opacity(0.7))
            }

            Spacer()

            Button(action: onSell) {
                HStack(spacing: 4) {
                    Text("💰").font(.system(size: 11))
                    Text("\(sellPrice)g")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
                }
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(Color.white.opacity(0.07))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.10, green: 0.07, blue: 0.02))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1))
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

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    return ShopView(engine: engine, shopIndex: 0)
}
