local L = LibStub("AceLocale-3.0"):GetLocale("Skada", false)

local Skada = Skada

local mod = Skada:NewModule("FailbotMode")
local playermod = Skada:NewModule("FailbotModePlayerView")

local fail = LibStub("LibFail-1.0")
local fail_events = fail:GetSupportedEvents()

mod.name = L["Fails"]

function mod:OnEnable()
	Skada:AddMode(self)
end

function mod:OnDisable()
	Skada:RemoveMode(self)
end

function mod:AddToTooltip(set, tooltip)
 	GameTooltip:AddDoubleLine(L["Fails"], set.fails, 1,1,1)
end

function mod:GetSetSummary(set)
	return set.fails
end

-- Called by Skada when a new player is added to a set.
function mod:AddPlayerAttributes(player)
	if not player.fails then
		player.fails = 0
		player.failevents = {}
	end
end

-- Called by Skada when a new set is created.
function mod:AddSetAttributes(set)
	if not set.fails then
		set.fails = 0
	end
end

local function onFail(event, who, fatal)
--   print(event, who, fatal)

	-- Always log to Total set. Current only if we are active.
	-- Idea: let modes force-start a set, so we can get a set
	-- for these things.
	if Skada.current then
		local unitGUID = UnitGUID(who)
		local player = Skada:get_player(Skada.current, unitGUID, who)
		player.fails = player.fails + 1
		
		if player.failevents[event] then
			player.failevents[event] = player.failevents[event] + 1
		else
			player.failevents[event] = 1
		end
	end
	
	if Skada.total then
		local unitGUID = UnitGUID(who)
		local player = Skada:get_player(Skada.total, unitGUID, who)
		player.fails = player.fails + 1
	
		if player.failevents[event] then
			player.failevents[event] = player.failevents[event] + 1
		else
			player.failevents[event] = 1
		end
	end
end

for _, event in ipairs(fail_events) do
	fail:RegisterCallback(event, onFail)
end

function mod:Update(win, set)
	-- Calculate the highest number.
	-- How to get rid of this iteration?
	local maxfails = 0
	for i, player in ipairs(set.players) do
		if player.fails > maxfails then
			maxfails = player.fails
		end
	end
	
	-- For each player in the set, see if we have a bar already.
	-- If so, update values, else create bar.
	for i, player in ipairs(set.players) do
		if player.fails > 0 then
			local bar = win:GetBar(tostring(player.id))
			if bar then
				bar:SetMaxValue(maxfails)
				bar:SetValue(player.fails)
			else
				bar = win:CreateBar(tostring(player.id), player.name, player.fails, maxfails, nil, false)
				bar:EnableMouse()
				bar:SetScript("OnMouseDown", function(bar, button) 
												if button == "LeftButton" then
													playermod.playerid = player.id
													playermod.name = player.name..L["'s Fails"]
													win:DisplayMode(playermod)
											 elseif button == "RightButton" then win:RightClick() end end)
				local color = Skada.classcolors[player.class] or win:GetDefaultBarColor()
				bar:SetColorAt(0, color.r, color.g, color.b, color.a or 1)
				
			end
			bar:SetTimerLabel(tostring(player.fails))
		end
	end
		
	-- Sort the possibly changed bars.
	win:SortBars()
end

-- Detail view of a player.
function playermod:Update(win, set)
	-- View spells for this player.
		
	local player = Skada:get_selected_player(set, self.playerid)
	local color = Skada:GetDefaultBarColor()
	
	if player then
		for event, fails in pairs(player.failevents) do
				
			local bar = win:GetBar(event)
			if bar then
				bar:SetMaxValue(player.fails)
				bar:SetValue(fails)
			else
				bar = win:CreateBar(event, event, fails, player.fails, nil, false)
				bar:SetColorAt(0, color.r, color.g, color.b, color.a)
				bar:ShowTimerLabel()
				bar:EnableMouse(true)
				bar:SetScript("OnMouseDown",function(bar, button)
												if button == "RightButton" then
													win:DisplayMode(mod)
												end
											end)
			end
			bar:SetTimerLabel(fails)
			
		end
	end
	
	-- Sort the possibly changed bars.
	win:SortBars()
end

