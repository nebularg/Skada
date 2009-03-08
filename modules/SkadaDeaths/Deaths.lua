local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local mod = Skada:NewModule("DeathsMode", "AceEvent-3.0")
local deathlog = Skada:NewModule("DeathLogMode", "AceEvent-3.0")

mod.name = L["Deaths"]

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

-- Called by Skada when a set is complete.
function mod:SetComplete(set)
	-- Clean; remove logs from all who did not die.
	for i, player in ipairs(set.players) do
		if player.deaths == 0 then
			wipe(player.deathlog)
			player.deathlog = nil
		end
	end
end

function mod:AddToTooltip(set, tooltip)
 	GameTooltip:AddDoubleLine(L["Deaths"], set.deaths, 1,1,1)
end

function mod:GetSetSummary(set)
	return set.deaths
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.deaths then
		player.deaths = 0
		player.deathts = 0
		player.deathlog = {}
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.deaths then
		set.deaths = 0
	end
end

function mod:log_resurrect(set, playerid, playername)
	if set then
		local player = Skada:get_player(set, playerid, playername)
		wipe(player.deathlog)
	end
end

function mod:log_deathlog(set, playerid, playername, spellid, spellname, amount, timestamp)
	if set then
		local player = Skada:get_player(set, playerid, playername)
		
		table.insert(player.deathlog, 1, {["spellid"] = spellid, ["spellname"] = spellname, ["amount"] = amount, ["ts"] = timestamp})
		
		-- Trim.
		while table.maxn(player.deathlog) > 15 do table.remove(player.deathlog) end
	end
end

function mod:log_death(set, playerid, playername, timestamp)
	if set then
		local player = Skada:get_player(set, playerid, playername)
		
		-- Add to player deaths.
		player.deaths = player.deaths + 1
		
		-- Set timestamp for death.
		player.deathts = timestamp
		
		-- Also add to set deaths.
		set.deaths = set.deaths + 1

		-- Mark set as changed.
		set.changed = true
	end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Deaths
	if Skada:IsDataCollectionActive() and dstName and Skada:UnitIsInteresting(dstName) then
		local current = Skada:GetCurrentSet()
	
		if eventtype == 'UNIT_DIED' and Skada:UnitIsInterestingNoPets(dstName) then
	
			if not UnitIsFeignDeath(dstName) then	-- Those pesky hunters
				local current = Skada:GetCurrentSet()
				local total = Skada:GetTotalSet()
				if current then
					self:log_death(current, dstGUID, dstName, timestamp)
				end
				self:log_death(total, dstGUID, dstName, timestamp)
			end
			
		elseif (eventtype == 'SPELL_DAMAGE' or eventtype == 'SPELL_PERIODIC_DAMAGE' or eventtype == 'SPELL_BUILDING_DAMAGE' or eventtype == 'RANGE_DAMAGE') then
			-- Spell damage. We have to fix for pets. (hi there, Malygos!)
			local spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
			
			dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
			if srcName then
				self:log_deathlog(current, dstGUID, dstName, spellId, srcName..L["'s "]..spellName, 0-samount, timestamp)
			else
				self:log_deathlog(current, dstGUID, dstName, spellId, spellName, 0-samount, timestamp)
			end
				
		elseif eventtype == 'SWING_DAMAGE' then
			-- White melee.
			local samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
			local spellid = 6603
			local spellname = L["Attack"]
			
			dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
			if srcName then
				self:log_deathlog(current, dstGUID, dstName, spellid, srcName..L["'s "]..spellname, 0-samount, timestamp)
			else
				self:log_deathlog(current, dstGUID, dstName, spellid, spellname, 0-samount, timestamp)
			end
			
		elseif srcName and eventtype == 'SPELL_HEAL' or eventtype == 'SPELL_PERIODIC_HEAL' then
	
			-- Healing
			local spellId, spellName, spellSchool, samount, soverhealing, scritical = ...
			smount = min(0, samount - soverhealing)
			
			srcGUID, srcName = Skada:FixMyPets(srcGUID, srcName)
			dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
			self:log_deathlog(current, dstGUID, dstName, spellId, srcName.."'s "..spellName, samount, timestamp)
		elseif srcName and eventtype == 'SPELL_RESURRECT' then
			-- Clear deathlog for this player.
			self:log_resurrect(current, dstGUID, dstName)
		end

	end

end

local function sort_by_ts(a,b)
	return a.ts > b.ts
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
				local label = player.name
				if player.deaths > 1 then
					label = label.." ("..player.deaths..")"
				end
				bar = Skada:CreateBar(tostring(player.id), label, player.deaths, maxdeaths, nil, false)
				bar.ts = player.deathts
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button)
												if button == "LeftButton" then
													deathlog.playerid = player.id
													deathlog.name = player.name..L["'s Death"]
													Skada:DisplayMode(deathlog)
												elseif button == "RightButton" then Skada:RightClick() end end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(date("%H:%M:%S", player.deathts))
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SetSortFunction(sort_by_deathts)
	Skada:SortBars()
end

-- Death log.
function deathlog:Update(set)
	local player = Skada:get_player(set, self.playerid)
	
	-- Find the max amount
	local maxhit = 0
	for i, log in ipairs(player.deathlog) do
		if math.abs(log.amount) > maxhit then
			maxhit = math.abs(log.amount)
		end
	end
	
	for i, log in ipairs(player.deathlog) do
		local diff = tonumber(log.ts) - tonumber(player.deathts)
		-- Ignore hits older than 30s before death.
		if diff > -30 then
			local bar = Skada:GetBar("log"..i)
			if bar then
				bar:SetMaxValue(maxhit)
				bar:SetValue(math.abs(log.amount))
			else
				local icon = select(3, GetSpellInfo(log.spellid))
				bar = Skada:CreateBar("log"..i, log.spellname, math.abs(log.amount), maxhit, icon, false)
				bar.ts = log.ts
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then Skada:DisplayMode(mod) end end)
				if log.amount > 0 then
					bar:SetColorAt(0, 0, 255, 0, 1)
				else
					bar:SetColorAt(0, 255, 0, 0, 1)
				end
				if icon then
					bar:ShowIcon()
				end
			end
			bar:SetTimerLabel(Skada:FormatNumber(log.amount)..", "..("%2.3f"):format(diff))
		end
	end
	
	-- Use our special sort function and sort.
	Skada:SetSortFunction(sort_by_ts)
	Skada:SortBars()
end
