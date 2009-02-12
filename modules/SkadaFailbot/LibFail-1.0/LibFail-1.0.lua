local MAJOR, MINOR = "LibFail-1.0", tonumber("37") or 999 

assert(LibStub, MAJOR.." requires LibStub")

local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local callbacks = LibStub("CallbackHandler-1.0"):New(lib)

lib.frame = lib.frame or CreateFrame("Frame")

local frame = lib.frame
frame:RegisterEvent("PLAYER_ENTERING_WORLD")


--- Fail Events.
--@description The list of supported events
--@class table
--@name fail_events
--@field 1 Fail_Sartharion_LavaWaves
--@field 2 Fail_Heigan_Dance
--@field 3 Fail_Sartharion_VoidZone
--@field 4 Fail_KelThuzad_VoidZone
--@field 5 Fail_Sapphiron_Breath
--@field 6 Fail_Frogger
--@field 7 Fail_Thaddius_PolaritySwitch
--@field 8 Fail_Thaddius_Jump
local fail_events = {
	"Fail_Sartharion_LavaWaves",
	"Fail_Heigan_Dance",
    "Fail_Sartharion_VoidZone",
    "Fail_KelThuzad_VoidZone",
	"Fail_Sapphiron_Breath",
	"Fail_Frogger",
	"Fail_Thaddius_PolaritySwitch",
	"Fail_Thaddius_Jump",
}

--[===[@debug@ 
function lib:Test()
    local e = math.floor(math.random() * #fail_events) + 1
    local p = math.floor(math.random() * 5) + 1

--    self:FailEvent(fail_events[e], "Test"..p)
    self:FailEvent(fail_events[e], "player")
end
--@end-debug@]===]

local survivable_fails = {
	Fail_Sartharion_LavaWaves = true,
    Fail_Sartharion_VoidZone = true,
	Fail_Heigan_Dance = true,
	Fail_Thaddius_PolaritySwitch = true,
	Fail_Thaddius_Jump = true,
}


--- Get a list of supported events.
-- @see fail_events
-- @return a table of event names which can be fired
function lib:GetSupportedEvents() return fail_events end


--- Is the event survivable.
--@param event an event from the list of supported events
--@return true or nil
function lib:IsSurvivable(event) return survivable_fails[event] end


function lib:GoInactive()
    if not self.active then return end

	self.LastTsunami = {}
	self.ChargeCounter = {}
	self.LastCharge = {}
	self.ThaddiusAlive = true;
	self.DeathTime = 0
	self.LastSlime = {}
    self.FroggerTime = {}

    self.active = nil

    frame:RegisterEvent("RAID_ROSTER_UPDATE")
	frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    callbacks:Fire("Fail_Inactive")
end

lib.active = true
lib:GoInactive()

lib.THADDIUS_JUMP_WINDOW = 120
lib.THADDIUS_JUMP_RETRY_WINDOW = 5
lib.FROGGER_DEATH_WINDOW = 4

do
	local _, etype, f
	
	frame:SetScript("OnEvent", function (self, event, ...)
		if event == "COMBAT_LOG_EVENT_UNFILTERED" then
			_, etype = ...
			f = lib[etype]
	
			if f then
				f(lib, ...)
			end
            
            -- This needs to be moved elsewhere
            local timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName = ...
            if destName then 
                if (destName=="Stalagg") or (destName=="Feugen") then
        		    self.DeathTime = timestamp
                end
            end
			
			return
		end

		f = lib[event]

		if f then
			f(lib, ...)
		end
	end)
end


function lib:FailEvent(name, playername)
    callbacks:Fire(name, playername, survivable_fails[name])
end


function lib:GoActive()
    if self.active then return end

    --frame:UnregisterEvent("RAID_ROSTER_UPDATE")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

	self.active = true

    callbacks:Fire("Fail_Active")
end


function lib:PLAYER_ENTERING_WORLD(...)
	if GetNumRaidMembers() > 0 then
        self:GoActive()
	else
        self:GoInactive()
	end
end

function lib:RAID_ROSTER_UPDATE(...)
	if GetNumRaidMembers() > 0 then
        self:GoActive()
	else
        self:GoInactive()
	end
end

function lib:SPELL_DAMAGE(timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool)
	if (sourceName=="Mirror Image") or (destName=="Mirror Image") then
		return
	end

	-- Lava Waves: Flame Tsunami 57491
	if spellId == 57491 then
		if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
			if self.LastTsunami[destName] == nil then
				self.LastTsunami[destName] = timestamp
				
				self:FailEvent("Fail_Sartharion_LavaWaves", destName)
			else
				if (timestamp - lib.LastTsunami[destName]) > 10 then
					self:FailEvent("Fail_Sartharion_LavaWaves", destName)
				end
				self.LastTsunami[destName] = timestamp
			end
		end

        return
	end

	-- Heigan Dance, Void Zones, Sapphiron's Breath, Frogger

    -- Frogger: Living Poision -> Explode 28433
    -- Heigan: Eruption 29371
    -- Sapphiron: Frost Breath 28524
    -- Void Blast 27812
    local FailType
--	if (spellName=="Eruption") or (spellName=="Void Blast") or (spellName=="Frost Breath") or (spellName=="Explode") then
--		if (sourceName:find("Fissure")) or (sourceName=="Sapphiron") or (sourceName=="Living Poison") then


	if spellId == 29371 then
		FailType = "Heigan_Dance"
	elseif spellId == 59128 then
        FailType = "Sartharion_VoidZone"
    elseif spellId == 27812 then
        FailType = "KelThuzad_VoidZone"
	elseif spellId == 28524 then
		FailType = "Sapphiron_Breath"
	elseif spellId == 28433 then
        self.FroggerTime[destName] = timestamp
        return
	end


	if FailType and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
		self:FailEvent("Fail_"..FailType, destName)
        return
	end

--		end
--	end

	-- Thaddius Polarity Switch
    -- 28062 Positive Charge
    -- 28085 Negative Charge
	if self.ThaddiusAlive then
		if spellId == 28062  or spellId == 28085 then
			if self.ChargeCounter[sourceName] == nil then
				self.ChargeCounter[sourceName] = 1
				self.LastCharge[sourceName] = timestamp
			elseif (timestamp - lib.LastCharge[sourceName]) < 2 then
				self.ChargeCounter[sourceName] = lib.ChargeCounter[sourceName] + 1
				self.LastCharge[sourceName] = timestamp
			else
				self.ChargeCounter[sourceName] = 1
				self.LastCharge[sourceName] = timestamp
			end

			if self.ChargeCounter[sourceName] == 3 then
				callbacks:Fire("Fail_Thaddius_PolaritySwitch", sourceName)
			end
		end
	end
end


function lib:ENVIRONMENTAL_DAMAGE(timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, dmgType)
    if (timestamp - self.DeathTime) < self.THADDIUS_JUMP_WINDOW and dmgType == "FALLING" then 
    	if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then    
            self.LastSlime[destName] = timestamp
            self:FailEvent("Fail_Thaddius_Jump", destName)
        end
    end
end

-- 28089 Polarity Shift 
function lib:SPELL_CAST_START(timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool)
--	if sourceName=="Thaddius" then
		if spellId == 28089 then
			wipe(self.ChargeCounter)
			self.ThaddiusAlive = true;
		end
--	end
end

function lib:UNIT_DIED(timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags)
	if (destName=="Thaddius") then
		self.ThaddiusAlive = false
	elseif self.FroggerTime[destName] then

        if (timestamp - self.FroggerTime[destName] < self.FROGGER_DEATH_WINDOW ) and bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0  then
           self:FailEvent("Fail_Frogger", destName)
        end

        self.FroggerTime[destName] = nil
	end
end

-- 28801 Slime (Under Thaddius)
function lib:SPELL_AURA_APPLIED(timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool)
	if spellId == 28801 then
		if (timestamp - self.DeathTime) < self.THADDIUS_JUMP_WINDOW then -- error
			if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
				if self.LastSlime[destName] == nil then
					self:FailEvent("Fail_Thaddius_Jump", destName)
				elseif (timestamp - self.LastSlime[destName]) > self.THADDIUS_JUMP_RETRY_WINDOW then
					self:FailEvent("Fail_Thaddius_Jump", destName)
				end
			end
		end
	end
end


-- 28801 Slime (Under Thaddius)
function lib:SPELL_AURA_REMOVED(timestamp, type, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool)
	if spellId == 28801 then
		if (timestamp - self.DeathTime) < self.THADDIUS_JUMP_WINDOW then --error
			if bit.band(destFlags, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 then
				self.LastSlime[destName] = timestamp
			end
		end
	end
end



