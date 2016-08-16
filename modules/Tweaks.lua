-- Various silly tweaks needed to keep up with Blizzard's shenanigans. Not added to core because they may not be needed forever.
Skada:AddLoadableModule("Tweaks", function(Skada, L)
	if Skada.db.profile.modulesBlocked.Tweaks then return end

    local boms = {}
    local stormlashes = {}
        
    local orig = Skada.cleuFrame:GetScript("OnEvent")
    Skada.cleuFrame:SetScript("OnEvent", function(frame, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)

        -- Only perform these modifications if we are already in combat
        if Skada.current then
            local firstArg = select(1, ...)

            -- Greater Blessing of Might (7.0)
            if firstArg == 205729 and eventtype == 'SPELL_DAMAGE' then
                --Skada:Print('Ooh, caught a GBOM!')
                if not boms[srcGUID] then
                    local _, _, _, _, _, _, _, caster, _, _, _ = UnitBuff(select(2, ...))
                    if caster then
                        boms[dstGUID] = {
                            id = UnitGUID(caster),
                            name = UnitName(caster)
                        }
                    end
                end

                if boms[srcGUID] then
                    --Skada:Print("added BOM source")
                    srcGUID = boms[srcGUID].id
                    srcName = boms[srcGUID].name
                end
            end

            if firstArg == 203528 and eventtype == 'SPELL_AURA_REMOVED' then
                --Skada:Print("removed BOM source")
                boms[dstGUID] = nil
            end

            -- Stormlash (7.0)
            if firstArg == 195256 then
                if eventtype == 'SPELL_DAMAGE' then
                    --Skada:Print('Ooh, caught a Stormlash!')
                    if stormlashes[dstGUID] then
                        srcGUID = stormlashes[dstGUID].id
                        srcName = stormlashes[dstGUID].name
                    end
                end
            end

            if firstArg == 195222 then
                if eventtype == 'SPELL_AURA_APPLIED' then
                    --Skada:Print('New Stormlash source')
                    stormlashes[dstGUID] = {
                        id = srcGUID,
                        name = srcName
                    }
                end

                if eventtype == 'SPELL_AURA_REMOVED' then
                    --Skada:Print('Removed Stormlash source')
                    boms[dstGUID] = nil
                end
            end
                    
        end

        orig(frame, event, timestamp, eventtype, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, ...)
    end)
        
end)