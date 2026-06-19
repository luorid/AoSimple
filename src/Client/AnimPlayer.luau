local AnimationPlayer = {}
local Players = game:GetService("Players")

local cache: {[string]: AnimationTrack} = {}

local function getAnimator(): Animator?
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

local function toAnimation(animationSource): Animation?
	if typeof(animationSource) == "Instance" and animationSource:IsA("Animation") then
		return animationSource
	elseif type(animationSource) == "string" or type(animationSource) == "number" then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. tostring(animationSource)
		return anim
	end
	error("AnimationPlayer: pass an Animation instance or an animation ID")
end

function AnimationPlayer.load(animationSource): AnimationTrack?
	local animator = getAnimator()
	if not animator then return end

	local animation = toAnimation(animationSource)
	local key = animation.AnimationId

	if cache[key] then
		return cache[key]
	end

	local track = animator:LoadAnimation(animation)
	cache[key] = track
	return track
end

function AnimationPlayer.play(animationSource, looped: boolean?, priority: Enum.AnimationPriority?): AnimationTrack?
	local track = AnimationPlayer.load(animationSource)
	if not track then return end

	if looped ~= nil then track.Looped = looped end
	if priority then track.Priority = priority end
	track:Play()
	return track
end

Players.LocalPlayer.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")
	local animator = humanoid:WaitForChild("Animator")

	local newCache: {[string]: AnimationTrack} = {}
	for key, oldTrack in cache do
		local anim = Instance.new("Animation")
		anim.AnimationId = key
		newCache[key] = animator:LoadAnimation(anim)
	end
	cache = newCache
end)

return AnimationPlayer