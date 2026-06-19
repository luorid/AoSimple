local CombatClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientServices = ReplicatedStorage.src.Client.Services
local inputService = require(clientServices.InputService)
local player = require(clientServices.PlayerService)

local meleeAction = inputService.GetAction("idle", "Melee")

function CombatClient.Init()
	
	meleeAction.Pressed:Connect(function()
		print("Melee input action was pressed!")
	end)
	
	meleeAction.Released:Connect(function()
		--print("Melee input action was released!")
	end)
	meleeAction.StateChanged:Connect(function(state)
		--print("The melee input action was changed to state " .. tostring(state))
	end)
end


function CombatClient.Start()
	meleeAction.KeyboardBinding.KeyCode = Enum.KeyCode.MouseLeftButton
	local combatGui = player.PlayerGui():FindFirstChild("CombatGui")
	if combatGui then
		meleeAction.UIBinding.UIButton = combatGui.TextButton
	end
end

return CombatClient