import SwiftUI

struct CharacterProfileView: View {
    let engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack {
            background
            ScrollView {
                VStack(spacing: 0) {
                    DismissHandle()
                        .padding(.top, 8)

                    portraitSection
                    identitySection
                    expSection
                    Divider().background(.white.opacity(0.08)).padding(.horizontal, 24).padding(.vertical, 16)
                    attributesSection
                    Divider().background(.white.opacity(0.08)).padding(.horizontal, 24).padding(.vertical, 16)
                    vitalsSection
                        .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            LinearGradient(
                colors: classGradient,
                startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.55)
            )
            .ignoresSafeArea()
        }
    }

    private var classGradient: [Color] {
        switch hero.heroClass {
        case .barbarian:
            return [Color(red: 0.18, green: 0.05, blue: 0.02), .black]
        case .rogue:
            return [Color(red: 0.05, green: 0.04, blue: 0.14), .black]
        case .sorceress:
            return [Color(red: 0.04, green: 0.03, blue: 0.18), .black]
        }
    }

    // MARK: - Portrait

    private var portraitSection: some View {
        HeroPortraitView(heroClass: hero.heroClass, size: 240)
            .shadow(color: accentColor.opacity(0.40), radius: 28)
            .padding(.top, 12)
    }

    // MARK: - Identity

    private var identitySection: some View {
        VStack(spacing: 6) {
            Text(hero.heroClass.rawValue.uppercased())
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(accentColor)
                .tracking(6)
                .shadow(color: accentColor.opacity(0.5), radius: 8)

            Text(hero.heroClass.lore)
                .font(.system(size: 12))
                .foregroundStyle(.gray.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 8) {
                Text("LEVEL \(hero.level)")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(.white)
                    .tracking(2)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(accentColor.opacity(0.18))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(accentColor.opacity(0.40), lineWidth: 1))
            }
            .padding(.top, 4)
        }
        .padding(.top, 16)
    }

    // MARK: - EXP Bar

    private var expSection: some View {
        VStack(spacing: 5) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.80), accentColor.opacity(0.45)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * hero.expProgress)
                        .animation(.easeOut(duration: 0.6), value: hero.expProgress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 32)

            Text("\(hero.experience) / \(hero.expToNextLevel) XP")
                .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.5))
        }
        .padding(.top, 12)
    }

    // MARK: - Attributes

    private var attributesSection: some View {
        VStack(spacing: 0) {
            sectionHeader("ATTRIBUTES")
            VStack(spacing: 10) {
                ForEach(StatKey.allCases, id: \.self) { key in
                    statRow(key: key)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 10)
        }
    }

    private func statRow(key: StatKey) -> some View {
        let value = hero.stats[key]
        let maxDisplay = 30
        let fraction = min(1.0, Double(value) / Double(maxDisplay))

        return HStack(spacing: 10) {
            Text(key.shortName)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(key.themeColor)
                .tracking(1)
                .frame(width: 32, alignment: .leading)

            Text("\(value)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, alignment: .trailing)
                .contentTransition(.numericText())

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [key.themeColor, key.themeColor.opacity(0.50)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 5)

            Text(bonusLabel(for: key))
                .font(.system(size: 10))
                .foregroundStyle(key.themeColor.opacity(0.70))
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func bonusLabel(for key: StatKey) -> String {
        switch key {
        case .strength:     return "+\(hero.statAttackBonus) ATK"
        case .dexterity:    return "+\(hero.statDefenseBonus) DEF"
        case .vitality:     return "+\(hero.stats.vitality * 3) HP"
        case .intelligence: return "+\(hero.statEnergyBonus) NRG"
        }
    }

    // MARK: - Vitals

    private var vitalsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("VITALS")
            VStack(spacing: 12) {
                vitalRow(icon: "heart.fill", label: "Health",
                         value: "\(hero.currentHp) / \(hero.maxHp)",
                         fraction: Double(hero.currentHp) / Double(max(1, hero.maxHp)),
                         color: .red)

                HStack(spacing: 20) {
                    Text("💰  \(hero.gold) gold")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))

                    Spacer()

                    let deckCount = hero.deck.count + hero.hand.count + hero.discardPile.count
                    Text("🃏  \(deckCount) cards")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white.opacity(0.70))
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 10)
        }
    }

    private func vitalRow(icon: String, label: String, value: String,
                          fraction: Double, color: Color) -> some View {
        VStack(spacing: 5) {
            HStack {
                Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
                Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(.gray)
                Spacer()
                Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 24)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [color, color.opacity(0.50)],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * min(1, max(0, fraction)))
                        .animation(.easeOut(duration: 0.5), value: fraction)
                }
            }
            .frame(height: 5)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black))
            .foregroundStyle(.gray.opacity(0.45))
            .tracking(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
    }

    // MARK: - Helpers

    private var accentColor: Color {
        switch hero.heroClass {
        case .barbarian: return Color(red: 1.0,  green: 0.45, blue: 0.10)
        case .rogue:     return Color(red: 0.12, green: 0.88, blue: 0.68)
        case .sorceress: return Color(red: 0.72, green: 0.38, blue: 1.00)
        }
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .sorceress)
    return CharacterProfileView(engine: engine)
}
