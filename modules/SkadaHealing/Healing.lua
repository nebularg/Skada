local mod = Skada:NewModule("HealingMode", "AceEvent-3.0")
local playermod = Skada:NewModule("HealingModePlayerView")

mod.name = "Healing"

function mod:OnEnable()
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
	local endtime = set.endtime
	if not endtime then
		endtime = time()
	end
	local raidhps = set.healing / (endtime - set.starttime + 1)
 	GameTooltip:AddDoubleLine("HPS", ("%02.1f"):format(raidhps), 1,1,1)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.healing then
		player.healing = 0
		player.healingspells = {}
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.healing then
		set.healing = 0
	end
end

function mod:log_heal(set, heal)
	if set then
		-- Get the player from set.
		local player = Skada:get_player(set, heal.playerid, heal.playername)
		if player then
			-- Subtract overhealing
			local amount = math.max(0, heal.amount - heal.overhealing)
	
			-- Add to player total.
			player.healing = player.healing + amount
			player.overhealing = player.overhealing + heal.overhealing
			
			-- Also add to set total damage.
			set.healing = set.healing + amount
			set.overhealing = set.overhealing + heal.overhealing
			
			-- Create spell if it does not exist.
			if not player.healingspells[heal.spellname] then
				player.healingspells[heal.spellname] = {id = heal.spellid, name = heal.spellname, hit = 0, totalhits = 0, healing = 0, overhealing = 0, critical = 0}
			end
			
			-- Get the spell from player.
			local spell = player.healingspells[heal.spellname]
			
			spell.healing = spell.healing + amount
			if heal.critical then
				spell.critical = spell.critical + 1
			end
			spell.overhealing = spell.overhealing + heal.overhealing
	
			set.changed = true
		end
	end
end

function mod:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if Skada:IsDataCollectionActive() and srcName and (eventtype == 'SPELL_HEAL' or eventtype == 'SPELL_PERIODIC_HEAL') and Skada:UnitIsInteresting(srcName) then
	
		local current = Skada:GetCurrentSet()
		local total = Skada:GetTotalSet()

		-- Healing
		local spellId, spellName, spellSchool, samount, soverhealing, scritical = ...
		local heal = {playerid = srcGUID, playername = srcName, spellid = spellId, spellname = spellName, amount = samount, overhealing = soverhealing, critical = scritical}
		
		Skada:FixPets(heal)
		self:log_heal(current, heal)
		self:log_heal(total, heal)
	end

end

function mod:Update(set)
	-- Calculate the highest damage.
	-- How to get rid of this iteration?
	local maxhealing = 0
	for i, player in ipairs(set.players) do
		if player.healing > maxhealing then
			maxhealing = player.healing
		end
	end
	
	-- Sort players according to healing done.
	table.sort(set.players, function(a,b) return a.healing > b.healing end)
	
--	Skada:Print("maxhealing: "..tostring(maxhealing))
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.healing > 0 then
			local bar = Skada:GetBarGroup():GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxhealing)
				bar:SetValue(player.healing)
	--			Skada:Print("updated "..player.name.." to "..tostring(player.healing))
			else
				bar = Skada:GetBarGroup():NewCounterBar(tostring(player.id), player.name, player.healing, maxhealing, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button)
												if button == "LeftButton" then
													playermod.playerid = player.id
													playermod.name = player.name.."'s Healing"
													Skada:DisplayMode(playermod)
												elseif button == "RightButton" then
													Skada:RightClick()
												end
											end)
				local color = Skada.classcolors[player.class]
				if color then
					bar:SetColorAt(0, color.r, color.g, color.b, color.a)
				else
					color = Skada:GetDefaultBarColor()
					bar:SetColorAt(0, color.r, color.g, color.b, color.a)
				end
				
	--			Skada:Print("created "..player.name.." at "..tostring(player.healing))
			end
			bar:SetLabel(("%2u. %s"):format(i, player.name))
			bar:SetTimerLabel(Skada:FormatNumber(player.healing)..(" (%02.1f%%)"):format(player.healing / set.healing * 100))
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end

-- Detail view of a player.
function playermod:Update(set)
	-- View spells for this player.
		
	local player = Skada:get_selected_player(set, self.playerid)
	local color = Skada:GetDefaultBarColor()
	
	if player then
		for spellname, spell in pairs(player.healingspells) do
				
			local bar = Skada:GetBarGroup():GetBar(spellname)
			--self:Print("max: "..tostring(player.damage))
			--self:Print(spell.name..": "..tostring(spell.damage))
			if bar then
				bar:SetMaxValue(player.healing)
				bar:SetValue(spell.healing)
			else
				local icon = select(3, GetSpellInfo(spell.id))
			
				bar = Skada:GetBarGroup():NewCounterBar(spellname, spell.name, spell.healing, player.healing, icon, false)
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
			bar:SetTimerLabel(Skada:FormatNumber(spell.healing)..(" (%02.1f%%)"):format(spell.healing / player.healing * 100))
			
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end
