local StatesManager = {}

local states = {}

function StatesManager.ReturnStates(plr: Player)
	return states[plr]
end

function StatesManager.GetState(plr: Player, stateKey)
	if states[plr] then
		return states[plr][stateKey]
	end
	return nil
end

local stateVersions = {}  -- tracks current version per player per state
function StatesManager.SetState(plr, stateKey, value, duration)
	if not states[plr] then
		states[plr] = {}
	end
	if not stateVersions[plr] then
		stateVersions[plr] = {}
	end

	states[plr][stateKey] = value

	if duration and type(duration) == "number" then
		local stateVersion = (stateVersions[plr][stateKey] or 0) + 1
		stateVersions[plr][stateKey] = stateVersion

		delay(duration, function()
			-- only clear if no newer SetState has happened
			if stateVersions[plr] and stateVersions[plr][stateKey] == stateVersion then
				if states[plr] then
					states[plr][stateKey] = nil
					if next(states[plr]) == nil then
						states[plr] = nil
					end
				end
			end
		end)
	end
end

function StatesManager.RemoveState(plr: Player, stateKey)
	if not states[plr] then return end
	
	if stateKey then
		states[plr][stateKey] = nil
		if next(states[plr]) == nil then
			states[plr] = nil -- remove player from states table if no more states
		end
	else
		states[plr] = nil -- remove all states for player if no stateKey specified
	end
end

return StatesManager