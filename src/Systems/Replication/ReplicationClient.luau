local ReplicationClient = {}

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer    = Players.LocalPlayer
local ReplicateEvent = ReplicatedStorage.src.Systems.Replication:WaitForChild("UnreliableReplication")

local CFNew = CFrame.new
local exp	= math.exp
local cos	= math.cos
local sin	= math.sin
local atan2	= math.atan2

local PREC			= 10
local YAW_PREC		= 10
local INV_PREC		= 1 / PREC
local INV_YAW_PREC	= 1 / YAW_PREC
local SMOOTH =		50 -- Higher = snappier, lower = more latency-hiding lag.
local lastX, lastY, lastZ, lastYaw = 0, 0, 0, 0
local root

local otherRoots = table.create(16)  -- player -> HRP
local targetCFs  = table.create(16)  -- player -> target CFrame
local lastReceived = table.create(16) -- player -> tick()
local STALE_THRESHOLD = 0.3 -- seconds before we stop overriding

local function characterAdded(char)
	root = char:WaitForChild("HumanoidRootPart")
end
if LocalPlayer.Character then
	characterAdded(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(characterAdded)

local function watchPlayer(p)
	p.CharacterAdded:Connect(function()
		otherRoots[p] = nil
		targetCFs[p]  = nil
		lastReceived[p] = nil
	end)
end
for _, p in Players:GetPlayers() do
	watchPlayer(p)
end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(p)
	otherRoots[p] = nil
	targetCFs[p]  = nil
	lastReceived[p] = nil
end)

ReplicateEvent.OnClientEvent:Connect(function(otherPlayer, x, y, z, yaw)
	local otherRoot = otherRoots[otherPlayer]
	if not otherRoot then
		local char = otherPlayer.Character
		if not char then return end
		otherRoot = char:FindFirstChild("HumanoidRootPart")
		if not otherRoot then return end
		otherRoots[otherPlayer] = otherRoot
	end

	local ry = yaw * INV_YAW_PREC
	local c, s = cos(ry), sin(ry)

	targetCFs[otherPlayer] = CFNew(
		x * INV_PREC, y * INV_PREC, z * INV_PREC,
		c, 0, s,
		0, 1, 0,
		-s, 0, c
	)
	lastReceived[otherPlayer] = tick() 
end)

RunService.Heartbeat:Connect(function(dt)
	-- Smooth remote players toward their latest received CFrame
	local alpha = 1 - exp(-SMOOTH * dt)
	for p, hrp in otherRoots do
		local target = targetCFs[p]
		if not target then continue end
		if not lastReceived[p] or (tick() - lastReceived[p]) > STALE_THRESHOLD then continue end
		if (hrp.CFrame.Position - target.Position).Magnitude > 20 then
			hrp.CFrame = target
		else
			hrp.CFrame = hrp.CFrame:Lerp(target, alpha)
		end
	end

	-- Send local player position to server
	local r = root
	if not r then return end
	local rootcf = r.CFrame
	local _, _, _, r00, _, r02 = rootcf:GetComponents()
	local yaw = atan2(r02, r00)

	local x = rootcf.X * PREC // 1
	local y = rootcf.Y * PREC // 1
	local z = rootcf.Z * PREC // 1
	local w = yaw  * YAW_PREC // 1

	if x == lastX and y == lastY and z == lastZ and w == lastYaw then return end
	lastX, lastY, lastZ, lastYaw = x, y, z, w
	
	ReplicateEvent:FireServer(x, y, z, w)
end)



return ReplicationClient