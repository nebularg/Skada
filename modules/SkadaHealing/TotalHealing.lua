local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("TotalHealingMode")

mod.name = L["Total healing"]

function mod:OnEnable()
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
end

function mod:GetSetSummary(set)
	return Skada:FormatNumber(set.healing + set.overhealing)
end

local function sort_by_healing(a, b)
	return a.healing > b.healing
end

function mod:Update(win, set)
	-- Calculate the highest total healing.
	-- How to get rid of this iteration?
	local maxvalue = 0
	for i, player in ipairs(set.players) do
		if player.healing + player.overhealing > maxvalue then
			maxvalue = player.healing + player.overhealing
		end
	end
	
	local color = win:GetDefaultBarColorOne()
	local altcolor = win:GetDefaultBarColorTwo()

	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.healing > 0 or player.overhealing > 0 then
			local mypercent = (player.healing + player.overhealing) / maxvalue
			local bar = win:GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxvalue)
				bar:SetValue(player.healing)
				bar.bgtexture:SetWidth(mypercent * bar:GetLength())
				bar.healing = player.healing + player.overhealing
			else
				bar = win:CreateBar(tostring(player.id), player.name, player.healing, maxvalue, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) if button == "RightButton" then win:RightClick() end end)
	--			Skada:Print("created "..player.name.." at "..tostring(player.overhealing))
			end
			bar.healing = player.healing + player.overhealing
			bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
			bar.bgtexture:SetVertexColor(altcolor.r, altcolor.g, altcolor.b, altcolor.a or 1)
			bar.bgtexture:ClearAllPoints()
			bar.bgtexture:SetPoint("BOTTOMLEFT")
			bar.bgtexture:SetPoint("TOPLEFT")
			bar.bgtexture:SetWidth(mypercent * bar:GetLength())
			bar:SetTimerLabel(Skada:FormatNumber(player.healing).." / "..Skada:FormatNumber(player.overhealing))
		end
	end
	
	win:SetSortFunction(sort_by_healing)
	
	-- Sort the possibly changed bars.
	win:SortBars()
end

