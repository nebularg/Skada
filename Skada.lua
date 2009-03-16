Skada = LibStub("AceAddon-3.0"):NewAddon("Skada", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "SpecializedLibBars-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")
local libwindow = LibStub("LibWindow-1.1")
local media = LibStub("LibSharedMedia-3.0")

local dataobj = ldb:NewDataObject("Skada", {label = "Skada", type = "data source", icon = "Interface\\Icons\\Spell_Lightning_LightningBolt01", text = "n/a"})

-- All saved sets
local sets = {}

-- The current set
Skada.current = nil

-- The total set
Skada.total = nil

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

-- The selected data feed.
local selectedfeed = nil

-- A list of data feeds available. Modules add to it.
local feeds = {}

-- Determines if the GetDefaultColor functions returns the alternate color.
local usealt = true

-- Our windows.
local windows = {}

function Skada:GetWindows()
	return windows
end

Window = {

	-- The selected mode and set
	selectedmode = nil,
	selectedset = nil,

	-- Mode and set to return to after combat.
	restore_mode = nil,
	restore_set = nil,
	
	usealt = true,
}

local mt = {__index = Window}

function Window:new()
   return setmetatable({ }, mt)
end

function Window:destroy()
	self.bargroup:Hide()
	self.bargroup.bgframe = nil
	self.bargroup = nil
end

function Window:AnchorClicked(cbk, group, button)
	if IsShiftKeyDown() then
		Skada:OpenMenu()
	elseif button == "RightButton" then
		self:RightClick()
	end
end

function Window:AnchorMoved(cbk, group, x, y)
	libwindow.SavePosition(self.bargroup)
end
				
function Window:Show()
	self.bargroup:Show()
end

function Window:Hide()
	self.bargroup:Hide()
end
					
function Window:IsShown()
	return self.bargroup:IsShown()
end
	
function Window:SortBars()
	self.bargroup:SortBars()
end

function Window:GetBars()
	return self.bargroup:GetBars()
end
						
function Window:getNumberOfBars()
	local bars = self.bargroup:GetBars()
	local n = 0
	for i, bar in pairs(bars) do n = n + 1 end
	return n
end

function Window:OnMouseWheel(frame, direction)
	if direction == 1 and self.bargroup:GetBarOffset() > 0 then
		self.bargroup:SetBarOffset(self.bargroup:GetBarOffset() - 1)
	elseif direction == -1 and ((self:getNumberOfBars() - self.bargroup:GetMaxBars() - self.bargroup:GetBarOffset()) > 0) then
		self.bargroup:SetBarOffset(self.bargroup:GetBarOffset() + 1)
	end
end

function Window:GetDefaultBarColorOne()
	return self.db.barcolor
end

function Window:GetDefaultBarColorTwo()
	return self.db.baraltcolor
end

function Window:GetDefaultBarColor()
	self.usealt = not self.usealt
	if self.usealt then
		return self.db.baraltcolor
	else
		return self.db.barcolor
	end
end

function Window:GetBarGroup()
	return self.bargroup
end

function Window:SetSortFunction(func)
	self.bargroup:SetSortFunction(func)
end

function Window:GetBar(name)
	return self.bargroup:GetBar(name)
end

function Window:RemoveBar(bar)
	self.bargroup:RemoveBar(bar)
end

function Window:CreateBar(name, label, value, maxvalue, icon, o)
	local bar = self.bargroup:NewCounterBar(name, label, value, maxvalue, icon, o)
	bar:EnableMouseWheel(true)
	bar:SetScript("OnMouseWheel", function(f, d) self:OnMouseWheel(f, d) end)
	return bar
end

function Window:RemoveAllBars()
	self.usealt = true
	
	-- Reset sort function.
	self.bargroup:SetSortFunction(nil)
	
	-- Reset scroll offset.
	self.bargroup:SetBarOffset(0)
	
	-- Remove the bars.
	local bars = self.bargroup:GetBars()
	if bars then
		for i, bar in pairs(bars) do
			bar:Hide()
			self.bargroup:RemoveBar(bar)
		end
	end
	
	-- Clean up.
	self.bargroup:SortBars()
end
								
-- If selectedset is "current", returns current set if we are in combat, otherwise returns the last set.
function Window:get_selected_set()
	if self.selectedset == "current" then
		if Skada.current == nil then
			return sets[1]
		else
			return Skada.current
		end
	elseif self.selectedset == "total" then
		return Skada.total
	else
		return sets[self.selectedset]
	end
end

-- Sets up the mode view.
function Window:DisplayMode(mode)
	self:RemoveAllBars()

	self.selectedplayer = nil
	self.selectedspell = nil
	self.selectedmode = mode

	-- Save for posterity.
	self.db.mode = self.selectedmode.name

	self.bargroup.button:SetText(mode.name)

	changed = true
	Skada:UpdateBars()
end

-- Sets up the mode list.
function Window:DisplayModes(settime)
	self:RemoveAllBars()

	self.selectedplayer = nil
	self.selectedspell = nil
	self.selectedmode = nil

	self.bargroup.button:SetText(L["Skada: Modes"])

	-- Save for posterity.
	self.db.set = settime

	-- Find the selected set
	if settime == "current" or settime == "total" then
		self.selectedset = settime
	else
		for i, set in ipairs(sets) do
			if set.starttime == settime then
				if set.name == L["Current"] then
					selfselectedset = "current"
				elseif set.name == L["Total"] then
					self.selectedset = "total"
				else
					self.selectedset = i
				end
			end
		end
	end

	changed = true
	Skada:UpdateBars()
end

-- Sets up the set list.
function Window:DisplaySets()
	self:RemoveAllBars()
	
	self.selectedspell = nil
	self.selectedplayer = nil
	self.selectedmode = nil
	self.selectedset = nil

	self.bargroup.button:SetText(L["Skada: Fights"])
	
	changed = true
	Skada:UpdateBars()
end

function Window:RightClick(group, button)
	if self.selectedmode then
		self:DisplayModes(self.selectedset)
	elseif self.selectedset then
		self:DisplaySets()
	end
end

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
	media:Register("statusbar", "Round",			[[Interface\Addons\Skada\statusbar\Round]])

	-- DB
	self.db = LibStub("AceDB-3.0"):New("SkadaDB", self.defaults)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada", self.options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada", "Skada")

	-- Profiles
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada-Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada-Profiles", "Profiles", "Skada")
	
	self:RegisterChatCommand("skada", "Command")
	self.db.RegisterCallback(self, "OnProfileChanged", "ReloadSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReloadSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ReloadSettings")

	-- Window config.
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada-Windows", self.windowoptions)
	self.windowFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada-Windows", "Windows", "Skada")
	
	self:ReloadSettings()
end

function Skada:tcopy(to, from)
  for k,v in pairs(from) do
    if(type(v)=="table") then
      to[k] = {}
      Skada:tcopy(to[k], v);
    else
      to[k] = v;
    end
  end
end

function Skada:CreateWindow(name, db)
	if not db then
		db = {}
		self:tcopy(db, Skada.windowdefaults)
		table.insert(self.db.profile.windows, db)
	end

	local window = Window:new()
	window.db = db
	window.db.name = name
	
	-- Re-use bargroup if it exists.
	window.bargroup = self:GetBarGroup(name)
	if window.bargroup then
		-- Clear callbacks.
		window.bargroup.callbacks = LibStub:GetLibrary("CallbackHandler-1.0"):New(window.bargroup)
	else
		window.bargroup = self:NewBarGroup(name, nil, window.db.barwidth, window.db.barheight, "SkadaBarWindow"..name)
	end
	window.bargroup.RegisterCallback(window, "AnchorMoved")
	window.bargroup.RegisterCallback(window, "AnchorClicked")
	window.bargroup:EnableMouse(true)
	window.bargroup:SetScript("OnMouseDown", function(self, button) if button == "RightButton" then window:RightClick() end end)
	window.bargroup:HideIcon()

	self.windowoptions.args[name] = Skada:GetWindowOptions(window)
	
	libwindow.RegisterConfig(window.bargroup, window.db)

	table.insert(windows, window)

	self:ApplySettings()
end

-- Deleted named window from our windows table, and also from db.
function Skada:DeleteWindow(name)
	for i, win in ipairs(windows) do
		if win.db.name == name then
			win:destroy()
			wipe(table.remove(windows, i))
		end
	end
	for i, win in ipairs(self.db.profile.windows) do
		if win.name == name then
			table.remove(self.db.profile.windows, i)
		end
	end
	self.windowoptions.args[name] = nil
end

function Skada:Command(param)
	if param == "pets" then
		self:PetDebug()
	elseif param == "test" then
		self:OpenMenu()
	elseif param == "reset" then
		self:Reset()
	elseif param == "toggle" then
		self:ToggleWindow()
	elseif param == "config" then
		self:OpenOptions()
	--[[
	elseif param:sub(1,6) == "report" then
		param = param:sub(7)
		local chan = "say"
		local max = 0
		local chantype = "preset"
		for word in param:gmatch("[%a%d]+") do
			if word == "raid" or word == "guild" or word == "party" or word == "officer" then
				chantype = "preset"
				chan = word
			elseif word == "self" then
				chantype = "self"
			elseif tonumber(word) ~= nil then
				max = tonumber(word)
			elseif select(1, GetChannelName(word)) > 0 then
				chan = word
				chantype = "CHANNEL"
			else
				chan = word
				chantype = "WHISPER"
			end
		end
		self:Report(chan, chantype, max)
	--]]
	else
		self:Print("Usage:")
		self:Print(("%-20s %-s"):format("/skada report",L["reports the active mode"]))
		self:Print(("%-20s %-s"):format("/skada reset",L["resets all data"]))
		self:Print(("%-20s %-s"):format("/skada config",L["opens the configuration window"]))
	end
end

local function find_mode(name)
	for i, mode in ipairs(modes) do
		if mode.name == name then
			return mode
		end
	end
end

local function sendchat(msg, chan, chantype)
	if chantype == "self" then
		-- To self.
		Skada:Print(msg)
	elseif chantype == "channel" then
		-- To channel.
		SendChatMessage(msg, "CHANNEL", nil, chan)
	elseif chantype == "preset" then
		-- To a preset channel id (say, guild, etc).
		SendChatMessage(msg, string.upper(chan))
	elseif chantype == "whisper" then
		-- To player.
		SendChatMessage(msg, "WHISPER", nil, chan)
	end
end

-- I refuse to acknoledge that I have written this.
-- Ideally we want modes to be display system agnostic, so that we can simply
-- ask the chosen mode to print its contents as a table instead of bars. But for now...
function Skada:Report(channel, chantype, report_mode, report_set, max)

	local win = win or windows[1]
	if win then
		local old_mode = win.selectedmode
		local old_set = win.selectedset
		
		win.selectedset = report_set
		win.selectedmode = report_mode
		
		changed = true
		self:UpdateBars()

		local bars = win:GetBars()
		local list = {}
		
		for name, bar in pairs(bars) do table.insert(list, bar)	end

		-- Sort our temporary table according to value.
		table.sort(list, function(a,b) return a.value > b.value end)
	
		-- Title
		local set = win:get_selected_set()
		local endtime = set.endtime or time()
		sendchat(string.format(L["Skada report on %s for %s, %s to %s:"], win.selectedmode.name, set.name, date("%X",set.starttime), date("%X",endtime)), channel, chantype)
		
		-- For each active bar, print label and timer value.
		for i, bar in ipairs(list) do
			sendchat(("%s   %s"):format(bar:GetLabel(), bar:GetTimerLabel()), channel, chantype)
			if i == max or (max == 0 and i == win.db.barmax) then
				break
			end
		end
		
		-- Switch back to previous mode. Can you say "ugly"?
		if old_set then
			win.selectedset = old_set
			if old_mode then
				win.selectedmode = old_mode
			end
		else
			win:DisplaySets()
		end
		changed = true
		self:UpdateBars()
	else
		self:Print("Reporting requires a window to be present.")
	end
	
end

function Skada:RefreshMMButton()
	icon:Refresh("Skada", self.db.profile.icon)
	if self.db.profile.icon.hide then
		icon:Hide("Skada")
	else
		icon:Show("Skada")
	end
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
	self:RegisterEvent("UNIT_PET")
	
	self:ScheduleRepeatingTimer("UpdateBars", 0.5)
	self:ScheduleRepeatingTimer("Tick", 1)
	
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

-- Ask a mode to verify the contents of a set.
local function verify_set(mode, set)
	if mode.AddSetAttributes ~= nil then
		mode:AddSetAttributes(set)
	end
	for j, player in ipairs(set.players) do
		if mode.AddPlayerAttributes ~= nil then
			mode:AddPlayerAttributes(player)
		end
	end
end

local wasininstance

local function ask_for_reset()
	StaticPopupDialogs["ResetSkadaDialog"] = {
						text = L["Do you want to reset Skada?"], 
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
		
		-- Hide window if we have enabled the "Hide when solo" option.
		if Skada.db.profile.hidesolo then
			for i, win in ipairs(windows) do
				win:Hide()
			end
		end
	end

	if (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) and not wasinparty then
		-- We joined a raid.
		
		if Skada.db.profile.reset.join == 3 then
			ask_for_reset()
		elseif Skada.db.profile.reset.join == 2 then
			Skada:Reset()
		end

		-- Show window if we have enabled the "Hide when solo" option.
		if Skada.db.profile.hidesolo then
			for i, win in ipairs(windows) do
				win:Show()
				win:SortBars()
			end
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

-- Toggles all windows.
function Skada:ToggleWindow()
	for i, win in ipairs(windows) do
		if win:IsShown() then
			win.db.shown = false
			win:Hide()
		else
			win.db.shown = true
			win:Show()
			win:SortBars()
		end
	end
end

local function createSet(setname)
	local set = {players = {}, name = setname, starttime = time(), ["time"] = 0, last_action = time()}

	-- Tell each mode to apply its needed attributes.
	for i, mode in ipairs(modes) do verify_set(mode, set) end

	return set
end

function Skada:Reset()
	self:RemoveAllBars()
	
	pets = {}
	self:CheckPets()
	
	if self.current ~= nil then
		wipe(self.current)
		self.current = createSet(L["Current"])
	end
	if self.total ~= nil then
		wipe(self.total)
		self.total = createSet(L["Total"])
		self.db.profile.total = self.total
	end
	
	-- Delete sets that are not marked as persistent.
	for i=table.maxn(sets), 1, -1 do
		if not sets[i].keep then
			wipe(table.remove(sets, i))
		end
	end
	changed = true
	self:UpdateBars()
	self:Print(L["All data has been reset."])
end

-- Delete a set.
function Skada:DeleteSet(set)
	if not set then return end

	for i, s in ipairs(sets) do
		if s == set then
			wipe(table.remove(sets, i))
		end
	end
	self:RemoveAllBars()
	changed = true
	self:UpdateBars()
end

local report_channel = "Say"
local report_number = 10
local report_mode = nil
local report_chantype = "preset"
	
-- Open a menu. Supply a window to tailor it to that window, else generic.
function Skada:OpenMenu(win)
	if win and win.selectedset then
		report_set = win.selectedset
	end
	if win and win.selectedmode then
		report_mode = win.selectedmode
	end

	if not self.skadamenu then
		self.skadamenu = CreateFrame("Frame", "SkadaMenu")
	end
	local skadamenu = self.skadamenu
	
	skadamenu.displayMode = "MENU"
	local info = {}
	skadamenu.initialize = function(self, level)
	    if not level then return end
	    wipe(info)
	    if level == 1 then
	        -- Create the title of the menu
	        info.isTitle = 1
	        info.text = L["Skada Menu"]
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	        
			for i, win in ipairs(windows) do
		        wipe(info)
		        info.text = win.db.name
		        info.hasArrow = 1
		        info.value = win
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
			end

	        -- Add a blank separator
	        wipe(info)
	        info.disabled = 1
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)

	        wipe(info)
	        info.text = L["Report"]
	        info.hasArrow = 1
	        info.value = "report"
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = L["Delete segment"]
	        info.func = function() Skada:DeleteSet() end
	        info.hasArrow = 1
	        info.notCheckable = 1
	        info.value = "delete"
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = L["Keep segment"]
	        info.func = function() Skada:KeepSet() end
	        info.notCheckable = 1
	        info.hasArrow = 1
	        info.value = "keep"
	        UIDropDownMenu_AddButton(info, level)

	        -- Add a blank separator
	        wipe(info)
	        info.disabled = 1
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = L["Toggle window"]
	        info.func = function() Skada:ToggleWindow() end
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)

	        wipe(info)
	        info.text = L["Configure"]
	        info.func = function() Skada:OpenOptions() end
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)

	        -- Close menu item
	        wipe(info)
	        info.text         = CLOSE
	        info.func         = function() CloseDropDownMenus() end
	        info.checked      = nil
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	    elseif level == 2 then
	    	if type(UIDROPDOWNMENU_MENU_VALUE) == "table" then
	    		local window = UIDROPDOWNMENU_MENU_VALUE
	    		-- Display list of modes with current ticked; let user switch mode by checking one.
		        wipe(info)
		        info.isTitle = 1
		        info.text = L["Mode"]
		        UIDropDownMenu_AddButton(info, level)
		        
		        for i, module in ipairs(Skada:GetModes()) do
			        wipe(info)
		            info.text = module.name
		            info.func = function() window:DisplayMode(module) end
		            info.checked = (window.selectedmode == module)
		            UIDropDownMenu_AddButton(info, level)
		        end
		        
		        -- Separator
		        wipe(info)
		        info.disabled = 1
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
	        
		        -- Display list of sets with current ticked; let user switch set by checking one.
		        wipe(info)
		        info.isTitle = 1
		        info.text = L["Segment"]
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
	            info.text = L["Total"]
	            info.func = function()
	            				window.selectedset = "total"
	            				Skada:RemoveAllBars()
	            				changed = true
	            				Skada:UpdateBars()
	            			end
	            info.checked = (window.selectedset == "total")
	            UIDropDownMenu_AddButton(info, level)
		        wipe(info)
	            info.text = L["Current"]
	            info.func = function()
	            				window.selectedset = "current"
	            				Skada:RemoveAllBars()
	            				changed = true
	            				Skada:UpdateBars()
	            			end
	            info.checked = (window.selectedset == "current")
	            UIDropDownMenu_AddButton(info, level)
		        for i, set in ipairs(sets) do
			        wipe(info)
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() 
		            				window.selectedset = i
		            				Skada:RemoveAllBars()
		            				changed = true
		            				Skada:UpdateBars()
		            			end
		            info.checked = (window.selectedset == set.starttime)
		            UIDropDownMenu_AddButton(info, level)
		        end

		        -- Add a blank separator
		        wipe(info)
		        info.disabled = 1
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
	        
		        wipe(info)
	            info.text = L["Lock window"]
	            info.func = function()
	            				window.db.barslocked = not window.db.barslocked
	            				Skada:ApplySettings()
	            			end
	            info.checked = window.db.barslocked
		        UIDropDownMenu_AddButton(info, level)
			        	    	
		    elseif UIDROPDOWNMENU_MENU_VALUE == "delete" then
		        for i, set in ipairs(sets) do
			        wipe(info)
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() Skada:DeleteSet(set) end
			        info.notCheckable = 1
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "keep" then
		        for i, set in ipairs(sets) do
			        wipe(info)
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() 
		            				set.keep = not set.keep
		            				Skada:RemoveAllBars()
		            				changed = true
		            				Skada:UpdateBars()
		            			end
		            info.checked = set.keep
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "report" then
		        wipe(info)
		        info.text = L["Mode"]
		        info.hasArrow = 1
		        info.value = "modes"
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)

		        wipe(info)
		        info.hasArrow = 1
		        info.value = "segment"
		        info.notCheckable = 1
		        info.text = L["Segment"]
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
		        info.text = L["Channel"]
		        info.hasArrow = 1
		        info.value = "channel"
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
		        info.text = L["Lines"]
		        info.hasArrow = 1
		        info.value = "number"
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
		        info.text = L["Send report"]
		        info.func = function()
		        				if report_mode ~= nil and report_set ~= nil then
		        				
									if report_chantype == "whisper" then
										StaticPopupDialogs["SkadaReportDialog"] = {
															text = L["Name of recipient"], 
															button1 = ACCEPT, 
															button2 = CANCEL,
															hasEditBox = 1,
															timeout = 30, 
															hideOnEscape = 1, 
															OnAccept = 	function()
																			report_channel = getglobal(this:GetParent():GetName().."EditBox"):GetText()
																			Skada:Report(report_channel, report_chantype, report_mode, report_set, report_number)
																		end,
														}
										StaticPopup_Show("SkadaReportDialog")
									else
										Skada:Report(report_channel, report_chantype, report_mode, report_set, report_number)
									end
								else
									Skada:Print(L["No mode or segment selected for report."])
								end
		        			end
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		    end
		elseif level == 3 then
		    if UIDROPDOWNMENU_MENU_VALUE == "modes" then

		        for i, module in ipairs(Skada:GetModes()) do
			        wipe(info)
		            info.text = module.name
		            info.checked = (report_mode == module)
		            info.func = function() report_mode = module end
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "segment" then
		        wipe(info)
	            info.text = L["Total"]
	            info.func = function() report_set = "total" end
	            info.checked = (report_set == "total")
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Current"]
	            info.func = function() report_set = "current" end
	            info.checked = (report_set == "current")
	            UIDropDownMenu_AddButton(info, level)
	            
		        for i, set in ipairs(sets) do
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() report_set = i end
		            info.checked = (report_set == i)
		            UIDropDownMenu_AddButton(info, level)
		        end		        
		    elseif UIDROPDOWNMENU_MENU_VALUE == "number" then
		        for i = 1,10 do
			        wipe(info)
		            info.text = i
		            info.checked = (report_number == i)
		            info.func = function() report_number = i end
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "channel" then
		        wipe(info)
		        info.text = L["Whisper"]
		        info.checked = (report_chantype == "whisper")
		        info.func = function() report_channel = "Whisper"; report_chantype = "whisper" end
		        UIDropDownMenu_AddButton(info, level)
		        
		        info.text = L["Say"]
		        info.checked = (report_channel == "Say")
		        info.func = function() report_channel = "Say"; report_chantype = "preset" end
		        UIDropDownMenu_AddButton(info, level)
        
	            info.text = L["Raid"]
	            info.checked = (report_channel == "Raid")
	            info.func = function() report_channel = "Raid"; report_chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)

	            info.text = L["Party"]
	            info.checked = (report_channel == "Party")
	            info.func = function() report_channel = "Party"; report_chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Guild"]
	            info.checked = (report_channel == "Guild")
	            info.func = function() report_channel = "Guild"; report_chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Officer"]
	            info.checked = (report_channel == "Officer")
	            info.func = function() report_channel = "Officer"; report_chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Self"]
	            info.checked = (report_chantype == "self")
	            info.func = function() report_channel = "Self"; report_chantype = "self" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            local list = {GetChannelList()}
	            local i = 1
	            while i < #list do
		            info.text = list[i+1]
		            info.checked = (report_channel == list[i])
		            info.func = function() report_channel = list[i]; report_chantype = "channel" end
		            UIDropDownMenu_AddButton(info, level)
	            	
	            	i = i + 2
	            end
	            		    
		    end
		
	    end
	end
	
	local x,y = GetCursorPosition(UIParent); 
	ToggleDropDownMenu(1, nil, skadamenu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale())
end

function Skada:ReloadSettings()
	-- Delete all existing windows in case of a profile change.
	for i, win in ipairs(windows) do
		win:destroy()
	end
	windows = {}

	-- Re-create windows
	-- Note: as this can be called from a profile change as well as login, re-use windows when possible.
	for i, win in ipairs(self.db.profile.windows) do
		self:CreateWindow(win.name, win)
	end

	self.total = self.db.profile.total
	sets = self.db.profile.sets
	
	-- Restore window position.
	for i, win in ipairs(windows) do
		libwindow.RestorePosition(win.bargroup)
	end
	
	-- Minimap button.
	if not icon:IsRegistered("Skada") then
		icon:Register("Skada", dataobj, self.db.profile.icon)
	end

	self:RefreshMMButton()
	
	self:ApplySettings()
end

local titlebackdrop = {}
local windowbackdrop = {}

-- Applies settings to things like the bar window.
function Skada:ApplySettings()
	for i, win in ipairs(windows) do
		local g = win.bargroup
		local p = win.db
		g:ReverseGrowth(p.reversegrowth)
		g:SetOrientation(p.barorientation)
		g:SetHeight(p.barheight)
		g:SetWidth(p.barwidth)
		g:SetTexture(media:Fetch('statusbar', p.bartexture))
		g:SetFont(media:Fetch('font', p.barfont), p.barfontsize)
		g:SetSpacing(p.barspacing)
		g:UnsetAllColors()
		g:SetColorAt(0,p.barcolor.r,p.barcolor.g,p.barcolor.b, p.barcolor.a)
		g:SetMaxBars(p.barmax)
		if p.barslocked then
			g:Lock()
		else
			g:Unlock()
		end
		g:SortBars()
	
		-- Header
		local inset = p.title.margin
		titlebackdrop.bgFile = media:Fetch("statusbar", p.title.texture)
		if p.title.borderthickness > 0 then
			titlebackdrop.edgeFile = media:Fetch("border", p.title.bordertexture)
		else
			titlebackdrop.edgeFile = nil
		end
		titlebackdrop.tile = false
		titlebackdrop.tileSize = 0
		titlebackdrop.edgeSize = p.title.borderthickness
		titlebackdrop.insets = {left = inset, right = inset, top = inset, bottom = inset}
		g.button:SetBackdrop(titlebackdrop)
		local color = p.title.color
		g.button:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
		
		if p.enabletitle then
			g:ShowAnchor()
		else
			g:HideAnchor()
		end
		
		-- Window
		if p.enablebackground then
			if g.bgframe == nil then
				g.bgframe = CreateFrame("Frame", nil, g)
				g.bgframe:SetFrameStrata("BACKGROUND")
				g.bgframe:EnableMouse()
				g.bgframe:EnableMouseWheel()
				g.bgframe:SetScript("OnMouseDown", function(frame, btn) if btn == "RightButton" then win:RightClick() end end)
				g.bgframe:SetScript("OnMouseWheel", win.OnMouseWheel)
			end
	
			local inset = p.background.margin
			windowbackdrop.bgFile = media:Fetch("statusbar", p.background.texture)
			if p.background.borderthickness > 0 then
				windowbackdrop.edgeFile = media:Fetch("border", p.background.bordertexture)
			else
				windowbackdrop.edgeFile = nil
			end
			windowbackdrop.tile = false
			windowbackdrop.tileSize = 0
			windowbackdrop.edgeSize = p.background.borderthickness
			windowbackdrop.insets = {left = inset, right = inset, top = inset, bottom = inset}
			g.bgframe:SetBackdrop(windowbackdrop)
			local color = p.background.color
			g.bgframe:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
			g.bgframe:SetWidth(g:GetWidth() + (p.background.borderthickness * 2))
			g.bgframe:SetHeight(p.background.height)
	
			g.bgframe:ClearAllPoints()
			if p.reversegrowth then
				g.bgframe:SetPoint("LEFT", g.button, "LEFT", -p.background.borderthickness, 0)
				g.bgframe:SetPoint("RIGHT", g.button, "RIGHT", p.background.borderthickness, 0)
				g.bgframe:SetPoint("BOTTOM", g.button, "TOP", 0, 0)
			else
				g.bgframe:SetPoint("LEFT", g.button, "LEFT", -p.background.borderthickness, 0)
				g.bgframe:SetPoint("RIGHT", g.button, "RIGHT", p.background.borderthickness, 0)
				g.bgframe:SetPoint("TOP", g.button, "BOTTOM", 0, 0)
			end
			g.bgframe:Show()
			
			-- Calculate max number of bars to show if our height is not dynamic.
			if p.background.height > 0 then
				local maxbars = math.floor(p.background.height / math.max(1, p.barheight + p.barspacing))
				g:SetMaxBars(maxbars)
			else
				-- Adjust background height according to current bars.
				self:AdjustBackgroundHeight(win)
			end
			
		elseif g.bgframe then
			g.bgframe:Hide()
		end
		
		if p.shown then
			-- Don't show window if we are solo and we have enabled the "Hide when solo" option.
			if not (self.db.profile.hidesolo and GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) then
				win:Show()
			else
				win:Hide()
			end
		else
			win:Hide()
		end
	
		win:SortBars()
	end
	
	changed = true
	self:UpdateBars()
end

-- Set a data feed as selectedfeed.
function Skada:SetFeed(feed)
	selectedfeed = feed
	self:UpdateBars()
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

local function IsRaidInCombat()
	if GetNumRaidMembers() > 0 then
		-- We are in a raid.
		for i = 1, GetNumRaidMembers(), 1 do
			if UnitExists("raid"..i) and UnitAffectingCombat("raid"..i) then
				return true
			end
		end
	elseif GetNumPartyMembers() > 0 then
		-- In party.
		for i = 1, GetNumPartyMembers(), 1 do
			if UnitExists("party"..i) and UnitAffectingCombat("party"..i) then
				return true
			end
		end
	end
end

-- Our scheme for segmenting fights:
-- Each second, if player is not in combat and is not dead and we have an active set (current), 
-- check if anyone in raid is in combat; if so, close up shop.
-- We can not simply rely on PLAYER_REGEN_ENABLED since it is fired if we die and the fight continues.
function Skada:Tick()
	if self.current and not InCombatLockdown() and not UnitIsDead("player") and not IsRaidInCombat() then
	
		-- Save current set unless this a trivial set, or if we have the Only keep boss fights options on, and no boss in fight.
		-- A set is trivial if we have no mob name saved, or if total time for set is not more than 5 seconds.
		if not self.db.profile.onlykeepbosses or self.current.gotboss then
			if self.current.mobname ~= nil and time() - self.current.starttime > 5 then
				-- End current set.
				self.current.endtime = time()
				self.current.time = self.current.endtime - self.current.starttime
				setPlayerActiveTimes(self.current)
				self.current.name = self.current.mobname
				
				-- Tell each mode that set has finished and do whatever it wants to do about it.
				for i, mode in ipairs(modes) do
					if mode.SetComplete ~= nil then
						mode:SetComplete(self.current)
					end
				end
				
				table.insert(sets, 1, self.current)
			end
		end
		
		-- Add time spent to total set as well.
		self.total.time = self.total.time + self.current.time
		setPlayerActiveTimes(self.total)
		
		-- Set player.first and player.last to nil in total set.
		-- Neccessary since first and last has no relevance over an entire raid.
		-- Modes should look at the "time" value if available.
		for i, player in ipairs(self.total.players) do
			player.first = nil
			player.last = nil
		end
		
		-- Reset current set.
		self.current = nil
		
		-- Find out number of non-persistent sets.
		local numsets = 0
		for i, set in ipairs(sets) do if not set.keep then numsets = numsets + 1 end end
		
		-- Trim segments; don't touch persistent sets.
		for i=table.maxn(sets), 1, -1 do
			if numsets > self.db.profile.setstokeep and not sets[i].keep then
				local t = table.remove(sets, i)
				wipe(t)
				numsets = numsets - 1
			end
		end
		
		for i, win in ipairs(windows) do
			win:RemoveAllBars()
			changed = true
		
			-- Auto-switch back to previous set/mode.
			if win.db.returnaftercombat and win.restore_mode and win.restore_set then
				if win.restore_set ~= win.selectedset or win.restore_mode ~= win.selectedmode then
					
					self:RestoreView(win, win.restore_set, win.restore_mode)
					
					win.restore_mode = nil
					win.restore_set = nil
				end
			end
		end

		self:UpdateBars()

	end
end

function Skada:PLAYER_REGEN_DISABLED()
	-- Start a new set if we are not in one already.
	if not self.current then
		self:StartCombat()
	end
end

function Skada:StartCombat()
	-- Remove old bars.
	self:RemoveAllBars()
	
	-- Create a new current set.
	self.current = createSet(L["Current"])

	-- Also start the total set if it is nil.
	if self.total == nil then
		self.total = createSet(L["Total"])
		self.db.profile.total = self.total
	end
	
	-- Auto-switch set/mode if configured.
	for i, win in ipairs(windows) do
		if win.db.modeincombat ~= "" then
			-- First, get the mode. The mode may not actually be available.
			local mymode = find_mode(win.db.modeincombat)
			
			-- If the mode exists, switch to current set and this mode. Save current set/mode so we can return after combat if configured.
			if mymode ~= nil then
	--				self:Print("Switching to "..mymode.name.." mode.")
				
				if win.db.returnaftercombat then
					if win.selectedset then
						win.restore_set = win.selectedset
					end
					if win.selectedmode then
						win.restore_mode = win.selectedmode.name
					end
				end
				
				win.selectedset = "current"
				win:DisplayMode(mymode)
			end
		end
	end
	
	-- Force immediate update.
	changed = true
	self:UpdateBars()
end

-- Simply calls the same function on all windows.
function Skada:RemoveAllBars()
	for i, win in ipairs(windows) do
		win:RemoveAllBars()
	end
end

-- Attempts to restore a view (set and mode).
-- Set is either the set name ("total", "current"), or an index.
-- Mode is the name of a mode.
function Skada:RestoreView(win, theset, themode)
	-- Set the... set. If no such set exists, set to current.
	if theset and type(theset) == "string" and (theset == "current" or theset == "total") then
		win.selectedset = theset
	elseif theset and type(theset) == "number" and theset <= table.maxn(sets) then
		win.selectedset = theset
	else
		win.selectedset = "current"
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
			win:DisplayMode(mymode)
		else
			win:DisplayModes(selectedset)
		end
	end
end

-- Returns a player from the current. Safe to use to simply 
function Skada:find_player(set, playerid)
	local player = nil
	for i, p in ipairs(set.players) do
		if p.id == playerid then
			return p
		end
	end
end

-- Returns or creates a player in the current.
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
	changed = true
	return player
end

local combatlogevents = {}
function Skada:RegisterForCL(func, event, flags)
	if not combatlogevents[event] then
		combatlogevents[event] = {}
	end
	tinsert(combatlogevents[event], {["func"] = func, ["flags"] = flags})
end

-- The basic idea for CL processing:
-- Modules register for interest in a certain event, along with the function to call and the flags determining if the particular event is interesting.
-- On a new event, loop through the interested parties.
-- The flags are checked, and the flag value (say, that the SRC must be interesting, ie, one of the raid) is only checked once, regardless
-- of how many modules are interested in the event. The check is also only done on the first flag that requires it.
-- The exception is src_is_interesting, which we always check to determine combat start - I would like to get rid of this, but am not sure how.
-- Combat start bit disabled for now.

-- TODO: Start looking at flags instead of using functions.
function Skada:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	local src_is_interesting = nil --self:UnitIsInteresting(srcName, srcGUID)
	local dst_is_interesting = nil
	local src_is_interesting_nopets = nil
	local dst_is_interesting_nopets = nil
	
	if self.current and combatlogevents[eventtype] then
		for i, mod in ipairs(combatlogevents[eventtype]) do
			local fail = false
	
--			self:Print("event, "..eventtype)
			-- Lua can not use assignments as expressions... grmbl. 
			if not fail and mod.flags.src_is_interesting_nopets then
				if src_is_interesting_nopets == nil then
					src_is_interesting_nopets = self:UnitIsInterestingNoPets(srcName, srcGUID)
					if src_is_interesting_nopets then
						src_is_interesting = true
					end
				end
				-- Lua does not have a "continue"... grmbl.
				if not src_is_interesting_nopets then
--				self:Print("fail on src_is_interesting_nopets")
					fail = true
				end
			end
			if not fail and mod.flags.dst_is_interesting_nopets then
				if dst_is_interesting_nopets == nil then
					dst_is_interesting_nopets = self:UnitIsInterestingNoPets(dstName, dstGUID)
					if dst_is_interesting_nopets then
						dst_is_interesting = true
					end
				end
				if not dst_is_interesting_nopets then
--				self:Print("fail on dst_is_interesting_nopets")
					fail = true
				end
			end
			if not fail and mod.flags.src_is_interesting then
				if src_is_interesting == nil then
					src_is_interesting = self:UnitIsInteresting(srcName, srcGUID)
				end
				if not src_is_interesting then
--				self:Print("fail on src_is_interesting")
					fail = true
				end
			end
			if not fail and mod.flags.dst_is_interesting then
				if dst_is_interesting_ == nil then
					dst_is_interesting = self:UnitIsInteresting(dstName, dstGUID)
				end
				if not dst_is_interesting then
--				self:Print("fail on dst_is_interesting")
					fail = true
				end
			end
			
			-- Pass along event if it did not fail our tests.
			if not fail then
				mod.func(timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
			end
			
		end
	end

	-- Detect combat start.
	-- Not happy about this, really. Why can't there be a UNIT_ENTERED_COMBAT?
	--[[
	if not self.current and srcName and srcGUID ~= dstGUID and dstName and src_is_interesting and (eventtype == 'SPELL_DAMAGE' or eventtype == 'SPELL_PERIODIC_DAMAGE' or eventtype == 'SPELL_BUILDING_DAMAGE' or eventtype == 'RANGE_DAMAGE' or eventtype == "SWING_DAMAGE") then
		self:StartCombat()
	else
	--]]

	if self.current and srcName and srcGUID ~= dstGUID and dstName and src_is_interesting and (eventtype == 'SPELL_DAMAGE' or eventtype == 'SPELL_PERIODIC_DAMAGE' or eventtype == 'SPELL_BUILDING_DAMAGE' or eventtype == 'RANGE_DAMAGE' or eventtype == "SWING_DAMAGE") then
		-- Store mob name for set name. For now, just save first unfriendly name available, or first boss available.
		if not self.current.gotboss and self.bossIDs[tonumber(dstGUID:sub(9, 12), 16)] then
			self.current.mobname = dstName
			self.current.gotboss = true
		elseif not self.current.mobname then
			self.current.mobname = dstName
		end
	end
	
	-- Pet summons.
	-- Pet scheme: save the GUID in a table along with the GUID of the owner.
	-- Note to self: this needs 1) to be made self-cleaning so it can't grow too much, and 2) saved persistently.
	-- Now also done on raid roster/party changes.
	if eventtype == 'SPELL_SUMMON' then
		if src_is_interesting_nopets == nil then
			src_is_interesting_nopets = self:UnitIsInterestingNoPets(srcName, srcGUID)
			if src_is_interesting_nopets then
				pets[dstGUID] = {id = srcGUID, name = srcName}
			end
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
    
    local set
    if Skada.current then
    	set = Skada.current
    else
    	set = sets[1]
    end
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
    GameTooltip:AddLine(L["Right-click to open menu"], 0, 1, 0)
    
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
		Skada:OpenMenu()
	end
end

function Skada:UpdateBars()
	-- Update data feed.
	-- This is done even if our set has not changed, since for example DPS changes even though the data does not.
	-- Does not update feed text if nil.
	if selectedfeed ~= nil then
		local feedtext = selectedfeed()
		if feedtext then
			dataobj.text = feedtext
		end
	end
	
	if not changed then
		return
	end

	for i, win in ipairs(windows) do
		if win.selectedmode then
	
			local set = win:get_selected_set()
			
			-- If we have a set, go on.
			if set then
				-- Let mode handle the rest.
				win.selectedmode:Update(win, set)
			end
			
		elseif win.selectedset then
			local set = win:get_selected_set()
			
			-- View available modes.
			for i, mode in ipairs(modes) do
				local bar = win:GetBar(mode.name)
				if not bar then
					bar = win:CreateBar(mode.name, mode.name, 1, 1)
					local c = win:GetDefaultBarColor()
					bar:SetColorAt(0,c.r,c.g,c.b, c.a)
					bar:EnableMouse(true)
					bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then win:DisplayMode(mode) elseif button == "RightButton" then win:RightClick() end end)
				end
				if set and mode.GetSetSummary ~= nil then
					bar:SetTimerLabel(mode:GetSetSummary(set))
				end
			end
			
			win:SetSortFunction(function(a,b) return a.name < b.name end)
			win:SortBars()
		else
			-- View available sets.
			local bar = self:GetBar("total")
			if not bar then
				local bar = win:CreateBar("total", L["Total"], 1, 1)
				local c = win:GetDefaultBarColor()
				bar:SetColorAt(0,c.r,c.g,c.b, c.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then win:DisplayModes("total") elseif button == "RightButton" then win:RightClick() end end)
			end
	
			local bar = win:GetBar("current")
			if not bar then
				local bar = win:CreateBar("current", L["Current"], 1, 1)
				local c = win:GetDefaultBarColor()
				bar:SetColorAt(0,c.r,c.g,c.b, c.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then win:DisplayModes("current") elseif button == "RightButton" then win:RightClick() end end)
			end
	
			for i, set in ipairs(sets) do
			
				local bar = win:GetBar(tostring(set.starttime))
				if not bar then
					local bar = win:CreateBar(tostring(set.starttime), set.name, 1, 1)
					bar:SetTimerLabel(date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime))
					local c = win:GetDefaultBarColor()
					bar:SetColorAt(0,c.r,c.g,c.b, c.a)
					bar:EnableMouse(true)
					if set.keep then
						bar:SetFont(nil,nil,"OUTLINE")
					end
					bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then win:DisplayModes(set.starttime) elseif button == "RightButton" then win:RightClick() end end)
				end
				
			end
		end
		
		-- Adjust our background frame if background height is dynamic.
		if win.bargroup.bgframe and win.db.background.height == 0 then
			self:AdjustBackgroundHeight(win)
		end
	end
	
	-- Mark as unchanged.
	changed = false
end

function Skada:AdjustBackgroundHeight(win)
	local numbars = 0
	if win:GetBars() ~= nil then
		for name, bar in pairs(win:GetBars()) do if bar:IsShown() then numbars = numbars + 1 end end
		local height = numbars * (win.db.barheight + win.db.barspacing) + win.db.background.borderthickness
		if win.bargroup.bgframe:GetHeight() ~= height then
			win.bargroup.bgframe:SetHeight(height)
		end
	end
end
		
function Skada:GetModes()
	return modes
end

--[[

API
Everything below this is OK to use in modes.

--]]

-- Formats a number into human readable form.
function Skada:FormatNumber(number)
	if number then
		if self.db.profile.numberformat == 1 then
			if number > 1000000 then
				return 	("%02.2fM"):format(number / 1000000)
			else
				return 	("%02.1fK"):format(number / 1000)
			end
		else
			return number
		end
	end
end

-- Register a mode.
function Skada:AddMode(mode)
	-- Ask mode to verify our sets.
	-- Needed in case we enable a mode and we have old data.
	if self.total then
		verify_set(mode, self.total)
	end
	if self.current then
		verify_set(mode, self.current)
	end
	for i, set in ipairs(sets) do
		verify_set(mode, set)
	end

	table.insert(modes, mode)
	
	-- Set this mode as the active mode if it matches the saved one.
	-- Bit of a hack.
	for i, win in ipairs(windows) do
		if mode.name == win.db.mode then
			self:RestoreView(win, win.db.set, mode.name)
		end
	end

	-- Find if we now have our chosen feed.
	-- Also a bit ugly.
	if selectedfeed == nil and self.db.profile.feed ~= "" then
		for name, feed in pairs(feeds) do
			if name == self.db.profile.feed then
				self:SetFeed(feed)
			end
		end
	end
	
	-- Sort modes.
	table.sort(modes, function(a, b) return a.name > b.name end)
	
	-- Remove all bars and start over to get ordering right.
	-- Yes, this all sucks - the problem with this and the above is that I don't know when
	-- all modules are loaded. :/
	for i, win in ipairs(windows) do
		win:RemoveAllBars()
		changed = true
	end
end

-- Unregister a mode.
function Skada:RemoveMode(mode)
	table.remove(modes, mode)
end

function Skada:GetFeeds()
	return feeds
end

-- Register a data feed.
function Skada:AddFeed(name, func)
	feeds[name] = func
end

-- Unregister a data feed.
function Skada:RemoveFeed(name, func)
	for i, feed in ipairs(feeds) do
		if feed.name == name then
			table.remove(feeds, i)
		end
	end
end

--[[

Sets

--]]

-- Returns true if we are interested in the unit. Include pets.
function Skada:UnitIsInteresting(name, id)
	return name and (UnitIsUnit("player",name) or UnitIsUnit("pet",name) or UnitPlayerOrPetInRaid(name) or UnitPlayerOrPetInParty(name) or (id and pets[id] ~= nil))
end

-- Returns true if we are interested in the unit. Does not include pets.
function Skada:UnitIsInterestingNoPets(name)
	return name and (UnitIsUnit("player",name) or UnitInRaid(name) or UnitInParty(name))
end

-- Returns the time (in seconds) a player has been active for a set.
function Skada:PlayerActiveTime(set, player)
	local maxtime = 0
	
	-- Add recorded time (for total set)
	if player.time > 0 then
		maxtime = player.time
	end
	
	-- Add in-progress time if set is not ended.
	if not set.endtime and player.first then
		maxtime = maxtime + player.last - player.first
	end
	return maxtime
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

-- Same thing, only takes two arguments and returns two arguments.
function Skada:FixMyPets(playerGUID, playerName)
	if not UnitIsPlayer(playerName) then
		local pet = pets[playerGUID]
		if pet then
			return pet.id, pet.name
		end
	end
	-- No pet match - return the player.
	return playerGUID, playerName
end
