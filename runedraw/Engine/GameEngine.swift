// swiftlint:disable type_body_length function_body_length line_length cyclomatic_complexity file_length
import Foundation
import Observation

@Observable
class GameEngine {

    var screen: GameScreen = .characterSelect
    var hero: Hero?
    var currentEnemies: [Enemy] = []
    var currentArea: DungeonArea?
    var currentAreaIndex: Int = 1
    var totalAreasCleared: Int = 0
    var combatLog: [String] = []
    var groundLoot: [Card] = []
    var currentLootContext: LootContext = .combat
    var hasDungeonPortalOpen: Bool = false
    var currentEncounter: EncounterEvent?
    var currentEncounterResult: String?

    // Multi-character
    private(set) var currentSlot: Int = 0
    var sharedStash: SharedStash = SharedStash()

    var currentRoomIsBoss: Bool = false
    var currentRoomIsElite: Bool = false

    // Block phase state
    var isBlockPhase: Bool = false
    var pendingAttacks: [PendingAttack] = []
    var committedBlockIDs: Set<UUID> = []       // cards the player has tapped to block with

    // Played-cards queue — for the UI tray and recall feature
    var playedCards: [PlayedCardRecord] = []

    // Per-turn combat state
    var lastPlayedCardType: CardType? = nil   // combo mechanic: tracks type of last card played
    var amplifyActive: Bool = false            // Sorceress: next attack card deals 2×

    // Pitch state — FAB-style: pitch hand cards to fund the cost of another card
    /// The card currently staged for play (still in hand; awaiting pitch to cover its cost).
    var stagedCardID: UUID? = nil
    /// Cards being pitched to fund the staged card. Keys removed from hand when play is confirmed.
    var pitchedForStagedIDs: [UUID] = []
    /// Sum of pitchValue for all cards currently in pitchedForStagedIDs.
    var pitchResourceAvailable: Int {
        guard let h = hero else { return 0 }
        return pitchedForStagedIDs.compactMap { id in
            h.hand.first { $0.id == id }?.pitchValue
        }.reduce(0, +)
    }
    var stagedCard: Card? { hero?.hand.first { $0.id == stagedCardID } }
    var pitchCostMet: Bool { pitchResourceAvailable >= (stagedCard?.cost ?? 0) }

    // Per-combat keyword state (reset in beginCombat)
    var combatEvasionCharges: Int = 0          // Rogue: remaining dodge charges this combat
    var hasEnduredThisCombat: Bool = false     // Barbarian: Endure used this combat
    var pendingFreeCard: Bool = false          // Barbarian: Bloodlust — next card costs 0
    var pendingAssassinateReady: Bool = false  // Rogue: Assassinate — next attack costs 0
    var deckRecycleCount: Int = 0              // how many times the deck has been reshuffled this combat

    // Combat reward summary — read by LootPickupView for animations
    var lastCombatExpGained: Int = 0
    var lastCombatLevelsGained: Int = 0
    // Snapshot of hero state at the moment combat started (for bar animation)
    private(set) var combatStartExp: Int = 0
    private(set) var combatStartLevel: Int = 1

    // MARK: - Init / Load

    init() {
        sharedStash = SaveManager.loadStash()
        screen      = .characterSelect
    }

    // MARK: - Character Select

    /// Load an existing save into the engine and go to town/dungeon.
    func loadCharacter(slot: Int) {
        guard let save = SaveManager.load(slot: slot) else { return }
        currentSlot       = slot
        hero              = save.hero
        currentEnemies    = save.currentEnemies
        currentArea       = save.currentArea
        currentAreaIndex  = save.currentAreaIndex
        totalAreasCleared = save.totalAreasCleared
        screen            = save.isInCombat ? .combat : .dungeonMap
    }

    /// Prepare to create a new character in the given slot, then show class selection.
    func prepareNewCharacter(slot: Int) {
        currentSlot = slot
        screen      = .classSelect
    }

    // MARK: - New Game

    func startNewGame(with heroClass: HeroClass) {
        SaveManager.saveLastClass(heroClass)
        SaveManager.delete(slot: currentSlot)
        let deck = CardDatabase.startingDeck(for: heroClass)
        hero              = Hero(heroClass: heroClass, startingDeck: deck)
        currentAreaIndex  = 1
        totalAreasCleared = 0
        currentArea       = AreaDatabase.generate(areaIndex: 1)
        combatLog         = []
        hasDungeonPortalOpen = false
        screen            = .town
        autoSave()
    }

    /// Return to the character select screen (saves current state first).
    func exitToCharacterSelect() {
        autoSave()
        hero = nil
        currentArea = nil
        screen = .characterSelect
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
            let healed = 3
            hero?.restoreExiledCards(count: healed)
            log("🔥 Rested — restored \(healed) card(s) from exile.")
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
            let before = h.exiledCards.count
            h.restoreExiledCards(count: amt)
            let actual = before - h.exiledCards.count
            lines.append("Restored \(actual) card(s) from exile.")

        case .healPercent(let pct):
            let amt = max(1, Int(Double(h.exiledCards.count) * pct))
            let before = h.exiledCards.count
            h.restoreExiledCards(count: amt)
            let actual = before - h.exiledCards.count
            lines.append("Restored \(actual) card(s) from exile.")

        case .damage(let amt):
            let cardsExiled = max(1, amt / 5)
            h.exileCards(count: cardsExiled)
            lines.append("Lost \(cardsExiled) card(s) to damage.")

        case .damagePercent(let pct):
            let rawAmt = max(1, Int(Double(h.totalCardPool) * pct))
            let cardsExiled = max(1, rawAmt)
            h.exileCards(count: cardsExiled)
            lines.append("Lost \(cardsExiled) card(s) to damage.")

        case .gold:
            break   // gold removed from game — treat as nothing

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
        lastCombatLevelsGained = 0

        h.deck          = (h.deck + h.discardPile + h.hand).shuffled()
        h.discardPile   = []
        h.hand          = []
        h.block         = h.startingBlock
        h.currentEnergy = h.maxEnergy
        h.combatStrength = 0
        // exiledCards persist between fights — permanent run damage
        hero = h
        combatLog = []
        playedCards = []
        lastPlayedCardType = nil
        amplifyActive = false
        combatEvasionCharges    = h.skillPassives.evasionCharges
        hasEnduredThisCombat    = false
        pendingFreeCard         = false
        pendingAssassinateReady = false
        deckRecycleCount        = 0
        stagedCardID            = nil
        pitchedForStagedIDs     = []
        // Each enemy draws their opening block hand
        for idx in currentEnemies.indices { currentEnemies[idx].drawBlockHand() }
        log("⚔️ Combat begins!")
        if (hero?.startingBlock ?? 0) > 0 { log("🛡️ Starting block: \(hero!.startingBlock)") }
        drawCards(hero?.cardDrawCount ?? 5)
        autoSave()
    }

    // MARK: - Playing Cards

    /// A card can be played if either:
    /// - It costs 0 (free), OR
    /// - It is the currently staged card and pitch cost is already met, OR
    /// - It is not staged yet and the hand has enough pitch headroom after subtracting itself.
    /// This check is used by the UI to grey out unplayable cards; actual enforcement is in stageCard/confirmPlay.
    func canPlay(_ card: Card) -> Bool {
        guard !isBlockPhase else { return false }
        if pendingFreeCard || (pendingAssassinateReady && card.type == .attack) { return true }
        if card.cost == 0 { return true }
        // If this card is staged, it's playable (cost gating happens at confirmPlay)
        if card.id == stagedCardID { return true }
        // Otherwise, check whether there are enough other cards in hand to cover its cost
        let otherHandPitch = hero?.hand
            .filter { $0.id != card.id }
            .map(\.pitchValue)
            .reduce(0, +) ?? 0
        return otherHandPitch >= card.cost
    }

    // MARK: - Pitch / Stage

    /// Primary hand-card tap handler. Routes to immediate play (cost 0) or staging (cost > 0).
    func handleCardTap(_ card: Card, targeting enemyIndex: Int = 0) {
        guard !isBlockPhase else { return }

        // Tapping the staged card confirms the play if cost is met
        if card.id == stagedCardID {
            if pitchCostMet {
                confirmStagedPlay(targeting: enemyIndex)
            } else {
                // Not enough pitch yet — cancel staging
                cancelStage()
            }
            return
        }

        // If there's an active staged card, tap on other hand cards pitches them
        if stagedCardID != nil {
            togglePitch(card)
            return
        }

        // No staged card — try to play directly (free cards) or stage
        let isFree = pendingFreeCard || (pendingAssassinateReady && card.type == .attack)
        if isFree || card.cost == 0 {
            play(card, targeting: enemyIndex, pitching: [])
        } else {
            stageCard(card)
        }
    }

    /// Stage a card: it waits for pitch cards to cover its cost.
    func stageCard(_ card: Card) {
        guard hero?.hand.contains(where: { $0.id == card.id }) == true else { return }
        stagedCardID        = card.id
        pitchedForStagedIDs = []
    }

    /// Toggle a hand card as pitched for the staged card.
    func togglePitch(_ card: Card) {
        guard let stagedID = stagedCardID, card.id != stagedID else { return }
        guard hero?.hand.contains(where: { $0.id == card.id }) == true else { return }
        if let idx = pitchedForStagedIDs.firstIndex(of: card.id) {
            pitchedForStagedIDs.remove(at: idx)
        } else {
            pitchedForStagedIDs.append(card.id)
        }
    }

    /// Confirm the staged play: move pitched cards to deck bottom, then play the staged card.
    func confirmStagedPlay(targeting enemyIndex: Int = 0) {
        guard let stagedID = stagedCardID,
              var h = hero,
              let staged = h.hand.first(where: { $0.id == stagedID }),
              pitchCostMet else { return }

        // Move pitched cards to the bottom of the deck (in the order they were selected)
        let pitched = pitchedForStagedIDs.compactMap { id in h.hand.first { $0.id == id } }
        for pitchedCard in pitched {
            h.hand.removeAll { $0.id == pitchedCard.id }
            h.deck.append(pitchedCard)   // bottom of deck
        }
        if !pitched.isEmpty {
            let names = pitched.map(\.name).joined(separator: ", ")
            log("🔄 Pitched \(names) to fuel \(staged.name).")
        }
        hero = h

        // Clear pitch state before playing
        stagedCardID        = nil
        pitchedForStagedIDs = []

        // Play the staged card (energy cost bypass — pitch already paid)
        play(staged, targeting: enemyIndex, pitching: pitched)
    }

    /// Cancel staging without playing the card.
    func cancelStage() {
        stagedCardID        = nil
        pitchedForStagedIDs = []
    }

    /// Internal play — called after pitch cost is resolved. `pitching` is informational only (already removed from hand).
    func play(_ card: Card, targeting enemyIndex: Int = 0, pitching: [Card] = []) {
        guard var h = hero,
              let handIndex = h.hand.firstIndex(where: { $0.id == card.id }) else { return }

        // ── Bloodlust / Assassinate free-card check ──────────────────────
        let isFree = pendingFreeCard || (pendingAssassinateReady && card.type == .attack)
        if isFree {
            if pendingFreeCard         { pendingFreeCard = false;         log("🩸 Bloodlust: free card!") }
            if pendingAssassinateReady { pendingAssassinateReady = false; log("🎯 Assassinate: free attack!") }
        }
        // No energy deduction — cost is covered by pitch cards (already moved to deck bottom)
        h.hand.remove(at: handIndex)
        if !card.effect.exhausts {
            h.discardPile.append(card)
        } else {
            log("💨 \(card.name) exhausted — removed from your deck.")
        }
        hero = h

        let fx  = card.effect
        let passives = hero?.skillPassives ?? SkillPassives()
        let cardsPlayedThisTurn = playedCards.count + 1  // position of this card (1-based)

        // PlayedCardRecord tracking
        var rDmg: [UUID: Int] = [:]
        var rBlock = 0; var rPoison = 0; var rBurn = 0; var rBurnAll = 0
        var rWeak = 0; var rVuln = 0; var rStrength = 0; var rBleed = 0; var rChill = 0
        var rAmplify = false; var rDraw = 0; var rHeal = 0

        // ── Damage ────────────────────────────────────────────────────────
        let hasDamage = fx.damage > 0 || fx.damageFromBlock
        if hasDamage {
            let isPhysical = fx.damageType == .physical
            let isIce      = fx.damageType == .ice
            let scalingBonus: Int = isPhysical
                ? (hero?.attackBonus ?? 0) + (hero?.combatStrength ?? 0)
                : (hero?.spellpower ?? 0)
            let baseDmg: Int = fx.damageFromBlock
                ? max(1, hero?.block ?? 0)
                : fx.damage + scalingBonus
            let weakMult   = (hero?.weakStacks ?? 0) > 0 ? 0.75 : 1.0
            let amplifyMult: Double = amplifyActive ? 2.0 : 1.0
            if amplifyActive { amplifyActive = false; log("⚡ Amplified!") }
            var perHit = max(1, Int(Double(baseDmg) * weakMult * amplifyMult))

            // ── Backstab: +N per status stack on target ──────────────────
            if isPhysical && passives.backstabPerStack > 0 && enemyIndex < currentEnemies.count {
                let target = currentEnemies[enemyIndex]
                let statusCount = target.poisonStacks + target.burnStacks + target.bleedStacks
                    + target.weakStacks + target.vulnerableStacks + target.chillStacks
                if statusCount > 0 {
                    let bonus = passives.backstabPerStack * statusCount
                    perHit += bonus
                    log("🗡️ Backstab! +\(bonus) damage (\(statusCount) status stacks).")
                }
            }

            // ── Shatter: 2× on Frozen enemy ─────────────────────────────
            if passives.hasShatter && enemyIndex < currentEnemies.count
                && currentEnemies[enemyIndex].isFrozen {
                perHit *= 2
                currentEnemies[enemyIndex].frozenTurnsLeft = 0
                currentEnemies[enemyIndex].chillStacks = 0
                log("💥 Shatter! Frozen enemy takes double damage!")
            }

            let comboAdd = (fx.comboBonus > 0 && lastPlayedCardType == .attack) ? fx.comboBonus : 0
            if comboAdd > 0 { log("🗡️ Combo! +\(comboAdd) bonus damage.") }
            let typeTag = isPhysical ? "" : " (\(fx.damageType.rawValue))"

            if fx.damageAllEnemies {
                let total = perHit + comboAdd
                for idx in currentEnemies.indices {
                    rDmg[currentEnemies[idx].id, default: 0] += total
                    applyDamageToEnemy(at: idx, amount: total)
                    // Bleed ticks on all physical AoE
                    if isPhysical { triggerBleedTick(on: currentEnemies[idx].id, hits: fx.times) }
                }
                log("\(card.name): \(total)\(typeTag) damage vs all enemies.")
            } else if enemyIndex < currentEnemies.count {
                let totalHit = (perHit * fx.times) + comboAdd
                let target   = currentEnemies[enemyIndex]
                rDmg[target.id, default: 0] += totalHit
                var suffix = fx.times > 1 ? " ×\(fx.times)" : ""
                if comboAdd > 0 { suffix += " (combo)" }
                log("\(card.name): \(totalHit)\(typeTag) damage vs \(target.name)\(suffix).")
                applyDamageToEnemy(at: enemyIndex, amount: totalHit)

                // ── Bleed tick ──────────────────────────────────────────
                if isPhysical { triggerBleedTick(on: target.id, hits: fx.times) }

                // ── Chill on ice hits (from card, not passive) ──────────
                if isIce && fx.applyChillStacks > 0 {
                    applyChillToEnemy(at: enemyIndex, stacks: fx.applyChillStacks)
                    rChill = fx.applyChillStacks
                }
            }

            // ── Lifelink: restore exiled cards per physical hit ──────────
            if isPhysical && passives.lifeStealPerHit > 0 {
                let restored = passives.lifeStealPerHit * fx.times
                hero?.restoreExiledCards(count: restored)
                log("❤️ Lifelink: +\(restored) card(s) restored.")
            }

            // ── Poison on Hit (passive) ─────────────────────────────────
            let poisonBonus = hero?.poisonOnHit ?? 0
            if isPhysical && poisonBonus > 0 && enemyIndex < currentEnemies.count {
                currentEnemies[enemyIndex].poisonStacks += poisonBonus
                log("☠️ Poison on Hit: \(currentEnemies[enemyIndex].name) +\(poisonBonus) poison.")
            }

            // ── Bleed on Hit (passive) ──────────────────────────────────
            let bleedBonus = passives.bleedOnHit
            if isPhysical && bleedBonus > 0 && enemyIndex < currentEnemies.count {
                let stacks = bleedBonus * fx.times
                currentEnemies[enemyIndex].bleedStacks += stacks
                rBleed += stacks
                log("🩸 Bleed on Hit: \(currentEnemies[enemyIndex].name) +\(stacks) bleed.")
            }

            // ── Chill on Hit (passive — ice attacks) ────────────────────
            let chillBonus = passives.chillOnHit
            if isIce && chillBonus > 0 && !fx.damageAllEnemies && enemyIndex < currentEnemies.count {
                applyChillToEnemy(at: enemyIndex, stacks: chillBonus)
                rChill += chillBonus
            } else if isIce && chillBonus > 0 && fx.damageAllEnemies {
                for idx in currentEnemies.indices { applyChillToEnemy(at: idx, stacks: chillBonus) }
            }
        }

        // ── Block ─────────────────────────────────────────────────────────
        if fx.block > 0 {
            let amt = fx.block + (hero?.defenseBonus ?? 0)
            hero?.block += amt
            rBlock = amt
            log("Gained \(amt) block.")
        }

        // ── Status effects on targeted enemy ─────────────────────────────
        if enemyIndex < currentEnemies.count {
            let tname = currentEnemies[enemyIndex].name
            if fx.poisonStacks > 0 {
                currentEnemies[enemyIndex].poisonStacks += fx.poisonStacks
                rPoison = fx.poisonStacks
                log("☠️ \(tname) poisoned (\(fx.poisonStacks) stacks).")
                if passives.hasShadowMark { applyShadowMark(at: enemyIndex) }
            }
            if fx.applyBurn > 0 && !fx.applyBurnAll {
                currentEnemies[enemyIndex].burnStacks += fx.applyBurn
                rBurn = fx.applyBurn
                log("🔥 \(tname) burning (\(fx.applyBurn) stacks).")
                checkIgniteBurst(at: enemyIndex)
                if passives.hasShadowMark { applyShadowMark(at: enemyIndex) }
            }
            if fx.applyBleed > 0 {
                currentEnemies[enemyIndex].bleedStacks += fx.applyBleed
                rBleed += fx.applyBleed
                log("🩸 \(tname) bleeding (\(fx.applyBleed) stacks).")
                if passives.hasShadowMark { applyShadowMark(at: enemyIndex) }
            }
            if fx.applyChillStacks > 0 && fx.damageType != .ice {
                // Non-ice chill application (explicit field without damage)
                applyChillToEnemy(at: enemyIndex, stacks: fx.applyChillStacks)
                rChill += fx.applyChillStacks
                if passives.hasShadowMark { applyShadowMark(at: enemyIndex) }
            }
            if fx.weakStacks > 0 {
                currentEnemies[enemyIndex].weakStacks += fx.weakStacks
                rWeak = fx.weakStacks
                log("💀 \(tname) weakened (\(fx.weakStacks) stacks).")
                if passives.hasShadowMark { applyShadowMark(at: enemyIndex) }
            }
            if fx.vulnerableStacks > 0 {
                currentEnemies[enemyIndex].vulnerableStacks += fx.vulnerableStacks
                rVuln = fx.vulnerableStacks
                log("🎯 \(tname) vulnerable (\(fx.vulnerableStacks) stacks).")
            }

            // ── Assassinate trigger check ────────────────────────────────
            if passives.hasAssassinate && !pendingAssassinateReady {
                let target = currentEnemies[enemyIndex]
                let totalStacks = target.poisonStacks + target.burnStacks + target.bleedStacks
                    + target.weakStacks + target.vulnerableStacks + target.chillStacks
                if totalStacks >= 4 {
                    pendingAssassinateReady = true
                    log("🎯 Assassinate ready! Next attack against \(target.name) is free.")
                }
            }
        }

        // ── Burn all enemies ──────────────────────────────────────────────
        if fx.applyBurnAll && fx.applyBurn > 0 {
            for idx in currentEnemies.indices {
                currentEnemies[idx].burnStacks += fx.applyBurn
                checkIgniteBurst(at: idx)
            }
            rBurnAll = fx.applyBurn
            log("🔥 All enemies burning (\(fx.applyBurn) stacks).")
        }

        // ── Arcane keyword ────────────────────────────────────────────────
        if fx.arcaneBonus > 0 && passives.arcaneThreshold > 0
            && cardsPlayedThisTurn >= passives.arcaneThreshold
            && enemyIndex < currentEnemies.count {
            let rawBonus = fx.arcaneBonus
            let boosted  = max(1, Int(Double(rawBonus) * passives.arcaneMultiplier))
            rDmg[currentEnemies[enemyIndex].id, default: 0] += boosted
            applyDamageToEnemy(at: enemyIndex, amount: boosted)
            log("⚡ Arcane! +\(boosted) arcane bonus damage.")
        }

        // ── Barbarian Strength gain ───────────────────────────────────────
        if fx.strengthGain > 0 {
            hero?.combatStrength += fx.strengthGain
            rStrength = fx.strengthGain
            log("💪 Gained \(fx.strengthGain) Strength. Total: \(hero?.combatStrength ?? 0).")
        }

        // ── Sorceress Amplify ─────────────────────────────────────────────
        if fx.amplifyNext {
            amplifyActive = true
            rAmplify = true
            log("⚡ Amplify active — next attack deals double damage.")
        }

        // ── Utility ───────────────────────────────────────────────────────
        if fx.draw > 0         { drawCards(fx.draw); rDraw = fx.draw }
        if fx.energyGain > 0   { hero?.currentEnergy += fx.energyGain }
        if fx.heal > 0         { hero?.restoreExiledCards(count: fx.heal); rHeal = fx.heal; log("❤️ Restored \(fx.heal) card(s) from exile.") }

        // ── Played-card record ────────────────────────────────────────────
        let targetEnemyId = enemyIndex < currentEnemies.count ? currentEnemies[enemyIndex].id : nil
        playedCards.append(PlayedCardRecord(
            card: card, targetEnemyId: targetEnemyId,
            damageContributions: rDmg,
            blockGained: rBlock,
            poisonApplied: rPoison, burnApplied: rBurn, burnAllApplied: rBurnAll,
            weakApplied: rWeak, vulnerableApplied: rVuln,
            bleedApplied: rBleed, chillApplied: rChill,
            strengthGained: rStrength, amplifyActivated: rAmplify,
            drawCount: rDraw, healAmount: rHeal
        ))

        lastPlayedCardType = card.type

        // Kill check
        let justDied = currentEnemies.filter { !$0.isAlive }.count
        if justDied > 0 { awardKills(count: justDied) }
        currentEnemies.removeAll { !$0.isAlive }
        if currentEnemies.isEmpty { endCombat(won: true) }
    }

    // MARK: - Keyword helpers

    /// Trigger bleed ticks for `hits` physical hits against an enemy.
    /// Each tick deals current bleedStacks as direct damage and decrements.
    private func triggerBleedTick(on enemyId: UUID, hits: Int) {
        guard let idx = currentEnemies.firstIndex(where: { $0.id == enemyId }) else { return }
        var totalCardsLost = 0
        for _ in 0..<hits {
            guard currentEnemies[idx].bleedStacks > 0 else { break }
            let cardsLost = max(1, currentEnemies[idx].bleedStacks / 5)
            totalCardsLost += cardsLost
            currentEnemies[idx].lifeCards = max(0, currentEnemies[idx].lifeCards - cardsLost)
            currentEnemies[idx].bleedStacks -= 1
        }
        if totalCardsLost > 0 {
            log("🩸 \(currentEnemies[idx].name) bleeds for \(totalCardsLost) life card(s).")
        }
    }

    /// Apply damage to an enemy immediately: enemy auto-blocks first, remainder reduces HP.
    ///
    /// PvP hook: in a multiplayer match this function would instead forward `amount` to the
    /// server and skip `autoBlock` — the human defender handles their block phase explicitly.
    /// See docs/multiplayer-architecture.md for the planned intercept point.
    private func applyDamageToEnemy(at idx: Int, amount: Int) {
        guard idx < currentEnemies.count, amount > 0 else { return }
        let name    = currentEnemies[idx].name
        let blocked = currentEnemies[idx].autoBlock(incoming: amount)
        let leftover = max(0, amount - blocked)
        if blocked > 0 {
            log("🛡️ \(name) blocks \(blocked) damage.")
        }
        if leftover > 0 {
            let cardsExiled = max(1, leftover / 5)
            currentEnemies[idx].takeDamage(cardsExiled)
            log("💀 \(name) loses \(cardsExiled) life card(s).")
        } else {
            log("✅ \(name) fully blocked the attack!")
        }
    }

    /// Apply N chill stacks to enemy at index; freeze if threshold reached.
    private func applyChillToEnemy(at idx: Int, stacks: Int) {
        guard idx < currentEnemies.count else { return }
        let passives = hero?.skillPassives ?? SkillPassives()
        let threshold = passives.freezeThreshold
        guard threshold > 0 else { return }   // chill only works if Frost Mage unlocked
        let name = currentEnemies[idx].name

        if currentEnemies[idx].isFrozen && !passives.hasPermafrost {
            // Already frozen — don't stack chill until it thaws
            return
        }
        currentEnemies[idx].chillStacks += stacks
        log("❄️ \(name) chilled (\(currentEnemies[idx].chillStacks) stacks).")

        if currentEnemies[idx].chillStacks >= threshold && !currentEnemies[idx].isFrozen {
            let freezeTurns = passives.hasPermafrost ? 2 : 1
            currentEnemies[idx].frozenTurnsLeft = freezeTurns
            if !passives.hasPermafrost { currentEnemies[idx].chillStacks = 0 }
            log("❄️❄️ \(name) is FROZEN for \(freezeTurns) turn(s)!")
        }
    }

    /// Apply Shadow Mark: applying any status also adds 1 Vulnerable (once per play call, for each status).
    private func applyShadowMark(at idx: Int) {
        guard idx < currentEnemies.count else { return }
        currentEnemies[idx].vulnerableStacks += 1
        log("🌑 Shadow Mark: \(currentEnemies[idx].name) +1 Vulnerable.")
    }

    /// Check if Ignite Burst threshold reached on an enemy.
    private func checkIgniteBurst(at idx: Int) {
        guard idx < currentEnemies.count else { return }
        let threshold = hero?.skillPassives.igniteBurstThreshold ?? 0
        guard threshold > 0 else { return }
        let burn = currentEnemies[idx].burnStacks
        if burn >= threshold {
            let name = currentEnemies[idx].name
            let cardsLost = max(1, burn / 5)
            log("💥 IGNITE BURST! \(name) explodes for \(cardsLost) life card(s) AoE!")
            currentEnemies[idx].burnStacks = 0
            for i in currentEnemies.indices {
                currentEnemies[i].lifeCards = max(0, currentEnemies[i].lifeCards - cardsLost)
            }
        }
    }

    // MARK: - End Turn → Block Phase

    func endTurn() {
        guard hero != nil else { return }

        log("── Enemy Turn ──")

        // Execute non-attack enemy actions immediately (defend, poison, weaken)
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

        // Collect attack intents into the block phase queue (skip frozen enemies)
        pendingAttacks = currentEnemies.compactMap { enemy in
            if case .attack(var dmg) = enemy.currentIntent {
                if enemy.isFrozen {
                    log("❄️ \(enemy.name) is frozen and cannot attack!")
                    return nil
                }
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

    // MARK: - Recall (unplay a card from the played queue)

    func unplayCard(_ record: PlayedCardRecord) {
        guard record.canRecall, !isBlockPhase else { return }
        guard var h = hero else { return }
        // Card must still be in the discard pile (not already recalled or exhausted elsewhere)
        guard let discardIdx = h.discardPile.firstIndex(where: { $0.id == record.card.id }) else { return }

        // All hero mutations go through the local copy — single write at the end avoids
        // exclusive-access violations from reading and writing `hero` in the same expression.
        h.discardPile.remove(at: discardIdx)
        h.hand.append(record.card)
        h.currentEnergy = min(h.maxEnergy, h.currentEnergy + record.card.cost)
        if record.blockGained > 0 {
            h.block = max(0, h.block - record.blockGained)
        }
        if record.strengthGained > 0 {
            h.combatStrength = max(0, h.combatStrength - record.strengthGained)
        }
        hero = h  // single write

        // Reverse status effects on targeted enemy
        if let tid = record.targetEnemyId, let idx = currentEnemies.firstIndex(where: { $0.id == tid }) {
            if record.poisonApplied > 0 {
                currentEnemies[idx].poisonStacks = max(0, currentEnemies[idx].poisonStacks - record.poisonApplied)
            }
            if record.burnApplied > 0 {
                currentEnemies[idx].burnStacks = max(0, currentEnemies[idx].burnStacks - record.burnApplied)
            }
            if record.bleedApplied > 0 {
                currentEnemies[idx].bleedStacks = max(0, currentEnemies[idx].bleedStacks - record.bleedApplied)
            }
            if record.chillApplied > 0 {
                currentEnemies[idx].chillStacks = max(0, currentEnemies[idx].chillStacks - record.chillApplied)
            }
            if record.weakApplied > 0 {
                currentEnemies[idx].weakStacks = max(0, currentEnemies[idx].weakStacks - record.weakApplied)
            }
            if record.vulnerableApplied > 0 {
                currentEnemies[idx].vulnerableStacks = max(0, currentEnemies[idx].vulnerableStacks - record.vulnerableApplied)
            }
        }

        // Reverse burn-all
        if record.burnAllApplied > 0 {
            for idx in currentEnemies.indices {
                currentEnemies[idx].burnStacks = max(0, currentEnemies[idx].burnStacks - record.burnAllApplied)
            }
        }

        // Reverse amplify only if it hasn't been consumed yet
        if record.amplifyActivated && amplifyActive { amplifyActive = false }

        // Restore lastPlayedCardType to previous played card (or nil)
        playedCards.removeAll { $0.id == record.id }
        lastPlayedCardType = playedCards.last?.card.type

        log("↩️ Recalled \(record.card.name).")
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
        let passives = h.skillPassives

        // Remove committed cards from hand → discard
        let blockedIDs = Set(blockedCards.map(\.id))
        let totalDefense = blockedCards.map(\.defenseValue).reduce(0, +)
        h.hand.removeAll { blockedIDs.contains($0.id) }
        h.discardPile.append(contentsOf: blockedCards)

        // Discard the rest of the hand (unblocked, unplayed)
        h.discardPile.append(contentsOf: h.hand)
        h.hand = []
        hero = h

        // ── Evasion: auto-dodge attacks using charges ─────────────────────
        var resolvedAttacks = pendingAttacks
        if combatEvasionCharges > 0 && !resolvedAttacks.isEmpty {
            let sorted = resolvedAttacks.sorted { $0.rawDamage > $1.rawDamage }
            var dodged = Set<UUID>()
            var chargesSpent = 0
            for atk in sorted where chargesSpent < combatEvasionCharges {
                dodged.insert(atk.id)
                chargesSpent += 1
                log("💨 Evaded \(atk.rawDamage) damage from \(atk.enemyName)!")
            }
            resolvedAttacks.removeAll { dodged.contains($0.id) }
            combatEvasionCharges -= chargesSpent
            // Untouchable: +2 ATK per dodge
            if passives.hasUntouchable && chargesSpent > 0 {
                hero?.combatStrength += 2 * chargesSpent
                log("💨 Untouchable: +\(2 * chargesSpent) ATK this combat.")
            }
        }

        // Apply incoming damage minus card blocks
        let totalIncoming = resolvedAttacks.map(\.rawDamage).reduce(0, +)
        if totalIncoming > 0 {
            let remaining = max(0, totalIncoming - totalDefense)
            if !blockedCards.isEmpty {
                let blocked = min(totalDefense, totalIncoming)
                log("🛡️ Blocked \(blocked) damage with \(blockedCards.count) card(s).")
            }
            if remaining > 0 {
                let cardsExiled = max(1, remaining / 5)
                // ── Endure: survive lethal once ──────────────────────────
                if passives.hasEndure && !hasEnduredThisCombat
                    && (hero?.totalCardPool ?? 0) <= cardsExiled {
                    // Leave exactly 1 card in the pool
                    if var h = hero {
                        let toExile = max(0, h.totalCardPool - 1)
                        if toExile > 0 { h.exileCards(count: toExile) }
                        hero = h
                    }
                    hasEnduredThisCombat = true
                    log("🛡️ Endure! Survived a lethal blow!")
                } else {
                    hero?.exileCards(count: cardsExiled)
                    log("💀 You lose \(cardsExiled) card(s) to the attack!")
                }
                // ── Rage: +N STR per damage event ───────────────────────
                if passives.rageOnHit > 0 {
                    hero?.combatStrength += passives.rageOnHit
                    log("🩸 Rage: +\(passives.rageOnHit) Strength (\(hero?.combatStrength ?? 0) total).")
                }
            } else {
                log("✅ Fully blocked all incoming damage!")
            }

            // Advance enemy actions for attacks that resolved
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

        // Log burn ticks before enemies start new turn
        for idx in currentEnemies.indices {
            let burn = currentEnemies[idx].burnStacks
            if burn > 0 {
                log("🔥 \(currentEnemies[idx].name) burns for \(burn) damage.")
            }
        }
        log("── Your Turn ──")
        if let passives = hero?.skillPassives, passives.hasJuggernaut {
            // Juggernaut: carry leftover block into next turn (add startingBlock on top)
            let carried = hero?.block ?? 0
            hero?.startNewTurn()
            hero?.block += carried
            if carried > 0 { log("🪨 Juggernaut: carried \(carried) block into this turn.") }
        } else {
            hero?.startNewTurn()
        }
        for idx in currentEnemies.indices {
            currentEnemies[idx].startNewTurn()   // poison/burn tick + drawBlockHand
        }
        // Kill check after DoTs
        let dotDead = currentEnemies.filter { !$0.isAlive }.count
        if dotDead > 0 { awardKills(count: dotDead) }
        currentEnemies.removeAll { !$0.isAlive }
        if currentEnemies.isEmpty { endCombat(won: true); return }

        playedCards = []
        lastPlayedCardType = nil
        amplifyActive = false
        pendingFreeCard = false
        pendingAssassinateReady = false
        stagedCardID = nil
        pitchedForStagedIDs = []
        drawCards(hero?.cardDrawCount ?? 5)
        autoSave()
    }


    // Extracted kill-reward helper used in both play() and resolveBlockPhase()
    private func awardKills(count: Int) {
        let passives = hero?.skillPassives ?? SkillPassives()

        let lifePerKill = hero?.lifeOnKill ?? 0
        if lifePerKill > 0 {
            let gained = lifePerKill * count
            hero?.restoreExiledCards(count: gained)
            log("❤️ Life on Kill: +\(gained) card(s) restored")
        }
        let energyPerKill = hero?.energyOnKill ?? 0
        if energyPerKill > 0 {
            let gain = min(energyPerKill * count, (hero?.maxEnergy ?? 0) - (hero?.currentEnergy ?? 0))
            if gain > 0 {
                hero?.currentEnergy += gain
                log("⚡ Energy on Kill: +\(gain)")
            }
        }

        // ── Barbarian kill keywords ───────────────────────────────────────
        if passives.hasBloodlust && !pendingFreeCard {
            pendingFreeCard = true
            log("🩸 Bloodlust: next card this turn is free!")
        }
        if passives.hasRampage { drawCards(1); log("⚔️ Rampage: drew 1 card.") }
        if passives.hasWarlordGambit {
            hero?.combatStrength += 3 * count
            log("🪖 Warlord's Gambit: +\(3 * count) Strength!")
        }

        // ── Rogue: Death by a Thousand Cuts — spread bleed ───────────────
        if passives.hasDeathCuts {
            let deadWithBleed = currentEnemies.filter { !$0.isAlive && $0.bleedStacks > 0 }
            if !deadWithBleed.isEmpty {
                let living = currentEnemies.filter { $0.isAlive }
                if let recipient = living.randomElement(),
                   let idx = currentEnemies.firstIndex(where: { $0.id == recipient.id }) {
                    let totalBleed = deadWithBleed.map(\.bleedStacks).reduce(0, +)
                    currentEnemies[idx].bleedStacks += totalBleed
                    log("🩸 Death Cuts: \(totalBleed) bleed transferred to \(recipient.name)!")
                }
            }
        }

        // ── Sorceress: Conflagration — spread burn on kill ────────────────
        if passives.hasConflagration {
            let deadWithBurn = currentEnemies.filter { !$0.isAlive && $0.burnStacks > 0 }
            if !deadWithBurn.isEmpty {
                for idx in currentEnemies.indices where currentEnemies[idx].isAlive {
                    currentEnemies[idx].burnStacks += 5
                }
                log("🔥 Conflagration: 5 burn spread to all enemies!")
            }
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
    }

    // MARK: - Draw

    private func drawCards(_ count: Int) {
        guard var h = hero else { return }
        for _ in 0..<count {
            if h.deck.isEmpty {
                guard !h.discardPile.isEmpty else { break }
                h.deck        = h.discardPile.shuffled()
                h.discardPile = []
                deckRecycleCount += 1
                log("♻️ Deck exhausted — reshuffled discard pile.")
                applyRecyclePenalty(to: &h)
            }
            if !h.deck.isEmpty {
                h.hand.append(h.deck.removeFirst())
            }
        }
        hero = h
    }

    /// Class-specific penalty for exhausting the deck.
    /// Add a new case here when introducing a new class.
    private func applyRecyclePenalty(to h: inout Hero) {
        switch h.heroClass {
        case .barbarian:
            // Barbarian burns through rage when gassed out — lose all combat strength.
            if h.combatStrength > 0 {
                log("😤 Exhausted! Lost \(h.combatStrength) Strength (×\(deckRecycleCount) recycle).")
                h.combatStrength = 0
            } else {
                log("😤 Exhausted! (No Strength to lose.)")
            }
        case .sorceress:
            // Rushing the spell rotation causes arcane backlash — escalates per recycle.
            let dmg = 2 * deckRecycleCount
            let cardsExiled = max(1, dmg / 5)
            h.exileCards(count: cardsExiled)
            log("🌀 Arcane backlash! Lost \(cardsExiled) card(s) (×\(deckRecycleCount) recycle).")
        case .rogue:
            // Rogues cycle fast by design — no penalty.
            log("💨 Fleet-footed — no recycle penalty.")
        }
    }

    // MARK: - Combat End

    private func endCombat(won: Bool) {
        // Reset combat-only buffs
        hero?.combatStrength = 0
        lastPlayedCardType = nil
        amplifyActive = false
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
        // All loot is now combat cards — goes to collection
        h.cardCollection.append(card)
        groundLoot.remove(at: idx)
        hero = h
        autoSave()
    }

    // MARK: - Deck Management

    /// Move a card from collection into the active deck (max 60 cards).
    /// Off-class cards cannot be added — they must be traded via the stash.
    func addCardToDeck(_ card: Card) {
        guard var h = hero else { return }
        // Enforce class restriction
        if let cardClass = card.heroClass, cardClass != h.heroClass { return }
        let deckTotal = h.deck.count + h.hand.count + h.discardPile.count
        guard deckTotal < Hero.maxDeckSize else { return }
        guard let idx = h.cardCollection.firstIndex(where: { $0.id == card.id }) else { return }
        h.cardCollection.remove(at: idx)
        h.deck.append(card)
        hero = h
        autoSave()
    }

    // MARK: - Shared Stash

    /// Deposit a card from the hero's collection into the shared stash.
    func depositToStash(_ card: Card) {
        guard var h = hero,
              let idx = h.cardCollection.firstIndex(where: { $0.id == card.id }) else { return }
        h.cardCollection.remove(at: idx)
        sharedStash.cards.append(card)
        hero = h
        autoSave()
        SaveManager.saveStash(sharedStash)
    }

    /// Take a card from the shared stash into the hero's collection.
    func withdrawFromStash(_ card: Card) {
        guard var h = hero,
              let idx = sharedStash.cards.firstIndex(where: { $0.id == card.id }) else { return }
        sharedStash.cards.remove(at: idx)
        h.cardCollection.append(card)
        hero = h
        autoSave()
        SaveManager.saveStash(sharedStash)
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
                screen = .dungeonMap
                autoSave()
            }
        } else {
            screen = .dungeonMap
            autoSave()
        }
    }

    // MARK: - Inventory Management (stub — equipment system removed)

    /// No-op: equipment system has been removed. Kept for save compatibility.
    func dropFromInventory(_ card: Card) {
        autoSave()
    }

    // MARK: - Stat Allocation

    func allocateStat(_ key: StatKey) {
        guard var h = hero, h.statPoints > 0 else { return }
        h.statPoints -= 1
        h.stats[key] += 1
        // Vitality: restore exiled cards (1 per 3 VIT is handled elsewhere; here just track stat)
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
        ), slot: currentSlot)
    }

    // MARK: - EXP & Gold

    private func expPerKill() -> Int {
        let base = currentAreaIndex * 12 + 18
        let eliteBonus = currentRoomIsElite ? 3 : 1
        return (currentRoomIsBoss ? base * 2 : base) * eliteBonus / (currentRoomIsElite ? 2 : 1)
    }

    // MARK: - Town

    func returnToTown() {
        screen = .town
    }

    // MARK: - Waypoint Travel

    func travelToWaypoint(_ areaIndex: Int) {
        guard hero?.unlockedWaypoints.contains(areaIndex) == true else { return }
        currentAreaIndex     = areaIndex
        currentArea          = AreaDatabase.generate(areaIndex: areaIndex)
        hasDungeonPortalOpen = false
        screen = .dungeonMap
        autoSave()
    }

    func enterDungeon() {
        hasDungeonPortalOpen = false
        screen = .dungeonMap
        autoSave()
    }

    func returnToDungeon() {
        hasDungeonPortalOpen = false
        screen = .dungeonMap
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

        let m = node.mechanic
        // Numeric additive passives
        h.skillPassives.attackBonus      += m.attackBonus
        h.skillPassives.defenseBonus     += m.defenseBonus
        h.skillPassives.spellpowerBonus  += m.spellpowerBonus
        h.skillPassives.drawPerTurn      += m.drawPerTurn
        h.skillPassives.maxEnergyBonus   += m.maxEnergyBonus
        h.skillPassives.lifeOnKill       += m.lifeOnKill
        h.skillPassives.startingBlock    += m.startingBlock
        h.skillPassives.poisonOnHit      += m.poisonOnHit
        h.skillPassives.energyOnKill     += m.energyOnKill
        h.skillPassives.rageOnHit        += m.rageOnHit
        h.skillPassives.lifeStealPerHit  += m.lifeStealPerHit
        h.skillPassives.evasionCharges   += m.evasionCharges
        h.skillPassives.bleedOnHit       += m.bleedOnHit
        h.skillPassives.backstabPerStack += m.backstabPerStack
        h.skillPassives.chillOnHit       += m.chillOnHit
        h.skillPassives.freezeThreshold  += m.freezeThreshold
        h.skillPassives.igniteBurstThreshold += m.igniteBurstThreshold
        h.skillPassives.arcaneThreshold  += m.arcaneThreshold
        h.skillPassives.arcaneMultiplier += m.arcaneMultiplierBonus
        // Boolean OR passives (once on = always on)
        if m.hasBloodlust     { h.skillPassives.hasBloodlust     = true }
        if m.hasRampage       { h.skillPassives.hasRampage       = true }
        if m.hasWarlordGambit { h.skillPassives.hasWarlordGambit = true }
        if m.hasEndure        { h.skillPassives.hasEndure        = true }
        if m.hasJuggernaut    { h.skillPassives.hasJuggernaut    = true }
        if m.hasUntouchable   { h.skillPassives.hasUntouchable   = true }
        if m.hasShadowMark    { h.skillPassives.hasShadowMark    = true }
        if m.hasAssassinate   { h.skillPassives.hasAssassinate   = true }
        if m.hasDeathCuts     { h.skillPassives.hasDeathCuts     = true }
        if m.hasShatter       { h.skillPassives.hasShatter       = true }
        if m.hasPermafrost    { h.skillPassives.hasPermafrost    = true }
        if m.hasConflagration { h.skillPassives.hasConflagration = true }
        // maxHpBonus: no longer applicable — deck is life total
        hero = h
        autoSave()
    }

    // MARK: - Logging

    private func log(_ message: String) {
        combatLog.append(message)
        if combatLog.count > 60 { combatLog.removeFirst() }
    }
}
