-- Various silly tweaks needed to keep up with Blizzard's shenanigans. Not added to core because they may not be needed/relevant forever.
Skada:AddLoadableModule("Tweaks", "Various tweaks to get around deficiences and problems in the game's combat logs. Carries a small performance penalty.", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Tweaks then return end

	local band = bit.band

	local PET_FLAG = COMBATLOG_OBJECT_TYPE_PET
	local MINE_FLAG = COMBATLOG_OBJECT_AFFILIATION_MINE

	local orig = Skada.cleuHandler
    local function cleuHandler(timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
		-- Only perform these modifications if we are already in combat
		if Skada.current then
			local firstArg = ...

			-- Akaari's Soul (7.0, Sub Rogue artifact)
			if firstArg == 220893 and band(srcFlags, MINE_FLAG) ~= 0 then
				srcGUID = UnitGUID("player")
				srcName = UnitName("player")
				srcFlags = 0x517 -- COMBATLOG_FILTER_ME + party + raid
			end
		end

		orig(timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
	end

	Skada.cleuFrame:SetScript("OnEvent", function()
			cleuHandler(CombatLogGetCurrentEventInfo())
	end)
end)
