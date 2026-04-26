import SwiftUI

struct StatAllocationView: View {
    let engine: GameEngine
    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.02, blue: 0.08).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.3, green: 0.12, blue: 0.04).opacity(0.5), .clear],
                center: .init(x: 0.5, y: 0.25), startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                DismissHandle(tint: Color(red: 1.0, green: 0.65, blue: 0.25))
                header
                Divider().background(Color(red: 0.7, green: 0.4, blue: 0.1).opacity(0.3))
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(StatKey.allCases, id: \.self) { stat in
                            StatRow(
                                stat: stat,
                                value: hero.stats[stat],
                                bonus: bonusText(stat),
                                canAdd: hero.statPoints > 0,
                                onAdd: { engine.allocateStat(stat) }
                            )
                        }

                        requirementsGuide
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(red: 0.04, green: 0.02, blue: 0.08))
    }

    // MARK: - Header

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ATTRIBUTES")
                    .font(.system(size: 11, weight: .black)).foregroundStyle(.gray.opacity(0.6)).tracking(3)
                Text(hero.heroClass.rawValue.uppercased())
                    .font(.system(size: 20, weight: .black)).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(hero.statPoints)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(hero.statPoints > 0
                                     ? Color(red: 1.0, green: 0.75, blue: 0.3)
                                     : .gray.opacity(0.4))
                Text(hero.statPoints == 1 ? "point to spend" : "points to spend")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.5))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - Bonus text per stat

    private func bonusText(_ stat: StatKey) -> String {
        switch stat {
        case .strength:
            let b = hero.stats.strength / 5
            return b > 0 ? "+\(b) Attack" : "0 Attack"
        case .dexterity:
            let b = hero.stats.dexterity / 5
            return b > 0 ? "+\(b) Defense" : "0 Defense"
        case .vitality:
            return "+\(hero.stats.vitality * 3) Max HP"
        case .intelligence:
            let b = hero.statSpellpowerBonus
            return b > 0 ? "+\(b) Spellpower" : "+0 Spellpower"
        }
    }

    // MARK: - Requirements guide

    var requirementsGuide: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ITEM REQUIREMENTS")
                .font(.system(size: 10, weight: .black)).foregroundStyle(.gray.opacity(0.5)).tracking(3)
                .frame(maxWidth: .infinity, alignment: .leading)

            let entries: [(String, String)] = [
                ("Short Sword / Axe",     "STR 10"),
                ("Helm / Kite Shield",    "STR 10–12"),
                ("Chain Mail / Broad Sword", "STR 15–18"),
                ("War Axe / Tower Shield",   "STR 20–22"),
                ("Plate Mail / Great Sword", "STR 25–28"),
                ("Grimoire / Tome",       "INT 10–15"),
                ("Arcane Orb / Rune Blade", "INT/STR 18–20"),
                ("Greaves",               "DEX 8"),
                ("War Boots",             "DEX 14"),
            ]

            VStack(spacing: 0) {
                ForEach(entries, id: \.0) { name, req in
                    HStack {
                        Text(name).font(.system(size: 11)).foregroundStyle(.gray.opacity(0.55))
                        Spacer()
                        Text(req).font(.system(size: 11, weight: .bold)).foregroundStyle(.gray.opacity(0.45))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    if name != entries.last?.0 {
                        Divider().background(.white.opacity(0.05))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.03))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1))
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Stat Row

private struct StatRow: View {
    let stat: StatKey
    let value: Int
    let bonus: String
    let canAdd: Bool
    let onAdd: () -> Void

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(stat.themeColor.opacity(pulse ? 0.25 : 0.12))
                    .frame(width: 46, height: 46)
                    .scaleEffect(pulse ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
                Text(stat.icon).font(.system(size: 20))
            }

            // Name + description
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(stat.shortName)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(stat.themeColor)
                    Text(stat.rawValue)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Text(stat.effectDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(.gray.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            // Current value + bonus
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                Text(bonus)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(stat.themeColor.opacity(0.8))
            }

            // Add button
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(canAdd ? .black : .gray.opacity(0.3))
                    .frame(width: 34, height: 34)
                    .background(
                        canAdd
                        ? AnyShapeStyle(stat.themeColor)
                        : AnyShapeStyle(Color.white.opacity(0.06))
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(canAdd ? stat.themeColor.opacity(0.3) : Color.white.opacity(0.07), lineWidth: 1))
        )
        .onAppear { if canAdd { pulse = true } }
        .onChange(of: canAdd) { _, new in pulse = new }
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    if engine.hero != nil { engine.hero!.statPoints = 5 }
    return StatAllocationView(engine: engine)
}
