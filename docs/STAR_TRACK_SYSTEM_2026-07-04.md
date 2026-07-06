# Star Track System

## Current Definition

Star Track is the player battle progression and matchmaking value. The active range is `0` to `10000`.

It controls:

- Battle progression.
- Hero pool unlock pacing.
- Deck builder availability.
- Competitive matchmaking division and range.

It does not change combat rules, star power, star tide, hero skills, deck size, or battle formulas.

## Result Values

- Win: `+30` Star Track value.
- Loss below `500`: `0`.
- Loss at `500+`: `-10`.
- Protection: value is clamped to `0-10000`.

## Division Model

Star Track now uses six competitive divisions:

- `0-499`: 初星 · Awakening
- `500-1499`: 星轨 · Formation
- `1500-2999`: 星流 · Flow State
- `3000-4999`: 星域 · Domain
- `5000-7499`: 星界 · Astral Realm
- `7500-10000`: 星核 · Core Collapse

Boundary values enter the higher division.

## Unlock Tiers

- `0-499`: basic 20-hero pool.
- `500-1499`: 35-hero five-class core pool.
- `1500-4999`: 48-hero high-rarity pool.
- `5000+`: full 55-hero pool.

DeckBuilder still displays the full roster, but locked heroes are disabled and cannot enter the player deck.

## Matchmaking

The full matchmaking rules are documented in:

- `docs/STAR_TRACK_MATCHMAKING_SYSTEM_2026-07-05.md`

The implementation is in:

- `scripts/data/StarTrackSystem.gd`

## Files

- `scripts/data/StarTrackSystem.gd`
- `scripts/core/SaveService.gd`
- `scripts/core/AppState.gd`
- `scripts/data/BattleReportManager.gd`
- `scripts/data/DeckDataManager.gd`
- `scripts/ui/HomeScreen.gd`
- `scripts/ui/DeckScreen.gd`
- `tests/m98_star_track_system_check.gd`
- `tests/m99_star_track_matchmaking_check.gd`
