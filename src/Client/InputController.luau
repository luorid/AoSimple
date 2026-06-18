local InputController = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local client = replicatedStorage.src.Client
local inputService = require(client.Services.InputService)
local sprintService = require(client.Services.SprintService)
local highJumpService = require(client.Services.HighJumpService)
local dashService = require(client.Services.DashService)

local sprintAction = inputService.GetAction("idle", "ToggleSprint")
sprintAction.KeyboardBinding.KeyCode = Enum.KeyCode.LeftControl

local highJumpAction = inputService.GetAction("idle", "HighJump")
highJumpAction.KeyboardBinding.KeyCode = Enum.KeyCode.T

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

sprintAction.Pressed:Connect(function()
	sprintService.Toggle()
end)

highJumpAction.Pressed:Connect(function()
	highJumpService.StartCharge()
end)

highJumpAction.Released:Connect(function()
	highJumpService.Release()
end)



return InputController
