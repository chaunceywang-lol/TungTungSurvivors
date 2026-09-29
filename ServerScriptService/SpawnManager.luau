local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig")).EnemySpawning
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))

local SpawnManager = {}
local active = false
local untilSpawn = 0
local initialSpawn = true
local random = Random.new()
-- Register future enemy factories here; only the existing type is implemented.
local enemyFactories = { BasicEnemy = EnemyService.Spawn }

function SpawnManager.SupportsEnemyType(enemyType: string): boolean
	return enemyFactories[enemyType] ~= nil
end

local function positive(value)
	return typeof(value) == "number" and value > 0 and value < math.huge
end

assert(positive(Config.InitialCount) and Config.InitialCount % 1 == 0, "InitialCount must be a positive integer")
assert(positive(Config.MinSpawnDistance) and positive(Config.MaxSpawnDistance)
	and Config.MaxSpawnDistance >= Config.MinSpawnDistance, "Invalid spawn distance range")
assert(positive(Config.MinEnemySpacing), "MinEnemySpacing must be positive")
assert(positive(Config.PlacementAttempts) and Config.PlacementAttempts % 1 == 0, "PlacementAttempts must be a positive integer")

local function livingRoots()
	local roots = {}
	local characters = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character then
			table.insert(characters, character)
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local root = character:FindFirstChild("HumanoidRootPart")
			if character:IsDescendantOf(workspace) and humanoid and humanoid.Health > 0
				and root and root:IsA("BasePart") then
				table.insert(roots, root)
			end
		end
	end
	return roots, characters
end

local function aliveEnemies()
	local alive = {}
	local folder = workspace:FindFirstChild("Enemies")
	if folder then
		for _, enemy in folder:GetChildren() do
			local humanoid = enemy:FindFirstChildOfClass("Humanoid")
			if enemy:IsA("Model") and humanoid and humanoid.Health > 0 then
				table.insert(alive, enemy)
			end
		end
	end
	return alive
end

local function horizontalDistance(a: Vector3, b: Vector3): number
	local offset = a - b
	return Vector3.new(offset.X, 0, offset.Z).Magnitude
end

local function findSpawnPosition(roots, characters, enemies): Vector3?
	local excluded = table.clone(characters)
	local folder = workspace:FindFirstChild("Enemies")
	if folder then
		table.insert(excluded, folder)
	end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = excluded
	rayParams.RespectCanCollide = true
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = excluded
	overlapParams.RespectCanCollide = true

	for _ = 1, Config.PlacementAttempts do
		local target = roots[random:NextInteger(1, #roots)]
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(Config.MinSpawnDistance, Config.MaxSpawnDistance)
		local candidate = target.Position + Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance)
		local ground = workspace:Raycast(candidate + Vector3.new(0, 20, 0), Vector3.new(0, -80, 0), rayParams)
		if not ground or ground.Normal.Y < 0.8 or math.abs(ground.Position.Y - target.Position.Y) > 12 then
			continue
		end
		-- R6 feet sit three studs below the root; leave a small settling gap.
		local position = ground.Position + Vector3.new(0, 3.25, 0)
		local clear = true
		for _, root in roots do
			if horizontalDistance(position, root.Position) < Config.MinSpawnDistance then
				clear = false
				break
			end
		end
		for _, enemy in enemies do
			local root = enemy:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and horizontalDistance(position, root.Position) < Config.MinEnemySpacing then
				clear = false
				break
			end
		end
		if clear and #workspace:GetPartBoundsInBox(CFrame.new(position), Vector3.new(4, 6, 3), overlapParams) == 0 then
			return position
		end
	end
	-- Try again on the next scheduled spawn; never fall back to an unsafe spot.
	return nil
end

function SpawnManager.Stop()
	active = false
	workspace:SetAttribute("SpawnManagerActive", false)
end

function SpawnManager.Start()
	if active then
		return
	end
	active = true
	untilSpawn = 0
	initialSpawn = true
	workspace:SetAttribute("SpawnManagerActive", true)
end

-- RunManager supplies the authoritative wave and active elapsed time.
function SpawnManager.Update(deltaTime: number, wave, waveNumber: number)
	if not active then
		return
	end
	local roots, characters = livingRoots()
	local enemies = aliveEnemies()
	workspace:SetAttribute("SpawnInterval", wave.SpawnInterval)
	workspace:SetAttribute("MaxAliveEnemies", wave.MaxAlive)
	workspace:SetAttribute("AliveEnemies", #enemies)
	if #roots == 0 then
		return
	end
	untilSpawn = math.min(untilSpawn, wave.SpawnInterval) - deltaTime
	if untilSpawn > 0 then
		return
	end
	-- Wave changes preserve the schedule and never add a new initial batch.
	untilSpawn = wave.SpawnInterval
	local count = math.min(initialSpawn and Config.InitialCount or 1, math.max(0, wave.MaxAlive - #enemies))
	initialSpawn = false
	for _ = 1, count do
		local position = findSpawnPosition(roots, characters, enemies)
		if position then
			local enemy = enemyFactories[wave.EnemyType](position, wave)
			enemy:SetAttribute("SpawnWave", waveNumber)
			enemy:SetAttribute("SpawnPosition", position)
			table.insert(enemies, enemy)
		end
	end
	workspace:SetAttribute("AliveEnemies", #enemies)
end

return SpawnManager
