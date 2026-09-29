local Players = game:GetService("Players")
local state = game:GetService("ReplicatedStorage"):WaitForChild("RunState")

local gui = Instance.new("ScreenGui")
gui.Name = "WaveUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Name = "WaveTimer"
label.Position = UDim2.fromOffset(16, 68) -- Below the existing level/XP display.
label.Size = UDim2.fromOffset(280, 48)
label.BackgroundColor3 = Color3.fromRGB(22, 29, 40)
label.BackgroundTransparency = 0.15
label.TextColor3 = Color3.fromRGB(240, 245, 255)
label.Font = Enum.Font.GothamMedium
label.TextSize = 17
label.TextWrapped = true
label.Parent = gui

local function render()
	local wave = state:GetAttribute("CurrentWave")
	local remaining = state:GetAttribute("SecondsRemaining")
	local status = state:GetAttribute("Status")
	if wave == nil or remaining == nil or status == nil then
		label.Text = "Loading wave..."
		return
	end
	local time = string.format("%02d:%02d", math.floor(remaining / 60), remaining % 60)
	local suffix = if status == "Waiting" then " • Waiting for players" else ""
	if status == "Victory" then
		label.Text = "Victory • Boss defeated"
	elseif state:GetAttribute("BossWave") and remaining == 0 and status == "Running" then
		label.Text = "Wave " .. wave .. " • Defeat the boss"
	elseif status == "Completed" then
		label.Text = "Run complete • Wave " .. wave
	elseif status == "Stopped" then
		label.Text = "Run stopped • Wave " .. wave
	else
		label.Text = string.format("Wave %d • %s%s", wave, time, suffix)
	end
end

-- Display replicated server values only: no local countdown or control remote.
state.AttributeChanged:Connect(render)
render()
