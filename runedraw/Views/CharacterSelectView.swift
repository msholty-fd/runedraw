import SwiftUI

struct CharacterSelectView: View {
    let engine: GameEngine
    @State private var summaries: [CharacterSummary?] = []

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.02, blue: 0.12),
                         Color(red: 0.08, green: 0.04, blue: 0.18),
                         Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color(red: 0.5, green: 0.3, blue: 0.05).opacity(0.3), .clear],
                center: .init(x: 0.5, y: 0.15),
                startRadius: 0, endRadius: 280
            )
            .ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 0) {
                // Title
                VStack(spacing: 8) {
                    Text("RUNEDRAW")
                        .font(.system(size: 44, weight: .black))
                        .foregroundStyle(LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                                     Color(red: 0.85, green: 0.6, blue: 0.1)],
                            startPoint: .top, endPoint: .bottom))
                        .shadow(color: .orange.opacity(0.35), radius: 14)
                    Text("DUNGEON CRAWLER  •  CARD GAME")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.6)).tracking(4)
                }
                .padding(.top, 52)

                Text("SELECT CHARACTER")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.7))
                    .tracking(4)
                    .padding(.top, 32).padding(.bottom, 16)

                Divider().background(Color(red: 0.6, green: 0.4, blue: 0.1).opacity(0.3))

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(0..<SaveManager.totalSlots, id: \.self) { slot in
                            if let summary = summaries.indices.contains(slot) ? summaries[slot] : nil {
                                ExistingCharacterSlot(summary: summary) {
                                    engine.loadCharacter(slot: slot)
                                } onDelete: {
                                    SaveManager.delete(slot: slot)
                                    refreshSummaries()
                                }
                            } else {
                                EmptyCharacterSlot(slot: slot) {
                                    engine.prepareNewCharacter(slot: slot)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20).padding(.vertical, 20)
                }
            }
        }
        .onAppear { refreshSummaries() }
    }

    private func refreshSummaries() {
        summaries = SaveManager.allSummaries()
    }
}

// MARK: - Existing character slot

private struct ExistingCharacterSlot: View {
    let summary: CharacterSummary
    let onContinue: () -> Void
    let onDelete: () -> Void

    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 16) {
            // Class portrait
            ZStack {
                Circle()
                    .fill(summary.heroClass.themeColor.opacity(0.15))
                    .frame(width: 60, height: 60)
                Text(summary.heroClass.icon).font(.system(size: 30))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(summary.heroClass.rawValue.uppercased())
                        .font(.system(size: 15, weight: .black)).foregroundStyle(.white).tracking(1)
                    Text("LVL \(summary.level)")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(summary.heroClass.themeColor)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(summary.heroClass.themeColor.opacity(0.12)).clipShape(Capsule())
                }
                Text(summary.areaName)
                    .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.6))
                // HP bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.06))
                        let frac = min(1.0, Double(summary.currentHp) / Double(max(1, summary.maxHp)))
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient(colors: [.red, .red.opacity(0.5)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * frac)
                    }
                }
                .frame(height: 4)
                Text("\(summary.currentHp)/\(summary.maxHp) HP  •  \(summary.deckCount) cards")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.4))
            }

            Spacer()

            // Actions
            VStack(spacing: 6) {
                Button(action: onContinue) {
                    Text("PLAY")
                        .font(.system(size: 12, weight: .black)).tracking(2)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(summary.heroClass.themeColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button { confirmDelete = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.45))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.11, green: 0.07, blue: 0.18))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(summary.heroClass.themeColor.opacity(0.35), lineWidth: 1))
        )
        .confirmationDialog("Delete \(summary.heroClass.rawValue)?",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Character", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This character and all their progress will be permanently lost.")
        }
    }
}

// MARK: - Empty slot

private struct EmptyCharacterSlot: View {
    let slot: Int
    let onCreate: () -> Void

    var body: some View {
        Button(action: onCreate) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 60, height: 60)
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.white.opacity(0.25))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("EMPTY SLOT")
                        .font(.system(size: 13, weight: .black)).foregroundStyle(.white.opacity(0.35)).tracking(2)
                    Text("Create a new character")
                        .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.35))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray.opacity(0.25)).font(.caption)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.025))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CharacterSelectView(engine: GameEngine())
}
