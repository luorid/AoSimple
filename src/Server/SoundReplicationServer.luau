local SoundReplicationServer = {}
local quickNet = require(game.ReplicatedStorage.src.Shared.QuickNet)
local Players = game:GetService("Players")

function SoundReplicationServer.Init()
	
	local events = {
		quickNet:register("HighJumpSoundEvent", quickNet.Data.Player),
		quickNet:register("DashSoundEvent",     quickNet.Data.Player),
		quickNet:register("RollSoundEvent",     quickNet.Data.Player),
	}

	for _, event in events do
		event.OnServerEvent:Connect(function(soundPlr)
			for _, player in Players:GetPlayers() do
				if player ~= soundPlr then
					event:FireClient(player, soundPlr)
				end
			end
		end)
	end
	
end

return SoundReplicationServer