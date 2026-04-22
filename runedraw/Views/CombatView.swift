import SwiftUI

struct CombatView: View {
    let engine: GameEngine
    @State private var heroFlash = false
    @State private var showLevelUp = false
    @State private var levelText = ""
    @State private var energyPulse = false

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
        .onChange(of: hero.currentHp) { old, new in
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
        .onChange(of: hero.hand.count) { old, new in
            if new > old { SoundManager.cardDraw() }
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
            HStack(spacing: 5) {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.red).font(.system(size: 12))
                Text("\(hero.currentHp)/\(hero.maxHp)")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.3), value: hero.currentHp)
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
                        CardView(
                            card: card,
                            isPlayable: engine.canPlay(card)
                        ) {
                            guard engine.canPlay(card) else { return }
                            SoundManager.cardPlay()
                            engine.play(card, targeting: 0)
                        }
                        .padding(.vertical, 6)
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.5).combined(with: .opacity)
                        ))
                    }
                }
            }
            .padding(.horizontal, 16)
            .animation(.spring(response: 0.32, dampingFraction: 0.72), value: hero.hand.map(\.id))
        }
    }

    // MARK: - End Turn / Confirm Blocks

    var endTurnButton: some View {
        Group {
            if engine.isBlockPhase {
                blockPhaseControls
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

    private func logColor(for line: String) -> Color {
        if line.contains("──")       { return .gray }
        if line.contains("Victory")  { return .yellow }
        if line.contains("Defeated") { return .red }
        if line.contains("Healed")   { return .green }
        if line.contains("block")    { return .cyan }
        if line.contains("poison")   { return Color(red: 0.4, green: 0.9, blue: 0.4) }
        return .gray.opacity(0.7)
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
        .onChange(of: enemy.currentHp) { old, new in
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
                                .animation(.easeOut(duration: 0.4), value: enemy.currentHp)
                        }
                    }
                    .frame(height: 5)

                    Text("\(enemy.currentHp)/\(enemy.maxHp)")
                        .font(.system(size: 11)).foregroundStyle(.gray)
                        .frame(width: 55, alignment: .trailing)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.3), value: enemy.currentHp)
                }

                HStack(spacing: 6) {
                    if enemy.block > 0 {
                        StatusPill(icon: "🛡️", label: "\(enemy.block)", color: .cyan)
                    }
                    if enemy.poisonStacks > 0 {
                        StatusPill(icon: "☠️", label: "\(enemy.poisonStacks)", color: .green)
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
        guard enemy.maxHp > 0 else { return 0 }
        return CGFloat(enemy.currentHp) / CGFloat(enemy.maxHp)
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
