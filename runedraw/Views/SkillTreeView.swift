import SwiftUI

struct SkillTreeView: View {
    let engine: GameEngine
    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }
    private var tree: [SkillNode] { SkillDatabase.tree(for: hero.heroClass) }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.03, blue: 0.08).ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.15, green: 0.05, blue: 0.3).opacity(0.5), .clear],
                center: .init(x: 0.5, y: 0.3), startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                DismissHandle(tint: Color(red: 0.6, green: 0.3, blue: 1.0))
                treeHeader
                Divider().background(.purple.opacity(0.2))
                ScrollView {
                    treeGrid
                        .padding(.horizontal, 12)
                        .padding(.vertical, 20)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(red: 0.04, green: 0.03, blue: 0.08))
    }

    // MARK: - Header

    var treeHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("SKILL TREE")
                    .font(.system(size: 11, weight: .black)).foregroundStyle(.gray.opacity(0.6)).tracking(3)
                Text(hero.heroClass.rawValue.uppercased())
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
            }
            Spacer()
            // Skill points badge
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(hero.skillPoints)")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(hero.skillPoints > 0
                                     ? Color(red: 0.8, green: 0.6, blue: 1.0)
                                     : .gray.opacity(0.4))
                Text(hero.skillPoints == 1 ? "point to spend" : "points to spend")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.5))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - 3-Column Grid

    var treeGrid: some View {
        let branches = hero.heroClass.skillBranchNames
        let branchIcons = hero.heroClass.skillBranchIcons
        let tiers = [1, 2, 3]

        return HStack(alignment: .top, spacing: 8) {
            ForEach(0..<3, id: \.self) { branch in
                VStack(spacing: 0) {
                    // Branch header
                    VStack(spacing: 3) {
                        Text(branchIcons[branch]).font(.system(size: 22))
                        Text(branches[branch].uppercased())
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(SkillDatabase.branchColor(branch).opacity(0.8))
                            .tracking(2)
                    }
                    .padding(.bottom, 12)

                    // Tier nodes with connectors
                    ForEach(tiers, id: \.self) { tier in
                        if let node = tree.first(where: { $0.branch == branch && $0.tier == tier }) {
                            SkillNodeTile(
                                node: node,
                                isUnlocked: hero.unlockedSkills.contains(node.id),
                                isAvailable: isAvailable(node),
                                hasPoints: hero.skillPoints >= node.cost,
                                branchColor: SkillDatabase.branchColor(branch),
                                previewCard: SkillDatabase.card(for: node.id),
                                onUnlock: { engine.unlockSkill(node.id) }
                            )
                        }
                        // Connector arrow between tiers (not after last tier)
                        if tier < 3 {
                            connector(branch: branch, fromTier: tier)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func connector(branch: Int, fromTier: Int) -> some View {
        let nodeId = tree.first(where: { $0.branch == branch && $0.tier == fromTier })?.id ?? ""
        let nextId = tree.first(where: { $0.branch == branch && $0.tier == fromTier + 1 })?.id ?? ""
        let isActive = hero.unlockedSkills.contains(nodeId)
        let nextUnlocked = hero.unlockedSkills.contains(nextId)

        VStack(spacing: 0) {
            Rectangle()
                .fill(isActive
                      ? SkillDatabase.branchColor(branch).opacity(0.6)
                      : Color.white.opacity(0.07))
                .frame(width: 2, height: 12)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isActive || nextUnlocked
                                 ? SkillDatabase.branchColor(branch).opacity(0.7)
                                 : Color.white.opacity(0.1))
            Rectangle()
                .fill(isActive
                      ? SkillDatabase.branchColor(branch).opacity(0.6)
                      : Color.white.opacity(0.07))
                .frame(width: 2, height: 12)
        }
    }

    // MARK: - Availability check

    func isAvailable(_ node: SkillNode) -> Bool {
        guard !hero.unlockedSkills.contains(node.id) else { return false }
        if let reqId = node.requiresId {
            return hero.unlockedSkills.contains(reqId)
        }
        return true // T1 nodes always available
    }
}

// MARK: - Skill Node Tile

private struct SkillNodeTile: View {
    let node: SkillNode
    let isUnlocked: Bool
    let isAvailable: Bool
    let hasPoints: Bool
    let branchColor: Color
    let previewCard: Card
    let onUnlock: () -> Void

    @State private var pulse = false

    private var canUnlock: Bool { isAvailable && hasPoints }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Glow behind icon when available
                if canUnlock {
                    Circle()
                        .fill(branchColor.opacity(pulse ? 0.25 : 0.1))
                        .frame(width: 52, height: 52)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                }
                Text(node.icon)
                    .font(.system(size: isUnlocked ? 28 : 24))
                    .opacity(isUnlocked ? 1.0 : (isAvailable ? 0.9 : 0.3))
                    .saturation(isUnlocked ? 1.0 : (isAvailable ? 0.8 : 0.0))

                // Lock overlay
                if !isUnlocked && !isAvailable {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.3))
                        .offset(x: 10, y: 10)
                }

                // Checkmark overlay when unlocked
                if isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(branchColor)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 44, height: 44)

            Text(node.name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(isUnlocked ? branchColor : (isAvailable ? .white : .gray.opacity(0.35)))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(node.description)
                .font(.system(size: 8))
                .foregroundStyle(isUnlocked
                                 ? branchColor.opacity(0.7)
                                 : (isAvailable ? .gray.opacity(0.7) : .gray.opacity(0.25)))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            // Action
            if isUnlocked {
                Text("✓ IN DECK")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(branchColor.opacity(0.7))
                    .tracking(1)
            } else if isAvailable {
                Button(action: onUnlock) {
                    Text(hasPoints ? "UNLOCK" : "NO PTS")
                        .font(.system(size: 9, weight: .black)).tracking(1)
                        .foregroundStyle(canUnlock ? .black : .gray.opacity(0.5))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(
                            canUnlock
                            ? AnyShapeStyle(branchColor)
                            : AnyShapeStyle(Color.white.opacity(0.06))
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!canUnlock)
            } else {
                Text("LOCKED")
                    .font(.system(size: 8, weight: .black))
                    .foregroundStyle(.gray.opacity(0.2))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 4).padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked
                      ? branchColor.opacity(0.1)
                      : (isAvailable ? Color.white.opacity(0.04) : Color.white.opacity(0.02)))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked
                                ? branchColor.opacity(0.5)
                                : (canUnlock ? branchColor.opacity(0.35) : Color.white.opacity(0.06)),
                                lineWidth: isUnlocked ? 1.5 : 1)
                )
        )
        .onAppear { if canUnlock { pulse = true } }
        .onChange(of: canUnlock) { _, new in pulse = new }
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    engine.hero?.skillPoints = 3
    return SkillTreeView(engine: engine)
}
