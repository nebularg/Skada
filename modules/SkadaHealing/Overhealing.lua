local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local mod = Skada:NewModule("OverhealingMode")

mod.name = L["Overhealing"]

function mod:OnEnable()
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.overhealing then
		player.overhealing = 0
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.overhealing then
		set.overhealing = 0
	end
end

function mod:Update(set)
	-- Calculate the highest damage.
	-- How to get rid of this iteration?
	local maxoverhealing = 0
	for i, player in ipairs(set.players) do
		if player.overhealing > maxoverhealing then
			maxoverhealing = player.overhealing
		end
	end
	
--	Skada:Print("maxoverhealing: "..tostring(maxoverhealing))
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.overhealing > 0 then
			local bar = Skada:GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxoverhealing)
				bar:SetValue(player.overhealing)
	--			Skada:Print("updated "..player.name.." to "..tostring(player.overhealing))
			else
				bar = Skada:CreateBar(tostring(player.id), player.name, player.overhealing, maxoverhealing, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then Skada:RightClick() end end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a)
				
	--			Skada:Print("created "..player.name.." at "..tostring(player.overhealing))
			end
			bar:SetTimerLabel(Skada:FormatNumber(player.overhealing)..(" (%02.1f%%)"):format(player.overhealing / set.overhealing * 100))
		end
	end
	
	-- Sort the possibly changed bars.
	Skada:SortBars()
end

