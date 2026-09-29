local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TungBat = require(script.Parent:WaitForChild("TungBat"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

local CombatService = {}
local started = false
local nextAttackAt = {}
local connection = nil
local removingConnection = nil

function CombatService.Stop()
	started = false
	if connection then connection:Disconnect(); connection = nil end
	if removingConnection then removingConnection:Disconnect(); removingConnection = nil end
	table.clear(nextAttackAt)
end

function CombatService.Start()
	if started then
		return
	end
	started = true

	-- Outbound cosmetic event only. Clients cannot request hits or damage.
	local swingEvent = ReplicatedStorage:FindFirstChild("TungBatSwing") or Instance.new("RemoteEvent")
	swingEvent.Name = "TungBatSwing"
	swingEvent.Parent = ReplicatedStorage

	removingConnection = Players.PlayerRemoving:Connect(function(player)
		nextAttackAt[player] = nil
	end)

	local elapsed = 0
	connection = RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < 0.1 then
			return
		end
		elapsed = 0
		local now = os.clock()

		for _, player in Players:GetPlayers() do
			if not started then return end
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if character and character:IsDescendantOf(workspace)
				and humanoid and humanoid.Health > 0
				and root and root:IsA("BasePart")
				and now >= (nextAttackAt[player] or 0) then
				local stats = ProgressionService.GetWeaponStats(player)
				local hitPosition = TungBat.TryAttack(character, root, stats)
				if hitPosition then
					nextAttackAt[player] = now + stats.Cooldown
					swingEvent:FireAllClients(root.Position, hitPosition)
				end
			end
		end
	end)
end

return CombatService
