import SwiftUI

struct LootPickupView: View {
    let engine: GameEngine
    let groundLoot: [Card]

    @State private var remaining: [Card]
    @State private var currentPage = 0

    // EXP bar animation state
    @State private var displayedBarFraction: CGFloat
    @State private var displayedExpCount: Int = 0
    @State private var showLevelUpBurst = false
    @State private var levelUpScale: CGFloat = 0.5
    @State private var levelUpOpacity: Double = 0

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    // Pre-combat EXP fraction (where the bar should start from)
    private var startBarFraction: CGFloat {
        let lvl = engine.combatStartLevel
        let expToNext = lvl * 100
        guard expToNext > 0 else { return 0 }
        return CGFloat(engine.combatStartExp) / CGFloat(expToNext)
    }

    // Current EXP fraction (where the bar ends up)
    private var endBarFraction: CGFloat { CGFloat(hero.expProgress) }

    init(engine: GameEngine, groundLoot: [Card]) {
        self.engine = engine
        self.groundLoot = groundLoot
        // Equipment cards are no longer generated, but filter them just in case
        self._remaining = State(initialValue: groundLoot.filter { !$0.isEquipment })
        // Start bar at the pre-combat position
        let lvl = engine.combatStartLevel
        let expToNext = max(1, lvl * 100)
        self._displayedBarFraction = State(initialValue: CGFloat(engine.combatStartExp) / CGFloat(expToNext))
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.06, blue: 0.14), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(lootHeader.icon)
                        .font(.system(size: 36))
                        .shadow(color: lootHeader.glow.opacity(0.5), radius: 10)
                    Text(lootHeader.title)
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(lootHeader.color)
                        .tracking(3)
                        .shadow(color: lootHeader.glow.opacity(0.4), radius: 6)
                    if !remaining.isEmpty {
                        Text("\(remaining.count) item\(remaining.count == 1 ? "" : "s") found")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    } else {
                        Text("All items decided")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray.opacity(0.6))
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 10)

                // EXP + Gold strip — only shown after combat
                if engine.currentLootContext == .combat {
                    expStrip
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                }

                // Paged loot cards
                if remaining.isEmpty {
                    Spacer().frame(height: 260)
                } else {
                    TabView(selection: $currentPage) {
                        ForEach(remaining.indices, id: \.self) { idx in
                            LootCardFull(card: remaining[idx])
                                .padding(.horizontal, 24)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: remaining.count > 1 ? .always : .never))
                    .frame(height: 280)
                }

                // Pick Up / Leave buttons
                if !remaining.isEmpty {
                    let card = remaining[min(currentPage, remaining.count - 1)]
                    let fits = canFit(card)
                    HStack(spacing: 16) {
                        Button { removeCard(card, pickUp: false) } label: {
                            Text("LEAVE")
                                .font(.system(size: 13, weight: .bold)).tracking(3)
                                .foregroundStyle(.gray)
                                .frame(width: 110, height: 44)
                                .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(.gray.opacity(0.3), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        Button { if fits { removeCard(card, pickUp: true) } } label: {
                            Text(fits ? "ADD TO COLLECTION" : "BAG FULL")
                                .font(.system(size: 13, weight: .black)).tracking(3)
                                .foregroundStyle(fits ? .black : .gray)
                                .frame(width: 200, height: 44)
                                .background(
                                    fits
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [card.rarity.color, card.rarity.color.opacity(0.7)],
                                        startPoint: .top, endPoint: .bottom))
                                    : AnyShapeStyle(Color.gray.opacity(0.15))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(!fits)
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 14)
                    .animation(.easeInOut(duration: 0.15), value: currentPage)
                } else {
                    Spacer().frame(height: 60)
                }

                // Collection summary
                if hero.cardCollection.count > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: 11)).foregroundStyle(.purple.opacity(0.6))
                        Text("\(hero.cardCollection.count) card\(hero.cardCollection.count == 1 ? "" : "s") in collection")
                            .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20).padding(.bottom, 4)
                }

                Spacer().frame(height: 14)

                // Continue
                Button { engine.finishLooting() } label: {
                    Text("CONTINUE")
                        .font(.system(size: 14, weight: .black)).tracking(4)
                        .foregroundStyle(.black)
                        .frame(width: 180, height: 46)
                        .background(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                                     Color(red: 0.7, green: 0.5, blue: 0.1)],
                            startPoint: .top, endPoint: .bottom))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 28)
            }
        }
        .task { await runExpAnimation() }
    }

    // MARK: - Loot Header

    private struct LootHeader {
        let icon: String
        let title: String
        let color: Color
        let glow: Color
    }

    private var lootHeader: LootHeader {
        switch engine.currentLootContext {
        case .combat:
            return LootHeader(icon: "🏆", title: "VICTORY",
                              color: Color(red: 1.0, green: 0.85, blue: 0.3), glow: .orange)
        case .treasure:
            return LootHeader(icon: "📦", title: "TREASURE FOUND",
                              color: Color(red: 0.9, green: 0.75, blue: 0.2), glow: .yellow)
        case .encounter:
            return LootHeader(icon: "✨", title: "ITEM FOUND",
                              color: Color(red: 0.6, green: 0.85, blue: 1.0), glow: .cyan)
        }
    }

    // MARK: - EXP Strip

    private var expStrip: some View {
        ZStack {
            VStack(spacing: 6) {
                // Row: +EXP and +Gold labels
                HStack {
                    // EXP gain
                    HStack(spacing: 4) {
                        Text("✨")
                            .font(.system(size: 12))
                        Text("+\(displayedExpCount) EXP")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.4))
                            .contentTransition(.numericText())
                    }

                    Spacer()

                    // Gold gain
                    if engine.lastCombatGoldGained > 0 {
                        HStack(spacing: 4) {
                            Text("💰").font(.system(size: 12))
                            Text("+\(engine.lastCombatGoldGained)g")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
                        }
                    }
                }

                // EXP bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.07))
                            .frame(height: 8)

                        // Fill
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(
                                colors: [Color(red: 1.0, green: 0.8, blue: 0.2),
                                         Color(red: 0.8, green: 0.5, blue: 0.1)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(0, geo.size.width * displayedBarFraction), height: 8)
                            .shadow(color: Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.6), radius: 4)
                    }
                }
                .frame(height: 8)

                // Level label
                HStack {
                    Text("LEVEL \(hero.level)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.gray.opacity(0.5))
                        .tracking(2)
                    Spacer()
                    Text("\(hero.experience)/\(hero.expToNextLevel) XP")
                        .font(.system(size: 9))
                        .foregroundStyle(.gray.opacity(0.4))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1))
            )

            // Level-up burst overlay
            if showLevelUpBurst {
                levelUpBurstView
                    .scaleEffect(levelUpScale)
                    .opacity(levelUpOpacity)
            }
        }
    }

    private var levelUpBurstView: some View {
        VStack(spacing: 4) {
            Text("⬆ LEVEL UP!")
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(Color(red: 1.0, green: 0.9, blue: 0.3))
                .shadow(color: .orange.opacity(0.8), radius: 10)
                .tracking(2)
            Text("Now level \(hero.level)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.2))
            if engine.lastCombatLevelsGained > 1 {
                Text("×\(engine.lastCombatLevelsGained) levels gained!")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.orange.opacity(0.8))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.3, green: 0.15, blue: 0.0).opacity(0.95))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 1.0, green: 0.7, blue: 0.2).opacity(0.7), lineWidth: 1.5))
        )
        .shadow(color: .orange.opacity(0.4), radius: 16)
    }

    // MARK: - Animation Sequence

    private func runExpAnimation() async {
        let expGained    = engine.lastCombatExpGained
        let levelsGained = engine.lastCombatLevelsGained

        // Short pause for screen to settle
        try? await Task.sleep(nanoseconds: 350_000_000)

        // Count up the EXP number
        withAnimation(.easeOut(duration: 0.9)) {
            displayedExpCount = expGained
        }

        // Brief pause before bar moves
        try? await Task.sleep(nanoseconds: 200_000_000)

        if levelsGained == 0 {
            // Simple fill to current position
            withAnimation(.easeInOut(duration: 0.9)) {
                displayedBarFraction = endBarFraction
            }
        } else {
            // Fill to the level-up point (1.0)
            withAnimation(.easeInOut(duration: 0.7)) {
                displayedBarFraction = 1.0
            }

            // Wait for bar to reach end, then burst
            try? await Task.sleep(nanoseconds: 800_000_000)

            showLevelUpBurst = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                levelUpScale   = 1.0
                levelUpOpacity = 1.0
            }

            // Hold the burst
            try? await Task.sleep(nanoseconds: 900_000_000)

            // Dismiss burst + reset bar to 0
            withAnimation(.easeOut(duration: 0.25)) {
                levelUpOpacity = 0
                levelUpScale   = 1.15
            }
            try? await Task.sleep(nanoseconds: 280_000_000)
            showLevelUpBurst = false
            displayedBarFraction = 0

            // Fill to final position
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation(.easeOut(duration: 0.6)) {
                displayedBarFraction = endBarFraction
            }
        }
    }

    // MARK: - Helpers

    private func canFit(_ card: Card) -> Bool {
        // Bag is unbounded — equipment always fits, combat cards go to collection
        return true
    }

    private func removeCard(_ card: Card, pickUp: Bool) {
        if pickUp { engine.pickUpLoot(card) }
        withAnimation(.easeInOut(duration: 0.2)) {
            remaining.removeAll { $0.id == card.id }
        }
        currentPage = min(currentPage, max(0, remaining.count - 1))
    }
}

// MARK: - Full Loot Card

struct LootCardFull: View {
    let card: Card

    var body: some View {
        if card.isEquipment {
            equipmentCard
        } else {
            combatCardFull
        }
    }

    // MARK: Equipment display (original)

    private var equipmentCard: some View {
        VStack(spacing: 0) {
            rarityBanner
            // Slot icon
            ZStack {
                if card.isUnique {
                    Circle()
                        .fill(card.rarity.color.opacity(0.1))
                        .frame(width: 64, height: 64)
                        .blur(radius: 8)
                }
                Text(card.equipmentSlot?.icon ?? "🎒")
                    .font(.system(size: 44))
                    .shadow(color: card.rarity.color.opacity(card.isUnique ? 0.8 : 0.3), radius: 10)
            }
            .frame(height: 56)

            Text(card.name)
                .font(.system(size: card.isUnique ? 18 : 16, weight: .black))
                .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                .multilineTextAlignment(.center)
                .padding(.top, 8).padding(.horizontal, 12)

            Text(card.equipmentSlot?.rawValue ?? "")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.gray.opacity(0.6)).tracking(1)
                .padding(.top, 3).padding(.bottom, 12)

            Divider().background(.gray.opacity(0.2)).padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 5) {
                if !card.modifiers.isEmpty {
                    ForEach(card.modifiers.indices, id: \.self) { idx in
                        HStack(spacing: 6) {
                            Circle().fill(modColor(card: card, index: idx)).frame(width: 4, height: 4)
                            Text(card.modifiers[idx].label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(modColor(card: card, index: idx))
                        }
                    }
                } else if let bonus = card.statBonus {
                    ForEach(bonus.description.components(separatedBy: "\n"), id: \.self) { line in
                        HStack(spacing: 6) {
                            Circle().fill(Color.green.opacity(0.7)).frame(width: 4, height: 4)
                            Text(line).font(.system(size: 13, weight: .semibold)).foregroundStyle(.green.opacity(0.85))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.top, 12)

            if !card.description.isEmpty {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill").font(.system(size: 10))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                    Text(card.description).font(.system(size: 12))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.9))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
                .padding(.horizontal, 20)
            }

            if let flavor = card.flavorText {
                Text(flavor).font(.system(size: 11)).italic()
                    .foregroundStyle(.gray.opacity(0.55)).multilineTextAlignment(.center)
                    .padding(.horizontal, 16).padding(.top, 10)
            }
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBackground)
    }

    // MARK: Combat card display

    private var combatCardFull: some View {
        VStack(spacing: 0) {
            rarityBanner

            // Card type + class badge
            HStack(spacing: 8) {
                Text(card.typeIcon)
                    .font(.system(size: 11))
                Text(card.type.rawValue.uppercased())
                    .font(.system(size: 9, weight: .black)).tracking(2)
                    .foregroundStyle(.gray.opacity(0.6))
                if let hc = card.heroClass {
                    Text("·")
                        .foregroundStyle(.gray.opacity(0.4))
                    Text(hc.rawValue.uppercased())
                        .font(.system(size: 9, weight: .black)).tracking(2)
                        .foregroundStyle(hc.themeColor.opacity(0.8))
                } else {
                    Text("·")
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("NEUTRAL")
                        .font(.system(size: 9, weight: .black)).tracking(2)
                        .foregroundStyle(.gray.opacity(0.55))
                }
            }
            .padding(.bottom, 6)

            // Big center icon + cost
            ZStack {
                if card.rarity == .unique {
                    Circle().fill(card.rarity.color.opacity(0.12))
                        .frame(width: 72, height: 72).blur(radius: 10)
                }
                VStack(spacing: 4) {
                    Text(card.effect.damageType.icon)
                        .font(.system(size: 38))
                        .shadow(color: card.rarity.color.opacity(0.6), radius: 8)
                    Text("\(card.cost) ⚡")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(height: 68)

            // Name
            Text(card.name)
                .font(.system(size: card.rarity == .unique ? 18 : 16, weight: .black))
                .foregroundStyle(card.rarity == .unique ? card.rarity.color : .white)
                .multilineTextAlignment(.center)
                .padding(.top, 8).padding(.horizontal, 12)

            // Effect description
            Text(card.description)
                .font(.system(size: 13))
                .foregroundStyle(.gray.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20).padding(.top, 6)

            Divider().background(.gray.opacity(0.15)).padding(.horizontal, 20).padding(.top, 12)

            // Stats strip
            HStack(spacing: 16) {
                if card.effect.damage > 0 {
                    statPill(icon: "🗡️", label: "\(card.effect.damage) DMG")
                }
                if card.effect.block > 0 {
                    statPill(icon: "🛡️", label: "\(card.effect.block) BLK")
                }
                if card.effect.heal > 0 {
                    statPill(icon: "❤️", label: "\(card.effect.heal) HP")
                }
                if card.effect.draw > 0 {
                    statPill(icon: "🃏", label: "Draw \(card.effect.draw)")
                }
                if card.effect.times > 1 {
                    statPill(icon: "✕", label: "×\(card.effect.times)")
                }
                if card.effect.poisonStacks > 0 {
                    statPill(icon: "☠️", label: "\(card.effect.poisonStacks) PSN")
                }
                if card.defenseValue > 0 {
                    statPill(icon: "🔰", label: "\(card.defenseValue) DEF", color: .cyan)
                }
            }
            .padding(.top, 10)

            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBackground)
    }

    // MARK: Shared helpers

    private var rarityBanner: some View {
        HStack {
            if card.isUnique { Text("✦").foregroundStyle(card.rarity.color).font(.system(size: 11)) }
            Text(card.rarity.rawValue.uppercased())
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(card.rarity.color).tracking(4)
            if card.isUnique { Text("✦").foregroundStyle(card.rarity.color).font(.system(size: 11)) }
        }
        .padding(.top, 16).padding(.bottom, 10)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(card.isUnique
                  ? Color(red: 0.14, green: 0.06, blue: 0.22)
                  : Color(red: 0.10, green: 0.07, blue: 0.18))
            .overlay(RoundedRectangle(cornerRadius: 16)
                .stroke(card.rarity.color.opacity(card.isUnique ? 0.7 : 0.4),
                        lineWidth: card.isUnique ? 2 : 1))
            .shadow(color: card.rarity.color.opacity(card.isUnique ? 0.3 : 0.1), radius: 12)
    }

    private func statPill(icon: String, label: String, color: Color = .white) -> some View {
        HStack(spacing: 3) {
            Text(icon).font(.system(size: 11))
            Text(label).font(.system(size: 11, weight: .semibold)).foregroundStyle(color.opacity(0.85))
        }
    }
}

private func modColor(card: Card, index: Int) -> Color {
    if card.isUnique { return Color(red: 0.9, green: 0.75, blue: 0.3) }
    return index % 2 == 0
        ? Color(red: 0.5, green: 0.9, blue: 0.5)
        : Color(red: 0.4, green: 0.7, blue: 1.0)
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .sorceress)
    engine.lastCombatExpGained = 80
    engine.lastCombatGoldGained = 45
    engine.lastCombatLevelsGained = 1
    engine.hero?.experience = 40
    engine.hero?.level = 2
    let loot = LootDatabase.generateLoot(floorNumber: 2, isBoss: true, count: 4)
    return LootPickupView(engine: engine, groundLoot: loot)
}
