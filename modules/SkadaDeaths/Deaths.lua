local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local mod = Skada:NewModule("DeathsMode", "AceEvent-3.0")

mod.name = L["Deaths"]

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
 	GameTooltip:AddDoubleLine(L["Deaths:"], set.deaths, 1,1,1)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.deaths then
		player.deaths = 0
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.deaths then
		set.deaths = 0
	end
end

function mod:log_death(set, playerid, playername)
	if set then
		local player = Skada:get_player(set, playerid, playername)
		
		-- Add to player deaths.
		player.deaths = player.deaths + 1
		
		-- Also add to set deaths.
		set.deaths = set.deaths + 1

		-- Mark set as changed.
		set.changed = true
	end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if Skada:IsDataCollectionActive() and dstName and eventtype == 'UNIT_DIED' and Skada:UnitIsInterestingNoPets(dstName) then
	
		local current = Skada:GetCurrentSet()
		local total = Skada:GetTotalSet()
		
		if not UnitIsFeignDeath(dstName) then	-- Those pesky hunters
			if current then
				self:log_death(current, dstGUID, dstName)
			end
			self:log_death(total, dstGUID, dstName)
		end

	end

end

-- Death meter.
function mod:Update(set)

	-- Calculate the highest number.
	-- How to get rid of this iteration?
	local maxdeaths = 0
	for i, player in ipairs(set.players) do
		if player.deaths > maxdeaths then
			maxdeaths = player.deaths
		end
	end
	
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.deaths > 0 then
			local bar = Skada:GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxdeaths)
				bar:SetValue(player.deaths)
			else
				bar = Skada:CreateBar(tostring(player.id), player.name, player.deaths, maxdeaths, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then Skada:RightClick() end end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(tostring(player.deaths))
		end
	end
		
	-- Sort the possibly changed bars.
	Skada:SortBars()
	
end