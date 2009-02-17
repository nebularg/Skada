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

-- Flag marking if we need an update.
local changed = true

-- Flag for if we were in a prarty/raid. Set first time in PLAYER_ENTERING_WORLD.
local wasinparty = false

-- By default we just use RAID_CLASS_COLORS as class colors.
Skada.classcolors = RAID_CLASS_COLORS

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
	self:ShowMMButton(self.db.profile.mmbutton)
	
	self:RegisterChatCommand("skada", "Command")
end

function Skada:Command(param)
	if param == "pets" then
		self:PetDebug()
	elseif param == "reset" then
		self:Reset()
	elseif param == "config" then
		self:OpenOptions()
	elseif param == "report" then
		self:Report()
	else
		self:Print("Usage:")
		self:Print(("%-20s %-s"):format("/skada report",L["reports the active mode"]))
		self:Print(("%-20s %-s"):format("/skada reset",L["resets all data"]))
		self:Print(("%-20s %-s"):format("/skada config",L["opens the configuration window"]))
	end
end

-- Sends a report of the currently active set and mode to chat. 
function Skada:Report()
	local set = self:get_selected_set()
	local mode = selectedmode
	
	if set and mode then
		-- Title
		local endtime = set.endtime or time()
		SendChatMessage(string.format(L["Skada report on %s for %s, %s to %s:"], selectedmode.name, set.name, date("%X",set.starttime), date("%X",endtime)), "SAY")
		
		-- For each active bar, print label and timer value.
		for name, bar in pairs(self:GetBars()) do
			if bar:IsShown() then -- Do not show bars not shown (due to maxbars limit).
				SendChatMessage(("%s   %s"):format(bar:GetLabel(), bar:GetTimerLabel()))
			end
		end
	end
end

function Skada:ShowMMButton(show)
	if show then
		icon:Show("Skada")
	else
		icon:Hide("Skada")
	end
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
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UNIT_PET")
	
	self:ScheduleRepeatingTimer("UpdateBars", 0.5, nil)
	self:ScheduleRepeatingTimer("Tick", 1, nil)
	
	if type(CUSTOM_CLASS_COLORS) == "table" then
		Skada.classcolors = CUSTOM_CLASS_COLORS
	end
	
end

local function CheckPet(unit, pet)
--	DEFAULT_CHAT_FRAME:AddMessage("checking out "..pet)

	local petGUID = UnitGUID(pet)
	local unitGUID = UnitGUID(unit)
	local unitName = UnitName(unit)

	-- Add to pets if it does not already exist.
	-- TODO: We have a problem here with stale data. We could remove
	-- any existing pet when we add one, but this would not work with Mirror Image
	-- and other effects with multiple pets per player.
	if petGUID and unitGUID and unitName and not pets[petGUID] then
		pets[petGUID] = {id = unitGUID, name = unitName}
	end
end

function Skada:CheckPets()
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

local wasininstance

local function ask_for_reset()
	StaticPopupDialogs["ResetSkadaDialog"] = {
						text = "Do you want to reset Skada?", 
						button1 = ACCEPT, 
						button2 = CANCEL,
						timeout = 30, 
						whileDead = 0, 
						hideOnEscape = 1, 
						OnAccept = function() Skada:Reset() end,
					}
	StaticPopup_Show("ResetSkadaDialog")
end

-- Fired on entering a zone.
function Skada:PLAYER_ENTERING_WORLD()
	-- Check if we are entering an instance.
	local inInstance, instanceType = IsInInstance()
	local isininstance = inInstance and (instanceType == "party" or instanceType == "raid")

	-- If we are entering an instance, and we were not previously in an instance, and we got this event before...
	if isininstance and wasininstance ~= nil and not wasininstance and self.db.profile.reset.instance ~= 1 then
		if self.db.profile.reset.instance == 3 then
			ask_for_reset()
		else
			self:Reset()
		end
	end

	-- Save a flag marking our previous (current) instance status.
	if isininstance then
		wasininstance = true
	else
		wasininstance = false
	end

	-- Mark our last party status. This is done so that the flag is set to correct value on relog/reloadui.
	wasinparty = (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)

	-- Check for pets.
	self:CheckPets()
end

-- Check if we join a party/raid.
local function check_for_join_and_leave()
	if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 and wasinparty then
		-- We left a party.
		
		if Skada.db.profile.reset.leave == 3 then
			ask_for_reset()
		elseif Skada.db.profile.reset.leave == 2 then
			Skada:Reset()
		end
	end

	if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) and not wasinparty then
		-- We joined a raid.
		
		if Skada.db.profile.reset.join == 3 then
			ask_for_reset()
		elseif Skada.db.profile.reset.join == 2 then
			Skada:Reset()
		end
		
	end

	-- Mark our last party status.
	wasinparty = (GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0)
end

function Skada:PARTY_MEMBERS_CHANGED()
	check_for_join_and_leave()
	
	-- Check for new pets.
	self:CheckPets()
end

function Skada:RAID_ROSTER_UPDATE()
	check_for_join_and_leave()
	
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

local function createSet(setname)
	local set = {players = {}, name = setname, starttime = time(), ["time"] = 0}

	-- Tell each mode to apply its needed attributes.
	for i, mode in ipairs(modes) do
		if mode.AddSetAttributes ~= nil then
			mode:AddSetAttributes(set)
		end
	end

	return set
end

function Skada:Reset()
	self:RemoveAllBars()
	
	if current ~= nil then
		current = createSet(L["Current"])
	end
	if total ~= nil then
		total = createSet(L["Total"])
	end
	
	sets = {}
	
	self:Print(L["All data has been reset."])
end

-- Applies settings to things like the bar window.
function Skada:ApplySettings()
	self.bargroup:ReverseGrowth(self.db.profile.reversegrowth)
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
	if self.db.profile.barslocked then
		self.bargroup:Lock()
	else
		self.bargroup:Unlock()
	end	
end

-- Iterates over all players in a set and adds to the "time" variable
-- the time between first and last action.
local function setPlayerActiveTimes(set)
	for i, player in ipairs(set.players) do
		if player.last then
			player.time = player.time + (player.last - player.first)
		end
	end
end

-- Our scheme for segmenting fights:
-- Each second, if player is not in combat and is not dead and we have an active set (current), close up shop.
-- We can not simply rely on PLAYER_REGEN_ENABLED since it is fired if we die and the fight continues.
function Skada:Tick()
	if current and not InCombatLockdown() and not UnitIsDead("player") then
	
		-- Save current set unless this a trivial set, or if we have the Only keep boss fights options on, and no boss in fight.
		if not self.db.profile.onlykeepbosses or current.gotboss then
			if current.mobname ~= nil then
				-- End current set.
				current.endtime = time()
				current.time = current.endtime - current.starttime
				setPlayerActiveTimes(current)
				current.name = current.mobname
				table.insert(sets, 1, current)
			end
		end
		
		-- Add time spent to total set as well.
		total.time = total.time + current.time
		setPlayerActiveTimes(total)
		
		-- Set player.first and player.last to nil in total set.
		-- Neccessary since first and last has no relevance over an entire raid.
		-- Modes should look at the "time" value if available.
		for i, player in ipairs(total.players) do
			player.first = nil
			player.last = nil
		end
		
		-- Reset current set.
		current = nil
		
		-- Trim segments.
		while table.maxn(sets) > 10 do
			table.remove(sets)
		end
		
		self:RemoveAllBars()
		changed = true
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
		-- Remove old bars.
		self:RemoveAllBars()
		
		-- Create a new current set.
		current = createSet(L["Current"])

		-- Also start the total set if it is nil.
		if total == nil then
			total = createSet(L["Total"])
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
	changed = true
	
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

-- Returns a player from the current.
function Skada:get_player(set, playerid, playername)
	-- Add player to set if it does not exist.
	local player = nil
	for i, p in ipairs(set.players) do
		if p.id == playerid then
			player = p
		end
	end
	
	if not player then
		player = {id = playerid, class = select(2, UnitClass(playername)), name = playername, first = time(), ["time"] = 0}
		
		-- Tell each mode to apply its needed attributes.
		for i, mode in ipairs(modes) do
			if mode.AddPlayerAttributes ~= nil then
				mode:AddPlayerAttributes(player)
			end
		end
		
		table.insert(set.players, player)
	end
	
	-- The total set clears out first and last timestamps.
	if not player.first then
		player.first = time()
	end
	
	-- Mark now as the last time player did something worthwhile.
	player.last = time()
	return player
end

-- Save boss name and mark set as having a boss.
function Skada:UNIT_TARGET(event, unitId)
	if current and unitId and (UnitClassification(unitId.."target") == "worldboss" or UnitClassification(unitId.."target") == "boss") and not current.gotboss then
		current.gotboss = true
		current.mobname = UnitName(unitId.."target")
	end
end

function Skada:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Pet summons.
	-- Pet scheme: save the GUID in a table along with the GUID of the owner.
	-- Note to self: this needs 1) to be made self-cleaning so it can't grow too much, and 2) saved persistently.
	-- Now also done on raid roster/party changes.
	if eventtype == 'SPELL_SUMMON' and self:UnitIsInterestingNoPets(srcName) then
		pets[dstGUID] = {id = srcGUID, name = srcName}
	end

	if current and srcName and self:UnitIsInteresting(srcName) then
		-- Store mob name for set name. For now, just save first unfriendly name available.
		if dstName and not UnitIsFriend("player",dstName) and current.mobname == nil then
			current.mobname = dstName
		end
		
	end
	
	-- If we are active, and something happens to or by an interesting unit, mark as changed so we update our window.
	if current and srcName and (self:UnitIsInteresting(srcName) or self:UnitIsInteresting(dstName)) then
		changed = true
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

function Skada:UpdateBars()
	if not changed then
		return
	end

	if selectedmode then

		local set = self:get_selected_set()
		
		-- If we have a set, go on.
		if set then
			-- Let mode handle the rest.
			selectedmode:Update(set)
		end
		
	elseif selectedset then
		-- View available modes.
		for i, mode in ipairs(modes) do
			local bar = self.bargroup:GetBar(mode.name)
			if not bar then
				local bar = self:CreateBar(mode.name, mode.name, 1, 1, nil, false)
				bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayMode(mode) elseif button == "RightButton" then Skada:RightClick() end end)
			end
		end
		
	else
		-- View available sets.
		local bar = self:GetBar("total")
		if not bar then
			local bar = self:CreateBar("total", L["Total"], 1, 1, nil, false)
			bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
			bar:EnableMouse(true)
			bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes("total") elseif button == "RightButton" then Skada:RightClick() end end)
		end

		local bar = self:GetBar("current")
		if not bar then
			local bar = self:CreateBar("current", L["Current"], 1, 1, nil, false)
			bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
			bar:EnableMouse(true)
			bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes("current") elseif button == "RightButton" then Skada:RightClick() end end)
		end

		for i, set in ipairs(sets) do
		
			local bar = self:GetBar(tostring(set.starttime))
			if not bar then
				local bar = self:CreateBar(tostring(set.starttime), set.name, 1, 1, nil, false)
				bar:SetTimerLabel(date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime))
				bar:SetColorAt(0,self.db.profile.barcolor.r,self.db.profile.barcolor.g,self.db.profile.barcolor.b, self.db.profile.barcolor.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes(set.starttime) elseif button == "RightButton" then Skada:RightClick() end end)
			end
			
		end
	end
	
	-- Mark as unchanged.
	changed = false
end

function Skada:GetModes()
	return modes
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

	changed = true
	self:UpdateBars()
end

-- Sets up the mode list.
function Skada:DisplayModes(settime)
	self:RemoveAllBars()

	selectedplayer = nil
	selectedspell = nil
	selectedmode = nil

	self.bargroup.button:SetText(L["Skada: Modes"])

	-- Find the selected set
	if settime == "current" or settime == "total" then
		selectedset = settime
	else
	
		for i, set in ipairs(sets) do
			if set.starttime == settime then
				if set.name == L["Current"] then
					selectedset = "current"
				elseif set.name == L["Total"] then
					selectedset = "total"
				else
					selectedset = i
				end
			end
		end
		
	end

	changed = true
	self:UpdateBars()
end

-- Sets up the set list.
function Skada:DisplaySets()
	self:RemoveAllBars()
	
	selectedspell = nil
	selectedplayer = nil
	selectedmode = nil
	selectedset = nil

	self.bargroup.button:SetText(L["Skada: Fights"])
	
	changed = true
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

--
-- API
-- These functions are meant to be used by modes.
--

-- Formats a number into human readable form.
function Skada:FormatNumber(number)
	if self.db.profile.numberformat == 1 then
		if number > 1000000 then
			return 	("%02.1fM"):format(number / 1000000)
		else
			return 	("%02.1fK"):format(number / 1000)
		end
	else
		return number
	end
end

function Skada:AddMode(mode)
	table.insert(modes, mode)
	
	-- Set this mode as the active mode if it matches the saved one.
	-- Bit of a hack.
	if mode.name == self.db.profile.mode then
		self:RestoreView(selectedset, mode.name)
	end
	
	-- Sort modes.
	table.sort(modes, function(a, b) return a.name < b.name end)
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

-- Returns true if we are interested in the unit. Does not include pets.
function Skada:UnitIsInteresting(name)
	return name and (UnitIsUnit("player",name) or UnitIsUnit("pet",name) or UnitPlayerOrPetInRaid(name) or UnitPlayerOrPetInParty(name))
end

-- Returns true if we are interested in the unit. Include pets.
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
