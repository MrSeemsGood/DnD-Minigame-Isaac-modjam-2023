local bodak = {}
local g = require('src_dndtable.globals')

--[[
    Bodaks act similarly to the Vis enemy, with two corrections:
    - their lasers are white.
    - they can't be pushed around when they are attacking.
]]

---@param npc EntityNPC
function bodak:onNpcUpdate(npc)
    if npc.Variant ~= 0 or npc.SubType ~= 3 then return end
    local s = npc:GetSprite()

    --print(s:GetAnimation())

    if npc.State == NpcState.STATE_ATTACK2
    and npc.Friction > 0 then
        npc.Friction = 0
        npc.Velocity = Vector.Zero
        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    elseif npc.State == NpcState.STATE_MOVE
    and npc.Friction == 0 then
        npc.Friction = 1
        npc:ClearEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    end

    if s:IsEventTriggered('Shoot') then
        for _, laser in pairs(Isaac.FindByType(EntityType.ENTITY_LASER)) do
            if laser.SpawnerType == EntityType.ENTITY_VIS
            and laser.FrameCount == 0 then
                local c = laser.Color
                c:SetColorize(4, 4, 4, 1)
                laser:SetColor(c, 100, 1, false, false)
            end
        end

        for _, impact in pairs(Isaac.FindByType(EntityType.ENTITY_EFFECT, EffectVariant.LASER_IMPACT)) do
            if impact.FrameCount == 0 then
                local c = impact.Color
                c:SetColorize(4, 4, 4, 1)
                impact:SetColor(c, 100, 1, false, false)
            end
        end
    end
end

return bodak