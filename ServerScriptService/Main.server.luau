local RunManager = require(script.Parent:WaitForChild("RunManager"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local XPService = require(script.Parent:WaitForChild("XPService"))
local ProgressionService = require(script.Parent:WaitForChild("ProgressionService"))

ProgressionService.Start()
XPService.Start()
CombatService.Start()

RunManager.Start()
