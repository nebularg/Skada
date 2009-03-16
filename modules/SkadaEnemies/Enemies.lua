local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local done = Skada:NewModule("EnemyDoneMode")
local taken = Skada:NewModule("EnemyTakenMode")

local doneplayers = Skada:NewModule("EnemyDonePlayers")
local takenplayers = Skada:NewModule("EnemyTakenPlayers")

done.name = L["Enemy damage done"]
taken.name = L["Enemy damage taken"]

local function find_player(mob, name)
	for i, p in ipairs(mob.players) do
		if p.name == name then
			return p
		end
	end
	
	local player = {name = name, done = 0, taken = 0, class = select(2, UnitClass(name))}
	table.insert(mob.players, player)
	return player
end

local function log_damage_taken(set, dmg)
	set.mobtaken = set.mobtaken + dmg.amount
	
	if not set.mobs[dmg.dstName] then
		set.mobs[dmg.dstName] = {taken = 0, done = 0, players = {}}
	end
	
	local mob = set.mobs[dmg.dstName]
	
	mob.taken = set.mobs[dmg.dstName].taken + dmg.amount
	
	local player = find_player(mob, dmg.srcName)
	player.taken = player.taken + dmg.amount
end

local function log_damage_done(set, dmg)
	set.mobdone = set.mobdone + dmg.amount

	if not set.mobs[dmg.srcName] then
		set.mobs[dmg.srcName] = {taken = 0, done = 0, players = {}}
	end
	
	local mob = set.mobs[dmg.srcName]
	
	mob.done = mob.done + dmg.amount
	
	local player = find_player(mob, dmg.dstName)
	player.done = player.done + dmg.amount
end

local dmg = {}

local function SpellDamageTaken(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(4, ...)

		Skada:FixPets(dmg)
		log_damage_taken(Skada.current, dmg)
	end
end

local function SpellDamageDone(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(4, ...)

		log_damage_done(Skada.current, dmg)
	end
end

local function SwingDamageTaken(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(1,...)
		
		Skada:FixPets(dmg)
		log_damage_taken(Skada.current, dmg)
	end
end

local function SwingDamageDone(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	if srcName and dstName and srcGUID ~= dstGUID then
		dmg.dstName = dstName
		dmg.srcName = srcName
		dmg.amount = select(1,...)
		
		log_damage_done(Skada.current, dmg)
	end
end

function taken:Update(win, set)
	-- Calculate the highest damage.
	-- How to get rid of this iteration?
	local maxvalue = 0
	for name, mob in pairs(set.mobs) do
		if mob.taken > maxvalue then
			maxvalue = mob.taken
		end
	end
	
	-- For each mob in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for name, mob in pairs(set.mobs) do
		if mob.taken > 0 then
			local bar = win:GetBar(name)
			if bar then
				bar:SetMaxValue(maxvalue)
				bar:SetValue(mob.taken)
			else
				bar = win:CreateBar(name, name, mob.taken, maxvalue, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown",function(bar, button)
												if button == "LeftButton" then
													takenplayers.name = L["Damage on"].." "..name
													takenplayers.mob = mob
													win:DisplayMode(takenplayers)
												elseif button == "RightButton" then
												 	win:RightClick()
												end
											end)
				local color = win:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(Skada:FormatNumber(mob.taken))
		end
	end
	
	-- Sort the possibly changed bars.
	win:SortBars()
end

function done:Update(win, set)
	-- Calculate the highest damage.
	-- How to get rid of this iteration?
	local maxvalue = 0
	for name, mob in pairs(set.mobs) do
		if mob.done > maxvalue then
			maxvalue = mob.done
		end
	end
	
	-- For each mob in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for name, mob in pairs(set.mobs) do
		if mob.done > 0 then
			local bar = win:GetBar(name)
			if bar then
				bar:SetMaxValue(maxvalue)
				bar:SetValue(mob.done)
			else
				bar = win:CreateBar(name, name, mob.done, maxvalue, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown",function(bar, button)
												if button == "LeftButton" then
													doneplayers.name = L["Damage from"].." "..name
													doneplayers.mob = mob
													win:DisplayMode(doneplayers)
												elseif button == "RightButton" then
													win:RightClick()
												end
											end)
				local color = win:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(Skada:FormatNumber(mob.done))
		end
	end
	
	-- Sort the possibly changed bars.
	win:SortBars()
end

function doneplayers:Update(win, set)
	if self.mob then

		-- Calculate the highest damage.
		-- How to get rid of this iteration?
		local maxvalue = 0
		for name, player in ipairs(self.mob.players) do
			if player.done > maxvalue then
				maxvalue = player.done
			end
		end
		
		table.sort(self.mob.players, function(a,b) return a.done > b.done end)
		
		-- For each mob in the set, see if we have a bar already.
		-- If so, update values, else create bar.
		for i, player in ipairs(self.mob.players) do
			if player.done > 0 then
				local bar = win:GetBar(player.name)
				if bar then
					bar:SetMaxValue(maxvalue)
					bar:SetValue(player.done)
				else
					bar = win:CreateBar(player.name, player.name, player.done, maxvalue, nil, false)
					bar:EnableMouse()
					bar:SetScript("OnMouseDown",function(bar, button) if button == "RightButton" then win:DisplayMode(done) end end)
					local color = Skada.classcolors[player.class] or win:GetDefaultBarColor()
					bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
				end
				bar:SetTimerLabel(Skada:FormatNumber(player.done)..(" (%02.1f%%)"):format(player.done / self.mob.done * 100))
				bar:SetLabel(("%2u. %s"):format(i, player.name))
			end
		end
		
		-- Sort the possibly changed bars.
		win:SortBars()
	end
end

function takenplayers:Update(win, set)
	if self.mob then
		-- Calculate the highest damage.
		-- How to get rid of this iteration?
		local maxvalue = 0
		for name, player in ipairs(self.mob.players) do
			if player.taken > maxvalue then
				maxvalue = player.taken
			end
		end
		
		table.sort(self.mob.players, function(a,b) return a.taken > b.taken end)
		
		-- For each mob in the set, see if we have a bar already.
		-- If so, update values, else create bar.
		for i, player in ipairs(self.mob.players) do
			if player.taken > 0 then
				local bar = win:GetBar(player.name)
				if bar then
					bar:SetMaxValue(maxvalue)
					bar:SetValue(player.taken)
				else
					bar = win:CreateBar(player.name, player.name, player.taken, maxvalue, nil, false)
					bar:EnableMouse()
					bar:SetScript("OnMouseDown",function(bar, button) if button == "RightButton" then win:DisplayMode(taken) end end)
					local color = Skada.classcolors[player.class] or win:GetDefaultBarColor()
					bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
				end
				bar:SetTimerLabel(Skada:FormatNumber(player.taken)..(" (%02.1f%%)"):format(player.taken / self.mob.taken * 100))
				bar:SetLabel(("%2u. %s"):format(i, player.name))
			end
		end
		
		-- Sort the possibly changed bars.
		win:SortBars()
	end
end


function done:OnEnable()
	Skada:RegisterForCL(SpellDamageTaken, 'SPELL_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamageTaken, 'SPELL_PERIODIC_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamageTaken, 'SPELL_BUILDING_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SpellDamageTaken, 'RANGE_DAMAGE', {src_is_interesting = true})

	Skada:RegisterForCL(SpellDamageDone, 'SPELL_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamageDone, 'SPELL_PERIODIC_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamageDone, 'SPELL_BUILDING_DAMAGE', {dst_is_interesting_nopets = true})
	Skada:RegisterForCL(SpellDamageDone, 'RANGE_DAMAGE', {dst_is_interesting_nopets = true})

	Skada:RegisterForCL(SwingDamageTaken, 'SWING_DAMAGE', {src_is_interesting = true})
	Skada:RegisterForCL(SwingDamageDone, 'SWING_DAMAGE', {dst_is_interesting_nopets = true})
	
	Skada:AddMode(self)
end

function done:OnDisable()
	Skada:RemoveMode(self)
end

function taken:OnEnable()
	Skada:AddMode(self)
end

function taken:OnDisable()
	Skada:RemoveMode(self)
end

function done:GetSetSummary(set)
	return Skada:FormatNumber(set.mobdone)
end

function taken:GetSetSummary(set)
	return Skada:FormatNumber(set.mobtaken)
end

-- Called by Skada when a new set is created.
function done:AddSetAttributes(set)
	if not set.mobs then
		set.mobs = {}
		set.mobdone = 0
		set.mobtaken = 0
	end
end
