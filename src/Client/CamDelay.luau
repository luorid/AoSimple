local camDelay = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local SMOOTH_TIME = 0.0725
local delayedCharacterPosition = nil
local velocity = Vector3.zero
local hrp = nil

local function onCharacterAdded(character)
	delayedCharacterPosition = nil
	velocity = Vector3.zero
	hrp = character:WaitForChild("HumanoidRootPart")
end

local function onCharacterRemoving()
	hrp = nil
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end

RunService.RenderStepped:Connect(function(deltaTime)
	if not hrp or SMOOTH_TIME <= 0 then return end

	local actualPosition = hrp.Position

	if not delayedCharacterPosition then
		delayedCharacterPosition = actualPosition
	end

	delayedCharacterPosition, velocity = TweenService:SmoothDamp(
		delayedCharacterPosition, actualPosition, velocity, SMOOTH_TIME, nil, deltaTime
	)

	local offsetFromCharacter = Camera.CFrame.Position - actualPosition
	local currentRotation = Camera.CFrame - Camera.CFrame.Position
	Camera.CFrame = currentRotation + (delayedCharacterPosition + offsetFromCharacter)
end)

return camDelay