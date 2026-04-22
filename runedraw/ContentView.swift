import SwiftUI

struct ContentView: View {
    @State private var engine = GameEngine()

    var body: some View {
        Group {
            switch engine.screen {
            case .characterSelect:
                CharacterSelectView(engine: engine)
            case .classSelect:
                ClassSelectView(engine: engine)
            case .town:
                TownView(engine: engine)
            case .dungeonMap:
                DungeonMapView(engine: engine)
            case .combat:
                CombatView(engine: engine)
            case .encounter:
                EncounterView(engine: engine)
            case .loot(let cards):
                LootPickupView(engine: engine, groundLoot: cards)
            case .gameOver(let won):
                GameOverView(engine: engine, won: won)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: engine.screen.id)
    }
}

extension GameScreen {
    var id: String {
        switch self {
        case .characterSelect: return "characterSelect"
        case .classSelect:     return "classSelect"
        case .town:            return "town"
        case .dungeonMap:      return "dungeonMap"
        case .combat:          return "combat"
        case .encounter:       return "encounter"
        case .loot:            return "loot"
        case .gameOver:        return "gameOver"
        }
    }
}

#Preview {
    ContentView()
}
