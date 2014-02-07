local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule(L["Deaths"])
local deathlog = Skada:NewModule(L["Death log"])

local SORtime = {}

local death_spell = 41220 -- Death

local function log_deathlog(set, playerid, playername, srcname, spellid, spellname, amount, timestamp, logoverride, healthoverride)
	local player = Skada:get_player(set, playerid, playername)
	local log = logoverride or player.deathlog
	local pos = log.pos or 1

        local entry = log[pos] 
	if not entry then
	  entry = {}
	  log[pos] = entry
	end
	entry.srcname =   srcname
	entry.spellid =   spellid
	entry.spellname = spellname
	entry.amount =	  amount
	entry.ts = 	  timestamp
	entry.hp = 	  healthoverride or UnitHealth(playername)

	pos = pos + 1
	if pos > 15 then pos = 1 end
	log.pos = pos
end

local function log_death(set, playerid, playername, timestamp)
	local player = Skada:get_player(set, playerid, playername)

	if player then
		-- Add a death along with it's timestamp.
		table.insert(player.deaths, 1, {["ts"] = timestamp, ["log"] = player.deathlog})

		-- Add a fake entry for the actual death.
		local spellid = death_spell
		local spellname = string.format(L["%s dies"], player.name)
		log_deathlog(set, playerid, playername, nil, spellid, spellname, 0, timestamp, nil, 0)

		for i,entry in ipairs(player.deathlog) do
			-- sometimes multiple close events arrive with the same timestamp
			-- add a small bias to ensure we preserve the order in which we recorded them
			-- this ensures sort stability (to prevent oscillation on :Update())
			-- and makes it more likely the health bar progression is correct
			entry.ts = entry.ts + i*0.0001
		end

		-- Also add to set deaths.
		set.deaths = set.deaths + 1

		-- Change to a new deathlog.
		player.deathlog = {}
	end
end

local function log_resurrect(set, playerid, playername, srcname, spellid, spellname, timestamp)
	local player = Skada:get_player(set, playerid, playername)

	-- Add log entry to to previous death.
	if player and player.deaths and player.deaths[1] then
		log_deathlog(set, playerid, playername, srcname, spellid, spellname, 0, timestamp, player.deaths[1].log, 0)
	end
end

local function log_SORdeath(set, playerid, playername, timestamp)
	local player = Skada:get_player(set, playerid, playername)

	local spellid = death_spell
	local spellname = string.format(L["%s dies"], GetSpellInfo(20711))

	-- Add log entry to to previous death.
	if player and player.deaths and player.deaths[1] then
		log_deathlog(set, playerid, playername, playername, spellid, spellname, 0, timestamp, player.deaths[1].log, 0)
	end

	-- this event is the death of the Spirit of Redemption who is immune to all damage, so the deathlog is meaningless
	if player and player.deathlog then
		wipe(player.deathlog)
	end
end

local function UnitDied(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if timestamp < (SORtime[dstGUID] or 0) + 20 then -- Spirit of Redemption lasts 15 sec, allow some padding for latency
		log_SORdeath(Skada.current, dstGUID, dstName, timestamp)
		log_SORdeath(Skada.total,   dstGUID, dstName, timestamp)
	elseif not UnitIsFeignDeath(dstName) then	-- Those pesky hunters
		log_death(Skada.current, dstGUID, dstName, timestamp)
		log_death(Skada.total, dstGUID, dstName, timestamp)
	end
end

local function AuraApplied(...)
        local spellId = select(9,...)
	if spellId == 27827 then -- Spirit of Redemption, Holy priest just died
		UnitDied(...)
		local dstGUID = select(6,...)
		SORtime[dstGUID] = ... -- timestamp
	end
end

local function Resurrect(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Resurrection.
	local spellId, spellName, spellSchool = ...

	log_resurrect(Skada.current, dstGUID, dstName, srcName, spellId, nil, timestamp)
	log_resurrect(Skada.total, dstGUID, dstName, srcName, spellId, nil, timestamp)
end

local function SpellDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Spell damage.
	local spellId, spellName, spellSchool, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...

	dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
	log_deathlog(Skada.current, dstGUID, dstName, srcName, spellId, nil, 0-samount, timestamp)
	log_deathlog(Skada.total, dstGUID, dstName, srcName, spellId, nil, 0-samount, timestamp)
end

local function SwingDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- White melee.
	local samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...
	local spellid = 88163

	dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
	log_deathlog(Skada.current, dstGUID, dstName, srcName, spellid, nil, 0-samount, timestamp)
	log_deathlog(Skada.total, dstGUID, dstName, srcName, spellid, nil, 0-samount, timestamp)
end

local function EnvironmentalDamage(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Environmental damage.
	local environmentalType, samount, soverkill, sschool, sresisted, sblocked, sabsorbed, scritical, sglancing, scrushing = ...

	dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
	log_deathlog(Skada.current, dstGUID, dstName, srcName, nil, environmentalType, 0-samount, timestamp)
	log_deathlog(Skada.total, dstGUID, dstName, srcName, nil, environmentalType, 0-samount, timestamp)
end

local function Instakill(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Instakill events
	local spellId, spellName, spellSchool = ...
	spellId = spellId or 80468

	dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
	log_deathlog(Skada.current, dstGUID, dstName, srcName, spellId, spellName, -1e9, timestamp)
	log_deathlog(Skada.total, dstGUID, dstName, srcName, spellId, spellName, -1e9, timestamp)
end

local function SpellHeal(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Healing
	local spellId, spellName, spellSchool, samount, soverhealing, absorbed, scritical = ...
	local srcName_modified
	samount = max(0, samount - soverhealing)

	srcGUID, srcName_modified = Skada:FixMyPets(srcGUID, srcName)
	dstGUID, dstName = Skada:FixMyPets(dstGUID, dstName)
	log_deathlog(Skada.current, dstGUID, dstName, (srcName_modified or srcName), spellId, nil, samount, timestamp)
	log_deathlog(Skada.total, dstGUID, dstName, (srcName_modified or srcName), spellId, nil, samount, timestamp)
end

-- Death meter.
function mod:Update(win, set)
	local nr = 1
	local max = 0

	for i, player in ipairs(set.players) do
		if player.deaths and #player.deaths > 0 then
			local d = win.dataset[nr] or {}
			win.dataset[nr] = d

			-- Find latest death timestamp.
			local maxdeathts = 0
			for j, death in ipairs(player.deaths) do
				if death.ts > maxdeathts then
					maxdeathts = death.ts
				end
			end

			d.id = player.id
			d.value = maxdeathts
			d.label = player.name
			d.class = player.class
			d.valuetext = Skada:FormatValueText(
										tostring(#player.deaths), self.metadata.columns.Deaths,
										date("%H:%M:%S", maxdeathts), self.metadata.columns.Timestamp
									)
			if maxdeathts > max then
				max = maxdeathts
			end

			nr = nr + 1
		end
	end

	win.metadata.maxvalue = max
end

function deathlog:Enter(win, id, label)
	deathlog.playerid = id
	deathlog.title = label..L["'s Death"]
end

local green = {r = 0, g = 255, b = 0, a = 1}
local red = {r = 255, g = 0, b = 0, a = 1}

-- Death log.
function deathlog:Update(win, set)
	local player = Skada:get_player(set, self.playerid)

	if player and player.deaths then
		local nr = 1

		-- Sort deaths.
		table.sort(player.deaths, function(a,b) return a and b and a.ts > b.ts end)

		for i, death in ipairs(player.deaths) do
			-- Sort log entries.
			table.sort(death.log, function(a,b) return a and b and a.ts > b.ts end)

			for j, log in ipairs(death.log) do
				local diff = tonumber(log.ts) - tonumber(death.ts)
				-- Ignore hits older than 30s before death.
				if diff > -30 or diff > 0 then

					local d = win.dataset[nr] or {}
					win.dataset[nr] = d

					d.id = nr
					local spellid = log.spellid or 88163 -- "Attack" spell
					local spellname = log.spellname or GetSpellInfo(spellid)
					local rspellname
					if spellid == death_spell then
						rspellname = spellname -- nicely formatted death message
					else
						rspellname = GetSpellLink(spellid) or spellname	
					end
					local label
					if log.ts >= death.ts then
						label = date("%H:%M:%S", log.ts).. ": "
					else
						label = ("%2.2f"):format(diff) .. ": "
					end
					if log.srcname then 
						label = label..log.srcname..L["'s "]
					end
					d.label =       label..spellname
					d.reportlabel = label..rspellname
					d.ts = log.ts
					d.value = log.hp or 0
					local _, _, icon = GetSpellInfo(spellid)
					d.icon = icon
					d.spellid = spellid

					local change = Skada:FormatNumber(math.abs(log.amount))
					if log.amount > 0 then
						change = "+"..change
					else
						change = "-"..change
					end

					if log.ts > death.ts then
						d.valuetext = ""
					else
						d.valuetext = Skada:FormatValueText(
													change, self.metadata.columns.Change,
													Skada:FormatNumber(log.hp or 0), self.metadata.columns.Health,
													string.format("%02.1f%%", (log.hp or 1) / (player.maxhp or 1) * 100), self.metadata.columns.Percent
												)
					end

					if log.amount >= 0 then
						d.color = green
					else
						d.color = red
					end

					nr = nr + 1
				end
			end
		end

		win.metadata.maxvalue = player.maxhp
	end
end

function mod:OnEnable()
	mod.metadata 		= {click1 = deathlog, columns = {Deaths = true, Timestamp = true}}
	deathlog.metadata 	= {ordersort = true, columns = {Change = true, Health = false, Percent = true}}

	Skada:RegisterForCL(UnitDied, 'UNIT_DIED', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(AuraApplied, 'SPELL_AURA_APPLIED', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(SpellDamage, 'SPELL_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamage, 'SPELL_PERIODIC_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamage, 'SPELL_BUILDING_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamage, 'RANGE_DAMAGE', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(SwingDamage, 'SWING_DAMAGE', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(EnvironmentalDamage, 'ENVIRONMENTAL_DAMAGE', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(Instakill, 'SPELL_INSTAKILL', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(Instakill, 'RANGE_INSTAKILL', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(SpellHeal, 'SPELL_HEAL', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellHeal, 'SPELL_PERIODIC_HEAL', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(Resurrect, 'SPELL_RESURRECT', {dst_is_interesting_nopets = true})

	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

-- Called by Skada when a set is complete.
function mod:SetComplete(set)
	-- Clean
	for i, player in ipairs(set.players) do
		-- Remove pending logs
		wipe(player.deathlog)
		player.deathlog = nil
		-- Remove deaths collection from all who did not die
		if #player.deaths == 0 then
			wipe(player.deaths)
			player.deaths = nil
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
	if not player.deaths or type(player.deaths) ~= "table" then
		player.deathlog = {}
		player.deaths = {}
		player.maxhp = UnitHealthMax(player.name)
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.deaths then
		set.deaths = 0
	end
end
