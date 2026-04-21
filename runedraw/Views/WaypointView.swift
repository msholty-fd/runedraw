import SwiftUI

struct WaypointView: View {
    let engine: GameEngine
    @Environment(\.dismiss) private var dismiss

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }
    private var unlockedSet: Set<Int> { Set(hero.unlockedWaypoints) }

    var body: some View {
        ZStack {
            Color(red: 0.03, green: 0.06, blue: 0.14).ignoresSafeArea()

            // Faint radial glow
            RadialGradient(
                colors: [Color(red: 0.1, green: 0.4, blue: 0.8).opacity(0.3), .clear],
                center: .init(x: 0.5, y: 0.25), startRadius: 0, endRadius: 420
            )
            .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                DismissHandle(tint: Color(red: 0.3, green: 0.7, blue: 1.0))
                header
                Divider().background(Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.3))
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(AreaDatabase.act1, id: \.index) { def in
                            WaypointRow(
                                definition: def,
                                isUnlocked: unlockedSet.contains(def.index),
                                isCurrent: engine.currentAreaIndex == def.index,
                                onTravel: {
                                    engine.travelToWaypoint(def.index)
                                    dismiss()
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Color(red: 0.03, green: 0.06, blue: 0.14))
    }

    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("WAYPOINTS")
                    .font(.system(size: 11, weight: .black)).foregroundStyle(.gray.opacity(0.6)).tracking(3)
                Text("Act I — Ashenveil")
                    .font(.system(size: 20, weight: .black)).foregroundStyle(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(hero.unlockedWaypoints.count)/\(AreaDatabase.totalAreas)")
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Color(red: 0.3, green: 0.8, blue: 1.0))
                Text("discovered")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.5))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 14)
        .background(Color.black.opacity(0.35))
    }
}

// MARK: - Waypoint Row

private struct WaypointRow: View {
    let definition: AreaDefinition
    let isUnlocked: Bool
    let isCurrent: Bool
    let onTravel: () -> Void

    @State private var pulse = false

    var body: some View {
        HStack(spacing: 14) {
            // Area icon in circle
            ZStack {
                Circle()
                    .fill(isUnlocked
                          ? Color(red: 0.15, green: 0.45, blue: 0.85).opacity(pulse ? 0.35 : 0.18)
                          : Color.white.opacity(0.05))
                    .frame(width: 50, height: 50)
                    .scaleEffect(pulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: pulse)
                Text(isUnlocked ? definition.icon : "🔒")
                    .font(.system(size: 24))
                    .opacity(isUnlocked ? 1.0 : 0.3)
                    .saturation(isUnlocked ? 1.0 : 0.0)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text("AREA \(definition.index)")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(isUnlocked
                                         ? Color(red: 0.3, green: 0.75, blue: 1.0).opacity(0.7)
                                         : .gray.opacity(0.3))
                        .tracking(2)
                    if isCurrent {
                        Text("CURRENT")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                            .tracking(2)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(definition.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isUnlocked ? .white : .gray.opacity(0.3))
                Text(definition.description)
                    .font(.system(size: 11))
                    .foregroundStyle(isUnlocked ? .gray.opacity(0.55) : .gray.opacity(0.2))
                    .lineLimit(1)
            }

            Spacer()

            // Travel button
            if isUnlocked {
                Button(action: onTravel) {
                    VStack(spacing: 2) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.3, green: 0.75, blue: 1.0))
                        Text("TRAVEL")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(Color(red: 0.3, green: 0.75, blue: 1.0).opacity(0.7))
                            .tracking(1)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("LOCKED")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(.gray.opacity(0.2))
                    .tracking(2)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked
                      ? (isCurrent
                         ? Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.06)
                         : Color(red: 0.1, green: 0.25, blue: 0.5).opacity(0.15))
                      : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isUnlocked
                                ? (isCurrent
                                   ? Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.35)
                                   : Color(red: 0.2, green: 0.5, blue: 0.9).opacity(0.25))
                                : Color.white.opacity(0.05),
                                lineWidth: 1)
                )
        )
        .onAppear { if isUnlocked && !isCurrent { pulse = true } }
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    engine.hero?.unlockedWaypoints = [1, 2, 3]
    engine.currentAreaIndex = 3
    return WaypointView(engine: engine)
}
