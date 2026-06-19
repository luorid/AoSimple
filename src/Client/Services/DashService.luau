local DashService = {}

local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = require(replicatedStorage.src.Client.Services.PlayerService)
local states = require(replicatedStorage.src.Shared.States)
local animPlayer = require(replicatedStorage.src.Client.AnimPlayer)
local soundReplication = require(game.ReplicatedStorage.src.Client.SoundReplication)
local playDashSound = soundReplication.handleSoundEvent("DashSoundEvent", script.DashSound)
local playRollSound = soundReplication.handleSoundEvent("RollSoundEvent", script.RollSound)

-- Constants
local DASH_COOLDOWN = 0.5
local DASH_POWER = 120
local DASH_DURATION = 0.25
local DASH_UPWARD_BOOST = 0.2
local DASH_VFX_LIFETIME = 0.6
local DOUBLE_PRESS_INTERVAL = 0.3

-- State
local onCooldown = false
local isDashing = false
local lastKeyPressTime = {}
local animations = nil
local hasAirDashed = false

local function loadAnimations()
	animations = {
		FrontDash = animPlayer.load(script.FrontDash),
		BackDash  = animPlayer.load(script.BackDash),
		LeftDash  = animPlayer.load(script.LeftDash),
		RightDash = animPlayer.load(script.RightDash),
		FrontRoll = animPlayer.load(script.FrontRoll),
		BackRoll  = animPlayer.load(script.BackRoll),
		LeftRoll  = animPlayer.load(script.LeftRoll),
		RightRoll = animPlayer.load(script.RightRoll)
	}
end

local function getAnimation(dashDirection, useRoll)
	if not animations then return nil end
	local camCF = workspace.CurrentCamera.CFrame
	local forward = dashDirection:Dot(camCF.LookVector)
	local right = dashDirection:Dot(camCF.RightVector)

	if useRoll then
		if forward > 0.5 then return animations.FrontRoll
		elseif forward < -0.5 then return animations.BackRoll
		elseif right > 0.5 then return animations.RightRoll
		elseif right < -0.5 then return animations.LeftRoll
		end
		return animations.BackRoll
	end

	if forward > 0.5 then return animations.FrontDash
	elseif forward < -0.5 then return animations.BackDash
	elseif right > 0.5 then return animations.RightDash
	elseif right < -0.5 then return animations.LeftDash
	end
	return animations.BackDash
end

local function isGrounded()
	return player.Humanoid().FloorMaterial ~= Enum.Material.Air
end

local function calculateDashDirection(keyCode)
	local camCF = workspace.CurrentCamera.CFrame
	local flatLook  = Vector3.new(camCF.LookVector.X,  0, camCF.LookVector.Z).Unit
	local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit

	if keyCode == Enum.KeyCode.W then return flatLook
	elseif keyCode == Enum.KeyCode.S then return -flatLook
	elseif keyCode == Enum.KeyCode.A then return -flatRight
	elseif keyCode == Enum.KeyCode.D then return flatRight
	end
	return flatLook
end

local function performDash(keyCode)
	local dashDirection = calculateDashDirection(keyCode)
	local wasAirborne = not isGrounded()

	if isGrounded() and dashDirection.Y < 0 then
		dashDirection = Vector3.new(dashDirection.X, 0, dashDirection.Z).Unit
	end

	local finalDirection = Vector3.new(
		dashDirection.X,
		dashDirection.Y + DASH_UPWARD_BOOST,
		dashDirection.Z
	).Unit

	local anim = getAnimation(dashDirection)
	if anim then anim:Play() end

	local rollAnim = getAnimation(dashDirection, true)

	local camLook = workspace.CurrentCamera.CFrame.LookVector
	local faceDirection = Vector3.new(camLook.X, 0, camLook.Z).Unit

	isDashing = true
	states.SetState(player.Player(), "IsDashing", true)
	task.spawn(function()
		local startTime = time()

		while time() - startTime < DASH_DURATION do
			local hrp = player.HRP()
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + faceDirection)
			hrp.AssemblyLinearVelocity = finalDirection * DASH_POWER
			task.wait()
		end

		while time() - startTime < 0.75 do
			local hrp = player.HRP()
			hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + faceDirection)
			task.wait()
		end

		isDashing = false
		states.SetState(player.Player(), "IsDashing", false)
	end)

	if wasAirborne and player.Player():GetAttribute("IsRunning") then
		local conn
		conn = player.Humanoid().StateChanged:Connect(function(_, newState)
			if newState == Enum.HumanoidStateType.Landed then
				conn:Disconnect()
				if rollAnim and player.Humanoid().MoveDirection.Magnitude > 0 then
					rollAnim:Play()
					playRollSound(player.Player())
				end
			end
		end)
	end

	onCooldown = true
	task.delay(DASH_COOLDOWN, function()
		onCooldown = false
	end)
end

function DashService.OnDashInput(keyCode)
	if onCooldown or isDashing then return end
	if not player.HRP() or player.HRP().Anchored or not player.Humanoid() then return end
	if not isGrounded() and hasAirDashed then return end

	local now = tick()
	local last = lastKeyPressTime[keyCode]

	if last and (now - last) <= DOUBLE_PRESS_INTERVAL then
		lastKeyPressTime[keyCode] = nil
		if not isGrounded() then hasAirDashed = true end
		performDash(keyCode)
		playDashSound(player.Player())
	else
		lastKeyPressTime[keyCode] = now
	end
end

local function connectLandingReset()
	player.Humanoid().StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed
			or newState == Enum.HumanoidStateType.Running then
			hasAirDashed = false
		end
	end)
end

function DashService.Init()
	if player.Character() then
		loadAnimations()
		connectLandingReset()
	end

	player.CharacterAdded():Connect(function()
		onCooldown = false
		isDashing = false
		hasAirDashed = false
		lastKeyPressTime = {}
		loadAnimations()
		connectLandingReset()
	end)
end

return DashService