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

function StatesManager.SetState(plr: Player, stateKey, value, duration)
	if not states[plr] then
		states[plr] = {}
	end
	
	states[plr][stateKey] = value

	if duration and type(duration) == "number" then
		delay(duration, function()
			if states[plr] then
				states[plr][stateKey] = nil
				
				if next(states[plr]) == nil then
					states[plr] = nil
				end

			end

		end)

	end

end


function StateManager.RemoveState(plr: Player, stateKey)
	if not states[plr] then return end
	
	if stateKey then
		states[plr][stateKey] = nil
		if next(states[plr]) == nil then
			states[plr] = nil
		end
	else
		states[plr] = nil -- remove all states for player if no stateKey specified
	end
end

return StatesManager