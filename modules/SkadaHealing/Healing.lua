local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("HealingMode")
local playermod = Skada:NewModule("HealingModePlayerView")

mod.name = L["Healing"]

local function log_heal(set, heal)
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
	end
end

local heal = {}

local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Healing
	local spellId, spellName, spellSchool, samount, soverhealing, scritical = ...
	
	heal.playerid = srcGUID
	heal.playername = srcName
	heal.spellid = spellId
	heal.spellname = spellName
	heal.amount = samount
	heal.overhealing = soverhealing
	heal.critical = scritical
	
	Skada:FixPets(heal)
	log_heal(Skada.current, heal)
	log_heal(Skada.total, heal)
end

local function getHPS(set, player)
	local totaltime = Skada:PlayerActiveTime(set, player)
	
	return player.healing / math.max(1,totaltime)
end

local function click_on_player(win, id, label, button)
	if button == "LeftButton" then
		playermod.playerid = id
		playermod.name = label..L["'s Healing"]
		win:DisplayMode(playermod)
	elseif button == "RightButton" then
		win:RightClick()
	end
end

function mod:Update(win, set)
	local nr = 1
	local max = 0

	for i, player in ipairs(set.players) do
		if player.healing > 0 then
			
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			
			d.id = player.id
			d.label = player.name
			d.value = player.healing
			if Skada.db.profile.modules.healingnohps then
				d.valuetext = Skada:FormatNumber(player.healing)..(" (%02.1f%%)"):format(player.healing / set.healing * 100)
			else
				local hps = getHPS(set, player)
				d.valuetext = Skada:FormatNumber(player.healing)..(" (%02.1f, %02.1f%%)"):format(hps, player.healing / set.healing * 100)
			end
			d.class = player.class
			
			if player.healing > max then
				max = player.healing
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

local function spell_click(win, id, label, button)
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
		
		for spellname, spell in pairs(player.healingspells) do
		
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			
			d.id = spell.id
			d.label = spell.name
			d.value = spell.healing
			d.valuetext = Skada:FormatNumber(spell.healing)..(" (%02.1f%%)"):format(spell.healing / player.healing * 100)
			d.icon = select(3, GetSpellInfo(spell.id))
			
			if spell.healing > max then
				max = spell.healing
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

function mod:OnEnable()
	mod.metadata		= {showspots = true, click = click_on_player}
	playermod.metadata	= {click = spell_click}

	Skada:RegisterForCL(SpellHeal, 'SPELL_HEAL', {src_is_interesting = true})
	Skada:RegisterForCL(SpellHeal, 'SPELL_PERIODIC_HEAL', {src_is_interesting = true})

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
 	GameTooltip:AddDoubleLine(L["HPS"], ("%02.1f"):format(raidhps), 1,1,1)
end

function mod:GetSetSummary(set)
	return Skada:FormatNumber(set.healing)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.healing then
		player.healing = 0
		player.healingspells = {}
		player.overhealing = 0
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.healing then
		set.healing = 0
		set.overhealing = 0
	end
end


local opts = {
	healingoptions = {
		type="group",
		name=L["Healing"],
		args={

			showdps = {
				type = "toggle",
				name = L["Do not show HPS"],
				desc = L["Hides HPS from the Healing modes."],
				get = function() return Skada.db.profile.modules.healingnohps end,
				set = function() Skada.db.profile.modules.healingnohps = not Skada.db.profile.modules.healingnohps end,
				order=2,
			},
					
		},
	}
}

function mod:OnInitialize()
	-- Add our options.
	table.insert(Skada.options.plugins, opts)
end