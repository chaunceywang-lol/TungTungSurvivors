# Enemy variety: Studio tests

Runtime tests require Studio and have not been executed by Codex.

## Setup

1. Stop Play and sync. Confirm `ReplicatedStorage > EnemyConfig` is a ModuleScript. No new controllers or models need manual creation.
2. Your saved first three wave durations are 4 seconds. Temporarily set them to 60 in WaveConfig for observation. Restore 4 afterward if you want the short boss test again.
3. For initial inspection, temporarily set `GameConfig.TungBat.Damage = 0`, then start Play on the existing flat arena. Restore 25 before testing combat.

## Base types (no wave scaling)

In the **server** Command Bar during Play, run each command once:

```lua
game:GetService("ServerStorage").StudioTestTools.SpawnEnemy:Invoke("BasicEnemy")
game:GetService("ServerStorage").StudioTestTools.SpawnEnemy:Invoke("FastEnemy")
game:GetService("ServerStorage").StudioTestTools.SpawnEnemy:Invoke("TankEnemy")
```

These helpers use the actual server service, choose a clear nearby position, and deliberately bypass wave weights and the alive cap. Do not use them during cap testing. Inspect `Workspace > Enemies`:

| Type | Visual | MaxHealth | WalkSpeed | XPValue |
| --- | --- | --- | --- | --- |
| BasicEnemy | brown, scale 1 | 100 | 10 | 25 |
| FastEnemy | green, scale 0.8 | 50 | 14 | 30 |
| TankEnemy | blue, scale 1.4 | 250 | 6 | 50 |

Move around and confirm all three chase. Fast should close distance faster than Basic; Tank should be slower. Their `EnemyType` attribute identifies the type. Each uses the same Humanoid health and server-owned movement system.

## Wave pools and scaling

1. Restart without using manual spawn helpers. At wave 1, only BasicEnemy should spawn.
2. Wave 2 permits Basic and Fast at weights 70/30. No new TankEnemy should have `SpawnWave = 2`.
3. Wave 3 permits Basic/Fast/Tank at weights 50/30/20. Spawns are random, not guaranteed batches; a short sample will not necessarily match those percentages.
4. Inspect newly spawned enemies using these expected values:

| Wave | Type | MaxHealth | WalkSpeed | XPValue |
| --- | --- | --- | --- | --- |
| 2 | Basic | 115 | 10.5 | 25 |
| 2 | Fast | 57.5 | 14.7 | 30 |
| 3 | Basic | 135 | 11 | 25 |
| 3 | Fast | 67.5 | 15.4 | 30 |
| 3 | Tank | 337.5 | 6.6 | 50 |

Older enemies retain their spawn-wave stats. Counts and spawn intervals still obey the existing manager.

## Deterministic weight test

1. Stop Play. In wave 2's EnemyPool, set BasicEnemy Weight to 0 and FastEnemy Weight to 1. In wave 3, set BasicEnemy/FastEnemy weights to 0 and TankEnemy to 1.
2. Restart. Every NEW wave-2 spawn must be FastEnemy and every NEW wave-3 spawn must be TankEnemy. Earlier-wave survivors are allowed to remain.
3. Restore wave-2 weights 70/30 and wave-3 weights 50/30/20.
4. A weight of 0 disables an entry. Negative weights, unknown types, duplicate type entries, empty pools, and all-zero pools are rejected during server startup rather than silently spawning the wrong enemy. Restart after correcting configuration errors.

## Combat and XP

1. Restore bat damage to 25 and start a fresh session. Use the type helper to spawn one type at a time while still in wave 1.
2. Before selecting damage upgrades, the base Basic/Fast/Tank should take 4/2/10 bat hits respectively. With upgrades, expect fewer hits according to the player's server stats.
3. Every death should produce exactly one pickup with XPValue 25/30/50 respectively. With the current 10-stud collection radius it may be collected immediately; inspect the change to cumulative Player.XP. Exclude other simultaneous pickups when comparing totals.
4. Temporarily set wave 3's XPMultiplier to 2. Newly spawned Tanks should show XPValue 100 and award 100 on collection. Restore the multiplier to 1 after testing.
5. Confirm shared XP, leveling, queued choices, and individual weapon upgrades still work in a two-player test.

Enemy-specific XP rewards now live in EnemyConfig. GameConfig.XP.DefaultDropValue remains the default for generic pickups created directly through XPService; it does not override configured enemy rewards.

## Boss regression

Use `game:GetService("ServerStorage").StudioTestTools.StartBossWave:Invoke()` in the server Command Bar. Confirm one Great Tung boss appears, support spawns are Basic-only, contact damage works, and a boss kill still grants 250 XP and triggers victory. BossConfig remains separate from normal-enemy definitions.

Restore all temporary test changes before continuing development. Do not require stateful services directly in the Command Bar; use StudioTestTools.
