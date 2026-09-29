local Players = game:GetService("Players")

local EnemyService = {}

local MAX_HEALTH = 100
local WALK_SPEED = 10
local THINK_INTERVAL = 0.2
local STOP_DISTANCE = 4

function EnemyService.GetNearestLivingRoot(position: Vector3): BasePart?
	local nearestRoot = nil
	local nearestDistance = math.huge

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and character:IsDescendantOf(workspace)
			and humanoid and humanoid.Health > 0
			and root and root:IsA("BasePart") then
			local distance = (root.Position - position).Magnitude
			if distance < nearestDistance then
				nearestDistance = distance
				nearestRoot = root
			end
		end
	end

	return nearestRoot
end

-- Each call creates an independent enemy; the startup script controls the count.
function EnemyService.Spawn(position: Vector3): Model
	local folder = workspace:FindFirstChild("Enemies")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Enemies"
		folder.Parent = workspace
	end

	local model = Instance.new("Model")
	model.Name = "BasicEnemy"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(3, 4, 3)
	root.Color = Color3.fromRGB(180, 75, 55)
	root.Material = Enum.Material.Wood
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth
	root.CFrame = CFrame.new(position)
	root.Parent = model
	model.PrimaryPart = root

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Color = Color3.fromRGB(235, 170, 90)
	head.Material = Enum.Material.Wood
	head.CanCollide = false
	head.Massless = true
	head.CFrame = root.CFrame * CFrame.new(0, 3, 0)
	head.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = root

	local humanoid = Instance.new("Humanoid")
	-- This block placeholder uses a welded head rather than a character rig.
	humanoid.RequiresNeck = false
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 0
	humanoid.MaxHealth = MAX_HEALTH
	humanoid.Health = MAX_HEALTH
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.DisplayName = "Basic Enemy"
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	humanoid.Parent = model

	model.Parent = folder
	-- Keep physics ownership on the server, including when players approach.
	root:SetNetworkOwner(nil)

	task.spawn(function()
		while model:IsDescendantOf(workspace) and humanoid.Health > 0 do
			local target = EnemyService.GetNearestLivingRoot(root.Position)
			if target and (target.Position - root.Position).Magnitude > STOP_DISTANCE then
				humanoid:MoveTo(target.Position)
			else
				-- Cancel the previous destination when no living target is available.
				humanoid:MoveTo(root.Position)
			end
			task.wait(THINK_INTERVAL)
		end
	end)

	return model
end

return EnemyService
