# Time-based spawn manager: Studio tests

**Enemy variety update:** See `ENEMY_VARIETY_TESTS.md` for weighted pools and type-specific health/speed. The table below describes BasicEnemy only. Set the first three wave durations to 60 to test this timeline; the saved durations are currently 4 seconds.

**Boss update:** Wave 4 now spawns a boss and uses an 8-second normal-enemy interval with an alive cap of 3 (including the boss). Its normal enemies have base stats. Surviving earlier enemies are retained, so the count may temporarily exceed that cap when the mandatory boss arrives. Refer to `BOSS_TESTS.md`; the old fourth-wave row below is superseded.

These tests require Studio and have not been executed by Codex.

## Setup and normal gameplay

1. Stop Play and let Script Sync finish. Confirm `ServerScriptService > SpawnManager` is a ModuleScript. No manual enemy models or spawn points are needed.
2. Use a flat, anchored baseplate with at least 40 studs of clear ground around the player. Keep the player near the center for initial testing.
3. Press Play. Two enemies should appear within the first second, assuming two valid positions are available. They spawn in random directions 24–36 horizontal studs from a living player, never within 24 studs of another living player.
4. Additional enemies should spawn about every five seconds, regardless of whether earlier enemies have died, up to four alive in wave 1.
5. Let combat run. Verify enemies chase, take damage, drop XP once, and trigger leveling and individual upgrade choices as before. Enemy deaths do not start a separate respawn timer.
6. Inspect `ReplicatedStorage > RunState` for `ElapsedSeconds`, `CurrentWave`, and `SecondsRemaining`. Inspect Workspace for `SpawnInterval`, `MaxAliveEnemies`, and `AliveEnemies`.

## Cap and wave progression

1. Stop Play and temporarily set `TungBat.Damage = 0` in GameConfig so enemies survive. Record and restore the previous value after this test.
2. Play again. On open ground, expect two enemies initially, three after about five seconds, and four after about ten seconds. The alive count should remain four until wave 2. Do not use the manual SpawnEnemy test helper during this cap test; it deliberately bypasses the manager.
3. Keep watching Workspace attributes and newly spawned enemies:

| Active time | Wave | Interval | Alive cap | New enemy MaxHealth | New enemy WalkSpeed | DamageMultiplier |
| --- | --- | --- | --- | --- | --- | --- |
| 0–59 seconds | 1 | 5 seconds | 4 | 100 | 10 | 1 |
| 60–119 seconds | 2 | 4 seconds | 8 | 115 | 10.5 | 1.1 |
| 120–179 seconds | 3 | 3 seconds | 12 | 135 | 11 | 1.2 |
| 180+ seconds | 4 | 2 seconds | 18 | 160 | 11.5 | 1.3 |

The cap is a limit, not a batch size: it fills one enemy per scheduled spawn. Small timing differences up to the manager's 0.25-second check interval are expected. Each enemy has a `SpawnWave` attribute to identify its generation. Existing enemies retain their original stats. DamageMultiplier is metadata only; enemy attacks are not implemented.

4. While capped, select one enemy's Humanoid in the server Explorer and set Health to 0. Confirm the corpse disappears, XP drops once, and only one replacement appears on the next scheduled spawn. It may appear quickly if the next timer tick was already due; killing the enemy does not reset that timer.
5. Repeat with several enemy deaths: the cap should refill over successive timer ticks, without an immediate catch-up wave.
6. For a faster test, set each wave Duration in `ReplicatedStorage.WaveConfig` to `15` before Play. Restore the defaults afterward.
7. Stop Play, restore damage to its original value, and test normal combat again.

## Placement and multiplayer

1. Start a local server with two players. Move them apart on the same large baseplate.
2. Confirm there is one shared spawn schedule/cap, not a separate full cap for each player. Over several spawns, spawn locations should be distributed around the players.
3. Newly spawned enemies record `SpawnPosition`, which is their original root position before chasing. Use this if inspection happens after they have moved.
4. Approach a baseplate edge. Spawns should use valid nearby ground. If all placement attempts fail, that scheduled spawn is skipped; enemies should not be placed over empty space as a fallback.
5. Player characters and enemies are excluded from ground detection. Collidable scenery is checked for clearance. This is intended for an open arena, not maze navigation.

## No living players

1. In a solo session, use Reset Character while watching the server's Workspace attributes.
2. During the period with no living character, `ReplicatedStorage.RunState.ElapsedSeconds` should stop advancing and no new enemies should spawn.
3. After respawn, timing should continue from where it paused without a backlog. Existing enemies and the game's XP/upgrade state are not reset.

Do not call `require(SpawnManager)` from the Command Bar: the Command Bar has a separate module environment. Main starts RunManager in the actual server environment; RunManager drives SpawnManager. RunManager.Stop() stops the clock and new spawns without killing existing enemies. Wave definitions are in ReplicatedStorage.WaveConfig.
