local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("ManaGained")
local playermod = Skada:NewModule("ManaGainedPlayerView")

mod.name = L["Mana gained"]

local function log_gain(set, gain)
	-- Get the player from set.
	local player = Skada:get_player(set, gain.playerid, gain.playername)
	if player then
		-- Make sure power type exists.
		if not player.power[gain.type] then
			player.power[gain.type] = {spells = {}, amount = 0}
		end
		
		-- Make sure set power type exists.
		if not set.power[gain.type] then
			set.power[gain.type] = 0
		end
	
		-- Add to player total.
		player.power[gain.type].amount = player.power[gain.type].amount + gain.amount
		
		-- Also add to set total gain.
		set.power[gain.type] = set.power[gain.type] + gain.amount
		
		-- Create spell if it does not exist.
		if not player.power[gain.type].spells[gain.spellid] then
			player.power[gain.type].spells[gain.spellid] = 0
		end
		
		player.power[gain.type].spells[gain.spellid] = player.power[gain.type].spells[gain.spellid] + gain.amount
	end
end

local MANA = 0

local gain = {}

local function SpellEnergize(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Healing
	local spellId, spellName, spellSchool, samount, powerType = ...
	
	gain.playerid = srcGUID
	gain.playername = srcName
	gain.spellid = spellId
	gain.spellname = spellName
	gain.amount = samount
	gain.type = tonumber(powerType)
	
	Skada:FixPets(gain)
	log_gain(Skada.current, gain)
	log_gain(Skada.total, gain)
end

local function click_on_player(win, data, button)
	if button == "LeftButton" then
		playermod.playerid = data.id
		playermod.name = data.label..L["'s Healing"]
		win:DisplayMode(playermod)
	elseif button == "RightButton" then
		win:RightClick()
	end
end

function mod:Update(win, set)
	local nr = 1
	local max = 0

	for i, player in ipairs(set.players) do
		if player.power[MANA] then
			
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			
			d.id = player.id
			d.label = player.name
			d.value = player.power[MANA].amount
			d.valuetext = Skada:FormatNumber(player.power[MANA].amount)
			d.class = player.class
			
			if player.power[MANA].amount > max then
				max = player.power[MANA].amount
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

local function spell_click(win, data, button)
	if button == "RightButton" then
		win:DisplayMode(mod)
	end
end

-- Detail view of a player.
function playermod:Update(win, set)
	-- View spells for this player.
		
	local player = Skada:find_player(set, self.playerid)
	local nr = 1
	local max = 0
	
	if player then
		
		for spellid, amount in pairs(player.power[MANA].spells) do
		
			local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(spellid)

			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			
			d.id = spellid
			d.label = name
			d.value = amount
			d.valuetext = Skada:FormatNumber(amount)..(" (%02.1f%%)"):format(amount / player.power[MANA].amount * 100)
			d.icon = icon
			
			if amount > max then
				max = amount
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

function mod:OnEnable()
	mod.metadata		= {showspots = true, click = click_on_player}
	playermod.metadata	= {click = spell_click}

	Skada:RegisterForCL(SpellEnergize, 'SPELL_ENERGIZE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellEnergize, 'SPELL_PERIODIC_ENERGIZE', {src_is_interesting = true})

	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
end

function mod:GetSetSummary(set)
	return Skada:FormatNumber(set.power[MANA] or 0)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.power then
		player.power = {}
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.power then
		set.power = {}
	end
end
