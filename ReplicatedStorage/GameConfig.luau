return {
	EnemySpawning = {
		InitialCount = 2,
		MinSpawnDistance = 24,
		MaxSpawnDistance = 36,
		MinEnemySpacing = 6,
		PlacementAttempts = 12,
		-- Wave timing and enemy scaling live in ReplicatedStorage.WaveConfig.
	},
	Leveling = {
		BaseRequirement = 25, -- XP needed to go from level 1 to level 2.
		RequirementIncrease = 25, -- Each following level needs this much more XP.
	},
	XP = {
		DefaultDropValue = 25,
		PickupRadius = 10, -- Studs from a living player's root to the pickup.
	},
	TungBat = {
		Damage = 25,
		Cooldown = 1, -- Seconds between successful attacks.
		Range = 7, -- Studs between player and enemy root positions.
	},
}
