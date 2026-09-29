local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local swingEvent = ReplicatedStorage:WaitForChild("TungBatSwing")

-- Local, non-colliding feedback only; this bat never determines hits.
swingEvent.OnClientEvent:Connect(function(origin: Vector3, hitPosition: Vector3)
	local direction = Vector3.new(hitPosition.X - origin.X, 0, hitPosition.Z - origin.Z)
	if direction.Magnitude < 0.01 then
		direction = Vector3.new(0, 0, -1)
	end
	local facing = CFrame.lookAt(origin, origin + direction)
	local bat = Instance.new("Part")
	bat.Name = "TungBatVisual"
	bat.Size = Vector3.new(0.6, 0.6, 4)
	bat.Material = Enum.Material.Wood
	bat.Color = Color3.fromRGB(135, 85, 45)
	bat.Anchored = true
	bat.CanCollide = false
	bat.CanTouch = false
	bat.CanQuery = false
	bat.CastShadow = false
	bat.CFrame = facing * CFrame.Angles(0, math.rad(-70), 0) * CFrame.new(0, 0, -2.5)
	bat.Parent = workspace
	Debris:AddItem(bat, 1)

	local elapsed = 0
	local duration = 0.25
	while elapsed < duration and bat.Parent do
		elapsed += RunService.RenderStepped:Wait()
		local progress = math.min(elapsed / duration, 1)
		bat.CFrame = facing * CFrame.Angles(0, math.rad(-70 + 140 * progress), 0)
			* CFrame.new(0, 0, -2.5)
		bat.Transparency = progress * 0.6
	end
	bat:Destroy()
end)
