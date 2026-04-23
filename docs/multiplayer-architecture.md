# Multiplayer Architecture — Research Notes

> Status: **Not started.** This document captures the planning discussion so we can pick it up later without re-deriving everything.

---

## Features in scope

1. **Item / card trading** — players swap cards from their collections with each other
2. **PvP duels** — two players fight using their own decks and heroes

---

## Hard requirements (both features)

- **A backend is mandatory.** There is no P2P workaround:
  - Trading requires a server-authoritative inventory so items cannot be duplicated. The server must execute the swap atomically.
  - PvP requires server validation of moves so a modified client cannot play cards it doesn't own or invent energy.
- **Server-minted card IDs.** Cards currently get `UUID()` at creation time on-device (`Card.id`). For trading, cards need globally-unique IDs assigned by the server so ownership is tamper-proof. This is a required migration before trading can ship.
- **Player accounts.** Sign in with Apple is the right starting point — Apple requires it if you offer any social login, and it gives a stable player identity immediately.

---

## Backend options evaluated

| Option | Best for | Notes |
|---|---|---|
| **Firebase** | Most indie games | Firestore real-time listeners fit turn-based PvP naturally. Cloud Functions for server-side validation. Generous free tier. Best-documented iOS SDK. **Recommended starting point.** |
| **Supabase** | Relational queries | Postgres under the hood — better if you need queries like "find all trades offering a Fire card." Edge Functions for logic. Slightly less mature iOS SDK than Firebase. |
| **Nakama (Heroic Labs)** | Game-specific primitives | Has inventory, wallets, matchmaking, and trading economy built in. Purpose-fit but smaller community. Can run locally in Docker for dev. |
| **PlayFab (Microsoft)** | Enterprise feel | Virtual economy and player inventory built in. More infrastructure than needed to start. |
| **Roll your own (AWS)** | Scale | EC2/ECS + RDS + API Gateway. Maximum control, high operational burden. Not worth it to start. |

---

## Trading — how it works in shipped games

Pattern used by Pokémon TCG Live, MTG Arena, etc.:

1. Player A posts an item to a **trade board** with a "want" condition. Server moves the item into **escrow** (removed from A's inventory, not yet in anyone's possession).
2. Player B accepts. Server **atomically** removes from escrow, credits A's inventory with the wanted item, credits B's inventory with A's item.
3. Neither player can double-spend because the server holds escrow state.

Alternatively, **direct trades**: A proposes a specific swap to B. Server holds both items in escrow until both confirm.

### Implication for Runedraw

- `hero.cardCollection` and `hero.inventory` (gear) currently live in local JSON saves. They need to migrate to server-owned records.
- The server becomes the authoritative source; the local save is a cache / offline fallback.

---

## PvP — two viable models

### Async turn-based (lower complexity)
Like Words With Friends or Clash Royale challenges:
- Player A takes their turn, submits to server.
- Server validates moves, stores state, pushes a push notification to Player B.
- Player B responds whenever.
- No WebSocket infrastructure needed — works over REST + APNs.

### Synchronous real-time (higher complexity, more fun)
Like Hearthstone:
- Both players are in the match simultaneously.
- Player A plays cards and hits End Turn — server validates, applies state, notifies Player B that it's their turn.
- The **block phase** could be genuinely real-time: Player A's attacks arrive, Player B has N seconds to assign blockers before auto-resolution.

### Recommended hybrid for Runedraw
The "play cards" phase is async (take your time building your turn). The block phase has a **timeout** (e.g. 30 seconds). This suits the existing combat model — the block phase is the interactive moment — while keeping infrastructure manageable.

Runedraw's symmetric block phase is actually a strong PvP mechanic. Both players are active each round, which is more engaging than purely sequential turns.

---

## Architectural impact on the codebase

`GameEngine` is currently the single source of truth and runs entirely on-device. For multiplayer it needs to split:

| Concern | Current | Multiplayer |
|---|---|---|
| Game state ownership | Local JSON file | Server-authoritative Firestore document |
| Move validation | Client only | Server re-runs the same logic as a validator |
| Card IDs | `UUID()` on device | Server-minted, globally unique |
| Saves | `runedraw_save_N.json` | Synced to Firestore; local file is cache |
| Player identity | None | Sign in with Apple → stable UID |

`GameState` is already `Codable`, which is a significant head start — the full game state serializes to JSON today and could be written to/read from Firestore with minimal structural change.

The `play()` function in `GameEngine` would need a server-side mirror (Cloud Function or equivalent) that re-runs the same validation logic: does the player have enough energy? Is the card in their hand? This prevents a modified client from cheating.

---

## Recommended implementation order

1. **Sign in with Apple** — player identity foundation; required by App Store guidelines if any social login exists.
2. **Firebase project setup** — Firestore, Auth, Cloud Functions, APNs integration.
3. **Migrate saves to Firestore** — sync `GameState` server-side instead of only local JSON. Side benefit: free cross-device save support, which is a user-facing win before any multiplayer ships.
4. **Server-mint card IDs** — required prerequisite for trading. New cards get IDs from the server; existing saves need a one-time migration.
5. **Build trading** — stateless between turns, no real-time requirement. Validates the inventory/ownership model before tackling live sync.
6. **Build PvP** — builds on everything above. Start with async turn-based; add real-time block phase timeout later.

---

## Open questions to answer before starting

- **Monetization model for trading**: free trading, premium trading passes, or a cut on each trade (virtual currency)?
- **Ranked vs. casual PvP**: do duel results affect a persistent rating?
- **Deck restrictions in PvP**: can players use off-class cards (currently collectable but not playable in single-player)? Could be a PvP-only unlock.
- **Anti-cheat depth**: Cloud Function validation catches obvious cheats; a more robust solution (full server-side game simulation) is more work but more secure.
- **Region / latency**: real-time block phase needs low latency — Firebase's multi-region setup or a dedicated WebSocket server in the right region matters if the player base is global.
