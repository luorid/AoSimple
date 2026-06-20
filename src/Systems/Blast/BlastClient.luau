local BlastClient = {}

-- Services
local replicatedStorage = game:GetService("ReplicatedStorage")
local clientServices = replicatedStorage.src.Client.Services

-- Modules
local playerService = require(clientServices.PlayerService)
local animPlayer    = require(replicatedStorage.src.Client.AnimPlayer)
local states        = require(replicatedStorage.src.Shared.States)
local dataService   = require(replicatedStorage.src.Shared.Services.DataService).client

-- Constants
local CHARGE_SCALE_MAX = 4
local CHARGE_TIME_MAX  = 0.2
local END_LAG_TIME     = 0.3
local COOLDOWN         = 0.5
local CIRCLE_OFFSET    = CFrame.new(0, 0, -5) * CFrame.Angles(math.rad(90), math.rad(-90), 0)

-- Assets
local magicCircles = script.MagicCircles

-- State
local player          = playerService.Player()
local cooldownDebounce = false
local charging         = false
local blastAnim: AnimationTrack = nil
local magicCircle: BasePart     = nil

-- Helpers

local function getCircleCFrame(hrpCFrame: CFrame): CFrame
	return hrpCFrame * CIRCLE_OFFSET
end

local function destroyCircle()
	if magicCircle then
		magicCircle:Destroy()
		magicCircle = nil
	end
end

local function getMouseDirection(hrp: BasePart): Vector3
	return (player:GetMouse().Hit.Position - hrp.Position).Unit
end

-- Module

function BlastClient.OnPress()
	local character = playerService.Character()
	local humanoid  = playerService.Humanoid()
	local hrp       = playerService.HRP()

	if not character or not humanoid or humanoid.Health <= 0 or not hrp or cooldownDebounce then return end

	cooldownDebounce = true
	charging = true
	states.SetState(player, "isBlastCharging", true)
	hrp.Anchored = true

	local magic = dataService:get("magic")
	local magicCircleTemplate = magicCircles:FindFirstChild(magic)
	if not magicCircleTemplate then return end

	destroyCircle()

	local thisCircle = magicCircleTemplate:Clone()
	thisCircle.Parent = character
	thisCircle:PivotTo(getCircleCFrame(hrp.CFrame))
	thisCircle.Center.Shine:Emit(1)
	magicCircle = thisCircle

	blastAnim = animPlayer.play(script.BlastAnimation)

	local chargeStart = os.clock()
	local t = 0

	while charging or t < 1 do
		if not thisCircle.Parent then break end

		local elapsed = os.clock() - chargeStart
		t = math.min(elapsed / CHARGE_TIME_MAX, 1)
		local scale = 1 + (CHARGE_SCALE_MAX - 1) * t

		local lookAt = CFrame.lookAt(hrp.Position, hrp.Position + getMouseDirection(hrp))
		hrp.CFrame = lookAt
		thisCircle:PivotTo(getCircleCFrame(hrp.CFrame))
		thisCircle.Size = magicCircleTemplate.Size * scale

		task.wait()
	end
end

function BlastClient.OnRelease()
	if not charging then return end

	charging = false
	states.SetState(player, "isBlastCharging", false)

	local character = playerService.Character()
	local humanoid  = playerService.Humanoid()
	local hrp       = playerService.HRP()
	if not character or not humanoid or not hrp then return end

	task.wait(END_LAG_TIME)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	hrp.Anchored = false

	task.delay(0.35, destroyCircle)

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