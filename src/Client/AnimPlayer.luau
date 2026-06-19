local AnimationPlayer = {}

local Players = game:GetService("Players")

function AnimationPlayer.play(animationSource, looped: boolean?, priority: Enum.AnimationPriority?): AnimationTrack
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not humanoid or not animator then
		return
	end
	
	local animation
	if typeof(animationSource) == "Instance" and animationSource:IsA("Animation") then
		animation = animationSource
	elseif type(animationSource) == "string" or type(animationSource) == "number" then
		animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://" .. tostring(animationSource)
	else
		error("AnimationHelper.play: pass an Animation instance or an animation ID")
	end

	local track = animator:LoadAnimation(animation)
	if looped ~= nil then
		track.Looped = looped
	end
	if priority then
		track.Priority = priority
	end
	track:Play()
	return track
end

return AnimationPlayer