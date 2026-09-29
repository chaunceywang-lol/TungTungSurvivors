local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local runState = ReplicatedStorage:WaitForChild("RunState")

local gui = Instance.new("ScreenGui")
gui.Name = "BossUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "BossHealth"
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.new(0.5, 0, 0, 124)
bar.Size = UDim2.new(0.85, 0, 0, 42)
bar.BackgroundColor3 = Color3.fromRGB(35, 20, 40)
bar.Visible = false
bar.Parent = gui
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(520, 42)
limit.Parent = bar
local fill = Instance.new("Frame")
fill.BackgroundColor3 = Color3.fromRGB(155, 45, 170)
fill.BorderSizePixel = 0
fill.Size = UDim2.fromScale(1, 1)
fill.Parent = bar
local text = Instance.new("TextLabel")
text.BackgroundTransparency = 1
text.Size = UDim2.fromScale(1, 1)
text.Font = Enum.Font.GothamBold
text.TextSize = 18
text.TextColor3 = Color3.new(1, 1, 1)
text.ZIndex = 2
text.Parent = bar

local victory = Instance.new("TextLabel")
victory.Name = "Victory"
victory.AnchorPoint = Vector2.new(0.5, 1)
victory.Position = UDim2.new(0.5, 0, 1, -24)
victory.Size = UDim2.new(0.9, 0, 0, 64)
victory.BackgroundColor3 = Color3.fromRGB(25, 75, 45)
victory.TextColor3 = Color3.new(1, 1, 1)
victory.Font = Enum.Font.GothamBold
victory.TextSize = 22
victory.TextWrapped = true
victory.Text = "VICTORY!\nBoss defeated — run complete"
victory.Visible = false
victory.Parent = gui
local victoryLimit = Instance.new("UISizeConstraint")
victoryLimit.MaxSize = Vector2.new(520, 64)
victoryLimit.Parent = victory

local bossState = nil
local function render()
	local won = runState:GetAttribute("Status") == "Victory"
	victory.Visible = won
	bar.Visible = not won and bossState ~= nil and bossState:GetAttribute("Active") == true
	if bossState then
		local health = bossState:GetAttribute("Health") or 0
		local maximum = bossState:GetAttribute("MaxHealth") or 1
		fill.Size = UDim2.fromScale(math.clamp(health / math.max(1, maximum), 0, 1), 1)
		text.Text = string.format("%s  %d / %d", bossState:GetAttribute("Name") or "Boss", math.ceil(health), math.ceil(maximum))
	end
end

runState.AttributeChanged:Connect(render)
render()
-- This folder is only created when the boss appears. Observe its arrival rather
-- than waiting several minutes and producing a misleading infinite-yield warning.
local function attachState(child)
	if child.Name == "BossState" and bossState ~= child then
		bossState = child
		bossState.AttributeChanged:Connect(render)
		render()
	end
end
ReplicatedStorage.ChildAdded:Connect(attachState)
local existing = ReplicatedStorage:FindFirstChild("BossState")
if existing then attachState(existing) end
