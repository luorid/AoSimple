local InputController = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local clientServices = replicatedStorage.src.Client.Services
local inputService = require(clientServices.InputService)
local sprintService = require(clientServices.SprintService)

local sprintAction = inputService.GetAction("idle", "ToggleSprint")
sprintAction.KeyboardBinding.KeyCode = Enum.KeyCode.LeftControl

sprintAction.Pressed:Connect(function()
	sprintService.Toggle()
end)

return InputController
