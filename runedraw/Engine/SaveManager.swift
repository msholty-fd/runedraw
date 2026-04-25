import Foundation

struct SaveData: Codable {
    var hero: Hero
    var currentEnemies: [Enemy]
    var currentArea: DungeonArea
    var currentAreaIndex: Int
    var totalAreasCleared: Int
    var isInCombat: Bool
}

struct SharedStash: Codable {
    var cards: [Card] = []
}

/// Lightweight summary for the character select screen — built from SaveData.
struct CharacterSummary {
    let slot: Int
    let heroClass: HeroClass
    let level: Int
    let areaName: String
    let totalCardPool: Int
    let exiledCardCount: Int
    let deckCount: Int
}

struct SaveManager {

    static let totalSlots = 3

    // MARK: - Slot-based save paths

    private static func slotURL(_ slot: Int) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("runedraw_save_\(slot).json")
    }

    /// Legacy single-save path (pre multi-character)
    private static let legacySaveURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("runedraw_save.json")
    }()

    // MARK: - Character saves

    static func save(_ data: SaveData, slot: Int) {
        do {
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: slotURL(slot), options: .atomic)
        } catch {
            print("Save failed (slot \(slot)): \(error)")
        }
    }

    static func load(slot: Int) -> SaveData? {
        // First check the slot file
        if let data = try? Data(contentsOf: slotURL(slot)) {
            do {
                return try JSONDecoder().decode(SaveData.self, from: data)
            } catch {
                print("Save decode failed (slot \(slot)): \(error)")
            }
        }
        // Migrate legacy save → slot 0 on first load
        if slot == 0, let data = try? Data(contentsOf: legacySaveURL) {
            do {
                let saveData = try JSONDecoder().decode(SaveData.self, from: data)
                save(saveData, slot: 0)                // write to new path
                try? FileManager.default.removeItem(at: legacySaveURL) // clean up old file
                return saveData
            } catch {
                print("Legacy save decode failed: \(error)")
            }
        }
        return nil
    }

    static func delete(slot: Int) {
        try? FileManager.default.removeItem(at: slotURL(slot))
    }

    /// Returns a CharacterSummary for each occupied slot (nil = empty).
    static func allSummaries() -> [CharacterSummary?] {
        (0..<totalSlots).map { slot in
            guard let save = load(slot: slot) else { return nil }
            let h = save.hero
            let deckCount = h.deck.count + h.hand.count + h.discardPile.count
            return CharacterSummary(
                slot: slot,
                heroClass: h.heroClass,
                level: h.level,
                areaName: save.currentArea.name,
                totalCardPool: h.totalCardPool,
                exiledCardCount: h.exiledCards.count,
                deckCount: deckCount
            )
        }
    }

    // MARK: - Shared stash

    private static let stashURL: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("runedraw_stash.json")
    }()

    static func saveStash(_ stash: SharedStash) {
        do {
            let encoded = try JSONEncoder().encode(stash)
            try encoded.write(to: stashURL, options: .atomic)
        } catch {
            print("Stash save failed: \(error)")
        }
    }

    static func loadStash() -> SharedStash {
        guard let data = try? Data(contentsOf: stashURL) else { return SharedStash() }
        do {
            return try JSONDecoder().decode(SharedStash.self, from: data)
        } catch {
            return SharedStash()
        }
    }

    // MARK: - Legacy helpers (kept for compatibility)

    /// Backward-compat wrapper — saves to slot 0.
    static func save(_ data: SaveData) { save(data, slot: 0) }

    /// Backward-compat wrapper — loads from slot 0 (with legacy migration).
    static func load() -> SaveData? { load(slot: 0) }

    static func deleteSave() { delete(slot: 0) }

    private static let lastClassKey = "runedraw_last_hero_class"
    static func saveLastClass(_ heroClass: HeroClass) {
        UserDefaults.standard.set(heroClass.rawValue, forKey: lastClassKey)
    }
    static func loadLastClass() -> HeroClass? {
        guard let raw = UserDefaults.standard.string(forKey: lastClassKey) else { return nil }
        return HeroClass(rawValue: raw)
    }
}
