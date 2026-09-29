return {
	-- Continue with the final definition as waves 5, 6, etc. Set false to end
	-- spawning after the last configured wave; surviving enemies are preserved.
	RepeatLastWave = true,
	Waves = {
		{ Duration = 60, EnemyType = "BasicEnemy", SpawnInterval = 5, MaxAlive = 4, HealthMultiplier = 1, SpeedMultiplier = 1, DamageMultiplier = 1, XPMultiplier = 1 },
		{ Duration = 60, EnemyType = "BasicEnemy", SpawnInterval = 4, MaxAlive = 8, HealthMultiplier = 1.15, SpeedMultiplier = 1.05, DamageMultiplier = 1.1, XPMultiplier = 1 },
		{ Duration = 60, EnemyType = "BasicEnemy", SpawnInterval = 3, MaxAlive = 12, HealthMultiplier = 1.35, SpeedMultiplier = 1.1, DamageMultiplier = 1.2, XPMultiplier = 1 },
		{ Duration = 60, EnemyType = "BasicEnemy", SpawnInterval = 2, MaxAlive = 18, HealthMultiplier = 1.6, SpeedMultiplier = 1.15, DamageMultiplier = 1.3, XPMultiplier = 1 },
	},
}
