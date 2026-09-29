local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local XPService = require(script.Parent:WaitForChild("XPService"))

XPService.Start()
CombatService.Start()

-- Wait for a living character, then create exactly one enemy for this server.
local firstRoot = EnemyService.GetNearestLivingRoot(Vector3.zero)
while not firstRoot do
	task.wait(0.2)
	firstRoot = EnemyService.GetNearestLivingRoot(Vector3.zero)
end

EnemyService.Spawn(firstRoot.Position + Vector3.new(20, 3, 0))
print("[TungTungSurvivors] Spawned one basic enemy")
