-- Base stats. Wave multipliers are applied by the server when an enemy spawns.
return {
	BasicEnemy = {
		Name = "BasicEnemy", DisplayName = "Basic Enemy",
		Health = 100, WalkSpeed = 10, XPReward = 25, Scale = 1,
		Color = Color3.fromRGB(180, 75, 55),
	},
	FastEnemy = {
		Name = "FastEnemy", DisplayName = "Fast Enemy",
		Health = 50, WalkSpeed = 14, XPReward = 30, Scale = 0.8,
		Color = Color3.fromRGB(75, 210, 100),
	},
	TankEnemy = {
		Name = "TankEnemy", DisplayName = "Tank Enemy",
		Health = 250, WalkSpeed = 6, XPReward = 50, Scale = 1.4,
		Color = Color3.fromRGB(65, 105, 185),
	},
}
