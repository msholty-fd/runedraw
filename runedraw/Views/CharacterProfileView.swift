import SwiftUI

// MARK: - Tab

private enum ProfileTab: String, CaseIterable {
    case profile  = "Profile"
    case deck     = "Deck"
    case equipped = "Equipped"
    case items    = "Items"

    var icon: String {
        switch self {
        case .profile:  return "person.fill"
        case .deck:     return "rectangle.stack.fill"
        case .equipped: return "shield.fill"
        case .items:    return "bag.fill"
        }
    }
}

// MARK: - Item Selection

private enum ItemSelection {
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

// MARK: - CharacterProfileView

struct CharacterProfileView: View {
    let engine: GameEngine
    @State private var tab: ProfileTab = .profile
    @State private var selection: ItemSelection? = nil
    @State private var confirmDrop = false
    @State private var selectedSkillNode: SkillNode? = nil
    @State private var selectedCardForDetail: Card? = nil
    @Namespace private var tabNS

    private let panelHeight: CGFloat = 190
    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack(alignment: .bottom) {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                DismissHandle().padding(.top, 8)
                tabBar
                Divider().background(.white.opacity(0.08))
                tabContent
            }

            if let sel = selection {
                itemPanel(sel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.80), value: selection?.card?.id)
        .onChange(of: tab) { _, _ in withAnimation { selection = nil } }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .sheet(item: $selectedSkillNode) { node in
            SkillNodeDetailSheet(
                node: node,
                isUnlocked: engine.hero?.unlockedSkills.contains(node.id) ?? false,
                isAvailable: {
                    guard let h = engine.hero else { return false }
                    let tree = SkillDatabase.tree(for: h.heroClass)
                    return node.tier == 1 || tree.first(where: { $0.branch == node.branch && $0.tier == node.tier - 1 }).map { h.unlockedSkills.contains($0.id) } ?? false
                }(),
                hasPoints: (engine.hero?.skillPoints ?? 0) >= node.cost,
                branchColor: SkillDatabase.branchColor(node.branch),
                onUnlock: { engine.unlockSkill(node.id) }
            )
        }
        .sheet(item: $selectedCardForDetail) { card in
            CardDetailSheet(card: card)
        }
        .confirmationDialog(
            "Drop \(selection?.card?.name ?? "")?",
            isPresented: $confirmDrop, titleVisibility: .visible
        ) {
            Button("Drop Item", role: .destructive) {
                if let card = selection?.card { engine.dropFromInventory(card) }
                selection = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item will be permanently lost.")
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color.black
            LinearGradient(colors: classGradient, startPoint: .top,
                           endPoint: UnitPoint(x: 0.5, y: 0.45))
        }
    }

    private var classGradient: [Color] {
        switch hero.heroClass {
        case .barbarian: return [Color(red: 0.18, green: 0.05, blue: 0.02), .black]
        case .rogue:     return [Color(red: 0.05, green: 0.04, blue: 0.14), .black]
        case .sorceress: return [Color(red: 0.04, green: 0.03, blue: 0.18), .black]
        }
    }

    private var accent: Color {
        switch hero.heroClass {
        case .barbarian: return Color(red: 1.0,  green: 0.45, blue: 0.10)
        case .rogue:     return Color(red: 0.12, green: 0.88, blue: 0.68)
        case .sorceress: return Color(red: 0.72, green: 0.38, blue: 1.00)
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ProfileTab.allCases, id: \.self) { t in
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { tab = t }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: t.icon)
                            .font(.system(size: 14, weight: tab == t ? .bold : .regular))
                        Text(t.rawValue.uppercased())
                            .font(.system(size: 9, weight: .black)).tracking(1)
                    }
                    .foregroundStyle(tab == t ? accent : .gray.opacity(0.40))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(alignment: .bottom) {
                        if tab == t {
                            Rectangle().fill(accent).frame(height: 2)
                                .matchedGeometryEffect(id: "indicator", in: tabNS)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Content Router

    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case .profile:  profileTab
        case .deck:     deckTab
        case .equipped: equippedTab
        case .items:    itemsTab
        }
    }

    // MARK: - Profile Tab

    private var profileTab: some View {
        ScrollView {
            VStack(spacing: 0) {
                HeroPortraitView(heroClass: hero.heroClass, equipment: hero.equipment, size: 175)
                    .shadow(color: accent.opacity(0.38), radius: 22)
                    .padding(.top, 14)

                VStack(spacing: 6) {
                    Text(hero.heroClass.rawValue.uppercased())
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(accent).tracking(5)
                        .shadow(color: accent.opacity(0.45), radius: 8)
                    Text("LEVEL \(hero.level)")
                        .font(.system(size: 11, weight: .black)).tracking(2).foregroundStyle(.white)
                        .padding(.horizontal, 12).padding(.vertical, 4)
                        .background(accent.opacity(0.15)).clipShape(Capsule())
                        .overlay(Capsule().stroke(accent.opacity(0.35), lineWidth: 1))
                }
                .padding(.top, 10)

                expBar.padding(.top, 10)

                profileDivider

                // Attributes header + points badge
                HStack(alignment: .firstTextBaseline) {
                    sectionHeader("ATTRIBUTES")
                    Spacer()
                    if hero.statPoints > 0 {
                        Text("\(hero.statPoints) pts")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.3))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 1.0, green: 0.55, blue: 0.1).opacity(0.18))
                            .clipShape(Capsule())
                            .padding(.trailing, 20)
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(StatKey.allCases, id: \.self) { statTile(key: $0) }
                }
                .padding(.horizontal, 20).padding(.top, 8)

                profileDivider

                sectionHeader("VITALS")
                vitalsRows
                    .padding(.horizontal, 20).padding(.top, 10)

                profileDivider

                // Skills header + points badge
                HStack(alignment: .firstTextBaseline) {
                    sectionHeader("SKILLS")
                    Spacer()
                    if hero.skillPoints > 0 {
                        Text("\(hero.skillPoints) pts")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(Color(red: 0.8, green: 0.6, blue: 1.0))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color(red: 0.5, green: 0.2, blue: 1.0).opacity(0.18))
                            .clipShape(Capsule())
                            .padding(.trailing, 20)
                    }
                }

                inlineSkillTree
                    .padding(.horizontal, 12).padding(.top, 8).padding(.bottom, 36)
            }
        }
    }

    private var expBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: [accent.opacity(0.80), accent.opacity(0.42)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * hero.expProgress)
                        .animation(.easeOut(duration: 0.5), value: hero.expProgress)
                }
            }
            .frame(height: 5).padding(.horizontal, 32)
            Text("\(hero.experience) / \(hero.expToNextLevel) XP")
                .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.40))
        }
    }

    @ViewBuilder
    private func statTile(key: StatKey) -> some View {
        let value    = hero.stats[key]
        let frac     = min(1.0, Double(value) / 28.0)
        let canSpend = hero.statPoints > 0
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(key.shortName)
                        .font(.system(size: 10, weight: .black)).foregroundStyle(key.themeColor).tracking(1)
                    Text(key.rawValue)
                        .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.45))
                }
                Spacer()
                HStack(spacing: 6) {
                    Text("\(value)").font(.system(size: 16, weight: .black)).foregroundStyle(.white)
                        .contentTransition(.numericText())
                    if canSpend {
                        Button { engine.allocateStat(key) } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.black)
                                .frame(width: 22, height: 22)
                                .background(key.themeColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [key.themeColor, key.themeColor.opacity(0.42)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * frac)
                        .animation(.easeOut(duration: 0.3), value: value)
                }
            }
            .frame(height: 4)
            Text(bonusLabel(key)).font(.system(size: 10)).foregroundStyle(key.themeColor.opacity(0.65))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(key.themeColor.opacity(canSpend ? 0.09 : 0.06))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(canSpend ? key.themeColor.opacity(0.35) : key.themeColor.opacity(0.18), lineWidth: 1))
        )
    }

    private func bonusLabel(_ key: StatKey) -> String {
        switch key {
        case .strength:     return "+\(hero.statAttackBonus) ATK"
        case .dexterity:    return "+\(hero.statDefenseBonus) DEF"
        case .vitality:     return "+\(hero.stats.vitality * 3) HP"
        case .intelligence: return "+\(hero.statSpellpowerBonus) SP  +\(hero.statEnergyBonus) NRG"
        }
    }

    // MARK: - Inline Skill Tree

    private var inlineSkillTree: some View {
        let branches     = hero.heroClass.skillBranchNames
        let branchIcons  = hero.heroClass.skillBranchIcons
        let tree         = SkillDatabase.tree(for: hero.heroClass)

        return HStack(alignment: .top, spacing: 8) {
            ForEach(0..<3, id: \.self) { branch in
                VStack(spacing: 0) {
                    VStack(spacing: 3) {
                        Text(branchIcons[branch]).font(.system(size: 20))
                        Text(branches[branch].uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(SkillDatabase.branchColor(branch).opacity(0.8))
                            .tracking(1)
                    }
                    .padding(.bottom, 10)

                    ForEach([1, 2, 3, 4], id: \.self) { tier in
                        if let node = tree.first(where: { $0.branch == branch && $0.tier == tier }) {
                            SkillNodeTile(
                                node: node,
                                isUnlocked:   hero.unlockedSkills.contains(node.id),
                                isAvailable:  isSkillAvailable(node),
                                hasPoints:    hero.skillPoints >= node.cost,
                                branchColor:  SkillDatabase.branchColor(branch),
                                onUnlock:     { engine.unlockSkill(node.id) },
                                onTap:        { selectedSkillNode = node }
                            )
                        }
                        if tier < 4 {
                            skillConnector(branch: branch, fromTier: tier, tree: tree)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func skillConnector(branch: Int, fromTier: Int, tree: [SkillNode]) -> some View {
        let nodeId     = tree.first(where: { $0.branch == branch && $0.tier == fromTier })?.id ?? ""
        let isActive   = hero.unlockedSkills.contains(nodeId)
        let color      = SkillDatabase.branchColor(branch)
        VStack(spacing: 0) {
            Rectangle().fill(isActive ? color.opacity(0.6) : Color.white.opacity(0.07)).frame(width: 2, height: 10)
            Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
                .foregroundStyle(isActive ? color.opacity(0.7) : Color.white.opacity(0.1))
            Rectangle().fill(isActive ? color.opacity(0.6) : Color.white.opacity(0.07)).frame(width: 2, height: 10)
        }
    }

    private func isSkillAvailable(_ node: SkillNode) -> Bool {
        guard !hero.unlockedSkills.contains(node.id) else { return false }
        if let reqId = node.requiresId { return hero.unlockedSkills.contains(reqId) }
        return true
    }

    private var vitalsRows: some View {
        VStack(spacing: 10) {
            vitalBar(icon: "heart.fill", label: "Health",
                     value: "\(hero.currentHp) / \(hero.maxHp)",
                     frac: Double(hero.currentHp) / Double(max(1, hero.maxHp)), color: .red)
            HStack(spacing: 14) {
                Text("💰  \(hero.gold) gold")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.25))
                Spacer()
                let dc = hero.deck.count + hero.hand.count + hero.discardPile.count
                Text("🃏  \(dc) cards")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private func vitalBar(icon: String, label: String,
                          value: String, frac: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon).font(.system(size: 11)).foregroundStyle(color)
                Text(label).font(.system(size: 11, weight: .bold)).foregroundStyle(.gray)
                Spacer()
                Text(value).font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LinearGradient(colors: [color, color.opacity(0.45)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * min(1, max(0, frac)))
                        .animation(.easeOut(duration: 0.4), value: frac)
                }
            }
            .frame(height: 4)
        }
    }

    // MARK: - Deck Tab

    private var deckTab: some View {
        let deckCards    = hero.deck + hero.discardPile
        let deckTotal    = deckCards.count + hero.hand.count
        let canAdd       = deckTotal < Hero.maxDeckSize
        let canRemove    = deckTotal > Hero.minDeckSize
        let collection   = hero.cardCollection

        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                miniHeroBar
                Divider().background(.white.opacity(0.08))

                // Deck size gauge
                deckSizeGauge(deckTotal: deckTotal)
                    .padding(.horizontal, 20).padding(.top, 14).padding(.bottom, 6)

                Divider().background(.white.opacity(0.06)).padding(.horizontal, 20).padding(.bottom, 4)

                // Active deck
                HStack(alignment: .firstTextBaseline) {
                    sectionHeader("ACTIVE DECK")
                    Spacer()
                    Text("\(deckTotal) cards")
                        .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.4))
                        .padding(.trailing, 20)
                }
                .padding(.top, 10)

                if deckCards.isEmpty && hero.hand.isEmpty {
                    emptyDeckHint
                } else {
                    // Sort: attack first, then skill, then by cost
                    let sorted = (deckCards + hero.hand).sorted {
                        $0.type.rawValue < $1.type.rawValue || ($0.type == $1.type && $0.cost < $1.cost)
                    }
                    VStack(spacing: 4) {
                        ForEach(sorted) { card in
                            deckCardRow(card: card, inDeck: true, canToggle: canRemove) {
                                engine.removeCardFromDeck(card)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 6)
                }

                Divider().background(.white.opacity(0.06))
                    .padding(.horizontal, 20).padding(.vertical, 14)

                // Collection
                HStack(alignment: .firstTextBaseline) {
                    sectionHeader("COLLECTION")
                    Spacer()
                    Text("\(collection.count) cards")
                        .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.4))
                        .padding(.trailing, 20)
                }

                if collection.isEmpty {
                    emptyCollectionHint
                } else {
                    let sortedCol = collection.sorted {
                        $0.rarity.rawValue > $1.rarity.rawValue || ($0.rarity == $1.rarity && $0.cost < $1.cost)
                    }
                    VStack(spacing: 4) {
                        ForEach(sortedCol) { card in
                            let isOffClass = card.heroClass != nil && card.heroClass != hero.heroClass
                            deckCardRow(card: card, inDeck: false, canToggle: canAdd && !isOffClass, isOffClass: isOffClass) {
                                engine.addCardToDeck(card)
                            }
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 6)
                }

                Spacer().frame(height: 28)
            }
        }
    }

    private func deckSizeGauge(deckTotal: Int) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("DECK SIZE")
                    .font(.system(size: 10, weight: .black)).foregroundStyle(.gray.opacity(0.45)).tracking(3)
                Spacer()
                Text("\(deckTotal) / \(Hero.maxDeckSize)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(deckTotal >= Hero.maxDeckSize ? .orange : .white.opacity(0.7))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.06))
                    // Min line marker
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 1.5)
                        .offset(x: geo.size.width * CGFloat(Hero.minDeckSize) / CGFloat(Hero.maxDeckSize))
                    // Fill
                    let frac = min(1.0, Double(deckTotal) / Double(Hero.maxDeckSize))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(
                            colors: deckTotal < Hero.minDeckSize
                                ? [.orange, .red]
                                : [accent, accent.opacity(0.5)],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(0, geo.size.width * frac))
                        .animation(.easeOut(duration: 0.3), value: deckTotal)
                }
            }
            .frame(height: 6)
            HStack {
                Text("Min \(Hero.minDeckSize)")
                    .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.35))
                Spacer()
                Text("Max \(Hero.maxDeckSize)")
                    .font(.system(size: 9)).foregroundStyle(.gray.opacity(0.35))
            }
        }
    }

    private func deckCardRow(card: Card, inDeck: Bool, canToggle: Bool, isOffClass: Bool = false, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            // Cost badge
            ZStack {
                Circle().fill(accent.opacity(0.18)).frame(width: 28, height: 28)
                Text("\(card.cost)")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(accent)
            }

            // Type icon
            Text(card.effect.damageType.icon)
                .font(.system(size: 16))

            // Name + description (tap to expand full details)
            Button { selectedCardForDetail = card } label: {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(card.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(card.rarity == .common ? .white : card.rarity.color)
                        if card.rarity != .common {
                            Text(card.rarity.rawValue.uppercased())
                                .font(.system(size: 6, weight: .black)).tracking(1.5)
                                .foregroundStyle(card.rarity.color.opacity(0.8))
                                .padding(.horizontal, 3).padding(.vertical, 1)
                                .background(card.rarity.color.opacity(0.12)).clipShape(Capsule())
                        }
                        if isOffClass, let cc = card.heroClass {
                            HStack(spacing: 2) {
                                Image(systemName: "lock.fill").font(.system(size: 6))
                                Text(cc.rawValue.uppercased())
                                    .font(.system(size: 6, weight: .black)).tracking(1)
                            }
                            .foregroundStyle(.orange.opacity(0.8))
                            .padding(.horizontal, 3).padding(.vertical, 1)
                            .background(Color.orange.opacity(0.12)).clipShape(Capsule())
                        }
                    }
                    Text(card.description)
                        .font(.system(size: 10))
                        .foregroundStyle(.gray.opacity(0.5))
                        .lineLimit(2)
                    if card.description.count > 40 {
                        Text("tap to read more")
                            .font(.system(size: 7)).foregroundStyle(accent.opacity(0.5))
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            // Add / Remove button
            if canToggle {
                Button(action: action) {
                    Image(systemName: inDeck ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(inDeck ? .red.opacity(0.7) : .green.opacity(0.8))
                }
                .buttonStyle(.plain)
            } else if isOffClass {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.orange.opacity(0.35))
            } else {
                Image(systemName: inDeck ? "minus.circle" : "plus.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(.gray.opacity(0.15))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(inDeck ? 0.04 : 0.02))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(card.rarity.color.opacity(card.rarity == .common ? 0.0 : 0.2), lineWidth: 1))
        )
    }

    private var emptyDeckHint: some View {
        Text("No cards in your deck yet.")
            .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.35))
            .frame(maxWidth: .infinity).padding(.vertical, 20)
    }

    private var emptyCollectionHint: some View {
        VStack(spacing: 6) {
            Image(systemName: "rectangle.stack.badge.plus")
                .font(.system(size: 28)).foregroundStyle(.gray.opacity(0.2))
            Text("Defeat enemies to collect cards.")
                .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.35))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 24)
    }

    // MARK: - Equipped Tab

    private var equippedTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                miniHeroBar
                Divider().background(.white.opacity(0.08))
                sectionHeader("EQUIPPED").padding(.top, 14).padding(.bottom, 2)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(EquipmentSlot.allCases, id: \.self) { slot in
                        EquippedSlotTile(
                            slot: slot,
                            card: hero.equipment.equipped(in: slot),
                            isSelected: selection?.slot == .some(slot)
                        )
                        .onTapGesture {
                            guard hero.equipment.equipped(in: slot) != nil else { return }
                            let already = selection?.slot == .some(slot)
                            withAnimation { selection = already ? nil : .equipped(slot) }
                        }
                    }
                }
                .padding(.horizontal, 16)
                if selection != nil { Color.clear.frame(height: panelHeight + 16) }
            }
            .padding(.bottom, 8)
        }
        .onTapGesture { if selection != nil { withAnimation { selection = nil } } }
    }

    // MARK: - Items Tab

    private var itemsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                miniHeroBar
                Divider().background(.white.opacity(0.08))
                HStack(alignment: .firstTextBaseline) {
                    sectionHeader("INVENTORY").padding(.top, 14).padding(.bottom, 2)
                    Spacer()
                    Text("\(hero.inventory.count) item\(hero.inventory.count == 1 ? "" : "s")")
                        .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.40))
                        .padding(.trailing, 20).padding(.top, 14)
                }
                GearListView(bag: hero.inventory, selectedId: selection?.card?.id) { card in
                    let already = selection?.card?.id == card.id
                    withAnimation { selection = already ? nil : .inventory(card) }
                }
                .padding(.horizontal, 16)
                .simultaneousGesture(TapGesture().onEnded { })
                if selection != nil { Color.clear.frame(height: panelHeight + 16) }
            }
            .padding(.bottom, 8)
        }
        .onTapGesture { if selection != nil { withAnimation { selection = nil } } }
    }

    // MARK: - Mini Hero Bar

    private var miniHeroBar: some View {
        HStack(spacing: 12) {
            HeroPortraitView(heroClass: hero.heroClass, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(hero.heroClass.rawValue.uppercased())
                    .font(.system(size: 10, weight: .black)).foregroundStyle(.gray).tracking(3)
                HStack(spacing: 8) {
                    Label("\(hero.currentHp)/\(hero.maxHp)", systemImage: "heart.fill")
                        .font(.system(size: 11, weight: .bold)).foregroundStyle(.red)
                    if hero.attackBonus  > 0 {
                        Text("+\(hero.attackBonus) ATK").font(.system(size: 10)).foregroundStyle(.orange)
                    }
                    if hero.defenseBonus > 0 {
                        Text("+\(hero.defenseBonus) DEF").font(.system(size: 10)).foregroundStyle(.cyan)
                    }
                }
            }
            Spacer()
            Text("LVL \(hero.level)")
                .font(.system(size: 11, weight: .black)).tracking(1).foregroundStyle(accent)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(accent.opacity(0.12)).clipShape(Capsule())
                .overlay(Capsule().stroke(accent.opacity(0.30), lineWidth: 1))
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Floating Item Panel

    @ViewBuilder
    private func itemPanel(_ sel: ItemSelection) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(.gray.opacity(0.30)).frame(width: 36, height: 4).padding(.top, 10)
            switch sel {
            case .inventory(let card): inventoryPanel(card)
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
                    Rectangle().fill(panelAccent(sel).opacity(0.22)).frame(height: 2)
                }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 20)
        .padding(.horizontal, 8).padding(.bottom, 8)
        .allowsHitTesting(true)
        .onTapGesture {}
    }

    private func inventoryPanel(_ card: Card) -> some View {
        let canEquip = hero.meetsRequirements(for: card)
        return HStack(alignment: .top, spacing: 14) {
            Text(card.equipmentSlot?.icon ?? "🎒").font(.system(size: 36))
                .shadow(color: card.rarity.color.opacity(0.6), radius: 6)
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(card.name).font(.system(size: 15, weight: .bold))
                        .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                    rarityBadge(card)
                }
                cardStatLines(card).lineLimit(3)
                if let reqs = card.requirements, !reqs.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: canEquip ? "checkmark.circle.fill" : "lock.fill")
                            .font(.system(size: 9)).foregroundStyle(canEquip ? .green : .red.opacity(0.85))
                        Text("Requires \(reqs.description)").font(.system(size: 10, weight: .bold))
                            .foregroundStyle(canEquip ? .green.opacity(0.8)
                                             : Color(red: 1.0, green: 0.35, blue: 0.35))
                    }
                }
                if let fl = card.flavorText {
                    Text(fl).font(.system(size: 10)).foregroundStyle(.gray.opacity(0.55))
                        .italic()
                }
            }
            Spacer()
            VStack(spacing: 8) {
                Button { engine.equipFromInventory(card); selection = nil } label: {
                    Text("EQUIP").font(.system(size: 12, weight: .black))
                        .foregroundStyle(canEquip ? .black : .gray.opacity(0.5))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(canEquip
                                    ? AnyShapeStyle(card.rarity.color)
                                    : AnyShapeStyle(Color.white.opacity(0.07)))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain).disabled(!canEquip)
                Button { confirmDrop = true } label: {
                    Image(systemName: "trash").font(.system(size: 13)).foregroundStyle(.gray)
                        .padding(8).background(Color.white.opacity(0.07)).clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func equippedPanel(slot: EquipmentSlot, card: Card) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(card.equipmentSlot?.icon ?? "🎒").font(.system(size: 36))
                .shadow(color: card.rarity.color.opacity(0.6), radius: 6)
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(card.name).font(.system(size: 15, weight: .bold))
                        .foregroundStyle(card.isUnique ? card.rarity.color : .white)
                    rarityBadge(card)
                }
                Text("Equipped in \(slot.rawValue)").font(.system(size: 10)).foregroundStyle(.gray.opacity(0.5))
                cardStatLines(card).lineLimit(3)
            }
            Spacer()
            Button { engine.unequipToInventory(slot); selection = nil } label: {
                VStack(spacing: 3) {
                    Image(systemName: "arrow.down.to.line").font(.system(size: 14))
                    Text("UNEQUIP").font(.system(size: 9, weight: .black)).tracking(1)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }

    private func panelAccent(_ sel: ItemSelection) -> Color {
        switch sel {
        case .inventory(let c): return c.rarity.color
        case .equipped(let s):  return hero.equipment.equipped(in: s)?.rarity.color ?? .gray
        }
    }

    // MARK: - Shared helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .black)).foregroundStyle(.gray.opacity(0.45)).tracking(3)
            .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 20)
    }

    private var profileDivider: some View {
        Divider().background(.white.opacity(0.08)).padding(.horizontal, 24).padding(.vertical, 14)
    }

    private func rarityBadge(_ card: Card) -> some View {
        Text(card.rarity.rawValue.uppercased())
            .font(.system(size: 7, weight: .black)).foregroundStyle(card.rarity.color.opacity(0.9)).tracking(2)
            .padding(.horizontal, 4).padding(.vertical, 2)
            .background(card.rarity.color.opacity(0.12)).clipShape(Capsule())
    }

    @ViewBuilder
    private func cardStatLines(_ card: Card) -> some View {
        if !card.modifiers.isEmpty {
            Text(card.modifiers.map(\.label).joined(separator: "  ·  "))
                .font(.system(size: 11)).foregroundStyle(Color(red: 0.5, green: 0.9, blue: 0.5))
        } else if let bonus = card.statBonus, !bonus.description.isEmpty {
            Text(bonus.description.components(separatedBy: "\n").joined(separator: "  ·  "))
                .font(.system(size: 11)).foregroundStyle(.green.opacity(0.8))
        }
    }
}

// MARK: - Card Detail Sheet

struct CardDetailSheet: View {
    let card: Card
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(red: 0.07, green: 0.04, blue: 0.14).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle().fill(card.rarity.color.opacity(0.18)).frame(width: 44, height: 44)
                            Text(card.effect.damageType.icon).font(.system(size: 22))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.name)
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(card.rarity == .common ? .white : card.rarity.color)
                            HStack(spacing: 6) {
                                // Cost
                                HStack(spacing: 3) {
                                    Image(systemName: "bolt.fill").font(.system(size: 9))
                                    Text("\(card.cost) Energy")
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.yellow.opacity(0.8))
                                // Rarity
                                if card.rarity != .common {
                                    Text(card.rarity.rawValue.uppercased())
                                        .font(.system(size: 8, weight: .black)).tracking(1.5)
                                        .foregroundStyle(card.rarity.color.opacity(0.9))
                                        .padding(.horizontal, 5).padding(.vertical, 2)
                                        .background(card.rarity.color.opacity(0.15)).clipShape(Capsule())
                                }
                                // Type
                                Text(card.type.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .black)).tracking(1)
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                        Spacer()
                    }

                    Divider().background(.white.opacity(0.08))

                    // Description
                    Text(card.description)
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Modifiers
                    if !card.modifiers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(card.modifiers, id: \.label) { mod in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("·").foregroundStyle(card.rarity.color)
                                    Text(mod.label).font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                        }
                    }

                    // Stat bonus
                    if let bonus = card.statBonus, !bonus.description.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PASSIVE BONUS")
                                .font(.system(size: 9, weight: .black)).tracking(1.5)
                                .foregroundStyle(.white.opacity(0.3))
                            ForEach(bonus.description.components(separatedBy: "\n"), id: \.self) { line in
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 10)).foregroundStyle(.green.opacity(0.7))
                                    Text(line).font(.system(size: 13))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                        }
                    }

                    // Requirements
                    if let reqs = card.requirements, !reqs.isEmpty {
                        HStack(spacing: 5) {
                            Image(systemName: "lock.fill").font(.system(size: 10))
                                .foregroundStyle(.orange.opacity(0.7))
                            Text("Requires \(reqs.description)")
                                .font(.system(size: 12)).foregroundStyle(.orange.opacity(0.8))
                        }
                    }

                    // Flavor text
                    if let fl = card.flavorText {
                        Divider().background(.white.opacity(0.06))
                        Text(fl)
                            .font(.system(size: 13)).italic()
                            .foregroundStyle(.gray.opacity(0.55))
                            .lineSpacing(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(24)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    return CharacterProfileView(engine: engine)
}
