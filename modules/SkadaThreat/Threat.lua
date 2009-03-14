local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local media = LibStub("LibSharedMedia-3.0")

-- This mode is a bit special.
local mod = Skada:NewModule("ThreatMode")

mod.name = L["Threat"]

local options = {
	type="group",
	name=L["Threat"],
	args={
		warnings = {
			type="group",
			name=L["Threat warning"],
			inline=true,
			order=1,
			args={
		
				flash = {
					type="toggle",
					name=L["Flash screen"],
					desc=L["This will cause the screen to flash as a threat warning."],
					get=function() return Skada.db.profile.modules.threatflash end,
					set=function(self, val) Skada.db.profile.modules.threatflash = val end,
					order=2,
				},
				
				shake = {
					type="toggle",
					name=L["Shake screen"],
					desc=L["This will cause the screen to shake as a threat warning."],
					get=function() return Skada.db.profile.modules.threatshake end,
					set=function(self, val) Skada.db.profile.modules.threatshake = not Skada.db.profile.modules.threatshake end,
					order=3,
				},
				
				playsound = {
					type="toggle",
					name=L["Play sound"],
					desc=L["This will play a sound as a threat warning."],
					get=function() return Skada.db.profile.modules.threatsound end,
					set=function(self, val) Skada.db.profile.modules.threatsound = not Skada.db.profile.modules.threatsound end,
					order=4,
				},
				
				sound = {
			         type = 'select',
			         dialogControl = 'LSM30_Sound',
			         name = L["Threat sound"],
			         desc = L["The sound that will be played when your threat percentage reaches a certain point."],
			         values = AceGUIWidgetLSMlists.sound,
			         get = function() return Skada.db.profile.modules.threatsoundname end,
			         set = function(self,val) Skada.db.profile.modules.threatsoundname = val end,
					order=5,
			    },
			    
				treshold = {
			         type = 'range',
			         name = L["Threat threshold"],
			         desc = L["When your threat reaches this level, relative to tank, warnings are shown."],
			         min=0,
			         max=130,
			         step=1,
			         get = function() return Skada.db.profile.modules.threattreshold end,
			         set = function(self,val) Skada.db.profile.modules.threattreshold = val end,
					order=6,
			    },			    
			},
		},
		
		rawthreat = {
			type = "toggle",
			name = L["Show raw threat"],
			desc = L["Shows raw threat percentage relative to tank instead of modified for range."],
			get = function() return Skada.db.profile.modules.threatraw end,
			set = function() Skada.db.profile.modules.threatraw = not Skada.db.profile.modules.threatraw end,
			order=2,
		},
				
	},
}

function mod:OnInitialize()
	-- Add our options.
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada-Threat", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada-Threat", "Threat", "Skada")
end

function mod:OnEnable()
	-- Add our feed.
	Skada:AddFeed(L["Threat: Personal Threat"], function()
								local current = Skada:GetCurrentSet()
								if current and UnitExists("target") then
									local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", "target")
									if threatpct then
										return ("%02.1f%%"):format(threatpct)
									end
								end
							end)
							
	-- Enable us
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

local maxthreat = 0

local function add_to_threattable(name, tbl)
	if name and UnitExists(name) then
		local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(name, "target")
	
		if Skada.db.profile.threatraw then
			if threatvalue then
				local class = select(2, UnitClass(name))
				table.insert(tbl, {["name"] = name, ["threat"] = threatvalue, ["class"] = class, ["value"] = threatvalue})
				if threatvalue > maxthreat then
					maxthreat = threatvalue
				end
			end
		else
			if threatpct then
				local class = select(2, UnitClass(name))
				table.insert(tbl, {["name"] = name, ["threat"] = threatpct, ["class"] = class, ["value"] = threatvalue})
			end
		end
	end
end

local function format_threatvalue(value)
	if value >= 100000 then
		return ("%2.1fk"):format(value / 100000)
	else
		return ("%d"):format(value / 100)
	end
end

local threattable = {}
local last_warn = time()

function mod:Update(win, set)
	if not UnitExists("target") then
		-- We have no target - wipe all threat bars.
		win:RemoveAllBars()
		return
	end
	
	-- Clear threat table
	while table.maxn(threattable) > 0 do table.remove(threattable) end
	
	maxthreat = 0
	
	if GetNumRaidMembers() > 0 then
		-- We are in a raid.
		for i = 1, 40, 1 do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			if name then
				add_to_threattable(name, threattable)
				
				if UnitExists("raid"..i.."pet") then
					add_to_threattable(select(1, UnitName("raid"..i.."pet")), threattable)
				end
			end
		end
	elseif GetNumPartyMembers() > 0 then
		-- We are in a party.
		for i = 1, 5, 1 do
			local name = (UnitName("party"..tostring(i)))
			if name then
				add_to_threattable(name, threattable)

				if UnitExists("party"..i.."pet") then
					add_to_threattable(select(1, UnitName("party"..i.."pet")), threattable)
				end
			end
		end
		
		-- Don't forget ourselves.
		add_to_threattable(UnitName("player"), threattable)
		
		-- Maybe we have a pet?
		if UnitExists("pet") then
			add_to_threattable(UnitName("pet"), threattable)
		end
	else
		-- We are all alone.
		add_to_threattable(UnitName("player"), threattable)
		
		-- Maybe we have a pet?
		if UnitExists("pet") then
			add_to_threattable(UnitName("pet"), threattable)
		end
	end

	-- For each bar, mark bar as unchecked.
	local bars = win:GetBars()
	if bars then
		for name, bar in pairs(bars) do
			bar.checked = false
		end
	end

	-- If we are going by raw threat we got the max threat from above; otherwise it's always 100.
	if not Skada.db.profile.threatraw then
		maxthreat = 100
	end
	
	local we_should_warn = false
	
	-- For each player in threat table, create or update bars.
	for i, player in ipairs(threattable) do
		if player.threat > 0 then
			local bar = win:GetBar(player.name)
			
			if player.name == UnitName("player") then
				if Skada.db.profile.modules.threattreshold and Skada.db.profile.modules.threattreshold < player.threat then
					we_should_warn = true
				end
			end
			
			if bar then
				bar:SetMaxValue(maxthreat)
				bar:SetValue(player.threat)
			else
				bar = win:CreateBar(player.name, player.name, player.threat, maxthreat, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then win:RightClick() end end)
				local color = Skada.classcolors[player.class] or win:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(format_threatvalue(player.value)..(", %02.1f%%"):format(player.threat / maxthreat * 100).."%")
			bar.checked = true
		end
	end
	
	-- Warn
	if we_should_warn and time() - last_warn > 2 then
		if Skada.db.profile.modules.threatflash then
			self:Flash()
		end
		if Skada.db.profile.modules.threatshake then
			self:Shake()
		end
		if Skada.db.profile.modules.threatsound then
			PlaySoundFile(media:Fetch("sound", Skada.db.profile.modules.threatsoundname)) 
		end
		
		last_warn = time()
	end
	
	-- Remove all unchecked bars.
	if bars then
		for name, bar in pairs(bars) do
			if not bar.checked then
				win:RemoveBar(bar)
			end
		end	
	end
	
	-- Sort the possibly changed bars.
	win:SortBars()
end

-- Shamelessly copied from Omen - thanks!
function mod:Flash()
	if not self.FlashFrame then
		local flasher = CreateFrame("Frame", "SkadaThreatFlashFrame")
		flasher:SetToplevel(true)
		flasher:SetFrameStrata("FULLSCREEN_DIALOG")
		flasher:SetAllPoints(UIParent)
		flasher:EnableMouse(false)
		flasher:Hide()
		flasher.texture = flasher:CreateTexture(nil, "BACKGROUND")
		flasher.texture:SetTexture("Interface\\FullScreenTextures\\LowHealth")
		flasher.texture:SetAllPoints(UIParent)
		flasher.texture:SetBlendMode("ADD")
		flasher:SetScript("OnShow", function(self)
			self.elapsed = 0
			self:SetAlpha(0)
		end)
		flasher:SetScript("OnUpdate", function(self, elapsed)
			elapsed = self.elapsed + elapsed
			if elapsed < 2.6 then
				local alpha = elapsed % 1.3
				if alpha < 0.15 then
					self:SetAlpha(alpha / 0.15)
				elseif alpha < 0.9 then
					self:SetAlpha(1 - (alpha - 0.15) / 0.6)
				else
					self:SetAlpha(0)
				end
			else
				self:Hide()
			end
			self.elapsed = elapsed
		end)
		self.FlashFrame = flasher
	end

	self.FlashFrame:Show()
end

-- Shamelessly copied from Omen (which copied from BigWigs) - thanks!
function mod:Shake()
	local shaker = self.ShakerFrame
	if not shaker then
		shaker = CreateFrame("Frame", "SkadaThreatShaker", UIParent)
		shaker:Hide()
		shaker:SetScript("OnUpdate", function(self, elapsed)
			elapsed = self.elapsed + elapsed
			local x, y = 0, 0 -- Resets to original position if we're supposed to stop.
			if elapsed >= 0.8 then
				self:Hide()
			else
				x, y = random(-8, 8), random(-8, 8)
			end
			if WorldFrame:IsProtected() and InCombatLockdown() then
				if not shaker.fail then
					shaker.fail = true
				end
				self:Hide()
			else
				WorldFrame:ClearAllPoints()
				for i = 1, #self.originalPoints do
					local v = self.originalPoints[i]
					WorldFrame:SetPoint(v[1], v[2], v[3], v[4] + x, v[5] + y)
				end
			end
			self.elapsed = elapsed
		end)
		shaker:SetScript("OnShow", function(self)
			-- Store old worldframe positions, we need them all, people have frame modifiers for it
			if not self.originalPoints then
				self.originalPoints = {}
				for i = 1, WorldFrame:GetNumPoints() do
					tinsert(self.originalPoints, {WorldFrame:GetPoint(i)})
				end
			end
			self.elapsed = 0
		end)
		self.ShakerFrame = shaker
	end

	shaker:Show()
end
