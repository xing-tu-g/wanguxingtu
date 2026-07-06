# Star Track Matchmaking System v1

## Definition

Star Track is the only matchmaking value in the playable alpha. The valid range is `0` to `10000`.

This system controls:

- Competitive division.
- Matchmaking range.
- Wait-time expansion.
- Anti-smurf reward and loss adjustment.
- Minimal MainMenu progression display.

It does not change Battle, star power, star tide, hero skills, deck size, or combat values.

## Divisions

| Range | Name | Base Range | Notes |
| --- | --- | ---: | --- |
| 0-499 | 初星 · Awakening | +/-200 | New player protection. Matches only `0-800`. Losses do not drop Star Track. |
| 500-1499 | 星轨 · Formation | +/-300 | Basic competitive range. |
| 1500-2999 | 星流 · Flow State | +/-500 | Normal loss pressure starts. |
| 3000-4999 | 星域 · Domain | +/-700 | Strategy and deck differences matter more. |
| 5000-7499 | 星界 · Astral Realm | +/-800 | High-pressure competitive range. |
| 7500-10000 | 星核 · Core Collapse | +/-1000 | Full competitive environment. |

Boundary values enter the higher division. For example, `500` enters Formation and `1500` enters Flow State.

## Match Range Rules

Matchmaking uses `scripts/data/StarTrackSystem.gd`.

1. Determine division from `star_track_value`.
2. Apply the division base range.
3. Prefer same division.
4. Allow adjacent division only after wait expansion.
5. After `10s`, range expands by `20%`.
6. After `20s`, one adjacent Star Track division may be crossed.
7. Win streak `>= 5` expands range by `15%`.

Initial Awakening remains protected and never matches above `800`.

## Result Rules

- Win: `+30`.
- Loss below `500`: `0`.
- Loss at `500+`: `-10`.
- Value is clamped to `0-10000`.

## Anti-Smurf Adjustment

When Star Track gap is at least `1000`:

- Higher player beating a much lower player gets reduced reward: `+30 -> +15`.
- Lower player losing to a much higher player gets reduced loss: `-10 -> 0`.

This keeps growth pressure while reducing bad mismatch outcomes.

## UI

MainMenu displays:

- Current Star Track value.
- Current division name.
- Distance to next division.

The progress bar shows progress inside the current division, not combat resources.

## Files

- `scripts/data/StarTrackSystem.gd`
- `scripts/ui/HomeScreen.gd`
- `tests/m98_star_track_system_check.gd`
- `tests/m99_star_track_matchmaking_check.gd`
