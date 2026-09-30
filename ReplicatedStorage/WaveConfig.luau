return {
	-- The final wave is a victory boss encounter, so it must not repeat.
	RepeatLastWave = false,
	Waves = {
		{
			Duration = 4, SpawnInterval = 5, MaxAlive = 4,
			HealthMultiplier = 1, SpeedMultiplier = 1, DamageMultiplier = 1, XPMultiplier = 1,
			EnemyPool = { { Type = "BasicEnemy", Weight = 1 } },
		},
		{
			Duration = 4, SpawnInterval = 4, MaxAlive = 8,
			HealthMultiplier = 1.15, SpeedMultiplier = 1.05, DamageMultiplier = 1.1, XPMultiplier = 1,
			EnemyPool = { { Type = "BasicEnemy", Weight = 70 }, { Type = "FastEnemy", Weight = 30 } },
		},
		{
			Duration = 4, SpawnInterval = 3, MaxAlive = 12,
			HealthMultiplier = 1.35, SpeedMultiplier = 1.1, DamageMultiplier = 1.2, XPMultiplier = 1,
			EnemyPool = {
				{ Type = "BasicEnemy", Weight = 50 },
				{ Type = "FastEnemy", Weight = 30 },
				{ Type = "TankEnemy", Weight = 20 },
			},
		},
		-- Duration is the displayed countdown; this wave waits for the boss kill.
		-- MaxAlive includes the boss and surviving enemies from previous waves.
		{
			Duration = 60, Boss = "TungBoss", SpawnInterval = 8, MaxAlive = 3,
			HealthMultiplier = 1, SpeedMultiplier = 1, DamageMultiplier = 1, XPMultiplier = 1,
			EnemyPool = { { Type = "BasicEnemy", Weight = 1 } },
		},
	},
}
