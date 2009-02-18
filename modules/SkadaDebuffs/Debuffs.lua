local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local mod = Skada:NewModule("DebuffMode", "AceEvent-3.0", "AceTimer-3.0")
local auramod = Skada:NewModule("DebuffModeSpellView")

mod.name = L["Debuff uptimes"]

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:ScheduleRepeatingTimer("Tick", 1)

	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

local function len(t)
	local l = 0
	for i,j in pairs(t) do
		l = l + 1
	end
	return l
end

function mod:AddToTooltip(set, tooltip)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.auras then
		player.auras = {}
		player.uptime = 0
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
end

-- This is highly inefficient. Come up with something better.
local function tick_spells(set)
	for i, player in ipairs(set.players) do
		for spellname, spell in pairs(player.auras) do
			if spell.active > 0 then
				spell.uptime = spell.uptime + 1
				player.uptime = player.uptime + 1
			end
		end
	end
end

-- Adds 1s to the uptime of all currently active spells.
-- A spell is considered active if at least 1 instance of it is still active.
-- We determine this by incrementing or subtracting from a counter.
-- This is less messy than fooling around with the aura events.
function mod:Tick()
	if Skada:IsDataCollectionActive() then
	
		local current = Skada:GetCurrentSet()
		local total = Skada:GetTotalSet()
		
		tick_spells(current)
		tick_spells(total)
	end
end

function mod:log_auraapply(set, aura)
	if set then
		
		-- Get the player.
		local player = Skada:get_player(set, aura.playerid, aura.playername)
		if player then
			-- Add aura to player if it does not exist.
			-- If it does exist, increment our counter of active instances by 1
			if not player.auras[aura.spellname] then
				player.auras[aura.spellname] = {id = aura.spellid, name = aura.spellname, active = 1, uptime = 0}
			else
				player.auras[aura.spellname].active = player.auras[aura.spellname].active + 1
			end
		end
		
	end
end

function mod:log_auraremove(set, aura)
	if set then
		
		-- Get the player.
		local player = Skada:get_player(set, aura.playerid, aura.playername)
		if player then
			-- If aura does not exist, we know nothing about it and ignore it.
			-- If it does exist and we know of 1 or more active instances, subtract 1 from our counter.
			if player.auras[aura.spellname] then
				local a = player.auras[aura.spellname]
				if a.active > 0 then
					a.active = a.active - 1
				end
			end
		end
		
	end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)

	if Skada:IsDataCollectionActive() and srcName and (eventtype == 'SPELL_AURA_APPLIED' or eventtype == 'SPELL_AURA_REMOVED') and Skada:UnitIsInteresting(srcName) then
	
		local current = Skada:GetCurrentSet()
		local total = Skada:GetTotalSet()

		if eventtype == 'SPELL_AURA_APPLIED' then
			local spellId, spellName, spellSchool, auraType = ...
			local aura = {playerid = srcGUID, playername = srcName, spellid = spellId, spellname = spellName, ["auratype"] = auraType}
			if auraType == "DEBUFF" then
				Skada:FixPets(aura)
				self:log_auraapply(current, aura)
				self:log_auraapply(total, aura)
			end
		elseif eventtype == 'SPELL_AURA_REMOVED' then
			local spellId, spellName, spellSchool, auraType = ...
			local aura = {playerid = srcGUID, playername = srcName, spellid = spellId, spellname = spellName, ["auratype"] = auraType}
			if auraType == "DEBUFF" then
				Skada:FixPets(aura)
				self:log_auraremove(current, aura)
				self:log_auraremove(total, aura)
			end
		end
	end

end

function mod:Update(set)
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		local nr = len(player.auras)
		if nr > 0 then
			local bar = Skada:GetBar(tostring(player.id))
			
			-- Calculate player max possible uptime.
			local maxtime = Skada:PlayerActiveTime(set, player)
			
			-- Now divide by the number of spells to get the average uptime.
			--Skada:Print(uptime.." divided on "..nr.." spells = "..(uptime / nr))
			local uptime = player.uptime / nr
			
			if uptime then
				
				if bar then
					bar:SetMaxValue(maxtime)
					bar:SetValue(uptime)
				else
					bar = Skada:CreateBar(tostring(player.id), player.name, uptime, maxtime, nil, false)
					bar:EnableMouse()
					bar:SetScript("OnMouseDown", function(bar, button)
													if button == "LeftButton" then
														auramod.playerid = player.id
														auramod.name = player.name..L["'s Debuffs"]
														Skada:DisplayMode(auramod)
													elseif button == "RightButton" then
														Skada:RightClick()
													end
												end)
					local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
					bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
				end
				bar:SetTimerLabel(("%02.1f%% / %u"):format(uptime / maxtime * 100, nr))
			end
		end
	end
		
	-- Sort the possibly changed bars.
	Skada:SortBars()
end

-- Detail view of a player.
function auramod:Update(set)
	-- View spells for this player.
		
	local player = Skada:get_selected_player(set, self.playerid)
	local color = Skada:GetDefaultBarColor()
	
	if player then
		-- Calculate player max possible uptime.
		local maxtime = time() - player.first
		if set.endtime then
			maxtime = set.endtime - player.first
		end
	
		for spellname, spell in pairs(player.auras) do
			
			local uptime = spell.uptime
			
			local bar = Skada:GetBar(spellname)
			--self:Print("max: "..tostring(player.damage))
			--self:Print(spell.name..": "..tostring(spell.damage))
			if bar then
				bar:SetMaxValue(maxtime)
				bar:SetValue(uptime)
			else
				local icon = select(3, GetSpellInfo(spell.id))
			
				bar = Skada:CreateBar(spellname, spell.name, uptime, maxtime, icon, false)
				bar:SetColorAt(0, color.r, color.g, color.b, color.a)
				bar:ShowTimerLabel()
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown",function(bar, button)
												if button == "RightButton" then
													Skada:DisplayMode(mod)
												end
											end)
				if icon then
					bar:ShowIcon()
				end
			end
			bar:SetTimerLabel(("(%02.1f%%)"):format(uptime / maxtime * 100))
			
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end