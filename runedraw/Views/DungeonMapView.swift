import SwiftUI

struct DungeonMapView: View {
    let engine: GameEngine
    @State private var showingProfile = false
    @State private var showingSkillTree = false
    @State private var showingWaypoints = false

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.02, blue: 0.10).ignoresSafeArea()

            VStack(spacing: 0) {
                // Hero bar — matches TownView layout
                if let hero = engine.hero {
                    HStack(spacing: 14) {
                        // Portrait — taps to full character profile
                        Button { showingProfile = true } label: {
                            ZStack(alignment: .topTrailing) {
                                HeroPortraitView(heroClass: hero.heroClass, size: 44)
                                if hero.statPoints > 0 || hero.skillPoints > 0 {
                                    Circle()
                                        .fill(Color(red: 1.0, green: 0.75, blue: 0.3))
                                        .frame(width: 8, height: 8)
                                        .offset(x: 2, y: -2)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showingProfile) {
                            CharacterProfileView(engine: engine)
                        }

                        // Hero identity + HP
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(hero.heroClass.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .black)).foregroundStyle(.gray).tracking(3)
                                Text("LVL \(hero.level)")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.2)).tracking(1)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.stack.fill").font(.system(size: 10)).foregroundStyle(.white)
                                Text("\(hero.totalCardPool)")
                                    .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                            }
                        }

                        Spacer()

                        // Town portal
                        if hero.townPortals > 0 {
                            Button { engine.useTownPortal() } label: {
                                HStack(spacing: 3) {
                                    Text("🌀").font(.system(size: 12))
                                    Text("×\(hero.townPortals)")
                                        .font(.system(size: 11, weight: .black))
                                        .foregroundStyle(Color(red: 0.5, green: 0.9, blue: 1.0))
                                }
                                .padding(.horizontal, 8).padding(.vertical, 5)
                                .background(Color(red: 0.1, green: 0.3, blue: 0.6).opacity(0.3))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color(red: 0.4, green: 0.7, blue: 1.0).opacity(0.35), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        // Waypoints
                        if !hero.unlockedWaypoints.isEmpty {
                            Button { showingWaypoints = true } label: {
                                Image(systemName: "map.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(red: 0.3, green: 0.8, blue: 1.0))
                                    .padding(8)
                                    .background(Color(red: 0.1, green: 0.5, blue: 0.8).opacity(0.15))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .sheet(isPresented: $showingWaypoints) {
                                WaypointView(engine: engine)
                            }
                        }

                        // Skill tree
                        Button { showingSkillTree = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color(red: 0.7, green: 0.4, blue: 1.0))
                                    .padding(8)
                                    .background(Color(red: 0.5, green: 0.2, blue: 1.0).opacity(0.12))
                                    .clipShape(Circle())
                                if hero.skillPoints > 0 {
                                    Circle()
                                        .fill(Color(red: 0.9, green: 0.6, blue: 1.0))
                                        .frame(width: 7, height: 7)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .sheet(isPresented: $showingSkillTree) {
                            SkillTreeView(engine: engine)
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 12)
                    .background(Color.black.opacity(0.55))
                }

                Divider().background(.gray.opacity(0.2))

                if let area = engine.currentArea {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Area header
                            VStack(spacing: 6) {
                                Text(area.icon)
                                    .font(.system(size: 36))
                                    .padding(.top, 20)
                                Text(area.name.uppercased())
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                                    .tracking(4)
                                Text("AREA \(area.areaIndex) OF \(AreaDatabase.totalAreas)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.gray.opacity(0.55))
                                    .tracking(3)
                                Text(area.progress + " rooms cleared")
                                    .font(.caption)
                                    .foregroundStyle(.gray.opacity(0.5))
                            }

                            // Room list
                            VStack(spacing: 0) {
                                ForEach(Array(area.rooms.enumerated()), id: \.element.id) { idx, room in
                                    RoomRow(
                                        room: room,
                                        isCurrent: idx == area.currentRoomIndex,
                                        isCompleted: room.isCompleted
                                    )
                                }
                            }
                            .padding(.horizontal)

                            // Enter room button
                            if !area.isComplete {
                                let nextRoom = area.currentRoom
                                let tc = nextRoom.type.color
                                let typeColor = Color(red: tc.0, green: tc.1, blue: tc.2)

                                VStack(spacing: 10) {
                                    Text("NEXT")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(.gray)
                                        .tracking(4)

                                    Button {
                                        engine.enterCurrentRoom()
                                    } label: {
                                        HStack(spacing: 10) {
                                            Text(nextRoom.type.icon)
                                                .font(.title3)
                                            Text(nextRoom.type.name.uppercased())
                                                .font(.system(size: 15, weight: .black))
                                                .tracking(3)
                                                .foregroundStyle(enterButtonTextColor(nextRoom.type))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 54)
                                        .background(enterButtonBackground(nextRoom.type, typeColor: typeColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .shadow(color: typeColor.opacity(0.3), radius: 6)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.horizontal)
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

// MARK: - Hero Status Bar

struct HeroStatusBar: View {
    let hero: Hero

    var body: some View {
        HStack(spacing: 14) {
            Text(hero.heroClass.icon)
                .font(.title2)

            VStack(alignment: .leading, spacing: 3) {
                Text(hero.heroClass.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.gray)
                    .tracking(2)

                // HP bar
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 11))

                    Text("\(hero.totalCardPool) cards")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.25))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.7))
                                .frame(width: geo.size.width * cardPoolFraction)
                        }
                    }
                    .frame(height: 5)
                }
            }

            Spacer()

            // Equipment
            let count = hero.equipment.allEquipped.count
            if count > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                    Text("\(count) items")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                }
            }
        }
    }

    private var cardPoolFraction: CGFloat {
        let total = hero.totalCardPool + hero.exiledCards.count
        guard total > 0 else { return 0 }
        return CGFloat(hero.totalCardPool) / CGFloat(total)
    }
}

// MARK: - Room Row

struct RoomRow: View {
    let room: DungeonRoom
    let isCurrent: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Track line + dot
            VStack(spacing: 0) {
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2, height: 16)
                Circle()
                    .fill(dotColor)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(lineColor)
                    .frame(width: 2, height: 16)
            }

            HStack(spacing: 10) {
                Text(room.type.icon)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 1) {
                    Text(room.type.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(labelColor)

                    // Subtitle hints
                    if !isCompleted {
                        Text(roomSubtitle)
                            .font(.system(size: 10))
                            .foregroundStyle(typeAccent.opacity(0.55))
                    }
                }

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green.opacity(0.7))
                        .font(.caption)
                } else if isCurrent {
                    Text("YOU ARE HERE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2))
                        .tracking(2)
                } else if room.type == .elite {
                    Text("ELITE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundStyle(typeAccent)
                        .tracking(2)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(typeAccent.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(rowFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(rowStroke, lineWidth: 1)
                    )
            )
        }
        .opacity(isCompleted ? 0.35 : 1.0)
    }

    private var typeAccent: Color {
        let c = room.type.color
        return Color(red: c.0, green: c.1, blue: c.2)
    }

    private var dotColor: Color {
        if isCompleted { return .green.opacity(0.5) }
        if isCurrent   { return Color(red: 0.9, green: 0.7, blue: 0.2) }
        return typeAccent.opacity(0.5)
    }

    private var lineColor: Color { .gray.opacity(0.2) }

    private var labelColor: Color {
        if isCompleted { return .gray }
        if isCurrent   { return Color(red: 0.9, green: 0.7, blue: 0.2) }
        return .white.opacity(0.85)
    }

    private var rowFill: Color {
        if isCurrent { return Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.07) }
        return typeAccent.opacity(0.04)
    }

    private var rowStroke: Color {
        if isCurrent { return Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.3) }
        return typeAccent.opacity(0.18)
    }

    private var roomSubtitle: String {
        switch room.type {
        case .combat:   return "Standard encounter"
        case .elite:    return "Tough champion — better drops"
        case .boss:     return "Area guardian"
        case .rest:     return "Recover 25% HP"
        case .treasure: return "Free loot chest"
        case .encounter: return "Random event — choose wisely"
        }
    }
}

// MARK: - Enter Button Helpers

private func enterButtonTextColor(_ type: RoomType) -> Color {
    switch type {
    case .rest:     return .white.opacity(0.9)
    case .treasure: return .black
    case .encounter: return .white.opacity(0.9)
    default:        return .black
    }
}

@ViewBuilder
private func enterButtonBackground(_ type: RoomType, typeColor: Color) -> some View {
    switch type {
    case .combat, .boss:
        LinearGradient(
            colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                     Color(red: 0.7, green: 0.5, blue: 0.1)],
            startPoint: .top, endPoint: .bottom
        )
    case .elite:
        LinearGradient(
            colors: [Color(red: 0.85, green: 0.35, blue: 0.9),
                     Color(red: 0.55, green: 0.15, blue: 0.6)],
            startPoint: .top, endPoint: .bottom
        )
    case .rest:
        LinearGradient(
            colors: [Color(red: 0.15, green: 0.55, blue: 0.3),
                     Color(red: 0.08, green: 0.35, blue: 0.18)],
            startPoint: .top, endPoint: .bottom
        )
    case .treasure:
        LinearGradient(
            colors: [Color(red: 0.9, green: 0.75, blue: 0.15),
                     Color(red: 0.6, green: 0.5, blue: 0.08)],
            startPoint: .top, endPoint: .bottom
        )
    case .encounter:
        LinearGradient(
            colors: [Color(red: 0.2, green: 0.45, blue: 0.85),
                     Color(red: 0.1, green: 0.25, blue: 0.6)],
            startPoint: .top, endPoint: .bottom
        )
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    return DungeonMapView(engine: engine)
}
