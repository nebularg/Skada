local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)
local AceGUI = LibStub("AceGUI-3.0")

if not StaticPopupDialogs["ResetSkadaDialog"] then
	StaticPopupDialogs["ResetSkadaDialog"] = {
		text = L["Do you want to reset Skada?"], 
		button1 = ACCEPT, 
		button2 = CANCEL,
		timeout = 30, 
		whileDead = 0, 
		hideOnEscape = 1, 
		OnAccept = function() Skada:Reset() end,
	}
end

-- Configuration menu.
function Skada:OpenMenu(window)
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
	        
			for i, win in ipairs(Skada:GetWindows()) do
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

			-- Can't report if we are not in a mode.
			if not window or (window or window.selectedmode) then
		        wipe(info)
		        info.text = L["Report"]
				info.func = function() Skada:OpenReportWindow(window) end
		        info.value = "report"
				info.notCheckable = 1
		        UIDropDownMenu_AddButton(info, level)
		    end
	        
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
	        info.text = L["Reset"]
	        info.func = function() Skada:Reset() end
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)
	        
	        wipe(info)
	        info.text = L["Start new segment"]
	        info.func = function() Skada:NewSegment() end
	        info.notCheckable = 1
	        UIDropDownMenu_AddButton(info, level)


	        wipe(info)
	        info.text = L["Configure"]
	        info.func = function() InterfaceOptionsFrame_OpenToCategory("Skada") end
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
		            info.text = module:GetName()
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
	            				Skada:Wipe()
	            				Skada:UpdateDisplay(true)
	            			end
	            info.checked = (window.selectedset == "total")
	            UIDropDownMenu_AddButton(info, level)
		        wipe(info)
	            info.text = L["Current"]
	            info.func = function()
	            				window.selectedset = "current"
	            				Skada:Wipe()
	            				Skada:UpdateDisplay(true)
	            			end
	            info.checked = (window.selectedset == "current")
	            UIDropDownMenu_AddButton(info, level)

		        for i, set in ipairs(Skada:GetSets()) do
			        wipe(info)
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() 
		            				window.selectedset = i
		            				Skada:Wipe()
		            				Skada:UpdateDisplay(true)
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

		        wipe(info)
	            info.text = L["Hide window"]
	            info.func = function() if window:IsShown() then window.db.hidden = true; window:Hide() else window.db.hidden = false; window:Show() end end
	            info.checked = not window:IsShown()
		        UIDropDownMenu_AddButton(info, level)
				
		    elseif UIDROPDOWNMENU_MENU_VALUE == "delete" then
		        for i, set in ipairs(Skada:GetSets()) do
			        wipe(info)
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() Skada:DeleteSet(set) end
			        info.notCheckable = 1
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "keep" then
		        for i, set in ipairs(Skada:GetSets()) do
			        wipe(info)
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() 
		            				set.keep = not set.keep
		            				Skada:Wipe()
		            				Skada:UpdateDisplay(true)
		            			end
		            info.checked = set.keep
		            UIDropDownMenu_AddButton(info, level)
		        end
		    end
		elseif level == 3 then
		    if UIDROPDOWNMENU_MENU_VALUE == "modes" then

		        for i, module in ipairs(Skada:GetModes()) do
			        wipe(info)
		            info.text = module:GetName()
		            info.checked = (Skada.db.profile.report.mode == module:GetName())
		            info.func = function() Skada.db.profile.report.mode = module:GetName() end
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "segment" then
		        wipe(info)
	            info.text = L["Total"]
	            info.func = function() Skada.db.profile.report.set = "total" end
	            info.checked = (Skada.db.profile.report.set == "total")
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Current"]
	            info.func = function() Skada.db.profile.report.set = "current" end
	            info.checked = (Skada.db.profile.report.set == "current")
	            UIDropDownMenu_AddButton(info, level)

		        for i, set in ipairs(sets) do
		            info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
		            info.func = function() Skada.db.profile.report.set = i end
		            info.checked = (Skada.db.profile.report.set == i)
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "number" then
		        for i = 1,25 do
			        wipe(info)
		            info.text = i
		            info.checked = (Skada.db.profile.report.number == i)
		            info.func = function() Skada.db.profile.report.number = i end
		            UIDropDownMenu_AddButton(info, level)
		        end
		    elseif UIDROPDOWNMENU_MENU_VALUE == "channel" then
		        wipe(info)
		        info.text = L["Whisper"]
		        info.checked = (Skada.db.profile.report.chantype == "whisper")
		        info.func = function() Skada.db.profile.report.channel = "Whisper"; Skada.db.profile.report.chantype = "whisper" end
		        UIDropDownMenu_AddButton(info, level)
		        
		        info.text = L["Say"]
		        info.checked = (Skada.db.profile.report.channel == "Say")
		        info.func = function() Skada.db.profile.report.channel = "Say"; Skada.db.profile.report.chantype = "preset" end
		        UIDropDownMenu_AddButton(info, level)
        
	            info.text = L["Raid"]
	            info.checked = (Skada.db.profile.report.channel == "Raid")
	            info.func = function() Skada.db.profile.report.channel = "Raid"; Skada.db.profile.report.chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)

	            info.text = L["Party"]
	            info.checked = (Skada.db.profile.report.channel == "Party")
	            info.func = function() Skada.db.profile.report.channel = "Party"; Skada.db.profile.report.chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Guild"]
	            info.checked = (Skada.db.profile.report.channel == "Guild")
	            info.func = function() Skada.db.profile.report.channel = "Guild"; Skada.db.profile.report.chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Officer"]
	            info.checked = (Skada.db.profile.report.channel == "Officer")
	            info.func = function() Skada.db.profile.report.channel = "Officer"; Skada.db.profile.report.chantype = "preset" end
	            UIDropDownMenu_AddButton(info, level)
	            
	            info.text = L["Self"]
	            info.checked = (Skada.db.profile.report.chantype == "self")
	            info.func = function() Skada.db.profile.report.channel = "Self"; Skada.db.profile.report.chantype = "self" end
	            UIDropDownMenu_AddButton(info, level)
	            
				local list = {GetChannelList()}
				for i=1,table.getn(list)/2 do
					info.text = list[i*2]
					info.checked = (Skada.db.profile.report.channel == list[i*2])
					info.func = function() Skada.db.profile.report.channel = list[i*2]; Skada.db.profile.report.chantype = "channel" end
					UIDropDownMenu_AddButton(info, level)
				end	            
	            
		    end
		
	    end
	end
	
	local x,y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, skadamenu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale())
end

function Skada:SegmentMenu(window)
	if not self.segmentsmenu then
		self.segmentsmenu = CreateFrame("Frame", "SkadaWindowButtonsSegments")
	end
	local segmentsmenu = self.segmentsmenu
	
	segmentsmenu.displayMode = "MENU"
	local info = {}
	segmentsmenu.initialize = function(self, level)
	    if not level then return end
	
		info.isTitle = 1
		info.text = L["Segment"]
		UIDropDownMenu_AddButton(info, level)
		info.isTitle = nil
		
		wipe(info)
		info.text = L["Total"]
		info.func = function()
						window.selectedset = "total"
						window.changed = true
						Skada:UpdateDisplay(false)
					end
		info.checked = (window.selectedset == "total")
		UIDropDownMenu_AddButton(info, level)
		
		wipe(info)
		info.text = L["Current"]
		info.func = function()
						window.selectedset = "current"
						window.changed = true
						Skada:UpdateDisplay(false)
					end
		info.checked = (window.selectedset == "current")
		UIDropDownMenu_AddButton(info, level)
		
		for i, set in ipairs(Skada:GetSets()) do
		    wipe(info)
			info.text = set.name..": "..date("%H:%M",set.starttime).." - "..date("%H:%M",set.endtime)
			info.func = function() 
							window.selectedset = i
							window.changed = true
							Skada:UpdateDisplay(false)
						end
			info.checked = (window.selectedset == i)
			UIDropDownMenu_AddButton(info, level)
		end
	end
	local x,y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, segmentsmenu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale())
end

function Skada:ModeMenu(window)
	--Spew("window", window)
	if not self.modesmenu then
		self.modesmenu = CreateFrame("Frame", "SkadaWindowButtonsModes")
	end
	local modesmenu = self.modesmenu
	
	modesmenu.displayMode = "MENU"
	local info = {}
	modesmenu.initialize = function(self, level)
	    if not level then return end
		
		info.isTitle = 1
		info.text = L["Mode"]
		UIDropDownMenu_AddButton(info, level)
		
		for i, module in ipairs(Skada:GetModes()) do
			wipe(info)
			info.text = module:GetName()
			info.func = function() window:DisplayMode(module) end
			info.checked = (window.selectedmode == module)
			UIDropDownMenu_AddButton(info, level)
		end
	end
	local x,y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, modesmenu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale())
end

function Skada:OpenReportWindow(window)
	if self.ReportWindow==nil then
		self:CreateReportWindow(window)
	end
	
	--self:UpdateReportWindow()
	self.ReportWindow:Show()
end

local function destroywindow()
	if Skada.ReportWindow then
		Skada.ReportWindow:ReleaseChildren()
		Skada.ReportWindow:Hide()
		Skada.ReportWindow:Release()
	end
	Skada.ReportWindow = nil
end

function Skada:CreateReportWindow(window)
	-- ASDF = window
	self.ReportWindow = AceGUI:Create("Window")
	local frame = self.ReportWindow
	frame:EnableResize(nil)
	frame:SetWidth(250)
	frame:SetLayout("Flow")
	frame:SetHeight(300)
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	frame:SetTitle(L["Report"] .. (" - %s"):format(window.db.name))
	frame:SetCallback("OnClose", function(widget, callback)
		destroywindow()
	end)
	
	local lines = AceGUI:Create("Slider")
	lines:SetLabel(L["Lines"])
	lines:SetValue(Skada.db.profile.report.number ~= nil and Skada.db.profile.report.number	 or 10)
	lines:SetSliderValues(1, 25, 1)
	lines:SetCallback("OnValueChanged", function(self,event, value) 
		Skada.db.profile.report.number = value
		-- Spew("value", value)
	end)
	lines:SetFullWidth(true)
	
	local channeltext = AceGUI:Create("Label")
	channeltext:SetText(L["Channel"])
	channeltext:SetFullWidth(true)
	frame:AddChildren(lines, channeltext)
	
	
	local channellist = {
		{"Whisper", "whisper"},
		{"Whisper Target", "whisper"},
		{"Say", "preset"},
		{"Raid", "preset"},
		{"Party", "preset"},
		{"Guild", "preset"},
		{"Officer", "preset"},
		{"Self", "self"},
	}
	local list = {GetChannelList()}
	for i=2, #list, 2 do
		if list[i] ~= "Trade" and list[i] ~= "General" and list[i] ~= "LookingForGroup" then
			channellist[#channellist+1] = {list[i], "channel"}
		end
	end
	for i=1,#channellist do
		--print(channellist[i][1], channellist[i][2])
		local checkbox = AceGUI:Create("CheckBox")
		_G["SkadaReportCheck" .. i] = checkbox
		checkbox:SetType("radio")
		checkbox:SetRelativeWidth(0.5)
		-- checkbox:SetValue(false)
		if Skada.db.profile.report.chantype == "channel" then
			if channellist[i][1] == Skada.db.profile.report.channel then
				frame.channel = channellist[i][1]
				frame.chantype = channellist[i][2]
				checkbox:SetValue(true)
			end
		elseif Skada.db.profile.report.chantype == "whisper" then
			if channellist[i][1] == "Whisper" then
				-- frame.channel = channellist[i][1]
				frame.chantype = channellist[i][2]
				checkbox:SetValue(true)
			end
		elseif Skada.db.profile.report.chantype == "preset" then
			-- print("pass")
			if rawget(L, channellist[i][1]) and L[channellist[i][1]] == Skada.db.profile.report.channel then
				frame.channel = channellist[i][1]
				frame.chantype = channellist[i][2]
				checkbox:SetValue(true)
			end
		elseif Skada.db.profile.report.chantype == "self" then
			if channellist[i][2] == "self" then
				frame.channel = channellist[i][1]
				frame.chantype = channellist[i][2]
				checkbox:SetValue(true)
			end
		end
		if i == 2 or i >= 9 then
			checkbox:SetLabel(channellist[i][1])
		else
			checkbox:SetLabel(L[channellist[i][1]])
		end
		checkbox:SetCallback("OnValueChanged", function(value)
			
			for i=1, #channellist do
				local c = getglobal("SkadaReportCheck"..i)
				if c ~= nil and c ~= checkbox then
					c:SetValue(false)
				end
				if c == checkbox then
					frame.channel = channellist[i][1]
					frame.chantype = channellist[i][2]
				end
			end 
		end)
		frame:AddChild(checkbox)
	end
	
	local whisperbox = AceGUI:Create("EditBox")
	whisperbox:SetLabel("Whisper Target")
	if Skada.db.profile.report.chantype == "whisper" and Skada.db.profile.report.channel ~= L["Whisper"] then
		whisperbox:SetText(Skada.db.profile.report.channel)
		frame.target = Skada.db.profile.report.channel
	end
	whisperbox:SetCallback("OnEnterPressed", function(box, event, text) frame.target = text frame.button.frame:Click() end)
	whisperbox:SetCallback("OnTextChanged", function(box, event, text) frame.target = text end)
	whisperbox:SetFullWidth(true)
	
	local report = AceGUI:Create("Button")
	frame.button = report
	report:SetText(L["Report"])
	report:SetCallback("OnClick", function()
		if frame.channel == "Whisper" then
			frame.channel = frame.target
		end
		if frame.channel == "Whisper Target" then
			if UnitExists("target") then
				frame.channel = UnitName("target")
			else
				frame.channel = nil
			end
		end
		-- print(tostring(frame.channel), tostring(frame.chantype), tostring(window.db.mode))
		if frame.channel and frame.chantype and window.db.mode then
			Skada.db.profile.report.channel = frame.channel
			Skada.db.profile.report.chantype = frame.chantype
			
			Skada:Report(frame.channel, frame.chantype, window.db.mode, Skada.db.profile.report.set, Skada.db.profile.report.number, window)
			frame:Hide()
		else
			Skada:Print("Error: No options selected")
		end
		
	end)
	report:SetFullWidth(true)
	frame:AddChildren(whisperbox, report)
	frame:SetHeight(180 + 27* math.ceil(#channellist/2))
end
