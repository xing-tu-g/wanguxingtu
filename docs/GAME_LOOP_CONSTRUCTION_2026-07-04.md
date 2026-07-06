# Game Loop Construction Sprint v1

Date: 2026-07-04

## Scope

This sprint builds the battle-external game loop around the stable Battle system. It does not change combat rules, star power, star tide, hero skills, professions, AI logic, or AttackShape.

## Implemented Loop

```text
MainMenuScene
  -> DeckBuilderScene
  -> BattleScreen
  -> BattleReportScene
  -> MainMenuScene
```

## Scenes

- `res://scenes/ui/MainMenuScene.tscn`: start battle, deck builder, hero codex, battle report.
- `res://scenes/ui/DeckBuilderScene.tscn`: 20-card deck editing, save/load, faction/profession filters.
- `res://scenes/ui/HeroCodexScene.tscn`: 55 playable heroes, faction, profession, skill text, Hero Identity text.
- `res://scenes/ui/BattleReportScene.tscn`: result payload display, MVP, star power, skills, kills, damage, pace summary, replay log.

## Data Managers

- `res://scripts/data/DeckDataManager.gd`: `MAX_BATTLE_DECK_SIZE = 20`, `MIN_BATTLE_DECK_SIZE = 5`, saves to `user://deck_builder.json`.
- `res://scripts/data/HeroIdentityData.gd`: reads `docs/HERO_IDENTITY_BIBLE.md`.
- `res://scripts/data/BattleReportManager.gd`: records the latest 20 reports to `user://battle_reports.json`.

## Data Flow

- `MainMenuScene -> BattleScreen`: passes `player_deck` and `enemy_deck`.
- `DeckBuilderScene -> BattleScreen`: saves edited deck and passes it into battle.
- `BattleScreen -> BattleReportScene`: passes `result_payload` plus `battle_log`.
- `BattleReportScene -> MainMenuScene`: returns through `EventBus.screen_changed`.

## Battle Log Policy

Battle event logs do not appear in the live Battle HUD. Battle keeps `battle_log_entries` as data only, and `BattleReportScene` renders the replay after combat.

## Verification

Passed:

```powershell
godot.cmd --headless --path D:\wanguxingtu --script res://tests/m85_deck_screen_flow_check.gd
godot.cmd --headless --path D:\wanguxingtu --script res://tests/m95_game_loop_construction_check.gd
godot.cmd --headless --path D:\wanguxingtu --script res://tests/m7a_battle_log_check.gd
godot.cmd --headless --path D:\wanguxingtu --script res://tests/m94_hud_information_architecture_check.gd
powershell -ExecutionPolicy Bypass -File scripts/check_test_manifest.ps1
powershell -ExecutionPolicy Bypass -File scripts/run_mvp_manifest_tests.ps1 -GodotBin godot.cmd
```

Expected sentinels:

```text
MANIFEST_TEST_COUNT=94
TEST_FILE_COUNT=94
TEST_MANIFEST_SYNC_CLEAN
RUNNING_TEST_COUNT=94
MVP_MANIFEST_CLEAN
```

## Android Follow-Up

After the next export, run:

```powershell
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --export-debug Android builds\wanguxingtu-game-loop-v1-debug.apk
powershell -ExecutionPolicy Bypass -File scripts/android_smoke_capture.ps1 -ApkPath builds\wanguxingtu-game-loop-v1-debug.apk
```

Close the emulator after use:

```powershell
adb -s <serial> emu kill
```


## Exported APK

- uilds/wanguxingtu-game-loop-v1-debug.apk exported successfully with Godot Android debug export on 2026-07-04.
- Export completed with signed APK verification by Godot exporter.

