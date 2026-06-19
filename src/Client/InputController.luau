local InputController = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local client = replicatedStorage.src.Client
local inputService = require(client.Services.InputService)
local sprintService = require(client.Services.SprintService)
local highJumpService = require(client.Services.HighJumpService)
local dashService = require(client.Services.DashService)

local blastClient = require(replicatedStorage.src.Systems.Blast.BlastClient)
local toolStateController = require(replicatedStorage.src.Systems.ToolSystem.ToolStateController)

local sprintAction = inputService.GetAction("idle", "ToggleSprint")
sprintAction.KeyboardBinding.KeyCode = Enum.KeyCode.LeftControl

local highJumpAction = inputService.GetAction("idle", "HighJump")
highJumpAction.KeyboardBinding.KeyCode = Enum.KeyCode.T

local blastAction = inputService.GetAction("idle", "Blast")
blastAction.KeyboardBinding.KeyCode = Enum.KeyCode.Q

local keyMap = {
	DashW = Enum.KeyCode.W,
	DashS = Enum.KeyCode.S,
	DashA = Enum.KeyCode.A,
	DashD = Enum.KeyCode.D,
}

for actionName, keyCode in keyMap do
	local action = inputService.GetAction("idle", actionName)
	action.KeyboardBinding.KeyCode = keyCode
	action.Pressed:Connect(function()
		dashService.OnDashInput(keyCode)
	end)
end

sprintAction.Pressed:Connect(sprintService.Toggle)

highJumpAction.Pressed:Connect(highJumpService.StartCharge)
highJumpAction.Released:Connect(highJumpService.Release)

blastAction.Pressed:Connect(function()
	highJumpService.Cancel()
	highJumpAction.Enabled = false
	blastClient.OnPress()
end)

blastAction.Released:Connect(function()
	highJumpAction.Enabled = true
	blastClient.OnRelease()
end)

toolStateController.OnChanged = function(active)
	blastAction.Enabled = active
end

blastAction.Enabled = toolStateController.IsToolActive

return InputController
