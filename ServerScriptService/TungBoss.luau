local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local XPService = require(script.Parent:WaitForChild("XPService"))
local Config = require(ReplicatedStorage:WaitForChild("BossConfig")).TungBoss

local TungBoss = { Scale = Config.Scale }
for _, key in { "Health", "WalkSpeed", "Scale", "Damage", "ContactCooldown", "ContactPadding", "XPReward" } do
	assert(typeof(Config[key]) == "number" and Config[key] > 0 and Config[key] < math.huge, "Invalid boss setting: " .. key)
end
assert(Config.XPReward % 1 == 0, "Boss XPReward must be an integer")

-- This enemy type owns its contact behavior and reward. Later boss modules can
-- reuse EnemyService's rig/chase implementation and supply different attacks.
function TungBoss.Spawn(position: Vector3, onDefeated)
	local state = ReplicatedStorage:FindFirstChild("BossState")
	if not state then
		state = Instance.new("Folder")
		state.Name = "BossState"
		state.Parent = ReplicatedStorage
	end
	local contactConnection, healthConnection, destroyConnection
	local stopped = false
	local function stop()
		stopped = true
		if contactConnection then contactConnection:Disconnect() end
		if healthConnection then healthConnection:Disconnect() end
		if destroyConnection then destroyConnection:Disconnect() end
		state:SetAttribute("Active", false)
	end
	local model = EnemyService.Spawn(position, nil, {
		Name = "TungBoss", DisplayName = Config.DisplayName,
		Health = Config.Health, WalkSpeed = Config.WalkSpeed, Scale = Config.Scale,
		Color = Color3.fromRGB(125, 45, 160), StopDistance = 1, ResumeDistance = 2,
		XPReward = Config.XPReward,
		OnDeath = function()
			stop()
			state:SetAttribute("Health", 0)
			XPService.AwardShared(Config.XPReward)
			onDefeated()
		end,
	})
	model:SetAttribute("EnemyType", "TungBoss")
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local torso = model:FindFirstChild("Torso")
	state:SetAttribute("Name", Config.DisplayName)
	state:SetAttribute("MaxHealth", humanoid.MaxHealth)
	state:SetAttribute("Health", humanoid.Health)
	state:SetAttribute("Active", true)
	healthConnection = humanoid.HealthChanged:Connect(function(health)
		state:SetAttribute("Health", math.max(0, health))
	end)
	destroyConnection = model.Destroying:Connect(stop)
	local nextDamage = setmetatable({}, { __mode = "k" })
	local elapsed = 0
	contactConnection = RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < 0.1 or stopped then return end
		elapsed = 0
		if humanoid.Health <= 0 or not model:IsDescendantOf(workspace) then
			stop()
			return
		end
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local target = character and character:FindFirstChildOfClass("Humanoid")
			if character and character:IsDescendantOf(workspace) and target and target.Health > 0
				and now >= (nextDamage[target] or 0) then
				local params = OverlapParams.new()
				params.FilterType = Enum.RaycastFilterType.Include
				params.FilterDescendantsInstances = { character }
				local padding = Vector3.one * (Config.ContactPadding * 2)
				if #workspace:GetPartBoundsInBox(torso.CFrame, torso.Size + padding, params) > 0 then
					nextDamage[target] = now + Config.ContactCooldown
					target:TakeDamage(Config.Damage)
				end
			end
		end
	end)
	return model, stop
end

return TungBoss
