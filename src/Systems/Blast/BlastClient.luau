local BlastClient = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local clientServices = replicatedStorage.src.Client.Services
local inputService = require(clientServices.InputService)
local playerService = require(clientServices.PlayerService)
local states = require(replicatedStorage.src.Shared.States)
local animPlayer = require(replicatedStorage.src.Client.AnimPlayer)
local dataService = require(replicatedStorage.src.Shared.Services.DataService).client

local magicCircles = script.MagicCircles

local player = playerService.Player()

local END_LAG_TIME = 0.3
local COOLDOWN = 0.5

local cooldownDebounce = false
local charging = false
local blastAnim: AnimationTrack = nil
local magicCircle: BasePart = nil

function BlastClient.OnPress()
	local character = playerService.Character()
	local humanoid = playerService.Humanoid()
	local hrp = playerService.HRP()
	if not character or not humanoid or not hrp or cooldownDebounce then return end
	cooldownDebounce = true
	charging = true
	states.SetState(player, "isBlastCharging", true)
	hrp.Anchored = true
	
	local magic = dataService:get("magic")
	local magicCircleTemplate = magicCircles:FindFirstChild(magic)
	if not magicCircleTemplate then return end
	
	-- destroy any leftover circle from a previous interrupted press
	if magicCircle then
		magicCircle:Destroy()
		magicCircle = nil
	end
	local thisCircle = magicCircleTemplate:Clone()  -- local ref tied to this press
	thisCircle.Parent = character
	thisCircle:PivotTo(hrp.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(math.rad(90), 0, 0))
	thisCircle.Center.Shine:Emit(1)
	magicCircle = thisCircle  -- also write to shared so OnRelease can clean it up

	blastAnim = animPlayer.play(script.BlastAnimation)
	
	
	local CHARGE_SCALE_MAX = 4    -- max scale multiplier
	local CHARGE_TIME_MAX  = 0.2    -- seconds to reach max scale
	local chargeStart = os.clock()
	local t = 0

	while charging or t < 1 do
		if not thisCircle or not thisCircle.Parent then break end

		local elapsed = os.clock() - chargeStart
		t = math.min(elapsed / CHARGE_TIME_MAX, 1)
		local scale = 1 + (CHARGE_SCALE_MAX - 1) * t

		local mouseDirection = (player:GetMouse().Hit.Position - hrp.Position).Unit
		local lookAt = CFrame.lookAt(hrp.Position, hrp.Position + mouseDirection)
		hrp.CFrame = lookAt
		thisCircle:PivotTo(hrp.CFrame * CFrame.new(0, 0, -5) * CFrame.Angles(math.rad(90), 0, 0))
		thisCircle.Size = magicCircleTemplate.Size * scale
		task.wait()
	end
	
end

function BlastClient.OnRelease()
	if not charging then return end
	charging = false
	states.SetState(player, "isBlastCharging", false)
	local character = playerService.Character()
	local humanoid = playerService.Humanoid()
	local hrp = playerService.HRP()
	if not character or not humanoid or not hrp then return end

	task.wait(END_LAG_TIME)

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.Anchored = false
	
	task.delay(0.35, function()
		if magicCircle then
			magicCircle:Destroy()
			magicCircle = nil
		end
	end)
	
	
	if blastAnim then
		blastAnim:Stop()
		blastAnim = nil
	end
	
	task.wait(COOLDOWN)
	cooldownDebounce = false
	
end

function BlastClient.Init()
	animPlayer.load(script.BlastAnimation)
end


function BlastClient.Start()

end

return BlastClient