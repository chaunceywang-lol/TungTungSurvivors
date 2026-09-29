local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local XPService = require(script.Parent:WaitForChild("XPService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))
local SpawnConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig")).EnemySpawning

ProgressionService.Start()
XPService.Start()
CombatService.Start()

-- One server-owned spawn loop: keep one enemy active, then replace it.
while true do
	local targetRoot = EnemyService.GetNearestLivingRoot(Vector3.zero)
	while not targetRoot do
		task.wait(0.2)
		targetRoot = EnemyService.GetNearestLivingRoot(Vector3.zero)
	end

	local enemy = EnemyService.Spawn(targetRoot.Position + Vector3.new(SpawnConfig.SpawnDistance, 3, 0))
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	print("[TungTungSurvivors] Spawned one basic enemy")
	while enemy:IsDescendantOf(workspace) and humanoid and humanoid.Health > 0 do
		task.wait(0.2)
	end

	task.wait(SpawnConfig.RespawnDelay)
end
