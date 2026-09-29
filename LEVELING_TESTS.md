# Leveling and upgrade tests in Roblox Studio

These are manual runtime tests, not a record of tests already passed.

## Setup

1. Stop Play and let Script Sync finish.
2. Confirm `ServerScriptService` contains ModuleScripts named `ProgressionService` and `UpgradeDefinitions`.
3. Confirm `StarterPlayer > StarterPlayerScripts` contains a LocalScript named `LevelUpUI`.
4. Keep the current config for these expectations: XP drops 25, pickup radius 10, base level requirement 25, requirement increase 25; Tung Bat damage 25, cooldown 1, range 7.
5. Open Output and Properties. No UI or remote objects need manual creation.
6. For the exact XP totals in these scripted tests, temporarily set `EnemySpawning.RespawnDelay` to `999` before Play so automatic replacement enemies do not add extra XP. Restore it to `2` afterward and restart Play to test the continuous loop.
7. Confirm `ServerScriptService > StudioTestTools` is a **Script**. During Play it creates `ServerStorage > StudioTestTools` with two BindableFunctions. These tools exist only in Studio.

Do not directly `require` stateful services from the Command Bar: it has its own module cache, which can create conflicting XP/progression state. Use the helpers below instead. If you previously used the old commands, stop and restart Play first. To return to your character after a server command, switch from Server to Client in the same running session; stopping Play starts a new run with reset XP.

## First level and damage upgrade

1. Press Play. The display should read `Level 1 | XP 0 / 25`.
2. Let the bat kill the existing enemy and collect the pickup.
3. Expect level 2 with `XP 0 / 50` and exactly three choices: +25% damage, -15% cooldown, +20% range.
4. Pick Heavy Tung. The panel should close.
5. In the server view, select `Players > your player` and inspect Attributes:
   - `XP = 25` (cumulative XP, preserved from the previous milestone)
   - `Level = 2`, `LevelXP = 0`, `XPRequired = 50`, `PendingUpgrades = 0`
   - `TungBatDamage = 31.25`, `TungBatCooldown = 1`, `TungBatRange = 7`

## Multiple levels from one pickup

After the previous test, open the Command Bar in the **server** view and run:

```lua
game:GetService("ServerStorage").StudioTestTools.SpawnXP:Invoke(125)
```

1. Expect level 4, `XP 0 / 100`, cumulative XP 150, and two pending choices: the 125 XP paid the level-2 cost of 50 and level-3 cost of 75.
2. Pick Quick Tung. The next offer should stay on screen with one choice remaining; cooldown should be 0.85.
3. Pick Long Tung. The panel should close; range should be 8.4. Damage should still be 31.25.
4. Run the same server command with `110` instead of `125`. Expect level 5, `XP 10 / 125`, and one choice.
5. Pick Heavy Tung again. Damage should become 39.0625 (31.25 multiplied by 1.25).
6. Reset your character. Level, leftover XP, and selected stats should survive the respawn.

## Invalid requests and stale selection replay

In a fresh Play session, collect the first enemy's XP but leave its offer open. Run this in the **client** Command Bar:

```lua
local remotes = game.ReplicatedStorage.ProgressionRemotes
local before = remotes.GetState:InvokeServer()
assert(before.PendingChoices > 0, "Leave an upgrade offer open first")

for _, invalid in { "unknown_upgrade", { Damage = 999999 } } do
    local result = remotes.SelectUpgrade:InvokeServer(invalid)
    assert(result.Revision == before.Revision, "Invalid request changed state")
    assert(result.PendingChoices == before.PendingChoices, "Invalid request consumed a choice")
end

local issuedId = before.Choices[1].Id
local accepted = remotes.SelectUpgrade:InvokeServer(issuedId)
assert(accepted.PendingChoices == before.PendingChoices - 1, "Valid choice was not consumed")

local replay = remotes.SelectUpgrade:InvokeServer(issuedId)
assert(replay.Revision == accepted.Revision, "Replayed ID changed state")
assert(replay.PendingChoices == accepted.PendingChoices, "Replayed ID consumed another choice")
print("PASS: invalid requests rejected, valid choice applied once, replay rejected")
```

Repeat this test with two choices queued to confirm a stale ID cannot consume the next offer. The first entry chooses Heavy Tung; verify in the server view that damage increases exactly once. No request above should produce a server error.

## Two players

1. Start a fresh local server with two players.
2. Collect one enemy pickup. Both players should reach level 2 and receive their own three choices.
3. Choose Heavy Tung on player 1. Player 2's offer must remain open.
4. Choose Long Tung on player 2.
5. Inspect both players' server attributes: player 1 should have damage 31.25 and range 7; player 2 should have damage 25 and range 8.4. Both have cumulative XP 25.
6. Spawn a 125-XP pickup using the server command above. Both players should independently have two choices to resolve.

## Combat regression

After upgrades, spawn one more enemy using the **server** Command Bar:

```lua
game:GetService("ServerStorage").StudioTestTools.SpawnEnemy:Invoke()
```

Confirm it still follows, takes automatic bat damage, dies, and drops one pickup. In solo play, after two Heavy Tung choices, the 100-health enemy should die in three hits. Inspect its Humanoid health in the server view to confirm individual hits do 39.0625 damage. Quick Tung affects subsequent attack cooldowns; a cooldown already in progress is allowed to finish. Long Tung increases the actual server hit range, not just its displayed attribute.

The server keeps running while choices are open. Upgrades stack multiplicatively, and a fresh server resets progression. Since XP is shared, late joiners catch up to the shared total and receive the corresponding pending choices.
