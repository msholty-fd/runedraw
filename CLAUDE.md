# Runedraw — CLAUDE.md

This file gives Claude (or any AI agent) the context needed to contribute to Runedraw without re-deriving it from first principles.

> **Maintenance rule for Claude:** After any session that introduces a new mechanic, changes a system's architecture, adds a new file/model, or shifts the product roadmap — update this file to reflect it. Keep it accurate so future sessions don't start cold.

---

## What is Runedraw?

Runedraw is an iOS card game blending **Diablo 2** (action-RPG loot, stat allocation, class fantasy) with **Flesh and Blood / Pokémon TCG** (physical card game combat with a block phase). Think: slay monsters, loot cards and gear, build your deck, progress through areas.

**Target audience:** hardcore mobile gamers who love deck-builders and ARPGs. Eventually a trading/collection layer à la Pokémon TCG or MTG Arena.

---

## Core gameplay loop

```
Town → Dungeon Map → Enter room → Combat → Loot → Repeat
```

1. **Town** — rest, visit shops, equip gear, manage deck
2. **Dungeon Map** — choose rooms (combat, elite, boss, treasure, encounter)
3. **Combat** — draw hand, play cards, block enemy attacks, enemy acts, repeat until one side dies
4. **Loot** — pick up equipment or combat cards; XP + gold rewards
5. **Progression** — level up → stat points + skill points; skill tree unlocks signature class cards

---

## Tech stack

- **SwiftUI + @Observable** — no UIKit, no MVVM framework
- **Single source of truth:** `GameEngine` (class, `@Observable`) owns all mutable state
- **Persistence:** `SaveManager` — JSON encode/decode of `GameState` to disk
- Swift 5.9+, Xcode 15+, iOS 17 target

---

## Project layout

```
runedraw/
  Engine/
    GameEngine.swift        — all game logic, state mutations
  Models/
    Card.swift              — Card, CardEffect, DamageType, StatBonus, etc.
    Hero.swift              — Hero struct, HeroClass, HeroStats, HeroEquipment
    Enemy.swift             — Enemy struct, EnemyCard, block hand logic
    GameState.swift         — GameScreen enum, PendingAttack, save/load types
  Data/
    Cards.swift             — CardDatabase: starting decks + droppable card pools
    Enemies.swift           — EnemyDatabase: regular/elite/boss by tier
    Skills.swift            — SkillDatabase: skill tree nodes per class
    Loot.swift              — LootDatabase: equipment + card drop generation
    Areas.swift             — AreaDatabase: dungeon area definitions
    Items.swift             — BaseItemDatabase, AffixDatabase, UniqueItemDatabase
    Shops.swift             — ShopDatabase
  Views/
    CombatView.swift        — main combat screen (hand, enemies, log, block phase)
    TownView.swift          — town hub
    DungeonMapView.swift    — area map
    CharacterProfileView.swift — profile/stats/skills/deck/equipment/inventory tabs
    LootPickupView.swift    — post-combat loot screen
    SkillTreeView.swift     — full-screen skill tree sheet
    Components/             — HeroPortraitView, CardView, InventoryGridView, etc.
```

---

## Key design decisions

### Damage types and scaling

`CardEffect` has `damageType: DamageType`. Scaling:
- `.physical` → scales off `hero.attackBonus` (STR/5 + weapon attack bonus)
- `.fire`, `.ice`, `.arcane` → scales off `hero.spellpower` (INT/4 + gear spellpowerBonus)
- `.poison` — poison stacks tick each turn, don't scale off a stat yet

### Block phase (symmetrical)

Both hero and enemies block. Flow per turn:

1. **Hero plays cards** — damage goes into `queuedHeroDamage[enemyId]`, not applied yet
2. **Hero ends turn** (`endTurn()`)
3. **Enemy auto-blocks** hero's queued damage greedily (highest DEF card first)
4. **Enemy acts**: non-attack actions execute immediately; attacks queue as `pendingAttacks`
5. If attacks exist → `isBlockPhase = true`; hero taps cards to block
6. **Hero confirms blocks** → `resolveBlockPhase()` applies remaining damage, clears state

Each card has a `defenseValue: Int` — how much damage it absorbs as a block card. Enemies have `blockHand: [EnemyCard]` drawn at turn start.

### Multiple characters & shared stash

- App launches to `CharacterSelectView` (screen `.characterSelect`); 3 save slots
- Saves: `runedraw_save_0/1/2.json`; legacy `runedraw_save.json` auto-migrates to slot 0
- `SaveManager.allSummaries()` returns `[CharacterSummary?]` for the select screen
- `engine.loadCharacter(slot:)` — loads a save; `engine.prepareNewCharacter(slot:)` → classSelect
- `engine.exitToCharacterSelect()` — saves current state, returns to character select
- Shared stash: `SharedStash { cards: [Card] }` saved to `runedraw_stash.json`
- `engine.depositToStash(_ card:)` / `engine.withdrawFromStash(_ card:)` move cards between hero's collection and stash
- Stash accessible from TownView via the 🏦 button → `StashView`

### Deck-building (Diablo-style loot)

- **Starting deck**: 8 class-specific cards from `CardDatabase.startingDeck(for:)`
- **Droppable cards**: `CardDatabase.droppableCard(for:heroClass:rarity:)` — own class cards are 2× weighted, plus one share each for the other two classes, plus neutrals. Off-class cards drop to encourage trading via the stash; they sit in `cardCollection` but cannot be added to the deck (enforced in `addCardToDeck`).
- **`hero.deck`** — active deck used in combat
- **`hero.cardCollection`** — cards owned but not in active deck
- Deck limits: min 20, max 60 (`Hero.minDeckSize` / `Hero.maxDeckSize`)
- Deck management: `engine.addCardToDeck()` / `engine.removeCardFromDeck()`
- Skill tree cards (unlocked via skill points) go directly into the deck at unlock

### Equipment (Diablo 2 style)

Equipment cards go to `hero.inventory` (a 5×8 grid, items take w×h cells). They're equipped to slots (weapon, off-hand, helm, chest, boots, ring, amulet) and contribute `StatBonus` totals. LootDatabase generates common/magic/rare/unique gear.

### Hero stats

- **STR**: +1 attack per 5 pts, unlocks heavy gear
- **DEX**: +1 defense per 5 pts, unlocks light gear
- **VIT**: +3 max HP per point
- **INT**: +1 spellpower per 4 pts, +1 energy per 10 pts, unlocks magic gear

Stat points: 3 per level-up. Allocated in CharacterProfile → Profile tab.

---

## Conventions

- **No force unwraps** except `hero!` in places guarded by game-state invariants (always use `guard var h = hero else { return }` pattern)
- **Save compat**: any new field on a `Codable` model **must** use `decodeIfPresent` with a sensible default in custom `init(from:)`
- **SwiftLint**: project enforces it. Common disable comments used: `// swiftlint:disable type_body_length function_body_length line_length cyclomatic_complexity`
- **No external dependencies** — pure SwiftUI, Foundation, AVFoundation

---

## Future roadmap (as of 2026-04)

1. **Trading/collection layer** — players own cards, can trade. Long-term Pokémon TCG / MTG Arena vision.
2. **More card affixes** — magic/rare cards can have random affixes (e.g., "Sharpened Strike — deal 6 dmg, draw 1")
3. **More classes** — Necromancer, Paladin likely next
4. **PvP** — the symmetrical block phase architecture already supports this
5. **Poison source variety** — poison via physical (poison dagger) OR spells (poison cloud)
6. **Area 9+** — procedurally generated areas beyond the 8 hand-crafted ones
