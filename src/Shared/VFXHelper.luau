local VFXHelper = {}

--[[
	- TweenModel(config) – Animate a Model/BasePart over time with optional movement, scale, and rotation.
 @param config table A table of named options:
 
   • Model         (Model|BasePart) – **REQUIRED** The object to animate.
   • Duration      (number) – Optional tween length in seconds (default = 1).
   • Scale         (number) – Optional uniform scale factor (default = 1).
   • Rotation      (Vector3) – Optional cumulative rotation in degrees (e.g. `Vector3.new(0,180,0)`).
   • Offset        (Vector3) – Optional relative translation (applied gradually).
   • Position      (Vector3) – Optional end **world** position (mutually exclusive with `CFrame`).
   • CFrame        (CFrame) – Optional end transform (position+rotation; mutually exclusive with `Position`).
   • WaitTweenEnd  (boolean) – Optional; if true, yield until tween finishes (default = false).
   • EasingStyle   (Enum.EasingStyle) – Optional easing curve (default = Enum.EasingStyle.Sine).
   • EasingDirection (Enum.EasingDirection) – Optional easing direction (default = Enum.EasingDirection.Out).
   • …any other property (e.g. Transparency, Color, etc.) – Optional passthrough property tween.
   
 @return table Controller – A table with methods `Stop()` and `IsRunning()`.

--------------------------------------------------
USAGE EXAMPLES
--------------------------------------------------

-- 1. Simple move up
VFXHelper.TweenModel({
	Model = workspace.Part,
	Offset = {0, 10, 0},
	Duration = 1
})

-- 2. Move to position + rotate
VFXHelper.TweenModel({
	Model = workspace.Model,
	Position = {0, 20, 0},
	Rotation = {0, 180, 0},
	Duration = 2
})

-- 3. Full CFrame control
VFXHelper.TweenModel({
	Model = workspace.Model,
	CFrame = CFrame.new(0, 10, 0) * CFrame.Angles(0, math.rad(90), 0),
	Duration = 1.5
})

-- 4. Scale + fade out
VFXHelper.TweenModel({
	Model = workspace.Model,
	Scale = 2,
	Transparency = 1,
	Duration = 1
})

-- 5. Spin continuously while moving
VFXHelper.TweenModel({
	Model = workspace.Model,
	Offset = {0, 5, 0},
	Rotation = {0, 360, 0},
	Duration = 2
})

-- 6. Blocking call (wait until done)
VFXHelper.TweenModel({
	Model = workspace.Model,
	Offset = {0, 10, 0},
	WaitTweenEnd = true
})

--------------------------------------------------
NOTES
--------------------------------------------------

• Rotation is applied over time (not instant).
• Offset is relative movement, Position/CFrame are absolute.
• Scale happens from the model's pivot.
• Works on ALL BaseParts inside the model.
• Safe cleanup is handled automatically.
• Returns a controller with:
	.Stop()
	.IsRunning()

]]


local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local stepped = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat

local CF_IDENTITY = CFrame.identity
local CFNew = CFrame.new
local CFAngles = CFrame.Angles
local RAD = math.rad

type Vec3Like = Vector3 | {number}

type TweenModelConfig = {
	Model: Model | BasePart,
	Duration: number?,
	Scale: number?,
	Rotation: Vec3Like?,
	Offset: Vec3Like?,
	Position: Vec3Like?,
	CFrame: CFrame | Vec3Like?,
	WaitTweenEnd: boolean?,
	EasingStyle: Enum.EasingStyle?,
	EasingDirection: Enum.EasingDirection?,
	[string]: any,
}

local function assertVec3Table(val, name)
	assert(
		type(val) == "table"
			and type(val[1]) == "number"
			and type(val[2]) == "number"
			and type(val[3]) == "number",
		("[VFXHelper.TweenModel] '%s' must be {x, y, z} or {1, 2, 3} numeric table"):format(name)
	)
end

local function resolveVec3(val, name)
	if typeof(val) == "Vector3" then
		return val
	end
	if type(val) == "table" then
		assertVec3Table(val, name)
		return Vector3.new(val[1], val[2], val[3])
	end
	error(("[VFXHelper.TweenModel] '%s' must be a Vector3 or numeric table"):format(name))
end

function VFXHelper.TweenModel(config: TweenModelConfig)
	assert(type(config) == "table", "[VFXHelper.TweenModel] config must be a table")

	local model = config.Model
	assert(
		typeof(model) == "Instance" and (model:IsA("Model") or model:IsA("BasePart")),
		"[VFXHelper.TweenModel] 'Model' must be a Model or BasePart"
	)

	if config.CFrame ~= nil and config.Position ~= nil then
		error("[VFXHelper.TweenModel] Supply 'CFrame' or 'Position', not both")
	end

	local duration = config.Duration or 1
	assert(type(duration) == "number" and duration > 0,
		"[VFXHelper.TweenModel] 'Duration' must be a positive number")

	local waitEnd = config.WaitTweenEnd
	if waitEnd == nil then
		waitEnd = false
	end
	assert(type(waitEnd) == "boolean",
		"[VFXHelper.TweenModel] 'WaitTweenEnd' must be a boolean")

	local easeStyle = config.EasingStyle or Enum.EasingStyle.Sine
	assert(
		typeof(easeStyle) == "EnumItem" and easeStyle.EnumType == Enum.EasingStyle,
		"[VFXHelper.TweenModel] 'EasingStyle' must be an Enum.EasingStyle"
	)

	local easeDir = config.EasingDirection or Enum.EasingDirection.Out
	assert(
		typeof(easeDir) == "EnumItem" and easeDir.EnumType == Enum.EasingDirection,
		"[VFXHelper.TweenModel] 'EasingDirection' must be an Enum.EasingDirection"
	)

	local hasScale = config.Scale ~= nil
	local scaleTarget = config.Scale or 1
	if hasScale then
		assert(type(scaleTarget) == "number" and scaleTarget > 0,
			"[VFXHelper.TweenModel] 'Scale' must be a positive number")
	end

	local rot: Vector3? = nil
	if config.Rotation ~= nil then
		assert(typeof(config.Rotation) == "Vector3" or type(config.Rotation) == "table",
			"[VFXHelper.TweenModel] 'Rotation' must be a Vector3 or numeric table")
		rot = resolveVec3(config.Rotation, "Rotation")
	end

	local offset: Vector3? = nil
	if config.Offset ~= nil then
		assert(typeof(config.Offset) == "Vector3" or type(config.Offset) == "table",
			"[VFXHelper.TweenModel] 'Offset' must be a Vector3 or numeric table")
		offset = resolveVec3(config.Offset, "Offset")
	end

	local position: Vector3? = nil
	if config.Position ~= nil then
		assert(typeof(config.Position) == "Vector3" or type(config.Position) == "table",
			"[VFXHelper.TweenModel] 'Position' must be a Vector3 or numeric table")
		position = resolveVec3(config.Position, "Position")
	end

	local pivotOrigin = model:IsA("BasePart") and model.CFrame or model:GetPivot()

	local goalCFrame: CFrame? = nil
	if config.CFrame ~= nil then
		local rawCFrame = config.CFrame
		assert(
			typeof(rawCFrame) == "CFrame" or typeof(rawCFrame) == "Vector3" or type(rawCFrame) == "table",
			"[VFXHelper.TweenModel] 'CFrame' must be a CFrame, Vector3, or numeric table"
		)

		if typeof(rawCFrame) == "CFrame" then
			goalCFrame = rawCFrame
		else
			goalCFrame = CFNew(resolveVec3(rawCFrame, "CFrame")) * pivotOrigin.Rotation
		end
	elseif position then
		goalCFrame = CFNew(position) * pivotOrigin.Rotation
	end

	local parts = {}
	if model:IsA("BasePart") then
		parts[1] = model
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			parts[#parts + 1] = d
		end
	end

	local partCount = #parts
	assert(partCount > 0,
		"[VFXHelper.TweenModel] 'Model' contains no BaseParts to animate")

	local snapshots = table.create(partCount)
	for i = 1, partCount do
		local p = parts[i]
		local rel = pivotOrigin:ToObjectSpace(p.CFrame)
		snapshots[i] = {
			part = p,
			size = p.Size,
			relPos = rel.Position,
			rotOnly = rel - rel.Position,
		}
	end

	local info = TweenInfo.new(duration, easeStyle, easeDir)

	local proxy = Instance.new("NumberValue")
	local proxyTween = TweenService:Create(proxy, info, { Value = 1 })

	local reserved = {
		Model = true,
		Duration = true,
		Scale = true,
		Rotation = true,
		Offset = true,
		Position = true,
		CFrame = true,
		WaitTweenEnd = true,
		EasingStyle = true,
		EasingDirection = true,
	}

	local passthrough = {}
	for k, v in pairs(config) do
		if not reserved[k] then
			passthrough[k] = v
		end
	end

	local propertyTweens = table.create(partCount)
	for i = 1, partCount do
		local s = snapshots[i]
		local props = {}

		for k, v in pairs(passthrough) do
			props[k] = v
		end

		if hasScale then
			props.Size = s.size * scaleTarget
		end

		if next(props) then
			propertyTweens[#propertyTweens + 1] = TweenService:Create(s.part, info, props)
		end
	end

	local running = true
	local cleaned = false

	local function cleanup()
		if cleaned then
			return
		end

		cleaned = true
		running = false

		proxyTween:Cancel()

		local tweenCount = #propertyTweens
		for i = 1, tweenCount do
			propertyTweens[i]:Cancel()
		end

		if proxy.Parent ~= nil then
			proxy:Destroy()
		else
			pcall(function()
				proxy:Destroy()
			end)
		end
	end

	local function runLoop()
		proxyTween:Play()

		local tweenCount = #propertyTweens
		for i = 1, tweenCount do
			propertyTweens[i]:Play()
		end

		while running do
			local alpha = proxy.Value
			local currentScale = hasScale and (1 + (scaleTarget - 1) * alpha) or 1

			local currentPivot
			if goalCFrame then
				currentPivot = pivotOrigin:Lerp(goalCFrame, alpha)
			else
				local offCF = offset and CFNew(offset * alpha) or CF_IDENTITY
				currentPivot = pivotOrigin * offCF
			end

			if rot then
				currentPivot *= CFAngles(
					RAD(rot.X * alpha),
					RAD(rot.Y * alpha),
					RAD(rot.Z * alpha)
				)
			end

			for i = 1, partCount do
				local s = snapshots[i]
				local part = s.part
				if part.Parent then
					part.CFrame = currentPivot * CFNew(s.relPos * currentScale) * s.rotOnly
				end
			end

			if alpha >= 1 then
				break
			end

			stepped:Wait()
		end

		cleanup()
	end

	local needsLoop = (rot ~= nil) or (offset ~= nil) or (goalCFrame ~= nil) or hasScale
	if needsLoop then
		if waitEnd then
			runLoop()
		else
			task.spawn(runLoop)
		end
	else
		proxyTween.Completed:Connect(cleanup)
		proxyTween:Play()

		local tweenCount = #propertyTweens
		for i = 1, tweenCount do
			propertyTweens[i]:Play()
		end
	end

	return {
		Stop = cleanup,
		IsRunning = function()
			return running and not cleaned
		end,
	}
end

return VFXHelper
