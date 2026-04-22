import Foundation
import Observation

// swiftlint:disable type_body_length
@Observable
class GameEngine {

    var screen: GameScreen = .classSelect
    var hero: Hero?
    var currentEnemies: [Enemy] = []
    var currentArea: DungeonArea?
    var currentAreaIndex: Int = 1
    var totalAreasCleared: Int = 0
    var combatLog: [String] = []
    var groundLoot: [Card] = []
    var currentLootContext: LootContext = .combat
    var shops: [Shop] = []
    var hasDungeonPortalOpen: Bool = false
    var currentEncounter: EncounterEvent?
    var currentEncounterResult: String?

    var currentRoomIsBoss: Bool = false
    var currentRoomIsElite: Bool = false

    // Block phase state
    var isBlockPhase: Bool = false
    var pendingAttacks: [PendingAttack] = []
    var committedBlockIDs: Set<UUID> = []       // cards the player has tapped to block with

    // Hero attack queue — filled by play(), resolved (after enemy blocks) in endTurn()
    var queuedHeroDamage: [UUID: Int] = [:]     // enemyId → total queued damage

    // Combat reward summary — read by LootPickupView for animations
    var lastCombatExpGained: Int = 0
    var lastCombatGoldGained: Int = 0
    var lastCombatLevelsGained: Int = 0
    // Snapshot of hero state at the moment combat started (for bar animation)
    private(set) var combatStartExp: Int = 0
    private(set) var combatStartLevel: Int = 1

    // MARK: - Init / Load

    init() {
        if let save = SaveManager.load() {
            hero              = save.hero
            currentEnemies    = save.currentEnemies
            currentArea       = save.currentArea
            currentAreaIndex  = save.currentAreaIndex
            totalAreasCleared = save.totalAreasCleared
            screen            = save.isInCombat ? .combat : .dungeonMap
        } else if let lastClass = SaveManager.loadLastClass() {
            startNewGame(with: lastClass)
        }
    }

    // MARK: - New Game

    func startNewGame(with heroClass: HeroClass) {
        SaveManager.saveLastClass(heroClass)
        SaveManager.deleteSave()
        let deck = CardDatabase.startingDeck(for: heroClass)
        hero              = Hero(heroClass: heroClass, startingDeck: deck)
        currentAreaIndex  = 1
        totalAreasCleared = 0
        currentArea       = AreaDatabase.generate(areaIndex: 1)
        combatLog         = []
        hasDungeonPortalOpen = false
        shops             = ShopDatabase.generateShops(floorNumber: 1)
        screen            = .town
    }

    // MARK: - Dungeon Navigation

    func enterCurrentRoom() {
        guard let a = currentArea else { return }
        let room = a.currentRoom

        switch room.type {

        case .combat, .elite, .boss:
            currentRoomIsBoss  = room.type == .boss
            currentRoomIsElite = room.type == .elite
            currentEnemies = EnemyDatabase.enemies(
                for: currentAreaIndex,
                isBoss: currentRoomIsBoss,
                isElite: currentRoomIsElite
            )
            beginCombat()
            screen = .combat

        case .rest:
            let healed = (hero?.maxHp ?? 0) / 4
            hero?.heal(healed)
            log("🔥 Rested — recovered \(healed) HP.")
            completeCurrentRoom()
            screen = .dungeonMap
            autoSave()

        case .treasure:
            let lootTier = AreaDatabase.definition(for: currentAreaIndex)?.lootTier ?? 1
            groundLoot = LootDatabase.generateLoot(
                floorNumber: lootTier,
                isBoss: false,
                count: Int.random(in: 2...3)
            )
            currentLootContext = .treasure
            completeCurrentRoom()
            screen = .loot(groundLoot)
            autoSave()

        case .encounter:
            if let eid = room.encounterId, let event = EncounterDatabase.event(id: eid) {
                currentEncounter = event
            } else {
                // Fallback: pick random
                let tier = AreaDatabase.definition(for: currentAreaIndex)?.enemyTier ?? 1
                let fallbackId = EncounterDatabase.randomId(tier: tier)
                currentEncounter = EncounterDatabase.event(id: fallbackId)
            }
            currentEncounterResult = nil
            screen = .encounter
        }
    }

    private func completeCurrentRoom() {
        guard let a = currentArea else { return }
        currentArea?.rooms[a.currentRoomIndex].isCompleted = true
        currentArea?.currentRoomIndex += 1
    }

    // MARK: - Encounter Resolution

    func resolveEncounterChoice(_ choice: EncounterChoice) {
        guard var h = hero else { return }
        var lines: [String] = []
        applyOutcome(choice.outcome, to: &h, lines: &lines)
        hero = h
        completeCurrentRoom()
        currentEncounterResult = lines.joined(separator: "\n")

        // If hero died (e.g. heavy damage outcome)
        if !(hero?.isAlive ?? false) {
            currentEncounter = nil
            currentEncounterResult = nil
            screen = .gameOver(won: false)
            return
        }

        autoSave()
    }

    func finishEncounter() {
        currentEncounter = nil
        currentEncounterResult = nil
        if !groundLoot.isEmpty {
            screen = .loot(groundLoot)
        } else {
            screen = .dungeonMap
            autoSave()
        }
    }

    private func applyOutcome(_ outcome: EncounterOutcome, to h: inout Hero, lines: inout [String]) {
        switch outcome {

        case .nothing:
            lines.append("Nothing happens.")

        case .heal(let amt):
            let before = h.currentHp
            h.heal(amt)
            let actual = h.currentHp - before
            lines.append("Recovered \(actual) HP.")

        case .healPercent(let pct):
            let amt = max(1, Int(Double(h.maxHp) * pct))
            let before = h.currentHp
            h.heal(amt)
            let actual = h.currentHp - before
            lines.append("Recovered \(actual) HP.")

        case .damage(let amt):
            h.takeDamage(amt)
            lines.append("Took \(amt) damage.")

        case .damagePercent(let pct):
            let amt = max(1, Int(Double(h.maxHp) * pct))
            h.takeDamage(amt)
            lines.append("Took \(amt) damage.")

        case .gold(let amt):
            if amt >= 0 {
                h.gold += amt
                lines.append("+\(amt) gold.")
            } else {
                let paid = min(h.gold, -amt)
                h.gold -= paid
                lines.append("Paid \(paid) gold.")
            }

        case .loot(let tier):
            let items = LootDatabase.generateLoot(floorNumber: tier, isBoss: false, count: 1)
            groundLoot.append(contentsOf: items)
            currentLootContext = .encounter
            if let item = items.first {
                lines.append("Found: \(item.name)!")
            } else {
                lines.append("Found an item!")
            }

        case .statPoints(let pts):
            h.statPoints += pts
            lines.append("+\(pts) stat point\(pts == 1 ? "" : "s") to spend!")

        case .combo(let parts):
            for part in parts { applyOutcome(part, to: &h, lines: &lines) }

        case .chance(let prob, let good, let bad):
            if Double.random(in: 0...1) < prob {
                applyOutcome(good, to: &h, lines: &lines)
            } else {
                applyOutcome(bad, to: &h, lines: &lines)
            }
        }
    }

    // MARK: - Combat Setup

    private func beginCombat() {
        guard var h = hero else { return }
        combatStartExp       = h.experience
        combatStartLevel     = h.level
        lastCombatExpGained  = 0
        lastCombatGoldGained = 0
        lastCombatLevelsGained = 0

        h.deck          = (h.deck + h.discardPile + h.hand).shuffled()
        h.discardPile   = []
        h.hand          = []
        h.block         = h.startingBlock
        h.currentEnergy = h.maxEnergy
        hero = h
        combatLog = []
        queuedHeroDamage = [:]
        // Each enemy draws their opening block hand
        for idx in currentEnemies.indices { currentEnemies[idx].drawBlockHand() }
        log("⚔️ Combat begins!")
        if (hero?.startingBlock ?? 0) > 0 { log("🛡️ Starting block: \(hero!.startingBlock)") }
        drawCards(hero?.cardDrawCount ?? 5)
        autoSave()
    }

    // MARK: - Playing Cards

    func canPlay(_ card: Card) -> Bool {
        (hero?.currentEnergy ?? 0) >= card.cost
    }

    func play(_ card: Card, targeting enemyIndex: Int = 0) {
        guard var h = hero,
              canPlay(card),
              let handIndex = h.hand.firstIndex(where: { $0.id == card.id }) else { return }

        h.currentEnergy -= card.cost
        h.hand.remove(at: handIndex)
        h.discardPile.append(card)
        hero = h

        let fx = card.effect

        // Damage
        if fx.damage > 0 {
            let isPhysical   = fx.damageType == .physical
            let scalingBonus = isPhysical ? (hero?.attackBonus ?? 0) : (hero?.spellpower ?? 0)
            let base         = fx.damage + scalingBonus
            let multi        = (hero?.weakStacks ?? 0) > 0 ? 0.75 : 1.0
            let dmg          = max(1, Int(Double(base) * multi))
            let typeTag      = isPhysical ? "" : " (\(fx.damageType.rawValue))"

            if fx.damageAllEnemies {
                for enemy in currentEnemies {
                    queuedHeroDamage[enemy.id, default: 0] += dmg
                }
                log("\(card.name): Queued \(dmg)\(typeTag) damage vs all enemies.")
            } else if enemyIndex < currentEnemies.count {
                let totalHit = dmg * fx.times
                let target   = currentEnemies[enemyIndex]
                queuedHeroDamage[target.id, default: 0] += totalHit
                let suffix = fx.times > 1 ? " ×\(fx.times)" : ""
                log("\(card.name): Queued \(totalHit)\(typeTag) damage vs \(target.name)\(suffix).")
            }

            // Poison on Hit — physical attacks only (equipment bonus)
            let poisonBonus = hero?.poisonOnHit ?? 0
            if isPhysical && poisonBonus > 0 && enemyIndex < currentEnemies.count {
                currentEnemies[enemyIndex].poisonStacks += poisonBonus
                log("☠️ Poison on Hit: \(currentEnemies[enemyIndex].name) +\(poisonBonus) poison.")
            }
        }

        // Block
        if fx.block > 0 {
            let amt = fx.block + (hero?.defenseBonus ?? 0)
            hero?.block += amt
            log("Gained \(amt) block.")
        }

        // Status effects on targeted enemy
        if enemyIndex < currentEnemies.count {
            if fx.poisonStacks > 0 {
                currentEnemies[enemyIndex].poisonStacks += fx.poisonStacks
                log("\(currentEnemies[enemyIndex].name) poisoned (\(fx.poisonStacks) stacks).")
            }
            if fx.weakStacks > 0 {
                currentEnemies[enemyIndex].weakStacks += fx.weakStacks
            }
            if fx.vulnerableStacks > 0 {
                currentEnemies[enemyIndex].vulnerableStacks += fx.vulnerableStacks
            }
        }

        // Utility
        if fx.draw > 0         { drawCards(fx.draw) }
        if fx.energyGain > 0   { hero?.currentEnergy += fx.energyGain }
        if fx.heal > 0         { hero?.heal(fx.heal); log("Healed \(fx.heal) HP.") }

        // Life on Kill + EXP + Gold
        let justDied = currentEnemies.filter { !$0.isAlive }.count
        if justDied > 0 { awardKills(count: justDied) }

        currentEnemies.removeAll { !$0.isAlive }
        if currentEnemies.isEmpty { endCombat(won: true) }
    }

    // MARK: - End Turn → Block Phase

    func endTurn() {
        guard hero != nil else { return }

        log("── Enemy Turn ──")

        // 1. Enemy blocks queued hero damage, then apply remainder
        if !queuedHeroDamage.isEmpty {
            for idx in currentEnemies.indices {
                let enemy  = currentEnemies[idx]
                guard let queued = queuedHeroDamage[enemy.id], queued > 0 else { continue }
                let blocked  = currentEnemies[idx].autoBlock(incoming: queued)
                let leftover = max(0, queued - blocked)
                if blocked > 0 {
                    log("🛡️ \(enemy.name) blocks \(blocked) damage (hand: \(enemy.blockHand.count) card(s) remaining).")
                }
                if leftover > 0 {
                    currentEnemies[idx].takeDamage(leftover)
                    log("💥 \(enemy.name) takes \(leftover) damage.")
                } else {
                    log("✅ \(enemy.name) fully blocked the attack!")
                }
            }
            queuedHeroDamage = [:]

            // Kill check + rewards
            let killed = currentEnemies.filter { !$0.isAlive }.count
            if killed > 0 { awardKills(count: killed) }
            currentEnemies.removeAll { !$0.isAlive }
            if currentEnemies.isEmpty { endCombat(won: true); return }
        }

        // 2. Execute non-attack enemy actions immediately (defend, poison, weaken)
        for idx in currentEnemies.indices {
            let enemy = currentEnemies[idx]
            switch enemy.currentIntent {
            case .defend(let blk):
                currentEnemies[idx].block += blk
                log("\(enemy.name) braces for \(blk) block.")
            case .poison(let stacks):
                hero?.poisonStacks += stacks
                log("\(enemy.name) applies \(stacks) poison.")
            case .weaken:
                hero?.weakStacks += 2
                log("\(enemy.name) weakens you.")
            case .attack:
                break   // handled in block phase
            }
        }

        // 2. Collect attack intents into the block phase queue
        pendingAttacks = currentEnemies.compactMap { enemy in
            if case .attack(var dmg) = enemy.currentIntent {
                if enemy.weakStacks > 0 { dmg = Int(Double(dmg) * 0.75) }
                return PendingAttack(enemyName: enemy.name, rawDamage: max(0, dmg))
            }
            return nil
        }

        if pendingAttacks.isEmpty {
            // No attacks this round — skip straight to next hero turn
            resolveBlockPhase(blockedWith: [])
        } else {
            // Hand stays in place so the player can choose blocks
            isBlockPhase = true
            committedBlockIDs = []
            let total = pendingAttacks.map(\.rawDamage).reduce(0, +)
            log("🛡️ \(pendingAttacks.count) attack(s) incoming — \(total) damage. Choose your blocks.")
        }
    }

    // MARK: - Block Phase Actions

    func toggleBlock(_ card: Card) {
        guard isBlockPhase else { return }
        if committedBlockIDs.contains(card.id) {
            committedBlockIDs.remove(card.id)
        } else {
            committedBlockIDs.insert(card.id)
        }
    }

    func confirmBlocks() {
        guard isBlockPhase, var h = hero else { return }
        let blockedCards = h.hand.filter { committedBlockIDs.contains($0.id) }
        resolveBlockPhase(blockedWith: blockedCards)
    }

    private func resolveBlockPhase(blockedWith blockedCards: [Card]) {
        guard var h = hero else { return }

        // Remove committed cards from hand → discard
        let blockedIDs = Set(blockedCards.map(\.id))
        let totalDefense = blockedCards.map(\.defenseValue).reduce(0, +)
        h.hand.removeAll { blockedIDs.contains($0.id) }
        h.discardPile.append(contentsOf: blockedCards)

        // Discard the rest of the hand (unblocked, unplayed)
        h.discardPile.append(contentsOf: h.hand)
        h.hand = []
        hero = h

        // Apply incoming damage minus blocks
        let totalIncoming = pendingAttacks.map(\.rawDamage).reduce(0, +)
        if totalIncoming > 0 {
            let remaining = max(0, totalIncoming - totalDefense)
            if !blockedCards.isEmpty {
                let blocked = min(totalDefense, totalIncoming)
                log("🛡️ Blocked \(blocked) damage with \(blockedCards.count) card(s).")
            }
            if remaining > 0 {
                hero?.takeDamage(remaining)
                log("💥 Took \(remaining) damage.")
            } else {
                log("✅ Fully blocked all incoming damage!")
            }

            // Advance enemy actions now that attacks resolved
            for idx in currentEnemies.indices {
                if case .attack = currentEnemies[idx].currentIntent {
                    currentEnemies[idx].advanceAction()
                }
            }
        }

        // Also advance non-attack enemy actions
        for idx in currentEnemies.indices {
            if case .attack = currentEnemies[idx].currentIntent { } else {
                currentEnemies[idx].advanceAction()
            }
        }

        // Clear block phase
        isBlockPhase = false
        pendingAttacks = []
        committedBlockIDs = []

        if hero?.isAlive == false {
            endCombat(won: false)
            return
        }

        // Poison tick + kill check
        let poisonDead = currentEnemies.filter { !$0.isAlive }.count
        if poisonDead > 0 {
            awardKills(count: poisonDead)
        }
        currentEnemies.removeAll { !$0.isAlive }
        if currentEnemies.isEmpty { endCombat(won: true); return }

        log("── Your Turn ──")
        hero?.startNewTurn()
        for idx in currentEnemies.indices {
            currentEnemies[idx].startNewTurn()   // also calls drawBlockHand()
        }
        queuedHeroDamage = [:]
        drawCards(hero?.cardDrawCount ?? 5)
        autoSave()
    }

    // Extracted kill-reward helper used in both play() and resolveBlockPhase()
    private func awardKills(count: Int) {
        let lifePerKill = hero?.lifeOnKill ?? 0
        if lifePerKill > 0 {
            let gained = lifePerKill * count
            hero?.heal(gained)
            log("❤️ Life on Kill: +\(gained) HP")
        }
        let exp = expPerKill() * count
        lastCombatExpGained += exp
        let leveled = hero?.gainExp(exp) ?? false
        if leveled {
            lastCombatLevelsGained += 1
            log("⬆️ LEVEL UP! Now level \(hero?.level ?? 1)!")
        } else {
            log("✨ +\(exp) EXP")
        }
        let gold = goldPerKill() * count
        lastCombatGoldGained += gold
        hero?.gold += gold
        log("💰 +\(gold)g")
    }

    // MARK: - Draw

    private func drawCards(_ count: Int) {
        guard var h = hero else { return }
        for _ in 0..<count {
            if h.deck.isEmpty {
                guard !h.discardPile.isEmpty else { break }
                h.deck        = h.discardPile.shuffled()
                h.discardPile = []
                log("Reshuffled discard pile.")
            }
            if !h.deck.isEmpty {
                h.hand.append(h.deck.removeFirst())
            }
        }
        hero = h
    }

    // MARK: - Combat End

    private func endCombat(won: Bool) {
        completeCurrentRoom()
        if won {
            log("🏆 Victory!")
            SoundManager.victory()
            let lootTier  = AreaDatabase.definition(for: currentAreaIndex)?.lootTier ?? 1
            let lootCount = currentRoomIsElite ? 3 : (currentRoomIsBoss ? 4 : 2)
            groundLoot = LootDatabase.generateLoot(
                floorNumber: currentRoomIsElite ? lootTier + 1 : lootTier,
                isBoss: currentRoomIsBoss,
                count: lootCount,
                heroClass: hero?.heroClass
            )
            currentLootContext = .combat
            screen = .loot(groundLoot)
        } else {
            log("💀 Defeated...")
            SoundManager.defeat()
            screen = .gameOver(won: false)
        }
    }

    // MARK: - Loot Pickup

    func pickUpLoot(_ card: Card) {
        guard var h = hero,
              let idx = groundLoot.firstIndex(where: { $0.id == card.id }) else { return }
        if card.isEquipment {
            guard h.inventory.autoPlace(card) else { return }
        } else {
            // Combat card → goes to collection, never to inventory grid
            h.cardCollection.append(card)
        }
        groundLoot.remove(at: idx)
        hero = h
        autoSave()
    }

    // MARK: - Deck Management

    /// Move a card from collection into the active deck (max 60 cards).
    func addCardToDeck(_ card: Card) {
        guard var h = hero else { return }
        let deckTotal = h.deck.count + h.hand.count + h.discardPile.count
        guard deckTotal < Hero.maxDeckSize else { return }
        guard let idx = h.cardCollection.firstIndex(where: { $0.id == card.id }) else { return }
        h.cardCollection.remove(at: idx)
        h.deck.append(card)
        hero = h
        autoSave()
    }

    /// Move a card from the active deck back to collection (min 20 cards).
    func removeCardFromDeck(_ card: Card) {
        guard var h = hero else { return }
        let deckTotal = h.deck.count + h.hand.count + h.discardPile.count
        guard deckTotal > Hero.minDeckSize else { return }
        // Search deck, hand, and discard — outside combat only hand/deck matter
        if let idx = h.deck.firstIndex(where: { $0.id == card.id }) {
            h.deck.remove(at: idx)
        } else if let idx = h.discardPile.firstIndex(where: { $0.id == card.id }) {
            h.discardPile.remove(at: idx)
        } else {
            return
        }
        h.cardCollection.append(card)
        hero = h
        autoSave()
    }

    func finishLooting() {
        groundLoot = []
        advanceAfterCombat()
    }

    private func advanceAfterCombat() {
        guard let a = currentArea else { return }
        if a.isComplete {
            if var h = hero, !h.unlockedWaypoints.contains(currentAreaIndex) {
                h.unlockedWaypoints.append(currentAreaIndex)
                hero = h
                log("⛩️ Waypoint discovered: \(a.name)")
            }
            totalAreasCleared += 1
            if currentAreaIndex >= AreaDatabase.totalAreas {
                SaveManager.deleteSave()
                screen = .gameOver(won: true)
            } else {
                currentAreaIndex += 1
                currentArea = AreaDatabase.generate(areaIndex: currentAreaIndex)
                let lootTier = AreaDatabase.definition(for: currentAreaIndex)?.lootTier ?? 1
                shops = ShopDatabase.generateShops(floorNumber: lootTier)
                screen = .dungeonMap
                autoSave()
            }
        } else {
            screen = .dungeonMap
            autoSave()
        }
    }

    // MARK: - Inventory Management

    func equipFromInventory(_ card: Card) {
        guard card.isEquipment, var h = hero, let slot = card.equipmentSlot else { return }
        guard h.meetsRequirements(for: card) else { return }
        guard h.inventory.remove(id: card.id) != nil else { return }

        if let displaced = h.equipment.unequip(slot) {
            if let bonus = displaced.statBonus, bonus.maxHp > 0 {
                h.maxHp -= bonus.maxHp
                h.currentHp = min(h.currentHp, h.maxHp)
            }
            h.inventory.autoPlace(displaced)
        }

        if let bonus = card.statBonus, bonus.maxHp > 0 {
            h.maxHp    += bonus.maxHp
            h.currentHp = min(h.currentHp + bonus.maxHp, h.maxHp)
        }

        h.equipment.equip(card)
        hero = h
        autoSave()
    }

    func unequipToInventory(_ slot: EquipmentSlot) {
        guard var h = hero else { return }
        if let displaced = h.equipment.unequip(slot) {
            if let bonus = displaced.statBonus, bonus.maxHp > 0 {
                h.maxHp -= bonus.maxHp
                h.currentHp = min(h.currentHp, h.maxHp)
            }
            if !h.inventory.autoPlace(displaced) {
                h.equipment.equip(displaced)
            }
        }
        hero = h
        autoSave()
    }

    func dropFromInventory(_ card: Card) {
        hero?.inventory.remove(id: card.id)
        autoSave()
    }

    // MARK: - Stat Allocation

    func allocateStat(_ key: StatKey) {
        guard var h = hero, h.statPoints > 0 else { return }
        h.statPoints -= 1
        h.stats[key] += 1
        if key == .vitality {
            h.maxHp    += 3
            h.currentHp = min(h.currentHp + 3, h.maxHp)
        }
        hero = h
        autoSave()
    }

    // MARK: - Reset

    func reset() {
        SaveManager.deleteSave()
        screen               = .classSelect
        hero                 = nil
        currentEnemies       = []
        currentArea          = nil
        currentAreaIndex     = 1
        totalAreasCleared    = 0
        combatLog            = []
        groundLoot           = []
        shops                = []
        hasDungeonPortalOpen = false
        currentEncounter     = nil
        currentEncounterResult = nil
    }

    // MARK: - Auto Save

    private func autoSave() {
        guard let h = hero, let a = currentArea else { return }
        SaveManager.save(SaveData(
            hero: h,
            currentEnemies: currentEnemies,
            currentArea: a,
            currentAreaIndex: currentAreaIndex,
            totalAreasCleared: totalAreasCleared,
            isInCombat: screen.id == "combat"
        ))
    }

    // MARK: - EXP & Gold

    private func expPerKill() -> Int {
        let base = currentAreaIndex * 12 + 18
        let eliteBonus = currentRoomIsElite ? 3 : 1
        return (currentRoomIsBoss ? base * 2 : base) * eliteBonus / (currentRoomIsElite ? 2 : 1)
    }

    private func goldPerKill() -> Int {
        let base = currentAreaIndex * 8 + 12
        let variance = Int.random(in: -5...10)
        let eliteBonus = currentRoomIsElite ? 20 : 0
        return max(5, base + variance + eliteBonus + (currentRoomIsBoss ? 50 : 0))
    }

    // MARK: - Town

    func enterTown() {
        let lootTier = AreaDatabase.definition(for: currentAreaIndex)?.lootTier ?? 1
        shops = ShopDatabase.generateShops(floorNumber: lootTier)
        screen = .town
        autoSave()
    }

    // MARK: - Waypoint Travel

    func travelToWaypoint(_ areaIndex: Int) {
        guard hero?.unlockedWaypoints.contains(areaIndex) == true else { return }
        currentAreaIndex     = areaIndex
        currentArea          = AreaDatabase.generate(areaIndex: areaIndex)
        hasDungeonPortalOpen = false
        let lootTier = AreaDatabase.definition(for: areaIndex)?.lootTier ?? 1
        shops = ShopDatabase.generateShops(floorNumber: lootTier)
        screen = .dungeonMap
        autoSave()
    }

    func enterDungeon() {
        hasDungeonPortalOpen = false
        screen = .dungeonMap
        autoSave()
    }

    func useTownPortal() {
        guard var h = hero, h.townPortals > 0 else { return }
        h.townPortals -= 1
        hero = h
        hasDungeonPortalOpen = true
        enterTown()
    }

    func returnToDungeon() {
        hasDungeonPortalOpen = false
        screen = .dungeonMap
        autoSave()
    }

    // MARK: - Shop

    func buyItem(at itemIndex: Int, in shopIndex: Int) {
        guard var h = hero,
              shopIndex < shops.count,
              itemIndex < shops[shopIndex].items.count else { return }
        let item = shops[shopIndex].items[itemIndex]
        guard !item.isPurchased, h.gold >= item.price else { return }
        guard h.inventory.autoPlace(item.card) else { return }
        h.gold -= item.price
        shops[shopIndex].items[itemIndex].isPurchased = true
        hero = h
        autoSave()
    }

    func buyTownPortal() {
        guard var h = hero, h.gold >= ShopDatabase.portalPrice else { return }
        h.gold -= ShopDatabase.portalPrice
        h.townPortals += 1
        hero = h
        autoSave()
    }

    // MARK: - Skill Tree

    func unlockSkill(_ nodeId: String) {
        guard var h = hero else { return }
        let tree = SkillDatabase.tree(for: h.heroClass)
        guard let node = tree.first(where: { $0.id == nodeId }),
              !h.unlockedSkills.contains(nodeId),
              h.skillPoints >= node.cost else { return }
        if let reqId = node.requiresId {
            guard h.unlockedSkills.contains(reqId) else { return }
        }
        h.skillPoints -= node.cost
        h.unlockedSkills.append(nodeId)
        let template = SkillDatabase.card(for: nodeId)
        let freshCard = Card(id: UUID(), name: template.name,
                             description: template.description,
                             cost: template.cost, type: template.type,
                             rarity: .common, heroClass: template.heroClass,
                             effect: template.effect)
        h.deck.append(freshCard)
        hero = h
        autoSave()
    }

    func sellItem(_ card: Card) {
        guard var h = hero,
              h.inventory.remove(id: card.id) != nil else { return }
        h.gold += ShopDatabase.sellPrice(for: card)
        hero = h
        autoSave()
    }

    // MARK: - Logging

    private func log(_ message: String) {
        combatLog.append(message)
        if combatLog.count > 60 { combatLog.removeFirst() }
    }
}
