local ToolLoadoutServer = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")
local dataService = require(replicatedStorage.src.Shared.Services.DataService).server
	
function ToolLoadoutServer:Init()
	players.PlayerAdded:Connect(function(plr)
		dataService:waitForData(plr)
		local magic = dataService:get(plr, "magic")
		local tool = Instance.new("Tool")
		tool.Name = magic
		tool.Parent = plr.Backpack
		
	end)
	
end

function ToolLoadoutServer:Start()
	
end

return ToolLoadoutServer