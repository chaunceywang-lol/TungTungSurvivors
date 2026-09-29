# First boss encounter: Studio tests

These are manual runtime tests, not a record of passed Studio tests.

## Setup

1. Stop Play and sync. Confirm these new instances:
   - `ReplicatedStorage > BossConfig`: ModuleScript.
   - `ServerScriptService > TungBoss`: ModuleScript.
   - `StarterPlayer > StarterPlayerScripts > BossUI`: LocalScript.
2. The boss model, health state, health bar, and victory banner are created automatically. Use the existing flat arena with at least 40 studs of open space around players.
3. For a quick test, start Play and run `game:GetService("ServerStorage").StudioTestTools.StartBossWave:Invoke()` in the **server** Command Bar. Then switch back to Client without stopping Play. This uses the real run manager and does not create a second test boss. Alternatively set the first three durations to 5 seconds before Play. Leave the fourth wave's `Boss = "TungBoss"` and `RepeatLastWave = false`.
4. Keep the boss defaults for the tests below: health 1500, speed 6, scale 2, damage 15, contact cooldown 1 second, XP reward 250.

## Appearance, spawn count, and chase

If the boss does not appear, inspect `ReplicatedStorage > RunState > Attributes > BossSpawnStatus`. `NotReached` means the run has not entered wave 4 (180 active seconds with default durations). `WaitingForPlayer` requires a living player; `WaitingForSpace` retries safe placement on open ground. `SpawnError` means Output contains a `[Boss] Spawn failed` traceback to report. `Spawned` means the model should be `Workspace > Enemies > TungBoss`.

1. Press Play. After about 15 active seconds, wave 4 should spawn exactly one purple Great Tung boss, twice the normal rig size. Check `Workspace > Enemies > TungBoss`.
2. Inspect its Humanoid in the server view: MaxHealth 1500 and WalkSpeed 6. Its health bar should appear near the top of every client's screen and begin at 1500 / 1500.
3. Move around. It should follow the nearest living player using the existing chase system. The boss approaches closer than normal enemies so it can make contact.
4. Normal enemies may spawn once every 8 seconds, with a combined alive cap of 3. Earlier-wave survivors are preserved; they can temporarily put the encounter above this cap. The boss still spawns once, and no new normal enemies spawn until the count falls below the cap.
5. Let the fourth wave countdown reach zero without killing the boss. The wave must remain 4, display “Defeat the boss,” and continue the encounter. Waiting out the timer is not victory.

## Contact damage and health bar

1. Wait until the player's spawn ForceField has expired, then approach the boss's torso. Touching multiple body parts must not multiply damage: expect one 15-health hit per player per second while contact continues.
2. Move away from contact. Damage must stop. Returning before the cooldown expires must not bypass it.
3. Let the automatic bat hit the boss. Its server Humanoid health and the client health bar should decrease together. No clicking is required.
4. Reset your character during the encounter. The boss must not duplicate; the UI should survive the respawn. If nobody is alive, the run timer pauses until respawn.

## Victory and XP

1. To shorten the fight, select the boss Humanoid in the **server** Explorer and set Health to 25. Do not change MaxHealth. Let a real bat hit kill it.
2. Expect the shared cumulative XP total to increase by 250 exactly once for the boss. Other normal pickups collected simultaneously can add their own XP. The boss reward is direct: there is no extra boss XP orb.
3. Both RunState.Status and the screen should show victory. The boss health bar disappears. The boss model is removed shortly afterward.
4. Wait at least 10 seconds. No new enemies, boss respawns, boss contact damage, or automatic bat attacks should occur. Surviving enemies stop moving and are not deleted.
5. The 250 XP may queue multiple level-up choices. The victory banner must not block choosing them; upgrades remain individual and server-validated. Verify the pending count decreases once per choice.
6. Remaining ordinary XP pickups can still be collected after victory. No permanent save or automatic new run is added. Stop and restart Play for another run.

## Multiplayer

1. Start a local server with two players and the shortened wave durations.
2. Verify one shared boss and one matching health bar on both clients.
3. Put both living players in contact after ForceFields expire. Each should take at most 15 damage per second independently.
4. Separate the players and move one closer. Verify the boss switches to the nearer living player and ignores a dead character.
5. Kill the boss. Both players should receive the same one-time 250 shared XP and see victory; their upgrade selections should remain independent.

## Configuration check

Before a fresh Play session, temporarily change BossConfig.TungBoss to Health 2000, WalkSpeed 5, Damage 10, XPReward 400. Confirm the spawned Humanoid, contact hits, and one-time death award reflect those values. Restore the defaults afterward.

Finally restore the first three wave durations to 60. Do not require stateful modules directly from the Command Bar; use Explorer properties or existing StudioTestTools helpers. Deleting a live boss is not a valid kill: the encounter retries placement rather than awarding XP or victory.
