local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

-- This mode is a bit special.
local mod = Skada:NewModule("ThreatMode")

mod.name = L["Threat"]

local options = {
	type="group",
	name=L["Threat"],
	args={
		rawthreat = {
			type = "toggle",
			name = L["Show raw threat"],
			desc = L["Shows raw threat percentage relative to tank instead of modified for range."],
			get = function() return Skada.db.profile.rawthreat end,
			set = function() Skada.db.profile.rawthreat = not Skada.db.profile.rawthreat end,
			order=1,
		},
	},
}

function mod:OnInitialize()
	-- Add our options.
	LibStub("AceConfig-3.0"):RegisterOptionsTable("Skada-Threat", options)
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Skada-Threat", "Threat", "Skada")
end

function mod:OnEnable()
	-- Listen for target changes
	

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
	
		if Skada.db.profile.rawthreat then
			if threatvalue then
				local class = select(2, UnitClass(name))
				table.insert(tbl, {["name"] = name, ["threat"] = threatvalue, ["class"] = class})
				if threatvalue > maxthreat then
					maxthreat = threatvalue
				end
			end
		else
			if threatpct then
				local class = select(2, UnitClass(name))
				table.insert(tbl, {["name"] = name, ["threat"] = threatpct, ["class"] = class})
			end
		end
	end
end

function mod:Update(set)
	if not UnitExists("target") then
		-- We have no target - wipe all threat bars.
		Skada:RemoveAllBars()
		return
	end
	
	local threattable = {}
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

				if UnitExists("raid"..i.."pet") then
					add_to_threattable(select(1, UnitName("party"..i.."pet")), threattable)
				end
			end
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
	local bars = Skada:GetBars()
	if bars then
		for name, bar in pairs(bars) do
			bar.checked = false
		end
	end

	-- If we are going by raw threat we got the max threat from above; otherwise it's always 100.
	if not Skada.db.profile.rawthreat then
		maxthreat = 100
	end
	
	-- For each player in threat table, create or update bars.
	for i, player in ipairs(threattable) do
		if player.threat > 0 then
			local bar = Skada:GetBar(player.name)
			if bar then
				bar:SetMaxValue(maxthreat)
				bar:SetValue(player.threat)
			else
				bar = Skada:CreateBar(player.name, player.name, player.threat, maxthreat, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then Skada:RightClick() end end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			end
			bar:SetTimerLabel(("%02.1f%%"):format(player.threat / maxthreat * 100).."%")
			bar.checked = true
		end
	end
	
	-- Remove all unchecked bars.
	if bars then
		for name, bar in pairs(bars) do
			if not bar.checked then
				Skada:RemoveBar(bar)
			end
		end	
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end