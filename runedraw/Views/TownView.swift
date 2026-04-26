import SwiftUI

struct TownView: View {
    let engine: GameEngine

    @State private var showingSkillTree = false
    @State private var showingStats = false
    @State private var showingWaypoints = false
    @State private var showingProfile = false
    @State private var showingStash = false

    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack {
            // Warm dark background — distinct from the dungeon's purple
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.07, blue: 0.03),
                    Color(red: 0.04, green: 0.03, blue: 0.01),
                ],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient warm glow
            RadialGradient(
                colors: [Color(red: 0.4, green: 0.22, blue: 0.05).opacity(0.35), .clear],
                center: .init(x: 0.5, y: 0.3),
                startRadius: 0, endRadius: 350
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                heroBar
                Divider().background(Color(red: 0.6, green: 0.4, blue: 0.1).opacity(0.3))
                ScrollView {
                    VStack(spacing: 20) {
                        townHeader
                        statsButton
                        skillTreeButton
                        stashButton
                        if !(hero.unlockedWaypoints.isEmpty) { waypointButton }
                        switchCharacterButton
                        enterButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
    }

    // MARK: - Hero Bar

    var heroBar: some View {
        HStack(spacing: 14) {
            Button { showingProfile = true } label: {
                HeroPortraitView(heroClass: hero.heroClass, size: 44)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showingProfile) {
                CharacterProfileView(engine: engine)
            }

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
                    Text("\(hero.totalCardPool) cards").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(Color.black.opacity(0.45))
    }

    // MARK: - Town Header

    var townHeader: some View {
        VStack(spacing: 4) {
            Text("🏘️")
                .font(.system(size: 44))
                .shadow(color: Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.6), radius: 12)

            Text("ASHENVEIL")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(Color(red: 1.0, green: 0.82, blue: 0.4))
                .tracking(6)

            Text("Rest, trade, and prepare for the dungeon below.")
                .font(.system(size: 12))
                .foregroundStyle(.gray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Stats Button

    var statsButton: some View {
        Button { showingStats = true } label: {
            HStack(spacing: 14) {
                Text("⚔️").font(.system(size: 28)).frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Attributes")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    Text("Spend points to boost STR, DEX, VIT, INT")
                        .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.6))
                }
                Spacer()
                if hero.statPoints > 0 {
                    Text("\(hero.statPoints)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color(red: 1.0, green: 0.75, blue: 0.3))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(red: 1.0, green: 0.5, blue: 0.1).opacity(0.2))
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.07, blue: 0.02))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(hero.statPoints > 0
                                ? Color(red: 1.0, green: 0.55, blue: 0.1).opacity(0.5)
                                : Color(red: 0.5, green: 0.3, blue: 0.05).opacity(0.25),
                                lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingStats) {
            StatAllocationView(engine: engine)
        }
    }

    // MARK: - Skill Tree Button

    var skillTreeButton: some View {
        Button { showingSkillTree = true } label: {
            HStack(spacing: 14) {
                Text("🌟").font(.system(size: 28)).frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Skill Tree")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    Text("Spend points to unlock new cards")
                        .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.6))
                }
                Spacer()
                if hero.skillPoints > 0 {
                    Text("\(hero.skillPoints)")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(Color(red: 0.8, green: 0.6, blue: 1.0))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(red: 0.5, green: 0.2, blue: 1.0).opacity(0.2))
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.06, blue: 0.18))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(hero.skillPoints > 0
                                ? Color(red: 0.6, green: 0.3, blue: 1.0).opacity(0.5)
                                : Color(red: 0.4, green: 0.2, blue: 0.7).opacity(0.2),
                                lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSkillTree) {
            SkillTreeView(engine: engine)
        }
    }

    // MARK: - Waypoint Button

    var waypointButton: some View {
        Button { showingWaypoints = true } label: {
            HStack(spacing: 14) {
                Text("⛩️").font(.system(size: 28)).frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Waypoints")
                        .font(.system(size: 14, weight: .bold)).foregroundStyle(.white)
                    Text("\(hero.unlockedWaypoints.count) area\(hero.unlockedWaypoints.count == 1 ? "" : "s") discovered")
                        .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.4))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.03, green: 0.1, blue: 0.18))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.2, green: 0.6, blue: 0.9).opacity(0.3), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingWaypoints) {
            WaypointView(engine: engine)
        }
    }

    // MARK: - Stash Button

    var stashButton: some View {
        let stashCount = engine.sharedStash.cards.count
        return Button { showingStash = true } label: {
            HStack(spacing: 14) {
                Text("🏦").font(.system(size: 28)).frame(width: 44)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Shared Stash")
                        .font(.system(size: 15, weight: .bold)).foregroundStyle(.white)
                    Text("Deposit cards for your other characters")
                        .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.55))
                }
                Spacer()
                if stashCount > 0 {
                    Text("\(stashCount)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(red: 1.0, green: 0.75, blue: 0.3))
                        .clipShape(Capsule())
                }
                Image(systemName: "chevron.right").foregroundStyle(.gray.opacity(0.4)).font(.caption)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.10, green: 0.07, blue: 0.02))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 1.0, green: 0.75, blue: 0.3).opacity(0.25), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingStash) {
            StashView(engine: engine)
        }
    }

    // MARK: - Switch Character Button

    var switchCharacterButton: some View {
        Button { engine.exitToCharacterSelect() } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 14)).foregroundStyle(.gray.opacity(0.6))
                Text("SWITCH CHARACTER")
                    .font(.system(size: 12, weight: .black)).tracking(2)
                    .foregroundStyle(.gray.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dungeon Button

    var enterButton: some View {
        Button {
            engine.enterDungeon()
        } label: {
            HStack(spacing: 10) {
                Text("⚔️")
                Text(engine.currentArea != nil ? "DUNGEON" : "ENTER DUNGEON")
                    .font(.system(size: 15, weight: .black)).tracking(3)
                    .foregroundStyle(.black)
            }
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                             Color(red: 0.7, green: 0.5, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .padding(.bottom, 20)
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    return TownView(engine: engine)
}
