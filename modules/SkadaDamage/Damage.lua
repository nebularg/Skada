local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("Damage done")
local dpsmod = Skada:NewModule("DPS")
local playermod = Skada:NewModule("Damage player spells")
local spellmod = Skada:NewModule("Damage spell details")

mod.name = L["Damage"]
dpsmod.name = L["DPS"]

-- Used to track where to go back to, Damage or DPS mode.
local lastmod = nil

local function getDPS(set, player)
	local totaltime = Skada:PlayerActiveTime(set, player)
	
	return player.damage / math.max(1,totaltime)
end

local function getRaidDPS(set)
	if set.time > 0 then
		return set.damage / math.max(1, set.time)
	else
		local endtime = set.endtime
		if not endtime then
			endtime = time()
		end
		return set.damage / math.max(1, endtime - set.starttime)
	end
end

local function log_damage(set, dmg)
	-- Get the player.
	local player = Skada:get_player(set, dmg.playerid, dmg.playername)
	if player then
	
		-- Subtract overkill
--		local amount = math.max(0,dmg.amount - dmg.overkill)
		-- Or don't. Seems to be the way other meters do it.
		local amount = dmg.amount
--		self:Print(player.name..": "..dmg.spellname.." for "..tostring(amount))

		-- Also add to set total damage.
		set.damage = set.damage + amount
		
		-- Add spell to player if it does not exist.
		if not player.damagespells[dmg.spellname] then
			player.damagespells[dmg.spellname] = {id = dmg.spellid, name = dmg.spellname, hit = 0, totalhits = 0, damage = 0, critical = 0, glancing = 0, crushing = 0, ABSORB = 0, BLOCK = 0, DEFLECT = 0, DODGE= 0, EVADE = 0, IMMUNE = 0, PARRY = 0, REFLECT = 0, RESIST = 0, MISS = 0}
		end
    		
		-- Add to player total damage.
		player.damage = player.damage + amount
		
		-- Get the spell from player.
		local spell = player.damagespells[dmg.spellname]
		
		spell.totalhits = spell.totalhits + 1
	
		spell.damage = spell.damage + amount
		if dmg.critical then
			spell.critical = spell.critical + 1
		elseif dmg.missed ~= nil then
			if spell[dmg.missed] ~= nil then	-- Just in case.
				spell[dmg.missed] = spell[dmg.missed] + 1
			end
		elseif dmg.glancing then
			spell.glancing = spell.glancing + 1
		elseif dmg.crushing then
			spell.crushing = spell.crushing + 1
		else
			spell.hit = spell.hit + 1
		end
	end
end

local dmg = {}

local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Spell damage.
	if srcGUID ~= dstGUID then
		local spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
		
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName
		dmg.amount = samount
		dmg.overkill = soverkill
		dmg.resisted = sresisted
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.missed = nil

		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end
end

local function SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- White melee.
	if srcGUID ~= dstGUID then
		local samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
		
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.spellid = 6603
		dmg.spellname = L["Attack"]
		dmg.amount = samount
		dmg.overkill = soverkill
		dmg.resisted = sresisted
		dmg.blocked = sblocked
		dmg.absorbed = sabsorbed
		dmg.critical = scritical
		dmg.glancing = sglancing
		dmg.crushing = scrushing
		dmg.missed = nil
		
		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end
end

local function SwingMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcGUID ~= dstGUID then
		-- Melee misses

		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.spellid = 6603
		dmg.spellname = L["Attack"]
		dmg.amount = 0
		dmg.overkill = 0
		dmg.resisted = nil
		dmg.blocked = nil
		dmg.absorbed = nil
		dmg.critical = nil
		dmg.glancing = nil
		dmg.crushing = nil
		dmg.missed = select(1, ...)
		
		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end
end

local function SpellMissed(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Misses
	if srcGUID ~= dstGUID then
		local spellId, spellName, spellSchool, missType, samount = ...
		dmg.playerid = srcGUID
		dmg.playername = srcName
		dmg.spellid = spellId
		dmg.spellname = spellName
		dmg.amount = 0
		dmg.overkill = 0
		dmg.resisted = nil
		dmg.blocked = nil
		dmg.absorbed = nil
		dmg.critical = nil
		dmg.glancing = nil
		dmg.crushing = nil
		dmg.missed = missType
		
		Skada:FixPets(dmg)
		log_damage(Skada.current, dmg)
		log_damage(Skada.total, dmg)
	end
end

-- Called when user clicks on a data row.
function mod_click(win, data, button)
	if button == "LeftButton" then
		playermod.name = data.label..L["'s Damage"]
		playermod.playerid = data.id
		win:DisplayMode(playermod)
	elseif button == "RightButton" then
		win:RightClick()
	end
end

-- Damage overview.
function mod:Update(win, set)
	lastmod = mod

	-- Max value.
	local max = 0
 
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	local nr = 1
	for i, player in ipairs(set.players) do
		if player.damage > 0 then
			local dps = getDPS(set, player)
			
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			d.label = player.name
			
			if Skada.db.profile.modules.damagenodps then
				d.valuetext = Skada:FormatNumber(player.damage)..(" (%02.1f%%)"):format(player.damage / set.damage * 100)
			else
				d.valuetext = Skada:FormatNumber(player.damage)..(" (%02.1f, %02.1f%%)"):format(dps, player.damage / set.damage * 100)
			end
			
			d.value = player.damage
			d.id = player.id
			d.color = Skada.classcolors[player.class]
			if player.damage > max then
				max = player.damage
			end
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

local function player_click(win, data, button)
	if button == "LeftButton" then
		local player = Skada:find_player(win:get_selected_set(), playermod.playerid)
		spellmod.spellname = data.label
		spellmod.name = player.name..L["'s "]..data.label
		win:DisplayMode(spellmod)
	elseif button == "RightButton" then
		win:DisplayMode(lastmod)
	end
end

-- Detail view of a player.
function playermod:Update(win, set)
	-- View spells for this player.
		
	local player = Skada:find_player(set, self.playerid)
	local max = 0
	
	-- If we reset we have no data.
	if player then
		
		local nr = 1
		if player then
			for spellname, spell in pairs(player.damagespells) do

				local d = win.dataset[nr] or {}
				win.dataset[nr] = d
				d.label = spell.name
				d.id = spell.id
				d.icon = select(3, GetSpellInfo(spell.id))
				d.value = spell.damage
				d.valuetext = Skada:FormatNumber(spell.damage)..(" (%02.1f%%)"):format(spell.damage / player.damage * 100)
				if spell.damage > max then
					max = spell.damage
				end
				nr = nr + 1
			end
		end
	end
	
	win.metadata.maxvalue = max
end

local function add_detail_bar(win, nr, title, value)
	local d = win.dataset[nr] or {}
	win.dataset[nr] = d
	
	d.value = value
	d.label = title
	d.id = title
	d.valuetext = ("%u (%02.1f%%)"):format(value, value / win.metadata.maxvalue * 100)
end

local function spell_click(win, data, button)
	if button == "RightButton" then
		win:DisplayMode(playermod)
	end
end

function spellmod:Update(win, set)
	local player = Skada:find_player(set,playermod.playerid)
	
	if player then
		local spell = player.damagespells[self.spellname]
		
		win.metadata.maxvalue = spell.totalhits
		
		if spell then
			if spell.hit > 0 then
				add_detail_bar(win, 1, L["Hit"], spell.hit)
			end
			if spell.critical > 0 then
				add_detail_bar(win, 2, L["Critical"], spell.critical)
			end
			if spell.glancing > 0 then
				add_detail_bar(win, 3, L["Glancing"], spell.glancing)
			end
			if spell.crushing > 0 then
				add_detail_bar(win, 4, L["Crushing"], spell.crushing)
			end
			if spell.ABSORB and spell.ABSORB > 0 then
				add_detail_bar(win, 5, L["Absorb"], spell.ABSORB)
			end
			if spell.BLOCK and spell.BLOCK > 0 then
				add_detail_bar(win, 6, L["Block"], spell.BLOCK)
			end
			if spell.DEFLECT and spell.DEFLECT > 0 then
				add_detail_bar(win, 7, L["Deflect"], spell.DEFLECT)
			end
			if spell.DODGE and spell.DODGE > 0 then
				add_detail_bar(win, 8, L["Dodge"], spell.DODGE)
			end
			if spell.EVADE and spell.EVADE > 0 then
				add_detail_bar(win, 9, L["Evade"], spell.EVADE)
			end
			if spell.IMMUNE and spell.IMMUNE > 0 then
				add_detail_bar(win, 10, L["Immune"], spell.IMMUNE)
			end
			if spell.MISS and spell.MISS > 0 then
				add_detail_bar(win, 11, L["Missed"], spell.MISS)
			end
			if spell.PARRY and spell.PARRY > 0 then
				add_detail_bar(win, 12, L["Parry"], spell.PARRY)
			end
			if spell.REFLECT and spell.REFLECT > 0 then
				add_detail_bar(win, 13, L["Reflect"], spell.REFLECT)
			end
			if spell.RESIST and spell.RESIST > 0 then
				add_detail_bar(win, 14, L["Resist"], spell.RESIST)
			end
			
		end
	end

end

-- DPS-only view
function dpsmod:GetSetSummary(set)
	return Skada:FormatNumber(getRaidDPS(set))
end

function dpsmod:Update(win, set)
	lastmod = dpsmod

	local max = 0
	local nr = 1
	
	for i, player in ipairs(set.players) do
		local dps = getDPS(set, player)
		
		if dps > 0 then
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d
			d.label = player.name
			d.id = player.id
			d.value = dps
			d.color = Skada.classcolors[player.class]
			d.valuetext = ("%02.1f"):format(dps)
			if dps > max then
				max = dps
			end
			
			nr = nr + 1
		end
	end
	
	win.metadata.maxvalue = max
end

function mod:OnEnable()
	dpsmod.metadata = 		{showspots = true, click = mod_click}
	playermod.metadata = 	{click = player_click}
	mod.metadata = 			{showspots = true, click = mod_click}
	spellmod.metadata = 	{click = spell_click}

	Skada:RegisterForCL(SpellDamage, 'DAMAGE_SHIELD', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamage, 'SPELL_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamage, 'SPELL_PERIODIC_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamage, 'SPELL_BUILDING_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamage, 'RANGE_DAMAGE', {src_is_interesting = true})
	
	Skada:RegisterForCL(SwingDamage, 'SWING_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SwingMissed, 'SWING_MISSED', {src_is_interesting = true})
	
	Skada:RegisterForCL(SpellMissed, 'SPELL_MISSED', {src_is_interesting = true})
	Skada:RegisterForCL(SpellMissed, 'SPELL_PERIODIC_MISSED', {src_is_interesting = true})
	Skada:RegisterForCL(SpellMissed, 'RANGE_MISSED', {src_is_interesting = true})
	Skada:RegisterForCL(SpellMissed, 'SPELL_BUILDING_MISSED', {src_is_interesting = true})
	
	Skada:AddFeed(L["Damage: Personal DPS"], function()
								if Skada.current then
									local player = Skada:find_player(Skada.current, UnitGUID("player"))
									if player then
										return ("%02.1f"):format(getDPS(Skada.current, player)).." "..L["DPS"]
									end
								end
							end)
	Skada:AddFeed(L["Damage: Raid DPS"], function()
								if Skada.current then
									return ("%02.1f"):format(getRaidDPS(Skada.current)).." "..L["RDPS"]
								end
							end)
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
	
	Skada:RemoveFeed(L["Damage: Personal DPS"])
	Skada:RemoveFeed(L["Damage: Raid DPS"])
end

function dpsmod:OnEnable()
	Skada:AddMode(self)
end

function dpsmod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
 	GameTooltip:AddDoubleLine(L["DPS"], ("%02.1f"):format(getRaidDPS(set)), 1,1,1)
end

function mod:GetSetSummary(set)
	return Skada:FormatNumber(set.damage)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.damage then
		player.damage = 0
		player.damagespells = {}
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.damage then
		set.damage = 0
	end
end

local opts = {
	damageoptions = {
		type="group",
		name=L["Damage"],
		args={

			showdps = {
				type = "toggle",
				name = L["Do not show DPS"],
				desc = L["Hides DPS from the Damage mode."],
				get = function() return Skada.db.profile.modules.damagenodps end,
				set = function() Skada.db.profile.modules.damagenodps = not Skada.db.profile.modules.damagenodps end,
				order=2,
			},
					
		},
	}
}

function mod:OnInitialize()
	-- Add our options.
	table.insert(Skada.options.plugins, opts)
end
