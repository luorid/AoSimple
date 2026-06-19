local ToolStateController = {}

local Players = game:GetService("Players")

ToolStateController.IsToolActive = false
ToolStateController.OnChanged = nil

local player = Players.LocalPlayer

local function computeState()
	local character = player.Character
	if not character then
		return false
	end

	return character:FindFirstChildWhichIsA("Tool") ~= nil
end

local function update()
	local newState = computeState()

	if ToolStateController.IsToolActive ~= newState then
		ToolStateController.IsToolActive = newState

		if ToolStateController.OnChanged then
			ToolStateController.OnChanged(newState)
		end
	end
end

local function hookCharacter(character)
	update()

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			update()
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			update()
		end
	end)
end

function ToolStateController:Init()
	player.CharacterAdded:Connect(hookCharacter)

	if player.Character then
		hookCharacter(player.Character)
	end
end

return ToolStateController