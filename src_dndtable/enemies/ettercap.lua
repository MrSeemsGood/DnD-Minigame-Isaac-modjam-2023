local ettercap = {}
local g = require('src_dndtable.globals')

--[[
    
]]

---@param npc EntityNPC
function ettercap:onNpcUpdate(npc)
    if npc.Variant ~= 3 then return end
    local s = npc:GetSprite()

    if npc.FrameCount == 1 then
        npc:GetData().attacks = -1
    end

    print(#Isaac.FindByType(EntityType.ENTITY_PROJECTILE))

    if s:IsEventTriggered('Shoot') then
        npc:GetData().attacks = 0
    end

    if npc:GetData().attacks > -1 and npc:GetData().attacks < 8 then
        npc:GetData().attacks = npc:GetData().attacks + 1

        for _, tear in pairs(Isaac.FindByType(EntityType.ENTITY_PROJECTILE)) do
            if tear.FrameCount == 0
            and tear.SpawnerType == EntityType.ENTITY_BLOATY then
                tear:Remove()
            end
        end

        for _, creep in pairs(Isaac.FindByType(1000, EffectVariant.CREEP_GREEN)) do
            if creep.FrameCount == 0 then
                creep:Remove()
            end
        end

        g.sfx:Stop(SoundEffect.SOUND_BOSS_LITE_GURGLE)
    elseif npc:GetData().attacks >= 8 then
        npc:GetData().attacks = -1
    end
end

return ettercap