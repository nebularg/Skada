Skada = LibStub("AceAddon-3.0"):NewAddon("Skada", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "SpecializedLibBars-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")
local win = LibStub("LibWindow-1.1")
local media = LibStub("LibSharedMedia-3.0")

local dataobj = ldb:NewDataObject("Skada", {type = "data source", icon = "Interface\\Icons\\Spell_Lightning_LightningBolt01", text = ""})

-- All saved sets
local sets = {}

-- The current set
local current = nil

-- The total set
local total = nil

-- The selected mode and set
local selectedmode = nil
local selectedset = nil

-- Mode and set to return to after combat.
local restore_mode = nil
local restore_set = nil

-- Modes - these are modules, really. Modeules?
local modes = {}

-- Pets; an array of pets and their owners.
local pets = {}

function Skada:OnInitialize()
	-- Register some SharedMedia goodies.
	media:Register("font", "Adventure",				[[Interface\Addons\Skada\fonts\Adventure.ttf]])
	media:Register("font", "ABF",					[[Interface\Addons\Skada\fonts\ABF.ttf]])
	media:Register("font", "Vera Serif",			[[Interface\Addons\Skada\fonts\VeraSe.ttf]])
	media:Register("font", "Diablo",				[[Interface\Addons\Skada\fonts\Avqest.ttf]])
	media:Register("font", "Accidental Presidency",	[[Interface\Addons\Skada\fonts\Accidental Presidency.ttf]])
	media:Register("statusbar", "Aluminium",		[[Interface\Addons\Skada\statusbar\Aluminium]])
	media:Register("statusbar", "Armory",			[[Interface\Addons\Skada\statusbar\Armory]])
	media:Register("statusbar", "BantoBar",			[[Interface\Addons\Skada\statusbar\BantoBar]])
	media:Register("statusbar", "Glaze2",			[[Interface\Addons\Skada\statusbar\Glaze2]])
	media:Register("statusbar", "Gloss",			[[Interface\Addons\Skada\statusbar\Gloss]])
	media:Register("statusbar", "Graphite",			[[Interface\Addons\Skada\statusbar\Graphite]])
	media:Register("statusbar", "Grid",				[[Interface\Addons\Skada\statusbar\Grid]])
	media:Register("statusbar", "Healbot",			[[Interface\Addons\Skada\statusbar\Healbot]])
	media:Register("statusbar", "LiteStep",			[[Interface\Addons\Skada\statusbar\LiteStep]])
	media:Register("statusbar", "Minimalist",		[[Interface\Addons\Skada\statusbar\Minimalist]])
	media:Register("statusbar", "Otravi",			[[Interface\Addons\Skada\statusbar\Otravi]])
	media:Register("statusbar", "Outline",			[[Interface\Addons\Skada\statusbar\Outline]])
	media:Register("statusbar", "Perl",				[[Interface\Addons\Skada\statusbar\Perl]])
	media:Register("statusbar", "Smooth",			[[Interface\Addons\Skada\statusbar\Smooth]])

	-- DB
	self.db = LibStub("AceDB-3.0"):New("SkadaDB", self.defaults)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada", self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada", "Skada")

	-- Profiles
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada-Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada-Profiles", "Profiles", "Skada")

	-- Window
	self.bargroup = self:NewBarGroup("Skada", nil, self.db.profile.barwidth, self.db.profile.barheight, "SkadaBarWindow")
	self.bargroup.RegisterCallback(self,"AnchorMoved")
	self.bargroup.RegisterCallback(self,"AnchorClicked")
	self.bargroup:EnableMouse(true)
	self.bargroup:SetScript("OnMouseDown", function(self, button) if button == "RightButton" then Skada:RightClick() end end)
	self:ApplySettings()
	self.bargroup:HideIcon()
	if self.db.profile.window.shown then
		self.bargroup:Show()
	else
		self.bargroup:Hide()
	end
	
	-- Restore window position.
	win.RegisterConfig(self.bargroup, self.db.profile)
	win.RestorePosition(self.bargroup)

	-- Minimap button.
	icon:Register("Skada", dataobj, self.db.profile.icon)
	icon:Show("Skada")
	
	self:RegisterChatCommand("skada", "OpenOptions")
	self:RegisterChatCommand("skadapets", "PetDebug")
end

function Skada:AnchorClicked(cbk, group, button)
	if button == "RightButton" then
		Skada:RightClick()
	end
end

function Skada:AnchorMoved(cbk, group, x, y)
	win.SavePosition(self.bargroup)
end

function Skada:OpenOptions()
	InterfaceOptionsFrame_OpenToCategory("Skada")
end

function Skada:PetDebug()
	self:CheckPets()
self:Print("pets:")
	for pet, owner in pairs(pets) do
		self:Print("pet "..pet.." belongs to ".. owner.id..", "..owner.name)
	end
end

function Skada:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	
	self:ScheduleRepeatingTimer("UpdateBars", 0.5, nil)
	self:ScheduleRepeatingTimer("Tick", 1, nil)
--	self:ScheduleRepeatingTimer("CheckPets", 60, nil)
end

local function CheckPet(unit, pet)
--	DEFAULT_CHAT_FRAME:AddMessage("checking out "..pet)

	local petGUID = UnitGUID(pet)
	local unitGUID = UnitGUID(unit)
	local unitName = UnitName(unit)
--	local c, c2 = UnitClass(pet)
	
--	if c then
--		DEFAULT_CHAT_FRAME:AddMessage("c = "..c..", c2 = "..c2)
--	end
	-- Add to pets if it does not already exist.
	-- TODO: We have a problem here with stale data. We could remove
	-- any existing pet when we add one, but this would not work with Mirror Image
	-- and other effects with multiple pets per player.
	if petGUID and unitGUID and unitName and not pets[petGUID] then
--DEFAULT_CHAT_FRAME:AddMessage("ahaa! "..petGUID.." belong to "..unitGUID..", "..unitName)
		pets[petGUID] = {id = unitGUID, name = unitName}
	end
end

function Skada:CheckPets()
--DEFAULT_CHAT_FRAME:AddMessage("checking out pets")
	if GetNumRaidMembers() > 0 then
		-- In raid.
		for i = 1, GetNumRaidMembers(), 1 do
			if UnitExists("raid"..i.."pet") then
				CheckPet("raid"..i, "raid"..i.."pet")
			end
		end
	elseif GetNumPartyMembers() > 0 then
		-- In party.
		for i = 1, GetNumPartyMembers(), 1 do
			if UnitExists("party"..i.."pet") then
				CheckPet("party"..i, "party"..i.."pet")
			end
		end
	end
	
	-- Solo. Always check.
	if UnitExists("pet") then
		CheckPet("player", "pet")
	end
end

function Skada:PLAYER_ENTERING_WORLD()
	-- Check for pets.
	self:CheckPets()
end

function Skada:PARTY_MEMBERS_CHANGED()
	-- Check for new pets.
	self:CheckPets()
end

function Skada:RAID_ROSTER_UPDATE()
	-- Check for new pets.
	self:CheckPets()
end

function Skada:UNIT_PET()
	-- Check for new pets.
	self:CheckPets()
end


function Skada:OnDisable()
	-- Save some settings.
	self.db.profile.selectedset = selectedset
	if selectedmode then
		self.db.profile.set = selectedmode.name
	else
		self.db.profile.mode = nil
	end
end

function Skada:ToggleWindow()
	if self.bargroup:IsShown() then
		self.db.profile.window.shown = false
		self.bargroup:Hide()
	else
		self.db.profile.window.shown = true
		self.bargroup:Show()
	end
end

function Skada:Reset()
	self:RemoveAllBars()
	if set then
		set.changed = true
	end
	
	if current ~= nil then
		current = {players = {}, damage = 0, damagetaken = 0, healing = 0, dispells = 0, overhealing = 0, deaths = 0, name = "Current", starttime = time()}
	end
	if total ~= nil then
		total = {players = {}, damage = 0, damagetaken = 0, healing = 0, dispells = 0, overhealing = 0, deaths = 0, name = "Total", starttime = time()}
	end
	
	sets = {}
	
	self:Print("All data has been reset.")
end

-- Applies settings to things like the bar window.
function Skada:ApplySettings()
	self.bargroup:SetOrientation(self.db.profile.barorientation)
	self.bargroup:SetHeight(self.db.profile.barheight)
	self.bargroup:SetWidth(self.db.profile.barwidth)
	self.bargroup:SetTexture(media:Fetch('statusbar', self.db.profile.bartexture))
	self.bargroup:SetFont(media:Fetch('font', self.db.profile.barfont), self.db.profile.barfontsize)
	self.bargroup:SetSpacing(self.db.profile.barspacing)
	self.bargroup:UnsetAllColors()
	self.bargroup:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
	self.bargroup:SetMaxBars(self.db.profile.barmax)
	self.bargroup:SortBars()
end

-- Our scheme for segmenting fights:
-- Each second, if player is not in combat and is not dead and we have an active set (current), close up shop.
-- We can not simply rely on PLAYER_REGEN_ENABLED since it is fired if we die and the fight continues.
function Skada:Tick()
	if current and not InCombatLockdown() and not UnitIsDead("player") then
	
		-- Unless this a trivial set
		if current.mobname ~= nil then
			-- End current set.
			current.endtime = time()
			current.name = current.mobname
			table.insert(sets, 1, current)
		end
		
		-- Reset current set.
		current = nil
		
		-- Trim segments.
		while table.maxn(sets) > 10 do
			table.remove(sets)
		end
		
		self:RemoveAllBars()
		local set = self:get_selected_set()
		if set then
			set.changed = 1
		end
		self:UpdateBars()
		
		-- Auto-switch back to previous set/mode.
		if self.db.profile.returnaftercombat and restore_mode and restore_set then
			if restore_set ~= selectedset or restore_mode ~= selectedmode then
--				self:Print("Switching back to "..restore_mode.." mode.")
				
				self:RestoreView(restore_set, restore_mode)
				
				restore_mode = nil
				restore_set = nil
			end
		end
		
	end
end

local function find_mode(name)
	for i, mode in ipairs(modes) do
		if mode.name == name then
			return mode
		end
	end
end

function Skada:PLAYER_REGEN_DISABLED()
	-- Start a new set if we are not in one already.
	if not current then
		current = {players = {}, name = "Current", starttime = time(), changed = true}

--damage = 0, damagetaken = 0, healing = 0, dispells = 0, overhealing = 0, deaths = 0,
		
		-- Tell each mode to apply its needed attributes.
		for i, mode in ipairs(modes) do
			if mode.AddSetAttributes ~= nil then
				mode:AddSetAttributes(current)
			end
		end

		-- Also start the total set if it is nil.
		if total == nil then
			total = {players = {}, name = "Total", starttime = time(), changed = true}
			
			-- Tell each mode to apply its needed attributes.
			for i, mode in ipairs(modes) do
				if mode.AddSetAttributes ~= nil then
					mode:AddSetAttributes(total)
				end
			end
		end
		
		-- Auto-switch set/mode if configured.
		if self.db.profile.modeincombat ~= "" then
			-- First, get the mode. The mode may not actually be available.
			local mymode = find_mode(self.db.profile.modeincombat)
			
			-- If the mode exists, switch to current set and this mode. Save current set/mode so we can return after combat if configured.
			if mymode ~= nil then
--				self:Print("Switching to "..mymode.name.." mode.")
				
				if self.db.profile.returnaftercombat then
					if selectedset then
						restore_set = selectedset
					end
					if selectedmode then
						restore_mode = selectedmode.name
					end
				end
				
				selectedset = "current"
				self:DisplayMode(mymode)
			end
		end
	end
end

-- Attempts to restore a view (set and mode).
-- Set is either the set name ("total", "current"), or an index.
-- Mode is the name of a mode.
function Skada:RestoreView(theset, themode)
	-- Set the... set. If no such set exists, set to current.
	if theset and type(theset) == "string" and (theset == "current" or theset == "total") then
		selectedset = theset
	elseif theset and type(theset) == "number" and theset <= table.maxn(sets) then
		selectedset = theset
	else
		selectedset = "current"
	end
	
	-- Force an update.
	local set = self:get_selected_set()
	if set then
		set.changed = true
	end
	
	-- Find the mode. The mode may not actually be available.
	if themode then
		local mymode = nil
		for i, m in ipairs(modes) do
			if m.name == themode then
				mymode = m
			end
		end
	
		-- If the mode exists, switch to this mode.
		-- If not, show modes.
		if mymode then
--			self:Print("Switching to "..mymode.name.." mode.")
			self:DisplayMode(mymode)
		else
			self:DisplayModes(selectedset)
		end
	end
end

function Skada:get_player(set, playerid, playername)
	-- Add player to set if it does not exist.
	local player = nil
	for i, p in ipairs(set.players) do
		if p.id == playerid then
			player = p
		end
	end
	
	if not player then
		player = {id = playerid, class = select(2, UnitClass(playername)), name = playername, first = time()}
		
		-- Tell each mode to apply its needed attributes.
		for i, mode in ipairs(modes) do
			if mode.AddPlayerAttributes ~= nil then
				mode:AddPlayerAttributes(player)
			end
		end
		
		table.insert(set.players, player)
	end
	
	-- Mark now as the last time player did something worthwhile.
	player.last = time()
	return player
end



function Skada:UnitIsInteresting(name)
	return name and (UnitIsUnit("player",name) or UnitIsUnit("pet",name) or UnitPlayerOrPetInRaid(name) or UnitPlayerOrPetInParty(name))
end

function Skada:UnitIsInterestingNoPets(name)
	return name and (UnitIsUnit("player",name) or UnitInRaid(name) or UnitInParty(name))
end

-- Modify objects if they are pets.
-- Expects to find "playerid", "playername", and optionally "spellname" in the object.
-- Playerid and playername are exchanged for the pet owner's, and spellname is modified to include pet name.
function Skada:FixPets(action)
	if action and not UnitIsPlayer(action.playername) then
		local pet = pets[action.playerid]
		if pet then
			if action.spellname then
				action.spellname = action.playername..": "..action.spellname
			end
			action.playername = pet.name
			action.playerid = pet.id
		end
	end

end

function Skada:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Pet summons.
	-- Pet scheme: save the GUID in a table along with the GUID of the owner.
	-- Note to self: this needs 1) to be made self-cleaning so it can't grow too much, and 2) saved persistently.
	-- Now also done on raid roster/party changes.
	if eventtype == 'SPELL_SUMMON' then
		pets[dstGUID] = {id = srcGUID, name = srcName}
	end

	-- This line will determine if the src player is being tracked.
	if current and srcName and self:UnitIsInteresting(srcName) then
		-- Store mob name for set name. For now, just save first name available, or if mob is a boss, re-save.
		if dstName and not UnitIsFriend("player",dstName) and (current.mobname == nil or UnitClassification(dstName) == "worldboss") then
			current.mobname = dstName
		end
	end
end

--
-- Data broker
--
function dataobj:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPLEFT", self, "BOTTOMLEFT")
    GameTooltip:ClearLines()
    
    local set = Skada:get_selected_set()
    if set then
	    GameTooltip:AddLine(L["Skada summary"], 0, 1, 0)
	    for i, mode in ipairs(modes) do
	    	if mode.AddToTooltip ~= nil then
	    		mode:AddToTooltip(set, GameTooltip)
	    	end
	    end
 	end
 	
    GameTooltip:AddLine(L["Hint: Left-Click to toggle Skada window."], 0, 1, 0)
    GameTooltip:AddLine(L["Shift + Left-Click to reset."], 0, 1, 0)
    GameTooltip:AddLine(L["Right-click to configure"], 0, 1, 0)
    
    GameTooltip:Show()
end

function dataobj:OnLeave()
    GameTooltip:Hide()
end

function dataobj:OnClick(button)
	if button == "LeftButton" and IsShiftKeyDown() then
		Skada:Reset()
	elseif button == "LeftButton" then
		Skada:ToggleWindow()
	elseif button == "RightButton" then
		Skada:OpenOptions()
	end
end

--
-- Window
--

-- If selectedset is "current", returns current set if we are in combat, otherwise returns the last set.
function Skada:get_selected_set()
	if selectedset == "current" then
		if current == nil then
			return sets[1]
		else
			return current
		end
	elseif selectedset == "total" then
		return total
	else
		return sets[selectedset]
	end
end

function Skada:get_selected_player(set, playerid)
	for i, player in ipairs(set.players) do
		if player.id == playerid then
			return player
		end
	end
end

function Skada:IsDataCollectionActive()
	return current ~= nil
end

function Skada:GetCurrentSet()
	return current
end

function Skada:GetTotalSet()
	return total
end

-- Snatched from Recount
Skada.classcolors = {
				["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45, a=1 },
				["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79, a=1 },
				["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0, a=1 },
				["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73, a=1 },
				["MAGE"] = { r = 0.41, g = 0.8, b = 0.94, a=1 },
				["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41, a=1 },
				["DRUID"] = { r = 1.0, g = 0.49, b = 0.04, a=1 },
				["SHAMAN"] = { r = 0.14, g = 0.35, b = 1.0, a=1 },
				["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43, a=1 },
				["DEATHKNIGHT"] = { r = 0.77, g = 0.12, b = 0.23, a=1 },
				["PET"] = { r = 0.09, g = 0.61, b = 0.55, a=1 },
				["MOB"] = { r = 0.58, g = 0.24, b = 0.63, a=1 },
				["UNKNOWN"] = { r = 0.1, g = 0.1, b = 0.1, a=1 },
				["HOSTILE"] = { r = 0.7, g = 0.1, b = 0.1, a=1 },
				["UNGROUPED"] = { r = 0.63, g = 0.58, b = 0.24, a=1 },
}

function Skada:UpdateBars()
	if selectedmode then

		local set = self:get_selected_set()
		
		-- If we have a set and this set has been changed since our last update, go on.
		if set and set.changed then
			-- Let mode handle the rest.
			selectedmode:Update(set)
			
			-- Mark set as unchanged.
			set.changed = false
		end
		
	elseif selectedset then
		-- View available modes.

		for i, mode in ipairs(modes) do
			local bar = self.bargroup:GetBar(mode.name)
			if not bar then
--				self:Print("mode "..mode.name.." not found; creating")
				bar = self.bargroup:NewCounterBar(mode.name, mode.name, 1, 1, nil, false)
				bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayMode(mode) elseif button == "RightButton" then Skada:RightClick() end end)
			end
		end
		
	else
		-- View available sets.
		local bar = self.bargroup:GetBar("Total")
		if bar then
			-- Potentially update name or something
		else
			bar = self.bargroup:NewCounterBar("total", "Total", 1, 1, nil, false)
			bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
			bar:EnableMouse(true)
			bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes("total") elseif button == "RightButton" then Skada:RightClick() end end)
		end

		local bar = self.bargroup:GetBar("Current")
		if bar then
			-- Potentially update name or something
		else
			bar = self.bargroup:NewCounterBar("current", "Current", 1, 1, nil, false)
			bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
			bar:EnableMouse(true)
			bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes("current") elseif button == "RightButton" then Skada:RightClick() end end)
		end

		for i, set in ipairs(sets) do
		
			local bar = self.bargroup:GetBar(tostring(set.starttime))
			if bar then
				-- Potentially update name or something
			else
				bar = self.bargroup:NewCounterBar(tostring(set.starttime), set.name, 1, 1, nil, false)
				bar:SetTimerLabel(date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime))
				bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes(set.starttime) elseif button == "RightButton" then Skada:RightClick() end end)
			end
			
		end
	end
end

function Skada:GetModes()
	return modes
end

function Skada:AddMode(mode)
	table.insert(modes, mode)
	
	-- Set this mode as the active mode if it matches the saved one.
	-- Bit of a hack.
	if mode.name == self.db.profile.mode then
		self:RestoreView(selectedset, mode.name)
	end
end

function Skada:RemoveMode(mode)
	table.remove(modes, mode)
end

function Skada:GetDefaultBarColor()
	return self.db.profile.barcolor
end

function Skada:GetBarGroup()
	return self.bargroup
end

function Skada:SortBars()
	self.bargroup:SortBars()
end

function Skada:GetBars()
	return self.bargroup:GetBars()
end

function Skada:GetBar(name)
	return self.bargroup:GetBar(name)
end

function Skada:RemoveBar(bar)
	self.bargroup:RemoveBar(bar)
end

function Skada:CreateBar(name, label, value, maxvalue, icon, o)
	return self.bargroup:NewCounterBar(name, label, value, maxvalue, icon, o)
end

function Skada:RemoveAllBars()
	local bars = self.bargroup:GetBars()
	if bars then
		for i, bar in pairs(bars) do
			bar:Hide()
			self.bargroup:RemoveBar(bar)
		end
	end
	self.bargroup:SortBars()
end

-- Sets up the mode view.
function Skada:DisplayMode(mode)
	self:RemoveAllBars()

	selectedplayer = nil
	selectedspell = nil
	selectedmode = mode

	-- Save for posterity.
	self.db.profile.mode = selectedmode.name

	self.bargroup.button:SetText(mode.name)

	-- Force re-display
	local set = self:get_selected_set()
	if set then
		set.changed = true
	end

	self:UpdateBars()
end

-- Sets up the mode list.
function Skada:DisplayModes(settime)
	self:RemoveAllBars()

	selectedplayer = nil
	selectedspell = nil
	selectedmode = nil

	self.bargroup.button:SetText("Skada: Modes")

	-- Find the selected set
	if settime == "current" or settime == "total" then
		selectedset = settime
	else
	
		for i, set in ipairs(sets) do
			if set.starttime == settime then
				if set.name == "Current" then
					selectedset = "current"
				elseif set.name == "Total" then
					selectedset = "total"
				else
					selectedset = i
				end
			end
		end
		
	end

	self:UpdateBars()
end

-- Sets up the set list.
function Skada:DisplaySets()
	self:RemoveAllBars()
	
	selectedspell = nil
	selectedplayer = nil
	selectedmode = nil
	selectedset = nil

	self.bargroup.button:SetText("Skada: Fights")
	
	self:UpdateBars()
end

function Skada:RightClick(group, button)
--	self:Print("rightclick!")
	-- Step up one level.
	-- Levels are:
	-- 1. Sets
	-- 2. Type
	-- 3. A mode
	if selectedmode then
		self:DisplayModes(selectedset)
	elseif selectedset then
		self:DisplaySets()
	else
		-- Top level. Do nothing.
	end
end

function Skada:FormatNumber(number)
	if number > 1000000 then
		return 	("%02.1fM"):format(number / 1000000)
	else
		return 	("%02.1fK"):format(number / 1000)
	end
end
