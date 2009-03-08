local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local mod = Skada:NewModule("InterruptsMode")

mod.name = L["Interrupts"]

function mod:OnEnable()
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
 	GameTooltip:AddDoubleLine(L["Interrupts"], set.interrupts, 1,1,1)
end

function mod:GetSetSummary(set)
	return set.interrupts
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.interrupts then
		player.interrupts = 0
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.interrupts then
		set.interrupts = 0
	end
end

function mod:Update(set)
	-- Calculate the highest number.
	local maxvalue = 0
	for i, player in ipairs(set.players) do
		if player.interrupts > maxvalue then
			maxvalue = player.interrupts
		end
	end
	
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.interrupts > 0 then
			local bar = Skada:GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxvalue)
				bar:SetValue(player.interrupts)
			else
				bar = Skada:CreateBar(tostring(player.id), player.name, player.interrupts, maxvalue, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then Skada:RightClick() end end)
				local color = Skada.classcolors[player.class] or Skada:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
				
			end
			bar:SetTimerLabel(tostring(player.interrupts))
		end
	end
		
	-- Sort the possibly changed bars.
	Skada:SortBars()
end