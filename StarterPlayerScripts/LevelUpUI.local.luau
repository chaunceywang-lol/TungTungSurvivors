local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ProgressionRemotes")
local stateChanged = remotes:WaitForChild("StateChanged")
local getState = remotes:WaitForChild("GetState")
local selectUpgrade = remotes:WaitForChild("SelectUpgrade")

local gui = Instance.new("ScreenGui")
gui.Name = "LevelUpUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function label(parent, name, position, size, textSize)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundTransparency = 1
	item.Font = Enum.Font.GothamMedium
	item.TextColor3 = Color3.fromRGB(240, 245, 255)
	item.TextSize = textSize
	item.TextWrapped = true
	item.Parent = parent
	return item
end

local hud = label(gui, "XPProgress", UDim2.fromOffset(16, 12), UDim2.fromOffset(280, 48), 16)
hud.BackgroundTransparency = 0.15
hud.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
hud.Text = "Loading level..."

local overlay = Instance.new("Frame")
overlay.Name = "UpgradeChoices"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.35
overlay.Active = true
overlay.Visible = false
overlay.Parent = gui

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.92, 0.8)
panel.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
panel.Parent = overlay
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(520, 400)
constraint.Parent = panel
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local title = label(panel, "Title", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.14), 26)
title.Text = "Level up!"
local subtitle = label(panel, "Subtitle", UDim2.fromScale(0.05, 0.18), UDim2.fromScale(0.9, 0.12), 16)
local status = label(panel, "Status", UDim2.fromScale(0.05, 0.9), UDim2.fromScale(0.9, 0.08), 14)
status.Text = ""

local buttons = {}
for index = 1, 3 do
	local button = Instance.new("TextButton")
	button.Name = "Choice" .. index
	button.Position = UDim2.fromScale(0.06, 0.32 + (index - 1) * 0.19)
	button.Size = UDim2.fromScale(0.88, 0.17)
	button.BackgroundColor3 = Color3.fromRGB(42, 78, 101)
	button.TextColor3 = Color3.fromRGB(240, 245, 255)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 18
	button.TextWrapped = true
	button.Modal = true
	button.Parent = panel
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button
	buttons[index] = button
end

local latest = nil
local submitting = false

local function render()
	if not latest then
		return
	end
	hud.Text = string.format("Level %d  |  XP %g / %g", latest.Level, latest.XP, latest.XPRequired)
	overlay.Visible = #latest.Choices > 0
	subtitle.Text = string.format("Choose one upgrade • %d choice(s) remaining", latest.PendingChoices)
	for index, button in buttons do
		local choice = latest.Choices[index]
		button.Visible = choice ~= nil
		button.Active = not submitting
		button.AutoButtonColor = not submitting
		button.Text = choice and (choice.Title .. "\n" .. choice.Description) or ""
	end
end

local function receive(state)
	-- Ignore older responses if an XP award or selection update arrived first.
	if not latest or state.Revision >= latest.Revision then
		latest = state
		render()
	end
end

for index, button in buttons do
	button.Activated:Connect(function()
		if submitting or not latest or not latest.Choices[index] then
			return
		end
		local upgradeId = latest.Choices[index].Id
		submitting = true
		status.Text = "Applying upgrade..."
		render()
		-- Only the issued upgrade ID is sent; no XP or stat values leave the client.
		local success, state = pcall(function()
			return selectUpgrade:InvokeServer(upgradeId)
		end)
		if success then
			receive(state)
		end
		submitting = false
		status.Text = success and "" or "Couldn't submit. Please try again."
		render()
	end)
end

stateChanged.OnClientEvent:Connect(receive)
-- Recover the initial state even if level-ups happened before this script loaded.
task.spawn(function()
	while not latest do
		local success, state = pcall(function()
			return getState:InvokeServer()
		end)
		if success then
			receive(state)
		elseif not latest then
			hud.Text = "Reconnecting level display..."
			task.wait(2)
		end
	end
end)
