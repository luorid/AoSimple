local InputController = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local client = replicatedStorage.src.Client
local inputService = require(client.Services.InputService)
local sprintService = require(client.Services.SprintService)
local highJump = require(client.HighJump)

local sprintAction = inputService.GetAction("idle", "ToggleSprint")
sprintAction.KeyboardBinding.KeyCode = Enum.KeyCode.LeftControl

local highJumpAction = inputService.GetAction("idle", "HighJump")
highJumpAction.KeyboardBinding.KeyCode = Enum.KeyCode.T

sprintAction.Pressed:Connect(function()
	sprintService.Toggle()
end)

highJumpAction.Pressed:Connect(function()
	highJump.StartCharge()
end)

highJumpAction.Released:Connect(function()
	highJump.Release()
end)

return InputController
