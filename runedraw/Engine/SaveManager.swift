import Foundation

struct SaveData: Codable {
    var hero: Hero
    var currentEnemies: [Enemy]
    var currentArea: DungeonArea
    var currentAreaIndex: Int
    var totalAreasCleared: Int
    var isInCombat: Bool
}

struct SaveManager {
    private static let saveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("runedraw_save.json")
    }()

    static func save(_ data: SaveData) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: saveURL, options: .atomic)
        } catch {
            print("Save failed: \(error)")
        }
    }

    static func load() -> SaveData? {
        guard let data = try? Data(contentsOf: saveURL) else { return nil }
        return try? JSONDecoder().decode(SaveData.self, from: data)
    }

    static func deleteSave() {
        try? FileManager.default.removeItem(at: saveURL)
    }
}
