local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("WaveConfig"))
local SpawnManager = require(script.Parent:WaitForChild("SpawnManager"))

local RunManager = {}
local connection = nil
local displayState = nil
local currentWave = 1
local waveElapsed = 0
local runElapsed = 0
local status = "Waiting"

local function positive(value)
	return typeof(value) == "number" and value > 0 and value < math.huge
end

assert(#Config.Waves > 0, "WaveConfig must contain at least one wave")
assert(typeof(Config.RepeatLastWave) == "boolean", "RepeatLastWave must be a boolean")
for _, wave in Config.Waves do
	assert(positive(wave.Duration) and positive(wave.SpawnInterval), "Wave duration and spawn interval must be positive and finite")
	assert(positive(wave.MaxAlive) and wave.MaxAlive % 1 == 0, "Wave MaxAlive must be a positive integer")
	assert(positive(wave.HealthMultiplier) and positive(wave.SpeedMultiplier)
		and positive(wave.DamageMultiplier) and positive(wave.XPMultiplier), "Wave multipliers must be positive and finite")
	assert(SpawnManager.SupportsEnemyType(wave.EnemyType), "Unknown wave enemy type: " .. tostring(wave.EnemyType))
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
	status = "Stopped"
	publish()
end

function RunManager.Start()
	if connection then
		return
	end
	currentWave, waveElapsed, runElapsed = 1, 0, 0
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
		SpawnManager.Update(step, currentDefinition(), currentWave)
		publish()
	end)
end

return RunManager
