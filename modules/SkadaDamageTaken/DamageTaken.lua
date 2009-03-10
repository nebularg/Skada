local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("DamageTakenMode", "AceEvent-3.0")
local playermod = Skada:NewModule("DamageTakenModePlayerView")

mod.name = L["Damage taken"]

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.damagetaken then
		player.damagetaken = 0
		player.damagetakenspells = {}
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.damagetaken then
		set.damagetaken = 0
	end
end

function mod:GetSetSummary(set)
	return Skada:FormatNumber(set.damagetaken)
end

function mod:log_damage_taken(set, dmg)
	if set then
		-- Get the player.
		local player = Skada:get_player(set, dmg.playerid, dmg.playername)
		if player then
			-- Also add to set total damage taken.
			set.damagetaken = set.damagetaken + dmg.amount
			
			-- Add spell to player if it does not exist.
			if not player.damagetakenspells[dmg.spellname] then
				player.damagetakenspells[dmg.spellname] = {id = dmg.spellid, name = dmg.spellname, damage = 0}
			end
			
			-- Add to player total damage.
			player.damagetaken = player.damagetaken + dmg.amount
			
			-- Get the spell from player.
			local spell = player.damagetakenspells[dmg.spellname]
		
			spell.damage = spell.damage + dmg.amount
	
			-- Mark set as changed.
			set.changed = true
		end
	end
end

local dmg = {}

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)

	if Skada:IsDataCollectionActive() and dstName and Skada:UnitIsInterestingNoPets(dstName) then
	
		local current = Skada:GetCurrentSet()
		local total = Skada:GetTotalSet()

		-- Damage taken.
		if eventtype == 'SPELL_DAMAGE' or eventtype == 'SPELL_PERIODIC_DAMAGE' or eventtype == 'SPELL_BUILDING_DAMAGE' or eventtype == 'RANGE_DAMAGE' then
			local spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
			
			dmg.playerid = dstGUID
			dmg.playername = dstName
			dmg.spellid = spellId
			dmg.spellname = spellName
			dmg.amount = samount
			
			self:log_damage_taken(current, dmg)
			self:log_damage_taken(total, dmg)
		elseif eventtype == 'SWING_DAMAGE' then
			-- White melee.
			local samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
			
			dmg.playerid = dstGUID
			dmg.playername = dstName
			dmg.spellid = 6603
			dmg.spellname = L["Attack"]
			dmg.amount = samount

			self:log_damage_taken(current, dmg)
			self:log_damage_taken(total, dmg)
		end

	end

end


function mod:Update(set)
	-- Calculate the highest damage.
	-- How to get rid of this iteration?
	local maxdamagetaken = 0
	for playerid, player in pairs(set.players) do
		if player.damagetaken > maxdamagetaken then
			maxdamagetaken = player.damagetaken
		end
	end
	
--	Skada:Print("maxhealing: "..tostring(maxhealing))
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.damagetaken > 0 then
			local bar = Skada:GetBar(tostring(playerid))
			if bar then
				bar:SetMaxValue(maxdamagetaken)
				bar:SetValue(player.damagetaken)
			else
				bar = Skada:CreateBar(tostring(player.id), player.name, player.damagetaken, maxdamagetaken, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button)
												if button == "LeftButton" then
													playermod.playerid = player.id
													playermod.name = player.name..L["'s Damage taken"]
													Skada:DisplayMode(playermod)
												elseif button == "RightButton" then
													Skada:RightClick()
												end
											end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(Skada:FormatNumber(player.damagetaken)..(" (%02.1f%%)"):format(player.damagetaken / set.damagetaken * 100))
			
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end

-- Detail view of a player.
function playermod:Update(set)
	-- View spells for this player.
		
	local player = Skada:get_selected_player(set, self.playerid)
	
	if player then
		for spellname, spell in pairs(player.damagetakenspells) do
				
			local bar = Skada:GetBar(spellname)
			if bar then
				bar:SetMaxValue(player.damagetaken)
				bar:SetValue(spell.damage)
			else
				local icon = select(3, GetSpellInfo(spell.id))
				bar = Skada:CreateBar(tostring(spellname), spell.name, spell.damage, player.damagetaken, icon, false)
				local color = Skada:GetDefaultBarColor()
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
			bar:SetTimerLabel(Skada:FormatNumber(spell.damage)..(" (%02.1f%%)"):format(spell.damage / player.damagetaken * 100))
			
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end
