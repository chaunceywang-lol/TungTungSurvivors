local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local XPService = require(script.Parent:WaitForChild("XPService"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local RunManager = require(script.Parent:WaitForChild("RunManager"))
local SpawnManager = require(script.Parent:WaitForChild("SpawnManager"))
local EnemyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("EnemyConfig"))

-- Bindable callbacks run in this server Script's environment. Requiring a
-- stateful module directly from the Command Bar would use a separate cache.
local function livingRoot()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and character:IsDescendantOf(workspace)
			and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
			return root
		end
	end
	error("No living player is available. Start Play and wait for the character to spawn.")
end

local folder = Instance.new("Folder")
folder.Name = "StudioTestTools"

local spawnXP = Instance.new("BindableFunction")
spawnXP.Name = "SpawnXP"
spawnXP.OnInvoke = function(value)
	return XPService.Spawn(livingRoot().Position, value)
end
spawnXP.Parent = folder

local spawnEnemy = Instance.new("BindableFunction")
spawnEnemy.Name = "SpawnEnemy"
spawnEnemy.OnInvoke = function(enemyType)
	enemyType = enemyType or "BasicEnemy"
	assert(typeof(enemyType) == "string" and EnemyConfig[enemyType], "Unknown enemy type")
	local position = SpawnManager.FindEncounterPosition(EnemyConfig[enemyType].Scale)
	assert(position, "No safe placement found; move to open, flat ground and try again")
	return EnemyService.SpawnType(position, enemyType)
end
spawnEnemy.Parent = folder

local startBossWave = Instance.new("BindableFunction")
startBossWave.Name = "StartBossWave"
startBossWave.OnInvoke = function()
	return RunManager.StartBossTest()
end
startBossWave.Parent = folder

-- No client remote and no test tools in published servers.
folder.Parent = ServerStorage
