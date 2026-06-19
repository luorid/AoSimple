local ClientData = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local services = replicatedStorage.src.Shared.Services
local dataService = require(services.DataService).client

function ClientData.Init()
	dataService:init()
end

function ClientData.Start()
	--local data = dataService:get()
	--for key, value in data do
	--	print(key .. ":", value)
	--end
end



return ClientData