# Current Update - Game Loop Construction Sprint v1

- Current manifest: `tests/test_manifest_mvp.txt`, 94 tests.
- Current game entry: `scenes/ui/MainMenuScene.tscn`.
- Current loop: MainMenu -> DeckBuilder -> Battle -> BattleReport -> MainMenu.
- Current sprint report: `docs/GAME_LOOP_CONSTRUCTION_2026-07-04.md`.
- Current APK: uilds/wanguxingtu-game-loop-v1-debug.apk.
- Live Battle HUD policy: battle logs are not shown during combat; they are kept as `battle_log_entries` data and rendered in `BattleReportScene`.
- Verification targets:
  - `MANIFEST_TEST_COUNT=94`
  - `TEST_FILE_COUNT=94`
  - `RUNNING_TEST_COUNT=94`
  - `MVP_MANIFEST_CLEAN`
- Latest focused checks:
  - `m85_deck_screen_flow_check.gd`
  - `m95_game_loop_construction_check.gd`
  - `m7a_battle_log_check.gd`
  - `m94_hud_information_architecture_check.gd`
# 涓囧彜鏄熷浘缁帴鍏ュ彛

鍙繚鐣欐渶杩戠姸鎬侊紝閬垮厤闀夸細璇濆弽澶嶈鍙栧畬鏁?`docs/HANDOFF.md`銆?
## 褰撳墠鐘舵€?
- 褰撳墠闃舵锛欳ombat Feel & Polish Sprint v1銆?- 褰撳墠鏈€楂樻垬鏂楄鑼冿細`docs/COMBAT_DESIGN_BIBLE.md`銆?- 褰撳墠鎶€鑳借鑼冿細`docs/SKILL_DESIGN_BIBLE.md`銆?- 褰撳墠鑻遍泟韬唤瑙勮寖锛歚docs/HERO_IDENTITY_BIBLE.md`銆?- 褰撳墠鎵嬪姩楠岃瘉鎶ュ憡锛歚docs/MANUAL_BATTLE_VALIDATION_2026-07-04.md`銆?- 褰撳墠鎴樻枟鎵嬫劅鎶ュ憡锛歚docs/COMBAT_FEEL_POLISH_2026-07-04.md`銆?- 褰撳墠闃佃惀鏄熷姏鎶ュ憡锛歚docs/FACTION_ENERGY_SYSTEM_2026-07-04.md`銆?- 褰撳墠涓荤嚎 manifest锛歚tests/test_manifest_mvp.txt`锛屽叡 91 椤规祴璇曘€?- 褰撳墠鍙瘯鐜?APK锛歚builds/wanguxingtu-battle-polish-v3-debug.apk`銆?- 褰撳墠妯℃嫙鍣ㄧ害瀹氾細姣忔浣跨敤鍚庢墽琛?`adb -s <serial> emu kill` 鍏抽棴銆?
## 鏈樁娈靛凡瀹屾垚

- 涓?55 鍚嶅彲鐜╂灏嗗缓绔嬩竴鍙ヨ瘽瀹氫綅銆佹牳蹇冪帺娉曞拰鎴樻枟鏍囩锛?  - `docs/HERO_IDENTITY_BIBLE.md`
- 鎷嗚В閲嶅鎶€鑳芥ā鏉匡紝褰撳墠瀹屾暣鎶€鑳界鍚嶉噸澶嶇粍涓?0锛?  - 鎴樺＋鑷姞鏀绘ā鏉挎媶鎴愭満鍔ㄣ€佺湡浼ゃ€佹垚闀裤€佹姢鐩俱€佺湬鏅曘€佺紦閫熴€佹寚鎸ョ瓑鏂瑰悜銆?  - 鍛戒腑鐕冪儳妯℃澘鎷嗘垚鐙欏嚮鐪熶激銆佸叏鍐涙満鍔ㄣ€佽疮鐭㈢湡浼ゃ€侀暱鏈熸瘨鐏€?  - 閮ㄧ讲鍓婃敾妯℃澘鎷嗘垚鍘嬪埗銆侀暱鏁堢闂淬€佸弸鍐涘姞鏀汇€佽嚜韬弽鏀汇€佺櫥鍦烘垚闀裤€?  - 鍧﹀厠鎶ょ浘妯℃澘鎷嗘垚鍥炲悎鐩俱€侀暱鏁堢浘銆侀珮鐩俱€侀儴缃茬浘銆佺敓鍛芥垚闀裤€?  - 娌荤枟/鏀彺妯℃澘鎷嗘垚鍗曚綋娌荤枟銆侀暱鏁堝姞鏀汇€佸叏浣撴不鐤椼€佺煭鏁堟壎鎸併€佺浉閭绘不鐤椼€?- 鏂板 100 灞€鑻遍泟韬唤妯℃嫙锛?  - `scripts/tools/HeroIdentitySimulationV1.gd`
  - `scripts/tools/run_hero_identity_simulation_v1.gd`
  - 鎶ュ憡锛歚tmp/hero_identity/hero_identity_simulation_v1_100.json`
- 鏂板鑻遍泟韬唤鍥炲綊娴嬭瘯锛?  - `tests/m91_hero_identity_check.gd`
- 鏂板 Manual Battle Test Mode锛?  - `BattleScreen.set_screen_data()` 鏀寔 `manual_battle_test_mode=true`銆?  - Manual 妯″紡鏄剧ず `ManualValidationPanel`锛屽疄鏃跺睍绀哄洖鍚堛€佹槦鍔涖€佸凡閮ㄧ讲姝﹀皢銆佹妧鑳借Е鍙戙€佷激瀹炽€佹壙浼ゃ€佹不鐤椼€佸嚮鏉€銆侀樀钀ユ槦鍔涖€?  - Manual 妯″紡鏄剧ず鈥滈噸寮€鈥濇寜閽紱姝ｅ紡妯″紡浠嶉殣钘忛噸缃叆鍙ｃ€?- 鏂板鎵嬪姩绔欎綅楠岃瘉宸ュ叿锛?  - `scripts/tools/ManualBattleValidationV1.gd`
  - `scripts/tools/run_manual_battle_validation_v1.gd`
  - 鎶ュ憡锛歚tmp/manual_validation/manual_battle_validation_v1.json`
  - 鏂囨。锛歚docs/MANUAL_BATTLE_VALIDATION_2026-07-04.md`
- 鏂板鎵嬪姩楠岃瘉鍥炲綊娴嬭瘯锛?  - `tests/m92_manual_battle_validation_check.gd`
- 鏂板 Combat Feel & Polish v1 琛ㄧ幇灞傚己鍖栵細
  - 鎵€鏈夋垚鍔熸妧鑳借Е鍙戦兘浼氭樉绀烘妧鑳藉悕妯箙鍜岃交閲忓崰浣?FX銆?  - 閮ㄧ讲銆佹槦鍔涘彉鍖栥€侀樀钀ヤ骇鏄熴€佷富灏嗗彈浼ゃ€佸崟浣嶆浜″鍔犳诞灞?闇囧姩/鎻愮ず銆?  - 椤堕儴鐘舵€佹樉绀轰笅娆℃槦鍔涖€佹槦娼€掕鏃舵垨涓诲皢浼ゅ鍔犳垚銆佸墠涓悗鏈熻妭濂忔彁绀恒€?  - 涓嶄慨鏀?`BattleState.gd`銆乣TurnController.gd`銆乣AttackShapeSystem.gd`銆乣FactionEnergySystem.gd`銆乣data/heroes.json`銆乣data/skills.json`銆?- 鏂板鎵嬫劅鍥炲綊娴嬭瘯锛?  - `tests/m93_combat_feel_polish_check.gd`

## 褰撳墠楠岃瘉

```powershell
powershell -ExecutionPolicy Bypass -File scripts/check_test_manifest.ps1
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://scripts/tools/run_hero_identity_simulation_v1.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://scripts/tools/run_manual_battle_validation_v1.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m91_hero_identity_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m92_manual_battle_validation_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m93_combat_feel_polish_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m88_hero_skill_completion_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m89_balance_gameplay_consolidation_check.gd
godot.cmd --headless --path D:\wanguxingtu --disable-crash-handler --script res://tests/m90_faction_energy_system_check.gd
powershell -ExecutionPolicy Bypass -File scripts/run_mvp_manifest_tests.ps1 -GodotBin godot.cmd
powershell -ExecutionPolicy Bypass -File scripts/android_smoke_capture.ps1 -ApkPath builds\wanguxingtu-battle-polish-v3-debug.apk
```

褰撳墠宸茬‘璁わ細

- Hero Identity Simulation v1锛歚HERO_IDENTITY_SAMPLE_COUNT=100` / `HERO_IDENTITY_ENDED_COUNT=100` / `HERO_IDENTITY_TIMEOUTS=0`銆?- 韬唤閲嶅妫€鏌ワ細`HERO_IDENTITY_DUPLICATE_SIGNATURE_GROUPS=0`銆?- 鎶€鑳藉瓨鍦ㄦ劅妫€鏌ワ細`HERO_IDENTITY_UNTRIGGERED_SKILLS=0`銆?- `m91_hero_identity_check.gd` 閫氳繃銆?- `m88_hero_skill_completion_check.gd` 閫氳繃銆?- Manual Battle Validation v1锛?5 涓満鏅紝5 鍚嶄綆瀛樺湪鎰熻嫳闆?脳 3 绉嶇珯浣嶏紝`MANUAL_BATTLE_VALIDATION_V1_CLEAN`銆?- 缁撹锛氳档浜戙€佸崕闆勩€侀┈瓒呭睘浜庤嚜鍔ㄦā鎷熶綆浼帮紱寰愮洓銆佸紶椋為渶瑕佹洿娓呮櫚鐨勭珯浣?鎶€鑳借鏄庯紝鏆備笉鏀规暟鍊笺€?- Combat Feel Polish v1锛歚m93_combat_feel_polish_check.gd` 閫氳繃銆?- Manifest 鍚屾锛歚MANIFEST_TEST_COUNT=91` / `TEST_FILE_COUNT=91` / `TEST_MANIFEST_SYNC_CLEAN`銆?- 鍏ㄩ噺涓荤嚎鍥炲綊閫氳繃鐩爣锛歚RUNNING_TEST_COUNT=91` / `MVP_MANIFEST_CLEAN`銆?- 鎶ュ憡锛歚tmp/hero_identity/hero_identity_simulation_v1_100.json`銆?
## 涓嬩竴姝ュ缓璁?
1. 鐢ㄦā鎷熷櫒瀹炴満楠岃瘉 Combat Feel锛氱湅鏄熷姏娴眰銆佹妧鑳芥í骞呫€佺牬闃靛弽棣堟槸鍚﹁繃瀵嗘垨閬尅妫嬬洏銆?2. 濡傛灉鍙嶉鑺傚杩囧己锛屼紭鍏堣皟鍔ㄧ敾鏃堕暱/閫忔槑搴︼紝涓嶆敼瑙勫垯銆?3. 鍚庣画鍙敤姝ｅ紡 FX 璧勬簮鏇挎崲褰撳墠杩愯鏃跺崰浣嶈壊鍧椼€?



