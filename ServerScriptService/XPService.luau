local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig")).XP

local XPService = {}
local CHECK_INTERVAL = 0.1
local started = false
local pickupFolder = nil
local pickups = {}
local totalXP = 0

assert(Config.PickupRadius > 0 and Config.PickupRadius < math.huge, "XP.PickupRadius must be positive and finite")

local function publishTotal(player: Player)
	-- Read-only display mirror for clients; the authoritative total is above.
	player:SetAttribute("XP", totalXP)
end

function XPService.GetTotalXP(): number
	return totalXP
end

function XPService.Start()
	if started then
		return
	end
	started = true
	pickupFolder = Instance.new("Folder")
	pickupFolder.Name = "XPPickups"
	pickupFolder.Parent = workspace

	-- This arena server is the current party. Respawns retain XP, and joining
	-- players receive the shared session total. Nothing is persisted between servers.
	Players.PlayerAdded:Connect(publishTotal)
	for _, player in Players:GetPlayers() do
		publishTotal(player)
	end

	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < CHECK_INTERVAL then
			return
		end
		elapsed %= CHECK_INTERVAL
		if next(pickups) == nil then
			return
		end

		local livingRoots = {}
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if character and character:IsDescendantOf(workspace)
				and humanoid and humanoid.Health > 0
				and root and root:IsA("BasePart") then
				table.insert(livingRoots, root)
			end
		end

		local radiusSquared = Config.PickupRadius * Config.PickupRadius
		local gainedXP = 0
		for pickup, drop in pickups do
			if not pickup:IsDescendantOf(workspace) then
				pickups[pickup] = nil
				continue
			end
			for _, root in livingRoots do
				local offset = root.Position - drop.position
				if offset:Dot(offset) <= radiusSquared then
					-- Claim first, then award. This block never yields, and only this
					-- server loop collects pickups, even with overlapping players.
					pickups[pickup] = nil
					gainedXP += drop.value
					pickup:Destroy()
					break
				end
			end
		end

		if gainedXP > 0 then
			totalXP += gainedXP
			for _, player in Players:GetPlayers() do
				publishTotal(player)
			end
		end
	end)
end

-- Call only from server code. Different enemy types can supply their own value.
function XPService.Spawn(position: Vector3, value: number?): BasePart
	local amount = if value == nil then Config.DefaultDropValue else value
	assert(typeof(amount) == "number" and amount > 0 and amount < math.huge
		and amount % 1 == 0, "XP drop value must be a positive finite integer")
	XPService.Start()

	local pickup = Instance.new("Part")
	pickup.Name = "XPOrb"
	pickup.Shape = Enum.PartType.Ball
	pickup.Size = Vector3.new(1, 1, 1)
	pickup.Material = Enum.Material.Neon
	pickup.Color = Color3.fromRGB(80, 220, 255)
	pickup.Anchored = true
	pickup.CanCollide = false
	pickup.CanTouch = false
	pickup.CanQuery = false
	pickup.Position = position
	pickup:SetAttribute("XPValue", amount) -- Inspection only; never read for awards.
	pickup.Parent = pickupFolder
	pickups[pickup] = { position = position, value = amount }
	return pickup
end

return XPService
