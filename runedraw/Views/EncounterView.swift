import SwiftUI

struct EncounterView: View {
    let engine: GameEngine

    private var event: EncounterEvent? { engine.currentEncounter }
    private var result: String? { engine.currentEncounterResult }
    private var hero: Hero { engine.hero ?? Hero(heroClass: .barbarian, startingDeck: []) }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.05, blue: 0.16),
                         Color(red: 0.02, green: 0.03, blue: 0.08),
                         Color.black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Ambient glow
            RadialGradient(
                colors: [Color(red: 0.2, green: 0.35, blue: 0.9).opacity(0.2), .clear],
                center: .init(x: 0.5, y: 0.2), startRadius: 0, endRadius: 380
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            if let event {
                if result == nil {
                    choicePhase(event: event)
                } else {
                    resultPhase(event: event)
                }
            }
        }
    }

    // MARK: - Choice Phase

    private func choicePhase(event: EncounterEvent) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer().frame(height: 60)

                // Icon
                Text(event.icon)
                    .font(.system(size: 72))
                    .shadow(color: Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.5), radius: 20)
                    .padding(.bottom, 20)

                // Title
                Text(event.title.uppercased())
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(Color(red: 0.7, green: 0.85, blue: 1.0))
                    .tracking(3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Spacer().frame(height: 16)

                // Description
                Text(event.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 36)

                // Divider
                HStack {
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                    Text("WHAT DO YOU DO?")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.gray.opacity(0.4))
                        .tracking(3)
                        .fixedSize()
                        .padding(.horizontal, 12)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Choices
                VStack(spacing: 10) {
                    ForEach(event.choices) { choice in
                        ChoiceButton(choice: choice, hero: hero) {
                            engine.resolveEncounterChoice(choice)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 50)
            }
        }
    }

    // MARK: - Result Phase

    private func resultPhase(event: EncounterEvent) -> some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon (smaller)
            Text(event.icon)
                .font(.system(size: 48))
                .opacity(0.5)
                .padding(.bottom, 12)

            // Result card
            VStack(spacing: 16) {
                Text("OUTCOME")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.gray.opacity(0.5))
                    .tracking(4)

                if let result {
                    VStack(spacing: 8) {
                        ForEach(result.components(separatedBy: "\n"), id: \.self) { line in
                            Text(line)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(resultLineColor(line))
                                .multilineTextAlignment(.center)
                        }
                    }
                }

                // Card pool snapshot
                HStack(spacing: 8) {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(.white)
                        .font(.system(size: 12))
                    Text("\(hero.totalCardPool) cards remaining")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)

                Divider().background(.white.opacity(0.1))

                // Continue button
                Button { engine.finishEncounter() } label: {
                    Text("CONTINUE")
                        .font(.system(size: 14, weight: .black))
                        .tracking(4)
                        .foregroundStyle(.black)
                        .frame(width: 180, height: 46)
                        .background(LinearGradient(
                            colors: [Color(red: 0.4, green: 0.8, blue: 1.0),
                                     Color(red: 0.2, green: 0.5, blue: 0.9)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.06, green: 0.09, blue: 0.22))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 0.3, green: 0.6, blue: 1.0).opacity(0.35), lineWidth: 1))
            )
            .shadow(color: Color(red: 0.2, green: 0.4, blue: 1.0).opacity(0.2), radius: 20)
            .padding(.horizontal, 32)
            .transition(.move(edge: .bottom).combined(with: .opacity))

            Spacer()
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: result)
    }

    private func resultLineColor(_ line: String) -> Color {
        let lower = line.lowercased()
        if lower.contains("recovered") || lower.contains("healed") || lower.contains("heal") {
            return Color(red: 0.3, green: 1.0, blue: 0.5)
        }
        if lower.contains("damage") || lower.contains("took") {
            return Color(red: 1.0, green: 0.3, blue: 0.3)
        }
        if lower.contains("gold") || lower.contains("paid") {
            return Color(red: 1.0, green: 0.82, blue: 0.25)
        }
        if lower.contains("stat point") || lower.contains("found:") {
            return Color(red: 0.8, green: 0.6, blue: 1.0)
        }
        return .white.opacity(0.85)
    }
}

// MARK: - Choice Button

private struct ChoiceButton: View {
    let choice: EncounterChoice
    let hero: Hero
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if choice.isRisky {
                            Text("⚠️")
                                .font(.system(size: 11))
                        }
                        Text(choice.label)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    if !choice.subtitle.isEmpty {
                        Text(choice.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.gray.opacity(0.6))
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(accentColor.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(pressed ? 0.12 : 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(pressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded   { _ in pressed = false }
        )
    }

    private var accentColor: Color {
        if choice.isRisky { return Color(red: 1.0, green: 0.5, blue: 0.2) }
        // Infer from outcome
        switch choice.outcome {
        case .heal, .healPercent:
            return Color(red: 0.3, green: 1.0, blue: 0.5)
        case .gold:
            return Color(red: 1.0, green: 0.82, blue: 0.25)
        case .loot:
            return Color(red: 0.8, green: 0.6, blue: 1.0)
        case .statPoints:
            return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .nothing:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        default:
            return Color(red: 0.4, green: 0.7, blue: 1.0)
        }
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .rogue)
    engine.currentEncounter = EncounterDatabase.event(id: "old_shrine")
    return EncounterView(engine: engine)
}
