local quickNet = require(game.ReplicatedStorage.src.Shared.QuickNet)

local SoundReplication = {}

function SoundReplication.handleSoundEvent(eventName, soundAsset)
	local event = quickNet:register(eventName, quickNet.Data.Player)
	event.OnClientEvent:Connect(function(soundPlayer)
		local hrp = soundPlayer.Character and soundPlayer.Character:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		local sound = soundAsset:Clone()
		sound.Parent = hrp
		sound:Play()
		sound.Ended:Once(function() sound:Destroy() end)
	end)

	local function fireAndPlay(localPlayer)
		local hrp = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local sound = soundAsset:Clone()
			sound.Parent = hrp
			sound:Play()
			sound.Ended:Once(function() sound:Destroy() end)
		end
		event:FireServer(localPlayer)
	end

	return fireAndPlay
end

return SoundReplication