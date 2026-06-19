local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local SprintService = {}
local player = require(script.Parent.PlayerService)
local states = require(game.ReplicatedStorage.src.Shared.States)

local walkSpeed = 8
local runSpeed = 30

local isRunning = false
local isRunAnimPlaying = false

local runConnection
local runTrack = nil -- AnimationTrack

local function stopRunning()
	local humanoid = player.Humanoid()
	local character = player.Character()
	if not humanoid or not character then return end

	isRunning = false
	humanoid.WalkSpeed = walkSpeed
	states.SetState(player.Player(), "IsRunning", false)

	if runConnection then
		runConnection:Disconnect()
		runConnection = nil
	end

	-- ensure animation is fully reset
	isRunAnimPlaying = false
	if runTrack then
		runTrack:Stop()
	end
end

local function trackMovementState()
	if runConnection then return end

	runConnection = RunService.RenderStepped:Connect(function()
		if not isRunning then return end

		local humanoid = player.Humanoid()
		local hrp = player.HRP()
		if not humanoid or not hrp then return end

		local isMoving = humanoid.MoveDirection.Magnitude > 0.1
		local isInAir = humanoid:GetState() == Enum.HumanoidStateType.Freefall
		local isAnchored = hrp.Anchored

		local shouldPlay = isMoving and not isInAir and not isAnchored

		if shouldPlay then
			if not isRunAnimPlaying then
				isRunAnimPlaying = true
				if runTrack then
					runTrack:Play()
				end
			end
		else
			if isRunAnimPlaying then
				isRunAnimPlaying = false
				if runTrack then
					runTrack:Stop()
				end
			end
		end
	end)
end

local function startRunning()
	local humanoid = player.Humanoid()
	local character = player.Character()
	local hrp = player.HRP()

	if not humanoid or not character or not hrp then return end
	if hrp.Anchored then return end

	isRunning = true
	humanoid.WalkSpeed = runSpeed
	states.SetState(player.Player(), "IsRunning", true)

	trackMovementState()
end

local function loadRunAnimation()
	local humanoid = player.Humanoid()
	local character = player.Character()
	if not humanoid or not character then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
		or humanoid:WaitForChild("Animator", 2)

	if not animator then return end

	local animate = character:FindFirstChild("NewAnimate")
	local runAnim = animate
		and animate:FindFirstChild("run")
		and animate.run:FindFirstChild("RunAnim")

	if not (runAnim and runAnim:IsA("Animation")) then
		return
	end

	runTrack = animator:LoadAnimation(runAnim)
	runTrack.Priority = Enum.AnimationPriority.Movement
	runTrack.Looped = true
end


function SprintService.Stop()
	if not isRunning then return end
	stopRunning()
end

function SprintService.Toggle()
	if isRunning then
		stopRunning()
	else
		startRunning()
	end
end

function SprintService.Init()
	if player.Character() then
		loadRunAnimation()
		stopRunning()
	end

	player.CharacterAdded():Connect(function()
		stopRunning()
		loadRunAnimation()
	end)
end

return SprintService