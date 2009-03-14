local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("DispelMode")

mod.name = L["Dispels"]

local function log_dispell(set, dispell)
	local player = Skada:get_player(set, dispell.playerid, dispell.playername)
	if player then
		-- Add to player dispels.
		player.dispells = player.dispells + 1
		
		-- Also add to set total dispels.
		set.dispells = set.dispells + 1
	end
end

local function log_interrupt(set, interrupt)
	local player = Skada:get_player(set, interrupt.playerid, interrupt.playername)
	if player then
		-- Add to player interrupts.
		player.interrupts = player.interrupts + 1
		
		-- Also add to set total interrupts.
		set.interrupts = set.interrupts + 1
	end
end

local dispell = {}

local function SpellDispel(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Dispells
	local spellId, spellName, spellSchool, sextraSpellId, sextraSpellName, sextraSchool, auraType = ...
	
	dispell.playerid = srcGUID
	dispell.playername = srcName
	dispell.spellid = spellId
	dispell.spellname = spellName
	dispell.extraspellid = sextraSpellId
	dispell.extraspellname = sextraSpellName		
	
	log_dispell(Skada.current, dispell)
	log_dispell(Skada.total, dispell)
end

local function SpellInterrupt(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Interrupts
	local spellId, spellName, spellSchool, sextraSpellId, sextraSpellName, sextraSchool = ...
	
	dispell.playerid = srcGUID
	dispell.playername = srcName
	dispell.spellid = spellId
	dispell.spellname = spellName
	dispell.extraspellid = sextraSpellId
	dispell.extraspellname = sextraSpellName		
	
	log_interrupt(Skada.current, dispell)
	log_interrupt(Skada.total, dispell)
end

function mod:Update(win, set)
	-- Calculate the highest number.
	-- How to get rid of this iteration?
	local maxdispells = 0
	for i, player in ipairs(set.players) do
		if player.dispells > maxdispells then
			maxdispells = player.dispells
		end
	end
	
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.dispells > 0 then
			local bar = win:GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxdispells)
				bar:SetValue(player.dispells)
			else
				bar = win:CreateBar(tostring(player.id), player.name, player.dispells, maxdispells, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then win:RightClick() end end)
				local color = Skada.classcolors[player.class] or win:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
				
			end
			bar:SetTimerLabel(tostring(player.dispells))
		end
	end
		
	-- Sort the possibly changed bars.
	win:SortBars()
end

function mod:OnEnable()
	Skada:RegisterForCL(SpellDispel, 'SPELL_DISPEL', {src_is_interesting = true})
	Skada:RegisterForCL(SpellInterrupt, 'SPELL_INTERRUPT', {src_is_interesting = true})
	
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
 	GameTooltip:AddDoubleLine(L["Dispels"], set.dispells, 1,1,1)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.dispells then
		player.dispells = 0
	end
	if not player.interrupts then
		player.interrupts = 0
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.dispells then
		set.dispells = 0
	end
	if not set.interrupts then
		set.interrupts = 0
	end
end

function mod:GetSetSummary(set)
	return set.dispells
end

