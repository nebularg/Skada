local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

-- This mode is a bit special.
local mod = Skada:NewModule("ThreatMode")

mod.name = L["Threat"]

function mod:OnEnable()
	-- Listen for target changes
	

	-- Enable us
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:Update(set)
	if not UnitExists("target") then
		-- We have no target - wipe all threat bars.
		Skada:RemoveAllBars()
		return
	end
	
	local threattable = {}
	
	if GetNumRaidMembers() > 0 then
		-- We are in a raid.
		for i = 1, 40, 1 do
			local name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			if name then
				local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(name, "target")
			
				if threatpct then
					table.insert(threattable, {["name"] = name, ["threat"] = threatpct})
				end
			end
		end
	elseif GetNumPartyMembers() > 0 then
		-- We are in a party.
		for i = 1, 5, 1 do
			local name = (UnitName("party"..tostring(i)))
			if name then
				local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation(name, "target")

				if threatpct then
					table.insert(threattable, {["name"] = name, ["threat"] = threatpct})
				end
			end
		end
	else
		-- We are all alone.
		local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("player", "target")
		
		if threatpct then
			table.insert(threattable, {["name"] = select(1, UnitName("player")), ["threat"] = threatpct})
		end
		
		-- Maybe we have a pet?
		if UnitExists("pet") then
			local isTanking, status, threatpct, rawthreatpct, threatvalue = UnitDetailedThreatSituation("pet", "target")
			
			if threatpct then
				table.insert(threattable, {["name"] = select(1, UnitName("pet")), ["threat"] = threatpct})
			end
		end
	end

	-- For each bar, mark bar as unchecked.
	local bars = Skada:GetBars()
	if bars then
		for i, bar in ipairs(bars) do
			bar.checked = false
		end
	end

	-- For each player in threat table, create or update bars.
	for i, player in ipairs(threattable) do
		if player.threat > 0 then
			local bar = Skada:GetBar(player.name)
			if bar then
				bar:SetMaxValue(100)
				bar:SetValue(player.threat)
			else
				bar = Skada:CreateBar(player.name, player.name, player.threat, 100, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then Skada:RightClick() end end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a)
			end
			bar:SetTimerLabel(("%02.1f%%"):format(player.threat).."%")
			bar.checked = true
		end
	end
	
	-- Remove all unchecked bars.
	if bars then
		for i, bar in ipairs(bars) do
			if not bar.checked then
				Skada:RemoveBar(bar)
			end
		end	
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end