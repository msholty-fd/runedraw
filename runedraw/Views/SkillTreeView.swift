import SwiftUI

struct SkillTreeView: View {
    let engine: GameEngine
    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }
    private var tree: [SkillNode] { SkillDatabase.tree(for: hero.heroClass) }

    @State private var selectedNode: SkillNode? = nil

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
        .sheet(item: $selectedNode) { node in
            SkillNodeDetailSheet(
                node: node,
                isUnlocked: hero.unlockedSkills.contains(node.id),
                isAvailable: isAvailable(node),
                hasPoints: hero.skillPoints >= node.cost,
                branchColor: SkillDatabase.branchColor(node.branch),
                onUnlock: {
                    engine.unlockSkill(node.id)
                    selectedNode = nil
                }
            )
        }
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

    // MARK: - 3-Column Grid (4 tiers)

    var treeGrid: some View {
        let branches   = hero.heroClass.skillBranchNames
        let branchIcons = hero.heroClass.skillBranchIcons
        let tiers = [1, 2, 3, 4]

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
                                onUnlock: { engine.unlockSkill(node.id) },
                                onTap: { selectedNode = node }
                            )
                        }
                        if tier < 4 {
                            connector(branch: branch, fromTier: tier)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func connector(branch: Int, fromTier: Int) -> some View {
        let nodeId  = tree.first(where: { $0.branch == branch && $0.tier == fromTier })?.id ?? ""
        let isActive = hero.unlockedSkills.contains(nodeId)

        VStack(spacing: 0) {
            Rectangle()
                .fill(isActive
                      ? SkillDatabase.branchColor(branch).opacity(0.6)
                      : Color.white.opacity(0.07))
                .frame(width: 2, height: 12)
            Image(systemName: "chevron.down")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isActive
                                 ? SkillDatabase.branchColor(branch).opacity(0.7)
                                 : Color.white.opacity(0.1))
            Rectangle()
                .fill(isActive
                      ? SkillDatabase.branchColor(branch).opacity(0.6)
                      : Color.white.opacity(0.07))
                .frame(width: 2, height: 12)
        }
    }

    func isAvailable(_ node: SkillNode) -> Bool {
        guard !hero.unlockedSkills.contains(node.id) else { return false }
        if let reqId = node.requiresId {
            return hero.unlockedSkills.contains(reqId)
        }
        return true
    }
}

// MARK: - Skill Node Tile (compact — tap to read full description)

struct SkillNodeTile: View {
    let node: SkillNode
    let isUnlocked: Bool
    let isAvailable: Bool
    let hasPoints: Bool
    let branchColor: Color
    let onUnlock: () -> Void
    let onTap: () -> Void

    @State private var pulse = false

    private var canUnlock: Bool { isAvailable && hasPoints }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
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

                    if !isUnlocked && !isAvailable {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.3))
                            .offset(x: 10, y: 10)
                    }
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

                // Mechanic summary (always visible, compact)
                if !node.mechanic.summary.isEmpty {
                    Text(node.mechanic.summary)
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundStyle(isUnlocked
                                         ? branchColor
                                         : (isAvailable ? branchColor.opacity(0.8) : .gray.opacity(0.25)))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Description — 2 lines max with "tap to read" hint when truncated
                Text(node.description)
                    .font(.system(size: 8))
                    .foregroundStyle(isUnlocked
                                     ? .gray.opacity(0.6)
                                     : (isAvailable ? .gray.opacity(0.6) : .gray.opacity(0.2)))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("tap to read more")
                    .font(.system(size: 7))
                    .foregroundStyle(isAvailable ? branchColor.opacity(0.5) : .gray.opacity(0.15))
                    .tracking(0.5)

                // Action button
                if isUnlocked {
                    Text("✓ ACTIVE")
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
        }
        .buttonStyle(.plain)
        .onAppear { if canUnlock { pulse = true } }
        .onChange(of: canUnlock) { _, new in pulse = new }
    }
}

// MARK: - Skill Node Detail Sheet (full description, no truncation)

struct SkillNodeDetailSheet: View {
    let node: SkillNode
    let isUnlocked: Bool
    let isAvailable: Bool
    let hasPoints: Bool
    let branchColor: Color
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    private var canUnlock: Bool { isAvailable && hasPoints }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.03, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 0) {
                DismissHandle(tint: branchColor)

                ScrollView {
                    VStack(spacing: 20) {
                        // Icon + name
                        VStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(branchColor.opacity(0.15))
                                    .frame(width: 80, height: 80)
                                Text(node.icon).font(.system(size: 44))
                                if isUnlocked {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(branchColor)
                                        .offset(x: 22, y: -22)
                                }
                            }

                            Text(node.name)
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 6) {
                                Text("TIER \(node.tier)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(branchColor.opacity(0.7))
                                    .tracking(1.5)
                                Text("·")
                                    .foregroundStyle(.gray.opacity(0.4))
                                Text("\(node.cost) SKILL PT\(node.cost == 1 ? "" : "S")")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .tracking(1.5)
                            }
                        }
                        .padding(.top, 8)

                        // Mechanic stats
                        if !node.mechanic.summary.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("BONUSES")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(branchColor.opacity(0.6))
                                    .tracking(2)

                                let parts = node.mechanic.summary.components(separatedBy: " · ")
                                ForEach(parts, id: \.self) { part in
                                    HStack(spacing: 8) {
                                        Circle()
                                            .fill(branchColor)
                                            .frame(width: 4, height: 4)
                                        Text(part)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(branchColor)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(branchColor.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(branchColor.opacity(0.25), lineWidth: 1)
                                    )
                            )
                        }

                        // Full description — no line limit
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.gray.opacity(0.5))
                                .tracking(2)

                            Text(node.description)
                                .font(.system(size: 15))
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Flavor text
                        if !node.flavorText.isEmpty {
                            Text(node.flavorText)
                                .font(.system(size: 13))
                                .foregroundStyle(.gray.opacity(0.55))
                                .italic()
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                        }

                        // Prerequisite info
                        if let reqId = node.requiresId {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.gray.opacity(0.4))
                                Text("Requires: \(reqId.replacingOccurrences(of: "_", with: " ").uppercased())")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.gray.opacity(0.4))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }

                // Action area
                VStack(spacing: 10) {
                    Divider().background(.white.opacity(0.08))

                    if isUnlocked {
                        Label("Skill Active", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(branchColor)
                            .padding(.vertical, 14)
                    } else if isAvailable {
                        Button(action: onUnlock) {
                            Text(canUnlock ? "UNLOCK — \(node.cost) SKILL PT" : "NOT ENOUGH SKILL POINTS")
                                .font(.system(size: 14, weight: .black))
                                .tracking(0.5)
                                .foregroundStyle(canUnlock ? .black : .gray.opacity(0.5))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    canUnlock
                                    ? AnyShapeStyle(branchColor)
                                    : AnyShapeStyle(Color.white.opacity(0.06))
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canUnlock)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                    } else {
                        Text("🔒 Unlock the previous tier first")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray.opacity(0.5))
                            .padding(.vertical, 14)
                    }
                }
                .background(Color.black.opacity(0.4))
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(red: 0.05, green: 0.03, blue: 0.10))
    }
}

// MARK: - SkillNode: Identifiable for sheet(item:)
extension SkillNode: @retroactive Hashable {
    public static func == (lhs: SkillNode, rhs: SkillNode) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    engine.hero?.skillPoints = 3
    return SkillTreeView(engine: engine)
}
