# Wave/run system tests

**Boss update:** The default fourth wave is now a boss encounter. Use `BOSS_TESTS.md` for its current expected behavior. The repeating-final-wave and timed-completion tests below only apply to a temporary configuration with the final wave's `Boss` field removed. Restore `Boss = "TungBoss"` and `RepeatLastWave = false` afterward. Normal-enemy wave settings 1–3 remain unchanged.

Runtime tests below require Roblox Studio; they have not been run by Codex.

## Setup

Stop Play, sync, and confirm:
- `ReplicatedStorage > WaveConfig`: ModuleScript.
- `ServerScriptService > RunManager`: ModuleScript.
- `StarterPlayer > StarterPlayerScripts > WaveUI`: LocalScript.

RunState and the UI are created automatically. Main starts the run once. Use the existing flat arena with at least 40 studs of clear ground around the spawn.

## Default behavior

1. Press Play. A wave display should appear below the level/XP display: `Wave 1 • 01:00`, counting down on the server. Initial enemies and ongoing spawns should still work.
2. At 60 active seconds, expect wave 2 with a fresh 60-second countdown. At 120 and 180 seconds, expect waves 3 and 4. Timing is checked every 0.25 seconds, so allow that much boundary latency.
3. Inspect `ReplicatedStorage > RunState` in the server view. Its `CurrentWave`, `SecondsRemaining`, `ElapsedSeconds`, and `Status` must agree with the client display. There is no client command to advance the wave.
4. Inspect newly spawned enemies. Their `SpawnWave` identifies their wave. Defaults are:

| Wave | Spawn interval | Alive cap | MaxHealth | WalkSpeed | XP reward |
| --- | --- | --- | --- | --- | --- |
| 1 | 5 seconds | 4 | 100 | 10 | 25 |
| 2 | 4 seconds | 8 | 115 | 10.5 | 25 |
| 3 | 3 seconds | 12 | 135 | 11 | 25 |
| 4+ | 2 seconds | 18 | 160 | 11.5 | 25 |

5. At 240 seconds, expect wave 5 using wave 4's configuration. Further waves repeat that last definition, because `RepeatLastWave = true` by default.
6. Kill enemies, collect XP, and choose upgrades. Confirm gameplay continues while the clock runs and each player still receives individual choices.

## Fast boundary and survivor test

1. Stop Play. Temporarily set every wave's `Duration = 15` in WaveConfig and `TungBat.Damage = 0` in GameConfig.
2. Play. Inspect an enemy from wave 1 before the first transition. At wave 2, the SAME instance should still exist with 100 MaxHealth and 10 WalkSpeed.
3. A new enemy with `SpawnWave = 2` should have 115 MaxHealth and 10.5 WalkSpeed. Existing enemies count toward the new wave's cap. A lower cap would suppress new spawns, never delete survivors.
4. Watch transitions at 15, 30, 45, and 60 active seconds. There should be no repeated initial batch or accumulated catch-up wave.
5. Reset your character. During the interval without a living player, the timer should freeze with a waiting message and no new spawns. On respawn the countdown resumes, and the UI persists once without duplicates.
6. Restore durations to 60 and bat damage to 25 after testing.

## Finite run

1. Before Play, set `RepeatLastWave = false` and all durations to 15 for a short test. Set bat damage to 0 if you want enemies to survive for inspection.
2. At 60 active seconds, the UI should say `Run complete`, RunState.Status should be `Completed`, and Workspace.SpawnManagerActive should be false.
3. Wait another ten seconds. There should be no new timed spawns. Existing enemies remain and may still chase; no bosses, rewards, or restart flow are added here.
4. Restore RepeatLastWave to true, durations to 60, and damage to 25.

## XP scaling

1. Before Play, temporarily set wave 2's XPMultiplier to 2 and its Duration to 120. Set wave 1 Duration to 15 for a quicker transition.
2. A newly spawned wave-2 enemy should have XPValue = 50. Killing it must create exactly one 50-XP pickup. Compare cumulative Player.XP before and after collecting it; other collected pickups also count.
3. A surviving wave-1 enemy must still drop 25 even if killed during wave 2. The reward is captured at spawn, not read from the current wave at death.
4. Fractional multipliers round the reward to the nearest whole XP, with a minimum of 1. Restore multiplier 1 and durations 60 afterward.

## Multiplayer

Start a two-player local test. Both clients should show the same wave/countdown, allowing normal replication delay, and share one spawn cap. Reset only one player: the timer must keep running while the other is alive. Late-joining clients read the current replicated RunState immediately. Each player's upgrades must remain independent.

Do not require stateful managers from the Command Bar. Use the existing StudioTestTools helpers for test XP/enemies; directly requiring a module there creates a different module environment.
