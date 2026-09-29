local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local Definitions = require(script.Parent:WaitForChild("UpgradeDefinitions"))

local ProgressionService = {}
local states = {}
local started = false
local stateChanged = nil

assert(Config.Leveling.BaseRequirement > 0 and Config.Leveling.BaseRequirement < math.huge,
	"Leveling.BaseRequirement must be positive and finite")
assert(Config.Leveling.RequirementIncrease >= 0 and Config.Leveling.RequirementIncrease < math.huge,
	"Leveling.RequirementIncrease must be nonnegative and finite")

local function requirement(level: number): number
	return Config.Leveling.BaseRequirement + (level - 1) * Config.Leveling.RequirementIncrease
end

local function getState(player: Player)
	if not states[player] then
		states[player] = {
			level = 1,
			totalXP = 0,
			xp = 0,
			pending = 0,
			revision = 0,
			stats = table.clone(Config.TungBat),
			offer = nil,
		}
	end
	return states[player]
end

local function makeOffer(state)
	if state.pending == 0 or state.offer then
		return
	end
	local choices = {}
	local allowed = {}
	local offerId = HttpService:GenerateGUID(false)
	for _, definition in Definitions do
		-- An offer-specific upgrade ID makes old clicks harmless after a new offer.
		local id = definition.Id .. ":" .. offerId
		allowed[id] = definition
		table.insert(choices, { Id = id, Title = definition.Title, Description = definition.Description })
	end
	state.offer = { choices = choices, allowed = allowed }
end

local function snapshot(state)
	return {
		Revision = state.revision,
		Level = state.level,
		TotalXP = state.totalXP,
		XP = state.xp,
		XPRequired = requirement(state.level),
		PendingChoices = state.pending,
		Choices = state.offer and state.offer.choices or {},
	}
end

local function publish(player: Player, state)
	state.revision += 1
	-- Attributes are display mirrors, never inputs for progression or combat.
	player:SetAttribute("Level", state.level)
	player:SetAttribute("XP", state.totalXP) -- Preserve the existing cumulative XP attribute.
	player:SetAttribute("LevelXP", state.xp)
	player:SetAttribute("XPRequired", requirement(state.level))
	player:SetAttribute("PendingUpgrades", state.pending)
	player:SetAttribute("TungBatDamage", state.stats.Damage)
	player:SetAttribute("TungBatCooldown", state.stats.Cooldown)
	player:SetAttribute("TungBatRange", state.stats.Range)
	if stateChanged then
		stateChanged:FireClient(player, snapshot(state))
	end
end

function ProgressionService.SetTotalXP(player: Player, totalXP: number)
	local state = getState(player)
	assert(totalXP >= state.totalXP and totalXP < math.huge, "Shared XP must be finite and cannot decrease")
	state.xp += totalXP - state.totalXP
	state.totalXP = totalXP
	while state.xp >= requirement(state.level) do
		state.xp -= requirement(state.level)
		state.level += 1
		state.pending += 1
	end
	makeOffer(state)
	publish(player, state)
end

function ProgressionService.GetWeaponStats(player: Player)
	return table.clone(getState(player).stats)
end

function ProgressionService.Start()
	if started then
		return
	end
	started = true
	local remotes = Instance.new("Folder")
	remotes.Name = "ProgressionRemotes"
	stateChanged = Instance.new("RemoteEvent")
	stateChanged.Name = "StateChanged"
	stateChanged.Parent = remotes
	local getSnapshot = Instance.new("RemoteFunction")
	getSnapshot.Name = "GetState"
	getSnapshot.Parent = remotes
	local selectUpgrade = Instance.new("RemoteFunction")
	selectUpgrade.Name = "SelectUpgrade"
	selectUpgrade.Parent = remotes

	getSnapshot.OnServerInvoke = function(player)
		return snapshot(getState(player))
	end
	selectUpgrade.OnServerInvoke = function(player, upgradeId)
		local state = getState(player)
		local definition = nil
		if typeof(upgradeId) == "string" and #upgradeId <= 100
			and state.pending > 0 and state.offer then
			definition = state.offer.allowed[upgradeId]
		end
		if definition then
			-- No yields: consume the offer before applying its server-defined effect.
			state.offer = nil
			state.pending -= 1
			state.stats[definition.Stat] *= definition.Multiplier
			makeOffer(state)
			publish(player, state)
		end
		return snapshot(state)
	end
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	remotes.Parent = ReplicatedStorage
end

return ProgressionService
