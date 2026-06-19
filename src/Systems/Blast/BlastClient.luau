local BlastClient = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local clientServices = replicatedStorage.src.Client.Services
local inputService = require(clientServices.InputService)
local playerService = require(clientServices.PlayerService)
local states = require(replicatedStorage.src.Shared.States)
local animPlayer = require(replicatedStorage.src.Client.AnimPlayer)

local player = playerService.Player()

local END_LAG_TIME = 0.2

local debounce = false
local charging = false
local blastAnim: AnimationTrack = nil

function BlastClient.OnPress()
	local character = playerService.Character()
	local humanoid = playerService.Humanoid()
	local hrp = playerService.HRP()
	if not character or not humanoid or not hrp or debounce then return end
	debounce = true
	charging = true
	states.SetState(player, "isBlastCharging", true)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.Anchored = true
	
	blastAnim = animPlayer.play(script.BlastAnimation)
	
	while charging do
		-- face the mouse direction
		local mouseDirection = (player:GetMouse().Hit.Position - hrp.Position).Unit
		local lookAt = CFrame.lookAt(hrp.Position, hrp.Position + mouseDirection)
		hrp.CFrame = lookAt
		task.wait()		
	end
	
end

function BlastClient.OnRelease()
	charging = false
	states.SetState(player, "isBlastCharging", false)
	local character = playerService.Character()
	local humanoid = playerService.Humanoid()
	local hrp = playerService.HRP()
	if not character or not humanoid or not hrp then return end
	
	task.wait(END_LAG_TIME)

	hrp.Anchored = false
	debounce = false
	
	if blastAnim then
		blastAnim:Stop()
		blastAnim = nil
	end
	
end

function BlastClient.Init()
	
end


function BlastClient.Start()

end

return BlastClient