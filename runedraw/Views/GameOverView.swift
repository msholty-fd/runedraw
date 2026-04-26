import SwiftUI

struct GameOverView: View {
    let engine: GameEngine
    let won: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: won
                    ? [Color(red: 0.02, green: 0.06, blue: 0.14), Color(red: 0.04, green: 0.10, blue: 0.04), Color.black]
                    : [Color(red: 0.12, green: 0.02, blue: 0.02), Color(red: 0.06, green: 0.02, blue: 0.02), Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Trophy / Skull
                Text(won ? "🏆" : "💀")
                    .font(.system(size: 80))
                    .shadow(color: won ? .yellow.opacity(0.5) : .red.opacity(0.4), radius: 16)

                Spacer().frame(height: 24)

                // Result
                Text(won ? "VICTORY" : "DEFEATED")
                    .font(.system(size: 46, weight: .black))
                    .foregroundStyle(won ? Color(red: 1.0, green: 0.85, blue: 0.3) : Color.red)
                    .tracking(4)

                Spacer().frame(height: 12)

                if let hero = engine.hero {
                    HStack(spacing: 8) {
                        Text(hero.heroClass.icon)
                        Text(hero.heroClass.rawValue)
                            .font(.title3.bold())
                            .foregroundStyle(.white)
                    }

                    Text("Reached \(engine.currentArea?.name ?? "Area \(engine.currentAreaIndex)")")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                }

                Spacer().frame(height: 32)


                Spacer()

                // Play Again
                Button {
                    engine.reset()
                } label: {
                    Text("NEW CHARACTER")
                        .font(.system(size: 15, weight: .black))
                        .tracking(4)
                        .foregroundStyle(.black)
                        .frame(width: 220, height: 52)
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

                Spacer().frame(height: 70)
            }
        }
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    engine.currentAreaIndex = 4
    return GameOverView(engine: engine, won: true)
}
