Skada = LibStub("AceAddon-3.0"):NewAddon("Skada", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0", "SpecializedLibBars-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local icon = LibStub("LibDBIcon-1.0")
local win = LibStub("LibWindow-1.1")
local media = LibStub("LibSharedMedia-3.0")

local dataobj = ldb:NewDataObject("Skada", {label = "Skada", type = "data source", icon = "Interface\\Icons\\Spell_Lightning_LightningBolt01", text = "n/a"})

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

-- The selected data feed.
local selectedfeed = nil

-- A list of data feeds available. Modules add to it.
local feeds = {}

-- Determines if the GetDefaultColor functions returns the alternate color.
local usealt = true

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

	-- Window
	self.bargroup = self:NewBarGroup("Skada", nil, self.db.profile.barwidth, self.db.profile.barheight, "SkadaBarWindow")
	self.bargroup.RegisterCallback(self,"AnchorMoved")
	self.bargroup.RegisterCallback(self,"AnchorClicked")
	self.bargroup:EnableMouse(true)
	self.bargroup:SetScript("OnMouseDown", function(self, button) if button == "RightButton" then Skada:RightClick() end end)
	self.bargroup:HideIcon()
	
	self:RegisterChatCommand("skada", "Command")
	self.db.RegisterCallback(self, "OnProfileChanged", "ReloadSettings")
	self.db.RegisterCallback(self, "OnProfileCopied", "ReloadSettings")
	self.db.RegisterCallback(self, "OnProfileReset", "ReloadSettings")
	
	self:ReloadSettings()
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
	elseif chantype == "WHISPER" then
		-- To player.
		SendChatMessage(msg, "WHISPER", GetDefaultLanguage("player"), chan)
	elseif chantype == "CHANNEL" then
		-- To channel.
		SendChatMessage(msg, "CHANNEL", GetDefaultLanguage("player"), select(1, GetChannelName(chan)))
	elseif chantype == "preset" then
		-- To a preset channel id (say, guild, etc).
		SendChatMessage(msg, string.upper(chan))
	end
end

-- Sends a report of the currently active set and mode to chat. 
function Skada:Report(chan, chantype, max)
	local set = self:get_selected_set()
	local mode = selectedmode
	
	if set and mode then
		local bars = self:GetBars()
		local list = {}
		
		for name, bar in pairs(bars) do table.insert(list, bar)	end

		-- Sort our temporary table according to value.
		table.sort(list, function(a,b) return a.value > b.value end)
	
		-- Title
		local endtime = set.endtime or time()
		sendchat(string.format(L["Skada report on %s for %s, %s to %s:"], selectedmode.name, set.name, date("%X",set.starttime), date("%X",endtime)), chan, chantype)
		
		-- For each active bar, print label and timer value.
		for i, bar in ipairs(list) do
			sendchat(("%s   %s"):format(bar:GetLabel(), bar:GetTimerLabel()), chan, chantype)
			if i == max or (max == 0 and i == self.db.profile.barmax) then
				break
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
	if IsShiftKeyDown() then
		Skada:OpenMenu()
	elseif button == "RightButton" then
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
			Skada.bargroup:Hide()
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
			Skada.bargroup:Show()
			Skada:SortBars()
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
		self.bargroup:SortBars()
	end
end

local function createSet(setname)
	local set = {players = {}, name = setname, starttime = time(), ["time"] = 0, last_action = time()}

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
		wipe(current)
		current = createSet(L["Current"])
	end
	if total ~= nil then
		wipe(total)
		total = createSet(L["Total"])
		self.db.profile.total = total
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

function Skada:OpenMenu()

	local report_channel = "Say"
	local report_number = 10
	local report_mode = nil
	if selectedmode then
		report_mode = selectedmode
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
	        info.text = "Skada Menu"
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = "Switch to mode"
	        info.hasArrow = 1
	        info.value = "show"
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)

	        wipe(info)
	        info.text = "Report"
	        info.hasArrow = 1
	        info.value = "report"
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = "Delete segment"
	        info.func = function() Skada:DeleteSet() end
	        info.hasArrow = 1
	        info.notCheckable = 1
	        info.value = "delete"
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = "Keep segment"
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
	        info.text = "Toggle window"
	        info.func = function() Skada:ToggleWindow() end
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)

	        wipe(info)
	        info.text = "Configure"
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
		    if UIDROPDOWNMENU_MENU_VALUE == "show" then
		        for i, module in ipairs(Skada:GetModes()) do
			        wipe(info)
		            info.text = module.name
		            info.func = function() Skada:DisplayMode(module) end
			        info.notCheckable = 1
		            UIDropDownMenu_AddButton(info, level)
		        end
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
		        info.text = "Mode"
		        info.hasArrow = 1
		        info.value = "modes"
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
		        info.text = "Lines"
		        info.hasArrow = 1
		        info.value = "number"
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
		        info.text = "Channel"
		        info.hasArrow = 1
		        info.value = "channels"
		        info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		        
		        wipe(info)
		        info.text = "Send report"
		        info.func = function()
		        				if report_mode ~= nil then
		        					-- Reporting is done on current bars... so we have to switch to the selected mode.
		        					local old_mode = selectedmode
			        				Skada:DisplayMode(report_mode)
			        				Skada:UpdateBars()
			        				if report_channel == "Self" then
										Skada:Report(report_channel, "self", report_number)
									else
										Skada:Report(report_channel, "preset", report_number)
									end
									-- Switch back to previous mode. Can you say "ugly"?
									if old_mode then
										Skada:DisplayMode(old_mode)
				        				Skada:UpdateBars()
									end
								else
									self:Print("No mode selected for report.")
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
		    elseif UIDROPDOWNMENU_MENU_VALUE == "number" then
		        for i = 1,10 do
			        wipe(info)
		            info.text = i
		            info.checked = (report_number == i)
		            info.func = function() report_number = i end
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "channels" then
		        wipe(info)
	            
		        info.text = "Say"
		        info.checked = (report_channel == "Say")
		        info.func = function() report_channel = "Say" end
		        UIDropDownMenu_AddButton(info, level)
        
	            info.text = "Raid"
	            info.checked = (report_channel == "Raid")
	            info.func = function() report_channel = "Raid" end
	            UIDropDownMenu_AddButton(info, level)

	            info.text = "Party"
	            info.checked = (report_channel == "Party")
	            info.func = function() report_channel = "Party" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = "Guild"
	            info.checked = (report_channel == "Guild")
	            info.func = function() report_channel = "Guild" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = "Officer"
	            info.checked = (report_channel == "Officer")
	            info.func = function() report_channel = "Officer" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = "Self"
	            info.checked = (report_channel == "Self")
	            info.func = function() report_channel = "Self" end
	            UIDropDownMenu_AddButton(info, level)
		    end
		
	    end
	end
	
	local x,y = GetCursorPosition(UIParent); 
	ToggleDropDownMenu(1, nil, skadamenu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale())
end

function Skada:ReloadSettings()
	total = self.db.profile.total
	sets = self.db.profile.sets
	
	-- Restore window position.
	win.RegisterConfig(self.bargroup, self.db.profile)
	win.RestorePosition(self.bargroup)

	-- Minimap button.
	if not icon:IsRegistered("Skada") then
		icon:Register("Skada", dataobj, self.db.profile.icon)
	else
		icon:Refresh("Skada", self.db.profile.icon)
	end
	self:ShowMMButton(self.db.profile.mmbutton)
	
	self:ApplySettings()
end

local function getNumberOfBars()
	local bars = Skada.bargroup:GetBars()
	local n = 0
	for i, bar in pairs(bars) do n = n + 1 end
	return n
end

local function OnMouseWheel(frame, direction)
	if direction == 1 and Skada.bargroup:GetBarOffset() > 0 then
		Skada.bargroup:SetBarOffset(Skada.bargroup:GetBarOffset() - 1)
	elseif direction == -1 and ((getNumberOfBars() - Skada.bargroup:GetMaxBars() - Skada.bargroup:GetBarOffset()) > 0) then
		Skada.bargroup:SetBarOffset(Skada.bargroup:GetBarOffset() + 1)
	end
end

local titlebackdrop = {}
local windowbackdrop = {}

-- Applies settings to things like the bar window.
function Skada:ApplySettings()
	local g = self.bargroup
	local p = self.db.profile
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
	
	if p.window.enabletitle then
		g:ShowAnchor()
	else
		g:HideAnchor()
	end
	
	-- Window
	if p.window.enablebackground then
		if g.bgframe == nil then
			g.bgframe = CreateFrame("Frame", nil, self.bargroup)
			g.bgframe:SetFrameStrata("BACKGROUND")
			g.bgframe:EnableMouse()
			g.bgframe:EnableMouseWheel()
			g.bgframe:SetScript("OnMouseDown", function(frame, btn) if btn == "RightButton" then Skada:RightClick() end end)
			g.bgframe:SetScript("OnMouseWheel", OnMouseWheel)
		end

		local inset = p.window.margin
		windowbackdrop.bgFile = media:Fetch("statusbar", p.window.texture)
		if p.window.borderthickness > 0 then
			windowbackdrop.edgeFile = media:Fetch("border", p.window.bordertexture)
		else
			windowbackdrop.edgeFile = nil
		end
		windowbackdrop.tile = false
		windowbackdrop.tileSize = 0
		windowbackdrop.edgeSize = p.window.borderthickness
		windowbackdrop.insets = {left = inset, right = inset, top = inset, bottom = inset}
		g.bgframe:SetBackdrop(windowbackdrop)
		local color = p.window.color
		g.bgframe:SetBackdropColor(color.r, color.g, color.b, color.a or 1)
		g.bgframe:SetWidth(g:GetWidth() + (p.window.borderthickness * 2))
		g.bgframe:SetHeight(p.window.height)

		g.bgframe:ClearAllPoints()
		if p.reversegrowth then
			g.bgframe:SetPoint("LEFT", g.button, "LEFT", -p.window.borderthickness, 0)
			g.bgframe:SetPoint("RIGHT", g.button, "RIGHT", p.window.borderthickness, 0)
			g.bgframe:SetPoint("BOTTOM", g.button, "TOP", 0, 0)
		else
			g.bgframe:SetPoint("LEFT", g.button, "LEFT", -p.window.borderthickness, 0)
			g.bgframe:SetPoint("RIGHT", g.button, "RIGHT", p.window.borderthickness, 0)
			g.bgframe:SetPoint("TOP", g.button, "BOTTOM", 0, 0)
		end
		g.bgframe:Show()
		
		-- Calculate max number of bars to show if our height is not dynamic.
		if p.window.height > 0 then
			local maxbars = math.floor(p.window.height / math.max(1, p.barheight + p.barspacing))
			g:SetMaxBars(maxbars)
		else
			-- Adjust background height according to current bars.
			self:AdjustBackgroundHeight()
		end
		
	elseif g.bgframe then
		g.bgframe:Hide()
	end
	
	if self.db.profile.window.shown then
		-- Don't show window if we are solo and we have enabled the "Hide when solo" option.
		if not (self.db.profile.hidesolo and GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0) then
			self.bargroup:Show()
		else
			self.bargroup:Hide()
		end
	else
		self.bargroup:Hide()
	end

	g:SortBars()
	
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
	if current and not InCombatLockdown() and not UnitIsDead("player") and not IsRaidInCombat() then
	
		-- Save current set unless this a trivial set, or if we have the Only keep boss fights options on, and no boss in fight.
		-- A set is trivial if we have no mob name saved, or if total time for set is not more than 5 seconds.
		if not self.db.profile.onlykeepbosses or current.gotboss then
			if current.mobname ~= nil and time() - current.starttime > 5 then
				-- End current set.
				current.endtime = time()
				current.time = current.endtime - current.starttime
				setPlayerActiveTimes(current)
				current.name = current.mobname
				
				-- Tell each mode that set has finished and do whatever it wants to do about it.
				for i, mode in ipairs(modes) do
					if mode.SetComplete ~= nil then
						mode:SetComplete(current)
					end
				end
				
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

function Skada:PLAYER_REGEN_DISABLED()
	-- Start a new set if we are not in one already.
	if not current then
		self:StartCombat()
	end
end

function Skada:StartCombat()
	-- Remove old bars.
	self:RemoveAllBars()
	
	-- Create a new current set.
	current = createSet(L["Current"])

	-- Also start the total set if it is nil.
	if total == nil then
		total = createSet(L["Total"])
		self.db.profile.total = total
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
	
	-- Force immediate update.
	self:UpdateBars()
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

-- Returns a player from the current. Safe to use to simply 
function Skada:find_player(set, playerid)
	local player = nil
	for i, p in ipairs(set.players) do
		if p.id == playerid then
			player = p
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

-- Save boss name and mark set as having a boss.
function Skada:UNIT_TARGET(event, unitId)
	if current and unitId and not UnitIsDead("target") and (UnitClassification(unitId.."target") == "worldboss" or UnitClassification(unitId.."target") == "boss") and not current.gotboss then
		current.gotboss = true
		current.mobname = UnitName(unitId.."target")
	end
end

function Skada:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, ...)
	-- Detect combat start.
	-- Not happy about this, really. Why can't there be a UNIT_ENTERED_COMBAT?
	if not current and srcName and dstName and Skada:UnitIsInteresting(srcName) and (eventtype == 'SPELL_DAMAGE' or eventtype == 'SPELL_PERIODIC_DAMAGE' or eventtype == 'SPELL_BUILDING_DAMAGE' or eventtype == 'RANGE_DAMAGE' or eventtype == "SWING_DAMAGE") then
		self:StartCombat()
	end

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
	--if current and srcName and (self:UnitIsInteresting(srcName) or self:UnitIsInteresting(dstName)) then
	--	changed = true
	--end
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

	if selectedmode then

		local set = self:get_selected_set()
		
		-- If we have a set, go on.
		if set then
			-- Let mode handle the rest.
			selectedmode:Update(set)
		end
		
	elseif selectedset then
		local set = self:get_selected_set()
		
		-- View available modes.
		for i, mode in ipairs(modes) do
			local bar = self.bargroup:GetBar(mode.name)
			if not bar then
				bar = self:CreateBar(mode.name, mode.name, 1, 1)
				local c = self:GetDefaultBarColor()
				bar:SetColorAt(0,c.r,c.g,c.b, c.a)
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayMode(mode) elseif button == "RightButton" then Skada:RightClick() end end)
			end
			if set and mode.GetSetSummary ~= nil then
				bar:SetTimerLabel(mode:GetSetSummary(set))
			end

		end
		
		self:SortBars()
	else
		-- View available sets.
		local bar = self:GetBar("total")
		if not bar then
			local bar = self:CreateBar("total", L["Total"], 1, 1)
			local c = self:GetDefaultBarColor()
			bar:SetColorAt(0,c.r,c.g,c.b, c.a)
			bar:EnableMouse(true)
			bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes("total") elseif button == "RightButton" then Skada:RightClick() end end)
		end

		local bar = self:GetBar("current")
		if not bar then
			local bar = self:CreateBar("current", L["Current"], 1, 1)
			local c = self:GetDefaultBarColor()
			bar:SetColorAt(0,c.r,c.g,c.b, c.a)
			bar:EnableMouse(true)
			bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes("current") elseif button == "RightButton" then Skada:RightClick() end end)
		end

		for i, set in ipairs(sets) do
		
			local bar = self:GetBar(tostring(set.starttime))
			if not bar then
				local bar = self:CreateBar(tostring(set.starttime), set.name, 1, 1)
				bar:SetTimerLabel(date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime))
				local c = self:GetDefaultBarColor()
				bar:SetColorAt(0,c.r,c.g,c.b, c.a)
				bar:EnableMouse(true)
				if set.keep then
					bar:SetFont(nil,nil,"OUTLINE")
				end
				bar:SetScript("OnMouseDown", function(bar, button) if button == "LeftButton" then Skada:DisplayModes(set.starttime) elseif button == "RightButton" then Skada:RightClick() end end)
			end
			
		end
	end
	
	-- Adjust our background frame if background height is dynamic.
	if self.bargroup.bgframe and self.db.profile.window.height == 0 then
		self:AdjustBackgroundHeight()
	end
	
	-- Mark as unchanged.
	changed = false
end

function Skada:AdjustBackgroundHeight()
	local numbars = 0
	if self:GetBars() ~= nil then
		for name, bar in pairs(self:GetBars()) do if bar:IsShown() then numbars = numbars + 1 end end
		local height = numbars * (self.db.profile.barheight + self.db.profile.barspacing) + self.db.profile.window.borderthickness
		if self.bargroup.bgframe:GetHeight() ~= height then
			self.bargroup.bgframe:SetHeight(height)
		end
	end
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
	self:SetSortFunction(function(a,b) return a.name < b.name end)

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


--[[

API
Everything below this is OK to use in modes.

--]]

-- Formats a number into human readable form.
function Skada:FormatNumber(number)
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

-- Register a mode.
function Skada:AddMode(mode)
	-- Ask mode to verify our sets.
	-- Needed in case we enable a mode and we have old data.
	for i, set in ipairs(sets) do
		if mode.AddSetAttributes ~= nil then
			mode:AddSetAttributes(set)
		end
		for j, player in ipairs(set.players) do
			if mode.AddPlayerAttributes ~= nil then
				mode:AddPlayerAttributes(player)
			end
		end
	end

	table.insert(modes, mode)
	
	-- Set this mode as the active mode if it matches the saved one.
	-- Bit of a hack.
	if mode.name == self.db.profile.mode then
		self:RestoreView(selectedset, mode.name)
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
	self:RemoveAllBars()
	changed = true
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

Bars

--]]

function Skada:GetDefaultBarColorOne()
	return self.db.profile.barcolor
end

function Skada:GetDefaultBarColorTwo()
	return self.db.profile.baraltcolor
end

function Skada:GetDefaultBarColor()
	usealt = not usealt
	if usealt == true then
		return self.db.profile.baraltcolor
	else
		return self.db.profile.barcolor
	end
end

function Skada:GetBarGroup()
	return self.bargroup
end

function Skada:SetSortFunction(func)
	self.bargroup:SetSortFunction(func)
end

function Skada:SortBars(func)
	if func then
		local oldfunc = self.bargroup:GetSortFunction()
		self:SetSortFunction(func)
		self.bargroup:SortBars()
		self:SetSortFunction(oldfunc)
	else
		self.bargroup:SortBars()
	end
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
	local bar = self.bargroup:NewCounterBar(name, label, value, maxvalue, icon, o)
	bar:EnableMouseWheel(true)
	bar:SetScript("OnMouseWheel", OnMouseWheel)
	return bar
end

function Skada:RemoveAllBars()
	usealt = true
	
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


--[[

Sets

--]]

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
