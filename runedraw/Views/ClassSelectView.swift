import SwiftUI

struct ClassSelectView: View {
    let engine: GameEngine

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.02, blue: 0.12),
                         Color(red: 0.08, green: 0.04, blue: 0.18),
                         Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle radial glow behind the title
            RadialGradient(
                colors: [Color(red: 0.5, green: 0.3, blue: 0.05).opacity(0.3), .clear],
                center: .init(x: 0.5, y: 0.18),
                startRadius: 0, endRadius: 320
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // Title
                VStack(spacing: 8) {
                    Text("RUNEDRAW")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.85, blue: 0.3),
                                         Color(red: 0.85, green: 0.6, blue: 0.1)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .shadow(color: .orange.opacity(0.35), radius: 14)

                    Text("DUNGEON CRAWLER  •  CARD GAME")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.gray.opacity(0.6))
                        .tracking(4)
                }
                .padding(.top, 56)

                // Section label
                Text("CREATE CHARACTER")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.7))
                    .tracking(4)
                    .padding(.top, 36)
                    .padding(.bottom, 16)

                Divider()
                    .background(Color(red: 0.6, green: 0.4, blue: 0.1).opacity(0.3))

                // Class cards
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(HeroClass.allCases) { heroClass in
                            ClassCard(heroClass: heroClass) {
                                engine.startNewGame(with: heroClass)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
    }
}

// MARK: - Class Card

struct ClassCard: View {
    let heroClass: HeroClass
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(heroClass.themeColor.opacity(0.15))
                        .frame(width: 66, height: 66)
                    Text(heroClass.icon)
                        .font(.system(size: 34))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(heroClass.rawValue.uppercased())
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                        .tracking(2)

                    Text(heroClass.lore)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(heroClass.statsLabel)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(heroClass.themeColor)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray.opacity(0.5))
                    .font(.caption)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.11, green: 0.07, blue: 0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(heroClass.themeColor.opacity(0.35), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ClassSelectView(engine: GameEngine())
}
