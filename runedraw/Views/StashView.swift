import SwiftUI

struct StashView: View {
    let engine: GameEngine
    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.03, blue: 0.08).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.2, green: 0.12, blue: 0.05).opacity(0.5), .clear],
                center: .init(x: 0.5, y: 0.2), startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                DismissHandle(tint: Color(red: 1.0, green: 0.75, blue: 0.3))

                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SHARED STASH")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.gray.opacity(0.6)).tracking(3)
                        Text("\(engine.sharedStash.cards.count) items stored")
                            .font(.system(size: 18, weight: .black)).foregroundStyle(.white)
                    }
                    Spacer()
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.3).opacity(0.8))
                }
                .padding(.horizontal, 20).padding(.vertical, 14)
                .background(Color.black.opacity(0.35))

                Divider().background(Color(red: 0.6, green: 0.4, blue: 0.1).opacity(0.3))

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {

                        // STASH CONTENTS
                        stashSection

                        Divider().background(.white.opacity(0.06))
                            .padding(.horizontal, 20).padding(.vertical, 14)

                        // YOUR COLLECTION
                        collectionSection
                    }
                    .padding(.bottom, 28)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(red: 0.04, green: 0.03, blue: 0.08))
    }

    // MARK: - Stash section

    private var stashSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("🏦  STASH")
                Spacer()
                Text("Available to all characters")
                    .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.35))
                    .padding(.trailing, 20)
            }
            .padding(.top, 16)

            if engine.sharedStash.cards.isEmpty {
                Text("The stash is empty.")
                    .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.35))
                    .frame(maxWidth: .infinity).padding(.vertical, 20)
            } else {
                let stashCards = engine.sharedStash.cards.sorted {
                    $0.rarity.rawValue > $1.rarity.rawValue
                }
                VStack(spacing: 4) {
                    ForEach(stashCards) { card in
                        stashCardRow(card: card, inStash: true)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }
        }
    }

    // MARK: - Collection section

    private var collectionSection: some View {
        let collection = hero.cardCollection
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                sectionHeader("🎒  YOUR COLLECTION")
                Spacer()
                Text("\(collection.count) cards")
                    .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.35))
                    .padding(.trailing, 20)
            }

            if collection.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "rectangle.stack.badge.plus")
                        .font(.system(size: 26)).foregroundStyle(.gray.opacity(0.2))
                    Text("No cards to deposit yet.")
                        .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.35))
                }
                .frame(maxWidth: .infinity).padding(.vertical, 24)
            } else {
                let sorted = collection.sorted { $0.rarity.rawValue > $1.rarity.rawValue }
                VStack(spacing: 4) {
                    ForEach(sorted) { card in
                        stashCardRow(card: card, inStash: false)
                    }
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }
        }
    }

    // MARK: - Card row

    private func stashCardRow(card: Card, inStash: Bool) -> some View {
        let isOwnClass = card.heroClass == nil || card.heroClass == hero.heroClass
        let classLabel = card.heroClass.map { $0.rawValue } ?? "Neutral"
        let classColor: Color = card.heroClass.map { $0.themeColor } ?? .gray

        return HStack(spacing: 10) {
            // Cost
            ZStack {
                Circle().fill(classColor.opacity(0.18)).frame(width: 28, height: 28)
                Text("\(card.cost)")
                    .font(.system(size: 12, weight: .black)).foregroundStyle(classColor)
            }

            Text(card.effect.damageType.icon).font(.system(size: 16))

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text(card.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(card.rarity == .common ? .white : card.rarity.color)
                        .opacity(isOwnClass ? 1.0 : 0.7)
                    if card.rarity != .common {
                        Text(card.rarity.rawValue.uppercased())
                            .font(.system(size: 6, weight: .black)).tracking(1.5)
                            .foregroundStyle(card.rarity.color.opacity(0.8))
                            .padding(.horizontal, 3).padding(.vertical, 1)
                            .background(card.rarity.color.opacity(0.12)).clipShape(Capsule())
                    }
                }
                HStack(spacing: 4) {
                    Text(classLabel)
                        .font(.system(size: 9, weight: .bold)).foregroundStyle(classColor.opacity(0.7))
                    Text("·").foregroundStyle(.gray.opacity(0.3)).font(.system(size: 9))
                    Text(card.description)
                        .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.45)).lineLimit(1)
                }
            }

            Spacer()

            if inStash {
                Button { engine.withdrawFromStash(card) } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.to.line")
                        Text("TAKE")
                    }
                    .font(.system(size: 10, weight: .black)).tracking(1)
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(isOwnClass
                                ? AnyShapeStyle(classColor)
                                : AnyShapeStyle(Color.white.opacity(0.25)))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button { engine.depositToStash(card) } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.to.line")
                        Text("DEPOSIT")
                    }
                    .font(.system(size: 10, weight: .black)).tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.white.opacity(0.10))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(card.rarity.color.opacity(card.rarity == .common ? 0.0 : 0.18),
                            lineWidth: 1))
        )
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black)).foregroundStyle(.gray.opacity(0.45)).tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    engine.hero?.cardCollection = [
        CardDatabase.droppableCard(for: .sorceress, rarity: .rare)!,
        CardDatabase.droppableCard(for: .rogue, rarity: .magic)!,
        CardDatabase.droppableCard(for: .barbarian, rarity: .common)!,
    ]
    return StashView(engine: engine)
}
