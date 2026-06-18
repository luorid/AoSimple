--// Server
local ReplicationServer = {}

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicateEvent = ReplicatedStorage.src.Systems.Replication:WaitForChild("UnreliableReplication")
local FireClient     = ReplicateEvent.FireClient

local PREC 			= 10
local INV_PREC		= 1 / PREC
local MAX_DELTA_SQ	= 10 * 10
local YAW_MAX		= math.ceil(math.pi * 10)
local playerList	= table.create(16)
local playerCount	= 0
local hrpCache		= {}

local function onPlayerAdded(p)
	playerCount += 1
	playerList[playerCount] = p
	p.CharacterAdded:Connect(function(char)
		hrpCache[p] = char:WaitForChild("HumanoidRootPart")
	end)
	p.CharacterRemoving:Connect(function()
		hrpCache[p] = nil
	end)
end

local function onPlayerRemoving(p)
	hrpCache[p] = nil
	for i = 1, playerCount do
		if playerList[i] == p then
			playerList[i] = playerList[playerCount]
			playerList[playerCount] = nil
			playerCount -= 1
			break
		end
	end
end

for _, p in Players:GetPlayers() do
	onPlayerAdded(p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

ReplicateEvent.OnServerEvent:Connect(function(sender, x, y, z, yaw)
	if yaw < -YAW_MAX or yaw > YAW_MAX then return end
	local hrp = hrpCache[sender]
	if not hrp then return end
	local rp = hrp.Position
	local dx = x * INV_PREC - rp.X
	local dy = y * INV_PREC - rp.Y
	local dz = z * INV_PREC - rp.Z
	if (dx*dx + dy*dy + dz*dz) > MAX_DELTA_SQ then return end

	local sx = x * INV_PREC
	local sy = y * INV_PREC
	local sz = z * INV_PREC

	for i = 1, playerCount do
		local other = playerList[i]
		if other == sender then continue end
		local otherHrp = hrpCache[other]
		if not otherHrp then continue end
		local op = otherHrp.Position
		local ex = sx - op.X
		local ey = sy - op.Y
		local ez = sz - op.Z
		if (ex*ex + ey*ey + ez*ez) > 100*100 then continue end
		FireClient(ReplicateEvent, other, sender, x, y, z, yaw)
	end
end)

return ReplicationServer