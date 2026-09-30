local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local XPService = require(script.Parent:WaitForChild("XPService"))
local EnemyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("EnemyConfig"))

local EnemyService = {}

local BasicDefinition = EnemyConfig.BasicEnemy
for enemyType, definition in EnemyConfig do
	for _, field in { "Health", "WalkSpeed", "XPReward", "Scale" } do
		local value = definition[field]
		assert(typeof(value) == "number" and value > 0 and value < math.huge, "Invalid " .. enemyType .. "." .. field)
	end
	assert(definition.XPReward % 1 == 0, "Enemy XPReward must be a whole number")
end
local TARGET_INTERVAL = 0.2
local STOP_DISTANCE = 4
local RESUME_DISTANCE = 5.5

local activeEnemies = {}
local movementConnection = nil

local function getLivingTargets()
	local targets = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and character:IsDescendantOf(workspace)
			and humanoid and humanoid.Health > 0
			and root and root:IsA("BasePart") then
			table.insert(targets, { player = player, character = character, humanoid = humanoid, root = root })
		end
	end
	return targets
end

local function nearestTarget(position: Vector3, targets)
	local nearest = nil
	local nearestDistanceSquared = math.huge
	for _, target in targets do
		local offset = target.root.Position - position
		local distanceSquared = offset:Dot(offset)
		if distanceSquared < nearestDistanceSquared then
			nearestDistanceSquared = distanceSquared
			nearest = target
		end
	end
	return nearest
end

function EnemyService.GetNearestLivingRoot(position: Vector3): BasePart?
	local target = nearestTarget(position, getLivingTargets())
	return target and target.root or nil
end

local function startMovementLoop()
	if movementConnection then
		return
	end
	local targetElapsed = TARGET_INTERVAL
	movementConnection = RunService.PreSimulation:Connect(function(deltaTime)
		targetElapsed += deltaTime
		local targets = nil
		if targetElapsed >= TARGET_INTERVAL then
			targetElapsed %= TARGET_INTERVAL
			-- Build the player list once per targeting update, shared by all enemies.
			targets = getLivingTargets()
		end

		for model, state in activeEnemies do
			local humanoid, root = state.humanoid, state.root
			if not model:IsDescendantOf(workspace) or humanoid.Health <= 0
				or not root:IsDescendantOf(model) or not humanoid:IsDescendantOf(model) then
				activeEnemies[model] = nil
				continue
			end
			if targets then
				state.target = nearestTarget(root.Position, targets)
			end
			local target = state.target
			if target and (target.player.Parent ~= Players
				or target.player.Character ~= target.character
				or target.humanoid.Health <= 0
				or not target.root:IsDescendantOf(workspace)) then
				state.target = nil
				target = nil
			end

			local offset = target and (target.root.Position - root.Position) or Vector3.zero
			local horizontalOffset = Vector3.new(offset.X, 0, offset.Z)
			local distance = horizontalOffset.Magnitude
			if not target or distance <= state.stopDistance then
				state.chasing = false
			elseif distance > state.resumeDistance then
				state.chasing = true
			end

			-- Let the Humanoid handle physical acceleration. Do not blend old headings
			-- or reduce WalkSpeed toward zero while the enemy is still chasing.
			humanoid.AutoRotate = state.chasing
			if state.chasing then
				humanoid:Move(horizontalOffset.Unit, false)
			else
				humanoid:Move(Vector3.zero, false)
			end
		end

		if next(activeEnemies) == nil then
			movementConnection:Disconnect()
			movementConnection = nil
		end
	end)
end

-- A complete R6 assembly gives the Humanoid the torso, legs, and joints it
-- expects for ground clearance and locomotion. No avatar download is needed.
local function createPlaceholderRig(model: Model, position: Vector3): BasePart
	local function part(name: string, size: Vector3, offset: Vector3): Part
		local bodyPart = Instance.new("Part")
		bodyPart.Name = name
		bodyPart.Size = size
		bodyPart.CFrame = CFrame.new(position + offset)
		bodyPart.Color = Color3.fromRGB(180, 75, 55)
		bodyPart.Material = Enum.Material.Wood
		bodyPart.TopSurface = Enum.SurfaceType.Smooth
		bodyPart.BottomSurface = Enum.SurfaceType.Smooth
		bodyPart.CanCollide = name == "Torso" or name == "Head"
		bodyPart.Massless = name ~= "HumanoidRootPart"
		bodyPart.Parent = model
		return bodyPart
	end

	local function joint(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame)
		local motor = Instance.new("Motor6D")
		motor.Name = name
		motor.Part0 = part0
		motor.Part1 = part1
		motor.C0 = c0
		motor.C1 = c1
		motor.Parent = part0
	end

	local root = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero)
	root.Transparency = 1
	root.RootPriority = 127
	local torso = part("Torso", Vector3.new(2, 2, 1), Vector3.zero)
	local head = part("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0))
	head.Color = Color3.fromRGB(235, 170, 90)
	local leftArm = part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0))
	local rightArm = part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0))
	local leftLeg = part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
	local rightLeg = part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
	joint("RootJoint", root, torso, CFrame.identity, CFrame.identity)
	joint("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	joint("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	joint("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	joint("Left Hip", torso, leftLeg, CFrame.new(-0.5, -1, 0), CFrame.new(0, 1, 0))
	joint("Right Hip", torso, rightLeg, CFrame.new(0.5, -1, 0), CFrame.new(0, 1, 0))
	model.PrimaryPart = root
	return root
end

-- Optional server-provided scaling applies only to this newly spawned enemy.
function EnemyService.Spawn(position: Vector3, multipliers, definition): Model
	definition = definition or BasicDefinition
	multipliers = multipliers or {}
	local healthMultiplier = multipliers.HealthMultiplier or 1
	local speedMultiplier = multipliers.SpeedMultiplier or 1
	local damageMultiplier = multipliers.DamageMultiplier or 1
	local xpMultiplier = multipliers.XPMultiplier or 1
	for _, value in { healthMultiplier, speedMultiplier, damageMultiplier, xpMultiplier } do
		assert(typeof(value) == "number" and value > 0 and value < math.huge, "Enemy multipliers must be positive and finite")
	end
	-- Capture the reward at spawn; later wave changes never alter this enemy.
	local xpValue = math.max(1, math.floor((definition.XPReward or BasicDefinition.XPReward) * xpMultiplier + 0.5))
	local onDeath = definition.OnDeath
	local folder = workspace:FindFirstChild("Enemies")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Enemies"
		folder.Parent = workspace
	end

	local model = Instance.new("Model")
	model.Name = definition.Name or "BasicEnemy"
	model:SetAttribute("EnemyType", model.Name)
	model:SetAttribute("HealthMultiplier", healthMultiplier)
	model:SetAttribute("SpeedMultiplier", speedMultiplier)
	model:SetAttribute("DamageMultiplier", damageMultiplier) -- Reserved; no enemy attack yet.
	model:SetAttribute("XPMultiplier", xpMultiplier)
	model:SetAttribute("XPValue", xpValue)

	local root = createPlaceholderRig(model, position)
	if definition.Scale then
		model:ScaleTo(definition.Scale)
	end
	if definition.Color then
		for _, part in model:GetChildren() do
			if part:IsA("BasePart") then
				part.Color = definition.Color
			end
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.HipHeight = 0
	humanoid.MaxHealth = (definition.Health or BasicDefinition.Health) * healthMultiplier
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = (definition.WalkSpeed or BasicDefinition.WalkSpeed) * speedMultiplier
	humanoid.DisplayName = definition.DisplayName or "Basic Enemy"
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model
	local droppedXP = false
	humanoid.Died:Connect(function()
		-- Stop tracking this enemy immediately; preserve the existing corpse cleanup.
		activeEnemies[model] = nil
		if not droppedXP then
			droppedXP = true
			if onDeath then
				onDeath(model)
			else
				XPService.Spawn(root.Position, xpValue)
			end
		end
		Debris:AddItem(model, 0.3)
	end)

	model.Parent = folder
	-- Keep physics ownership on the server, including when players approach.
	root:SetNetworkOwner(nil)

	activeEnemies[model] = {
		root = root,
		humanoid = humanoid,
		target = nil,
		chasing = false,
		stopDistance = definition.StopDistance or STOP_DISTANCE,
		resumeDistance = definition.ResumeDistance or RESUME_DISTANCE,
	}
	startMovementLoop()

	return model
end

function EnemyService.SpawnType(position: Vector3, enemyType: string, multipliers): Model
	local definition = EnemyConfig[enemyType]
	assert(definition, "Unknown enemy type: " .. tostring(enemyType))
	return EnemyService.Spawn(position, multipliers, definition)
end

function EnemyService.StopAll()
	for _, state in activeEnemies do
		state.humanoid:Move(Vector3.zero, false)
		state.humanoid.WalkSpeed = 0
	end
	table.clear(activeEnemies)
	if movementConnection then
		movementConnection:Disconnect()
		movementConnection = nil
	end
end

return EnemyService
