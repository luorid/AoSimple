local HighJump = {}

local player = require(game.ReplicatedStorage.src.Client.Services.PlayerService)

local FORCE = 100
local MAX_CHARGE_TIME = 2

local charging = false
local debounce = false
local forceFactor = 1

local sessionId = 0

local animTrack: AnimationTrack? = nil
local highJumpAnim: Animation = script:WaitForChild("HighJumpAnimation")

local function loadAnimation()
	local hum = player.Humanoid()
	if not hum then return end
	animTrack = hum:LoadAnimation(highJumpAnim)
	animTrack.Priority = Enum.AnimationPriority.Action2
end

local function executeJump(char, forceFactor)
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(0, math.huge, 0)
	velocity.Velocity = Vector3.new(0, FORCE * forceFactor, 0)
	velocity.P = 20000
	velocity.Parent = root

	task.delay(0.1, function()
		velocity:Destroy()
	end)
end

function HighJump.StartCharge()
	if debounce or charging then return end

	local char = player.Character()
	local hum = player.Humanoid()
	if not char or not hum then return end
	if hum.FloorMaterial == Enum.Material.Air then return end

	debounce = true
	charging = true
	forceFactor = 1
	local startTime = os.clock()

	sessionId += 1
	local mySession = sessionId

	loadAnimation()

	local lastSpeed = hum.WalkSpeed
	hum.WalkSpeed = 5

	if animTrack then
		animTrack:Play()

		task.spawn(function()
			-- wait for charge marker without blocking main thread
			animTrack:GetMarkerReachedSignal("Charge"):Wait()

			-- ignore if spam restarted
			if sessionId ~= mySession then return end
			if not charging then return end

			animTrack:AdjustSpeed(0)
		end)
	end

	task.spawn(function()
		while charging and sessionId == mySession do
			if os.clock() - startTime >= MAX_CHARGE_TIME then
				HighJump.Release()
				return
			end

			forceFactor = math.min(forceFactor + 0.03, 1.25)
			task.wait(0.1)
		end
	end)

	HighJump._state = {
		char = char,
		hum = hum,
		lastSpeed = lastSpeed,
		session = mySession,
		startTime = startTime
	}
end

function HighJump.Release()
	if not charging then return end

	charging = false

	local state = HighJump._state
	if not state then return end

	local char = state.char
	local hum = state.hum

	sessionId += 1 -- invalidate old threads

	if animTrack then
		animTrack:AdjustSpeed(1)

		task.spawn(function()
			animTrack:GetMarkerReachedSignal("Jump"):Wait()
		end)
	end
	
	task.wait(0.1)

	hum.WalkSpeed = state.lastSpeed
	
	local jumpSound = script.JumpSound:Clone()
	jumpSound.Parent = player.HRP()
	jumpSound:Play()
	jumpSound.Ended:Connect(function()
		jumpSound:Destroy()
	end)

	executeJump(char, forceFactor)

	task.delay(0.5, function()
		debounce = false
	end)

	HighJump._state = nil
end

loadAnimation()

return HighJump