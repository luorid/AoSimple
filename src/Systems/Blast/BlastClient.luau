local BlastClient = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local clientServices = ReplicatedStorage.src.Client.Services
local inputService = require(clientServices.InputService)
local player = require(clientServices.PlayerService)

function BlastClient.OnPress()
	print("blast pressed")
	
end

function BlastClient.OnRelease()
	print("blast released")
	
end

function BlastClient.Init()
	
end


function BlastClient.Start()

end

return BlastClient