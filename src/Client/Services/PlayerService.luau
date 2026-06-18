local Players = game:GetService("Players")

local PlayerService = {}
local player = Players.LocalPlayer

local character, humanoid, hrp

local plrGui = player:WaitForChild("PlayerGui")
local plrScripts = player:WaitForChild("PlayerScripts")

local charEvent = Instance.new("BindableEvent")

local function setCharacter(char)
	character = char
	humanoid = char:WaitForChild("Humanoid")
	hrp = char:WaitForChild("HumanoidRootPart")
	charEvent:Fire(char)
end

if player.Character then setCharacter(player.Character) end
player.CharacterAdded:Connect(setCharacter)

function PlayerService.Player() return player end
function PlayerService.Character() return character end
function PlayerService.Humanoid() return humanoid end
function PlayerService.HRP() return hrp end
function PlayerService.PlayerGui() return plrGui end
function PlayerService.PlayerScripts() return plrScripts end

function PlayerService.Health() return humanoid and humanoid.Health or 0 end
function PlayerService.WalkSpeed() return humanoid and humanoid.WalkSpeed or 0 end
function PlayerService.Position() return hrp and hrp.Position or Vector3.zero end
function PlayerService.CFrame() return hrp and hrp.CFrame or CFrame.new() end

function PlayerService.CharacterAdded() return charEvent.Event end

return PlayerService