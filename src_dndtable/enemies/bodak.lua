local bodak = {}
local g = require('src_dndtable.globals')

--[[
    Bodaks act similarly to the Vis enemy, with two corrections:
    - their lasers are white
    - they can't be pushed around when they are attacking
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
            if laser.SpawnerType == EntityType.ENTITY_VIS then
                laser:GetData().toRecolor = true
            end
        end
    end
end

---@param laser EntityLaser
function bodak:onLaserUpdate(laser)
    if laser:GetData().toRecolor
    and laser.FrameCount == 1 then
        laser:SetColor(Color(1, 1, 1, 1, 0, 0, 0), 1000, 1, false, false)
        laser:Update()
    end
end

return bodak