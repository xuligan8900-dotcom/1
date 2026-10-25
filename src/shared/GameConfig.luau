--!strict
return table.freeze({
	Title = "MEGA MECHANICAL TOWER",
	StageCount = 50,
	StageHeight = 20,
	BaseHeight = 8,
	Radius = 32,
	WalkSpeed = 16,
	JumpPower = 50,
	Gravity = 196.2,
	DataStoreName = "MechanicalTower_Progress_v1",
	SaveInterval = 30,
	SaveDebounce = 8,
	-- Studio defaults to session-only data. Enable deliberately on a separate test place.
	StudioPersistence = false,
	ZoneNames = {"STEELWORKS", "TURBINE GARDENS", "FOUNDRY", "REACTOR", "NEON CROWN"},
	ZoneColors = {
		Color3.fromRGB(70, 184, 255), Color3.fromRGB(40, 235, 180),
		Color3.fromRGB(255, 181, 45), Color3.fromRGB(218, 74, 211),
		Color3.fromRGB(110, 240, 255),
	},
})
