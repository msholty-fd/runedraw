import SwiftUI

struct CombatView: View {
    let engine: GameEngine
    @State private var heroFlash = false
    @State private var showLevelUp = false
    @State private var levelText = ""
    @State private var energyPulse = false
    /// Cards that have completed their deal-in animation and are fully visible.
    @State private var revealedCardIDs: Set<UUID> = []
    /// Current impact effect shown over the enemy section.
    @State private var combatEffect: CombatEffectData? = nil
    /// Whether the discard pile sheet is showing.
    @State private var showingDiscard: Bool = false

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.02, blue: 0.10), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                enemySection
                    .frame(maxHeight: .infinity)

                Divider().background(.gray.opacity(0.15))

                combatLogView
                    .frame(maxHeight: .infinity)

                Divider().background(.gray.opacity(0.15))

                if engine.isBlockPhase {
                    HStack(spacing: 6) {
                        Text("🛡️").font(.system(size: 14))
                        Text("BLOCK PHASE — tap cards to block incoming attacks")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.cyan)
                            .tracking(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.0, green: 0.25, blue: 0.35).opacity(0.8))
                }

                heroStatusRow
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.4))

                Divider().background(.gray.opacity(0.15))

                if !engine.playedCards.isEmpty && !engine.isBlockPhase {
                    playedCardsTray
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.3))
                }

                deckStatusBar
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                if engine.stagedCardID != nil {
                    pitchStatusBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.12, green: 0.10, blue: 0.06).opacity(0.9))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                handSection
                    .frame(height: 174)

                endTurnButton
                    .padding(.bottom, 24)
            }

            // Hero damage flash — red vignette at screen edges
            if heroFlash {
                RadialGradient(
                    colors: [.clear, Color.red.opacity(0.55)],
                    center: .center,
                    startRadius: 120,
                    endRadius: 420
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Impact effect — floats over the enemy section
            if let effect = combatEffect {
                VStack {
                    Spacer().frame(height: 80)   // push into the enemy area
                    CombatEffectView(data: effect)
                        .id(effect.id)           // new ID = new view = fresh animation
                    Spacer()
                }
                .allowsHitTesting(false)
                .transition(.opacity)
            }

            // Level up banner
            if showLevelUp {
                VStack {
                    Text(levelText)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
                        .tracking(2)
                        .shadow(color: .orange.opacity(0.8), radius: 10)
                        .padding(.horizontal, 24).padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.88))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            Color(red: 1.0, green: 0.75, blue: 0.2).opacity(0.6),
                                            lineWidth: 1.5
                                        )
                                )
                        )
                        .padding(.top, 60)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(20)
                .allowsHitTesting(false)
            }

        }
        .onChange(of: hero.totalCardPool) { old, new in
            if new < old {
                SoundManager.heroHit()
                withAnimation(.easeIn(duration: 0.08)) { heroFlash = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeOut(duration: 0.3)) { heroFlash = false }
                }
            }
        }
        .onChange(of: hero.level) { _, new in
            SoundManager.levelUp()
            levelText = "⬆️  LEVEL \(new)!"
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showLevelUp = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                withAnimation(.easeOut(duration: 0.4)) { showLevelUp = false }
            }
        }
        .onAppear { revealNewCards() }
        .onChange(of: hero.hand.map(\.id)) { old, new in
            if new.count > old.count { SoundManager.cardDraw() }
            revealNewCards()
        }
        .sheet(isPresented: $showingDiscard) {
            DiscardPileSheet(cards: hero.discardPile)
        }
    }

    // MARK: - Enemy Section

    var enemySection: some View {
        ScrollView {
            VStack(spacing: 10) {
                Spacer().frame(height: 12)
                ForEach(engine.currentEnemies) { enemy in
                    EnemyRow(
                        enemy: enemy,
                        isBoss: engine.currentRoomIsBoss,
                        isElite: engine.currentRoomIsElite
                    )
                    .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .scale(scale: 0.6).combined(with: .opacity)
                        ))
                }
                Spacer()
            }
            .padding(.horizontal)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.75),
                value: engine.currentEnemies.map(\.id)
            )
        }
    }

    // MARK: - Hero Status

    var heroStatusRow: some View {
        HStack(spacing: 0) {
            // Cards remaining (deck + hand + discard)
            HStack(spacing: 5) {
                Image(systemName: "rectangle.stack.fill")
                    .foregroundStyle(.white).font(.system(size: 12))
                Text("\(hero.totalCardPool)")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: hero.totalCardPool)
            }

            // Exiled cards (damage taken)
            if !hero.exiledCards.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.red.opacity(0.7)).font(.system(size: 12))
                    Text("\(hero.exiledCards.count)").font(.system(size: 13, weight: .bold)).foregroundStyle(.red.opacity(0.7))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: hero.exiledCards.count)
                }
                .padding(.leading, 12)
            }

            if hero.block > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill").foregroundStyle(.cyan).font(.system(size: 12))
                    Text("\(hero.block)").font(.system(size: 13, weight: .bold)).foregroundStyle(.cyan)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: hero.block)
                }
                .padding(.leading, 12)
            }

            if hero.poisonStacks > 0 {
                HStack(spacing: 3) {
                    Text("☠️").font(.system(size: 12))
                    Text("\(hero.poisonStacks)").font(.system(size: 12, weight: .bold)).foregroundStyle(.green)
                }
                .padding(.leading, 10)
            }

            if hero.weakStacks > 0 {
                Text("💀 \(hero.weakStacks)").font(.system(size: 11, weight: .bold)).foregroundStyle(.yellow)
                    .padding(.leading, 10)
            }

            if hero.combatStrength > 0 {
                HStack(spacing: 3) {
                    Text("⚔️").font(.system(size: 11))
                    Text("+\(hero.combatStrength)").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.45, blue: 0.2))
                }
                .padding(.leading, 10)
            }

            if engine.combatEvasionCharges > 0 {
                HStack(spacing: 3) {
                    Text("💨").font(.system(size: 11))
                    Text("×\(engine.combatEvasionCharges)").font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(red: 0.4, green: 0.9, blue: 0.6))
                }
                .padding(.leading, 10)
            }

            Spacer()

            HStack(spacing: 5) {
                Text("ENERGY").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray).tracking(2)
                HStack(spacing: 4) {
                    ForEach(0..<hero.maxEnergy, id: \.self) { index in
                        Circle()
                            .fill(index < hero.currentEnergy
                                  ? Color(red: 0.2, green: 0.5, blue: 1.0)
                                  : Color.gray.opacity(0.25))
                            .frame(width: 13, height: 13)
                            .scaleEffect(index < hero.currentEnergy && energyPulse ? 1.4 : 1.0)
                            .animation(
                                .spring(response: 0.3, dampingFraction: 0.45)
                                    .delay(Double(index) * 0.07),
                                value: energyPulse
                            )
                    }
                }
            }
        }
        .onChange(of: hero.currentEnergy) { old, new in
            if new > old {
                energyPulse = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { energyPulse = false }
            }
        }
    }

    // MARK: - Hand

    var handSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(hero.hand) { card in
                    if engine.isBlockPhase {
                        BlockCardView(
                            card: card,
                            isCommitted: engine.committedBlockIDs.contains(card.id)
                        ) {
                            SoundManager.cardPlay()
                            engine.toggleBlock(card)
                        }
                        .padding(.vertical, 6)
                    } else {
                        let isRevealed  = revealedCardIDs.contains(card.id)
                        let isStaged    = engine.stagedCardID == card.id
                        let isPitched   = engine.pitchedForStagedIDs.contains(card.id)
                        let canPlay     = engine.canPlay(card)

                        CardView(card: card,
                                 isPlayable: canPlay || isPitched,
                                 isSelected: isStaged,
                                 isPitched: isPitched) {
                            SoundManager.cardPlay()
                            engine.handleCardTap(card, targeting: 0)
                            // Impact animation fires when a damage card actually plays.
                            if isStaged && engine.pitchCostMet {
                                let fx = card.effect
                                if fx.damage > 0 || fx.damageFromBlock {
                                    combatEffect = CombatEffectData(damageType: fx.damageType, targetIndex: 0)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                        combatEffect = nil
                                    }
                                }
                            } else if card.cost == 0 && engine.stagedCardID == nil {
                                let fx = card.effect
                                if fx.damage > 0 || fx.damageFromBlock {
                                    combatEffect = CombatEffectData(damageType: fx.damageType, targetIndex: 0)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                                        combatEffect = nil
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        // Deal-in stagger: cards rise from below into place.
                        .offset(y: isRevealed ? 0 : 90)
                        .opacity(isRevealed ? 1.0 : 0.0)
                        .animation(.spring(response: 0.40, dampingFraction: 0.74),
                                   value: isRevealed)
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: hero.hand.map(\.id))
        }
    }

    /// Stagger newly-drawn cards into `revealedCardIDs` one at a time.
    private func revealNewCards() {
        let currentIDs = Set(hero.hand.map(\.id))
        // Drop IDs for cards no longer in hand.
        revealedCardIDs = revealedCardIDs.intersection(currentIDs)
        // Find cards added since last reveal cycle, preserving hand order.
        let toReveal = hero.hand.map(\.id).filter { !revealedCardIDs.contains($0) }
        for (i, id) in toReveal.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.09) {
                withAnimation(.spring(response: 0.40, dampingFraction: 0.72)) {
                    _ = revealedCardIDs.insert(id)
                }
            }
        }
    }

    // MARK: - End Turn / Confirm Blocks

    var endTurnButton: some View {
        Group {
            if engine.isBlockPhase {
                blockPhaseControls
            } else if engine.stagedCardID != nil {
                // Staging mode: show Cancel and (if cost met) Confirm
                HStack(spacing: 12) {
                    Button {
                        SoundManager.buttonTap()
                        engine.cancelStage()
                    } label: {
                        Text("CANCEL")
                            .font(.system(size: 13, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: 100, height: 44)
                            .background(Color.gray.opacity(0.25))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)

                    Button {
                        SoundManager.cardPlay()
                        engine.confirmStagedPlay(targeting: 0)
                    } label: {
                        Text(engine.pitchCostMet ? "PLAY ✓" : "NEED \(max(0, (engine.stagedCard?.cost ?? 0) - engine.pitchResourceAvailable)) MORE")
                            .font(.system(size: 13, weight: .black))
                            .tracking(2)
                            .foregroundStyle(engine.pitchCostMet ? .black : .white.opacity(0.5))
                            .frame(width: 140, height: 44)
                            .background(engine.pitchCostMet
                                ? LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.6, blue: 0.1),
                                             Color(red: 0.7, green: 0.35, blue: 0.0)],
                                    startPoint: .top, endPoint: .bottom)
                                : LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                                    startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .disabled(!engine.pitchCostMet)
                }
            } else {
                Button {
                    SoundManager.buttonTap()
                    engine.endTurn()
                } label: {
                    Text("END TURN")
                        .font(.system(size: 14, weight: .black))
                        .tracking(4)
                        .foregroundStyle(.black)
                        .frame(width: 160, height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                                         Color(red: 0.7, green: 0.5, blue: 0.1)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Block Phase Controls

    var blockPhaseControls: some View {
        let totalIncoming = engine.pendingAttacks.map(\.rawDamage).reduce(0, +)
        let committed = hero.hand.filter { engine.committedBlockIDs.contains($0.id) }
        let totalBlocked = min(committed.map(\.defenseValue).reduce(0, +), totalIncoming)
        let remaining = max(0, totalIncoming - totalBlocked)

        return VStack(spacing: 8) {
            // Incoming damage breakdown
            HStack(spacing: 16) {
                ForEach(engine.pendingAttacks) { atk in
                    HStack(spacing: 4) {
                        Text("⚔️").font(.system(size: 12))
                        Text(atk.enemyName)
                            .font(.system(size: 10)).foregroundStyle(.gray)
                        Text("\(atk.rawDamage)")
                            .font(.system(size: 13, weight: .black)).foregroundStyle(.red)
                    }
                }
            }

            // Block tally
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("INCOMING").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray).tracking(2)
                    Text("\(totalIncoming)").font(.system(size: 22, weight: .black)).foregroundStyle(.red)
                }
                Text("−").font(.system(size: 18, weight: .bold)).foregroundStyle(.gray)
                VStack(spacing: 2) {
                    Text("BLOCKED").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray).tracking(2)
                    Text("\(totalBlocked)")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(totalBlocked > 0 ? Color.cyan : Color.gray)
                }
                Text("=").font(.system(size: 18, weight: .bold)).foregroundStyle(.gray)
                VStack(spacing: 2) {
                    Text("YOU TAKE").font(.system(size: 9, weight: .bold)).foregroundStyle(.gray).tracking(2)
                    Text("\(remaining)")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(remaining == 0 ? Color.green : Color.red)
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 8)
            .background(Color.black.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.red.opacity(0.3), lineWidth: 1))

            Button {
                SoundManager.buttonTap()
                engine.confirmBlocks()
            } label: {
                Text(remaining == 0 ? "✅ FULLY BLOCKED" : "TAKE \(remaining) DAMAGE")
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
                    .foregroundStyle(remaining == 0 ? Color.black : Color.white)
                    .frame(width: 200, height: 44)
                    .background(
                        remaining == 0
                        ? AnyShapeStyle(LinearGradient(colors: [Color(red: 0.2, green: 0.9, blue: 0.4), Color(red: 0.1, green: 0.6, blue: 0.25)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(LinearGradient(colors: [Color(red: 0.75, green: 0.1, blue: 0.1), Color(red: 0.5, green: 0.05, blue: 0.05)], startPoint: .top, endPoint: .bottom))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Combat Log

    var combatLogView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(engine.combatLog.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11))
                            .foregroundStyle(logColor(for: line))
                    }
                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.black.opacity(0.35))
            .onChange(of: engine.combatLog.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    // MARK: - Deck / Discard Status Bar

    /// Compact row showing draw pile count and a tappable discard count.
    // MARK: - Pitch Status Bar

    private var pitchStatusBar: some View {
        let card    = engine.stagedCard
        let cost    = card?.cost ?? 0
        let pitched = engine.pitchResourceAvailable
        let met     = engine.pitchCostMet

        return HStack(spacing: 10) {
            // Staged card name
            HStack(spacing: 4) {
                Text("▶").font(.system(size: 10)).foregroundStyle(Color.orange)
                Text(card?.name ?? "")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Cost vs pitched resource bar
            HStack(spacing: 6) {
                Text("Cost \(cost)")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)

                // Pip row
                HStack(spacing: 3) {
                    ForEach(0..<max(cost, 1), id: \.self) { i in
                        Circle()
                            .fill(i < pitched ? Color.teal : Color.gray.opacity(0.3))
                            .frame(width: 9, height: 9)
                    }
                }

                Text("\(pitched)/\(cost)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(met ? Color.teal : .white.opacity(0.6))
            }

            if met {
                Text("READY")
                    .font(.system(size: 10, weight: .black))
                    .tracking(1)
                    .foregroundStyle(Color.teal)
            } else {
                Text("tap cards to pitch →")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray.opacity(0.6))
            }
        }
    }

    private var deckStatusBar: some View {
        HStack(spacing: 0) {
            // Draw pile
            HStack(spacing: 5) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.gray.opacity(0.5))
                Text("\(hero.deck.count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.25), value: hero.deck.count)
                Text("in deck")
                    .font(.system(size: 10))
                    .foregroundStyle(.gray.opacity(0.4))
            }

            Spacer()

            // Discard pile — tappable
            Button { showingDiscard = true } label: {
                HStack(spacing: 5) {
                    Text("discard")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray.opacity(0.4))
                    Text("\(hero.discardPile.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(hero.discardPile.isEmpty
                                         ? .gray.opacity(0.3)
                                         : Color(red: 1.0, green: 0.55, blue: 0.2))
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.25), value: hero.discardPile.count)
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(hero.discardPile.isEmpty
                                         ? .gray.opacity(0.25)
                                         : Color(red: 1.0, green: 0.55, blue: 0.2).opacity(0.8))
                }
            }
            .buttonStyle(.plain)
            .disabled(hero.discardPile.isEmpty)
        }
    }

    private func logColor(for line: String) -> Color {
        if line.contains("──")       { return .gray }
        if line.contains("Victory")  { return .yellow }
        if line.contains("Defeated") { return .red }
        if line.contains("Healed")   { return .green }
        if line.contains("block")    { return .cyan }
        if line.contains("poison")   { return Color(red: 0.4, green: 0.9, blue: 0.4) }
        return .gray.opacity(0.7)
    }

    // MARK: - Played Cards Tray

    private var playedCardsTray: some View {
        VStack(spacing: 4) {
            // Header
            HStack {
                Text("PLAYED THIS TURN")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.gray.opacity(0.5))
                    .tracking(3)
                Spacer()
            }
            .padding(.top, 6)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(engine.playedCards) { record in
                        PlayedCardTile(record: record) {
                            SoundManager.buttonTap()
                            engine.unplayCard(record)
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

}

// MARK: - Enemy Row

struct EnemyRow: View {
    let enemy: Enemy
    var isBoss: Bool = false
    var isElite: Bool = false

    @State private var shakeOffset: CGFloat = 0
    @State private var flashIntensity: Double = 0
    @State private var damageDisplay: Int? = nil
    @State private var floatOffset: CGFloat = 0
    @State private var floatOpacity: Double = 0

    var body: some View {
        ZStack {
            rowContent
                .offset(x: shakeOffset)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(flashIntensity))
                        .allowsHitTesting(false)
                )

            // Floating damage number
            if let dmg = damageDisplay {
                Text("-\(dmg)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.red)
                    .shadow(color: .red.opacity(0.7), radius: 6)
                    .offset(y: floatOffset)
                    .opacity(floatOpacity)
            }
        }
        .onChange(of: enemy.lifeCards) { old, new in
            guard new < old else { return }
            SoundManager.enemyHit()
            triggerHitEffects(amount: old - new)
        }
    }

    private var rowContent: some View {
        HStack(spacing: 14) {
            EnemyPortraitView(enemy: enemy, size: 68, isBoss: isBoss, isElite: isElite)

            VStack(alignment: .leading, spacing: 5) {
                Text(enemy.name)
                    .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)

                HStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.gray.opacity(0.25))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.red)
                                .frame(width: geo.size.width * hpFraction)
                                .animation(.easeOut(duration: 0.4), value: enemy.lifeCards)
                        }
                    }
                    .frame(height: 5)

                    Text("\(enemy.lifeCards) cards")
                        .font(.system(size: 11)).foregroundStyle(.gray)
                        .frame(width: 60, alignment: .trailing)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: enemy.lifeCards)
                }

                HStack(spacing: 6) {
                    if enemy.block > 0 {
                        StatusPill(icon: "🛡️", label: "\(enemy.block)", color: .cyan)
                    }
                    if enemy.poisonStacks > 0 {
                        StatusPill(icon: "☠️", label: "\(enemy.poisonStacks)", color: .green)
                    }
                    if enemy.burnStacks > 0 {
                        StatusPill(icon: "🔥", label: "\(enemy.burnStacks)", color: Color(red: 1.0, green: 0.45, blue: 0.1))
                    }
                    if enemy.bleedStacks > 0 {
                        StatusPill(icon: "🩸", label: "\(enemy.bleedStacks)", color: Color(red: 0.85, green: 0.1, blue: 0.2))
                    }
                    if enemy.isFrozen {
                        StatusPill(icon: "❄️", label: "FROZEN", color: Color(red: 0.4, green: 0.8, blue: 1.0))
                    } else if enemy.chillStacks > 0 {
                        StatusPill(icon: "❄️", label: "\(enemy.chillStacks)", color: Color(red: 0.6, green: 0.85, blue: 1.0))
                    }
                    if enemy.vulnerableStacks > 0 {
                        StatusPill(icon: "🎯", label: "Vuln", color: .orange)
                    }
                    if enemy.weakStacks > 0 {
                        StatusPill(icon: "💀", label: "Weak", color: .yellow)
                    }
                }
            }

            Spacer()

            VStack(spacing: 6) {
                // Intent
                VStack(spacing: 3) {
                    Text(enemy.currentIntent.icon).font(.system(size: 22))
                    Text(enemy.currentIntent.label)
                        .font(.system(size: 10, weight: .bold)).foregroundStyle(.orange)
                        .multilineTextAlignment(.center).frame(width: 60)
                }

                // Block hand — visible cards the player can plan around
                if !enemy.blockHand.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(enemy.blockHand) { card in
                            Text("\(card.defenseValue)")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.cyan)
                                .frame(width: 22, height: 22)
                                .background(Color(red: 0.0, green: 0.3, blue: 0.4).opacity(0.8))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.12, green: 0.05, blue: 0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var hpFraction: CGFloat {
        guard enemy.maxLifeCards > 0 else { return 0 }
        return CGFloat(enemy.lifeCards) / CGFloat(enemy.maxLifeCards)
    }

    private func triggerHitEffects(amount: Int) {
        // Floating number — rise and fade
        damageDisplay = amount
        floatOffset = 0
        floatOpacity = 1
        withAnimation(.easeOut(duration: 0.85)) {
            floatOffset = -60
            floatOpacity = 0
        }

        // Shake — 3-step spring
        withAnimation(.interpolatingSpring(stiffness: 600, damping: 8)) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.interpolatingSpring(stiffness: 600, damping: 8)) { shakeOffset = -7 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) {
            withAnimation(.spring()) { shakeOffset = 0 }
        }

        // Red flash
        withAnimation(.easeIn(duration: 0.05)) { flashIntensity = 0.45 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.easeOut(duration: 0.28)) { flashIntensity = 0 }
        }
    }
}

struct StatusPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(icon).font(.system(size: 10))
            Text(label).font(.system(size: 10, weight: .bold)).foregroundStyle(color)
        }
        .padding(.horizontal, 6).padding(.vertical, 2)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Played Card Tile

struct PlayedCardTile: View {
    let record: PlayedCardRecord
    let onRecall: () -> Void

    private var canRecall: Bool { record.canRecall }

    var body: some View {
        HStack(spacing: 6) {
            Text(record.card.effect.damageType.icon)
                .font(.system(size: 13))

            VStack(alignment: .leading, spacing: 1) {
                Text(record.card.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if !record.effectSummary.isEmpty {
                    Text(record.effectSummary)
                        .font(.system(size: 10))
                        .foregroundStyle(.gray.opacity(0.7))
                }
            }

            // Persistent-effects badge (draw/heal — can recall but effects stay)
            if record.hasPersistentEffects && canRecall {
                Text("~")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(.orange.opacity(0.7))
            }

            if !canRecall {
                // Damage cards: committed, can't be recalled
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.green.opacity(0.5))
            } else {
                Button(action: onRecall) {
                    Image(systemName: "arrow.uturn.left.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.4, green: 0.7, blue: 1.0))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(canRecall
                      ? Color(red: 0.12, green: 0.14, blue: 0.22)
                      : Color(red: 0.08, green: 0.12, blue: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(canRecall
                                ? Color(red: 0.3, green: 0.45, blue: 0.8).opacity(0.4)
                                : Color.green.opacity(0.2),
                                lineWidth: 1)
                )
        )
        .opacity(canRecall ? 1.0 : 0.7)
    }
}

// MARK: - Block Card View

struct BlockCardView: View {
    let card: Card
    let isCommitted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                // Defense value — the whole point during block phase
                Text("\(card.defenseValue)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(isCommitted ? Color.black : Color.cyan)

                Text("DEF").font(.system(size: 9, weight: .bold)).foregroundStyle(isCommitted ? Color.black.opacity(0.6) : Color.cyan.opacity(0.7)).tracking(2)

                Divider().background(isCommitted ? Color.black.opacity(0.3) : Color.white.opacity(0.1))

                Text(card.name)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(isCommitted ? Color.black : Color.white)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 110)
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isCommitted
                          ? AnyShapeStyle(LinearGradient(colors: [Color.cyan, Color(red: 0.0, green: 0.6, blue: 0.8)], startPoint: .top, endPoint: .bottom))
                          : AnyShapeStyle(Color(red: 0.10, green: 0.06, blue: 0.18)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isCommitted ? Color.white.opacity(0.4) : Color.cyan.opacity(0.35), lineWidth: isCommitted ? 2 : 1)
            )
            .scaleEffect(isCommitted ? 1.05 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isCommitted)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .sorceress)
    engine.enterCurrentRoom()
    return CombatView(engine: engine)
}
