import SwiftUI

// EquipmentView — retained as a stub for any future navigation references.
// The equipment system has been removed; this view is no longer shown in the game.
struct EquipmentView: View {
    let engine: GameEngine

    var body: some View {
        Text("Equipment system removed.")
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
    }
}

#Preview {
    let engine = GameEngine()
    engine.startNewGame(with: .barbarian)
    return EquipmentView(engine: engine)
}
