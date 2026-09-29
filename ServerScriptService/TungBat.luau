local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig")).TungBat

local TungBat = {}
TungBat.Cooldown = Config.Cooldown

-- Returns the hit position for cosmetic feedback, or nil when nothing was hit.
function TungBat.TryAttack(character: Model, playerRoot: BasePart): Vector3?
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return nil
	end

	local nearestHumanoid = nil
	local hitPosition = nil
	local nearestDistance = Config.Range
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	rayParams.RespectCanCollide = true

	for _, enemy in enemies:GetChildren() do
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		local root = enemy:FindFirstChild("HumanoidRootPart")
		if enemy:IsA("Model") and humanoid and humanoid.Health > 0
			and root and root:IsA("BasePart") then
			local offset = root.Position - playerRoot.Position
			local distance = offset.Magnitude
			if distance <= nearestDistance then
				local obstruction = workspace:Raycast(playerRoot.Position, offset, rayParams)
				if not obstruction or obstruction.Instance:IsDescendantOf(enemy) then
					nearestDistance = distance
					nearestHumanoid = humanoid
					hitPosition = root.Position
				end
			end
		end
	end

	if nearestHumanoid then
		nearestHumanoid:TakeDamage(Config.Damage)
	end
	return hitPosition
end

return TungBat
