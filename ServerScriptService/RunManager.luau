local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("WaveConfig"))
local SpawnManager = require(script.Parent:WaitForChild("SpawnManager"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local BossTypes = { TungBoss = require(script.Parent:WaitForChild("TungBoss")) }

local RunManager = {}
local connection = nil
local displayState = nil
local currentWave = 1
local waveElapsed = 0
local runElapsed = 0
local status = "Waiting"
local bossModel = nil
local stopBoss = nil
local bossRetry = 0
local bossSpawnStatus = "NotReached"

local function positive(value)
	return typeof(value) == "number" and value > 0 and value < math.huge
end

assert(#Config.Waves > 0, "WaveConfig must contain at least one wave")
assert(typeof(Config.RepeatLastWave) == "boolean", "RepeatLastWave must be a boolean")
for index, wave in Config.Waves do
	assert(positive(wave.Duration) and positive(wave.SpawnInterval), "Wave duration and spawn interval must be positive and finite")
	assert(positive(wave.MaxAlive) and wave.MaxAlive % 1 == 0, "Wave MaxAlive must be a positive integer")
	assert(positive(wave.HealthMultiplier) and positive(wave.SpeedMultiplier)
		and positive(wave.DamageMultiplier) and positive(wave.XPMultiplier), "Wave multipliers must be positive and finite")
	assert(SpawnManager.SupportsEnemyType(wave.EnemyType), "Unknown wave enemy type: " .. tostring(wave.EnemyType))
	if wave.Boss then
		assert(BossTypes[wave.Boss], "Unknown boss type: " .. tostring(wave.Boss))
		assert(index == #Config.Waves and not Config.RepeatLastWave, "The victory boss must be the final, nonrepeating wave")
	end
end

local function currentDefinition()
	return Config.Waves[math.min(currentWave, #Config.Waves)]
end

local function publish()
	if not displayState then
		return
	end
	displayState:SetAttribute("CurrentWave", currentWave)
	displayState:SetAttribute("SecondsRemaining", math.max(0, math.ceil(currentDefinition().Duration - waveElapsed)))
	displayState:SetAttribute("ElapsedSeconds", math.floor(runElapsed))
	displayState:SetAttribute("Status", status)
	displayState:SetAttribute("BossWave", currentDefinition().Boss ~= nil)
	displayState:SetAttribute("BossSpawnStatus", bossSpawnStatus)
end

local function hasLivingPlayer(): boolean
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and character:IsDescendantOf(workspace) and humanoid and humanoid.Health > 0
			and root and root:IsA("BasePart") then
			return true
		end
	end
	return false
end

function RunManager.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	SpawnManager.Stop()
	if stopBoss then stopBoss(); stopBoss = nil end
	status = "Stopped"
	publish()
end

function RunManager.Victory()
	if not connection or status == "Victory" then return end
	RunManager.Stop()
	EnemyService.StopAll()
	CombatService.Stop()
	status = "Victory"
	bossSpawnStatus = "Defeated"
	publish()
end

-- Called by the StudioTestTools Script, never through a client remote or a
-- Command Bar require (which would use a separate module environment).
function RunManager.StartBossTest()
	assert(RunService:IsStudio(), "Boss test is available only in Studio")
	assert(connection, "Start a fresh Play session before testing the boss")
	if currentDefinition().Boss then
		return "Already in the boss wave: " .. bossSpawnStatus
	end
	local bossWave = nil
	local precedingDuration = 0
	for index, wave in Config.Waves do
		if wave.Boss then
			bossWave = index
			break
		end
		precedingDuration += wave.Duration
	end
	assert(bossWave, "WaveConfig has no boss wave; check Script Sync")
	currentWave = bossWave
	waveElapsed = 0
	runElapsed = precedingDuration
	bossRetry = 0
	bossSpawnStatus = "Pending"
	publish()
	return "Advanced to boss wave. Placement runs on the next server update."
end

function RunManager.Start()
	if connection then
		return
	end
	currentWave, waveElapsed, runElapsed = 1, 0, 0
	bossModel, stopBoss, bossRetry = nil, nil, 0
	bossSpawnStatus = "NotReached"
	status = "Waiting"
	if not displayState then
		displayState = Instance.new("Folder")
		displayState.Name = "RunState"
		publish()
		displayState.Parent = ReplicatedStorage
	else
		publish()
	end
	SpawnManager.Start()
	local accumulated = 0
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		accumulated += deltaTime
		if accumulated < 0.25 then
			return
		end
		local step = accumulated
		accumulated = 0
		if not hasLivingPlayer() then
			if currentDefinition().Boss and not bossModel then bossSpawnStatus = "WaitingForPlayer" end
			status = "Waiting"
			publish()
			return
		end
		status = "Running"
		runElapsed += step
		waveElapsed += step
		-- Carry overshoot across boundaries, including a delayed server frame.
		while waveElapsed >= currentDefinition().Duration do
			local duration = currentDefinition().Duration
			if currentDefinition().Boss then
				waveElapsed = duration -- Expiring the countdown never defeats a boss.
				break
			end
			if currentWave == #Config.Waves and not Config.RepeatLastWave then
				runElapsed -= waveElapsed - duration
				waveElapsed = duration
				RunManager.Stop()
				status = "Completed"
				publish()
				return
			end
			waveElapsed -= duration
			currentWave += 1
		end
		local wave = currentDefinition()
		if wave.Boss then
			bossRetry -= step
			if bossModel and not bossModel:IsDescendantOf(workspace) then
				bossModel = nil -- Removal without death is not victory; retry the encounter.
			end
			if not bossModel and bossRetry <= 0 then
				bossRetry = 1
				local bossType = BossTypes[wave.Boss]
				local position = SpawnManager.FindEncounterPosition(bossType.Scale)
				if position then
					local success, modelOrError, cleanup = xpcall(function()
						return bossType.Spawn(position, RunManager.Victory)
					end, debug.traceback)
					if success then
						bossModel, stopBoss = modelOrError, cleanup
						bossModel:SetAttribute("SpawnWave", currentWave)
						bossSpawnStatus = "Spawned"
						print("[Boss] Great Tung spawned in wave " .. currentWave)
					else
						bossSpawnStatus = "SpawnError"
						bossRetry = math.huge -- Do not create repeated partial bosses after an error.
						warn("[Boss] Spawn failed; restart Play after fixing the error:\n" .. tostring(modelOrError))
					end
				else
					if bossSpawnStatus ~= "WaitingForSpace" then
						warn("[Boss] No safe spawn position. Move toward open, flat ground; placement will retry.")
					end
					bossSpawnStatus = "WaitingForSpace"
				end
			end
		end
		SpawnManager.Update(step, currentDefinition(), currentWave)
		publish()
	end)
end

return RunManager
