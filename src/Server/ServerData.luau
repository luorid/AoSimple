local ServerData = {}

local replicatedStorage = game:GetService("ReplicatedStorage")

function ServerData.Init()
	local dataService = require(replicatedStorage.src.Shared.Services.DataService).server
	local dataTemplate = require(replicatedStorage.src.Server.DataTemplate)
	
	function dataService:onPlayerInit(player, data)
		data.timesJoined += 1
		data.sessionStart = os.time()
		print("Player data loaded:", data)
	end
	
	dataService:addPlayerRemovingCallback(function(player, data)
		local playTime = os.time() - data.sessionStart
		data.timePlayed += playTime
	end)

	dataService:init({
		template = dataTemplate,
		useMock = false,
		resetData = false,
		--viewedUserId = [USERID HERE]
		--overridenUserId = [USERID HERE]
	})
end


return ServerData