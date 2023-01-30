local cnctable = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

function cnctable:slotUpdate()
    for _, slot in pairs(Isaac.FindByType(EntityType.ENTITY_SLOT, g.CNC_BEGGAR)) do
        local s = slot:GetSprite()

        if s:IsFinished('Hide') then
            s:Play('IdleHidden', true)
        elseif s:IsFinished('Show') then
            s:Play('IdleShown', true)
        end

        local near = #Isaac.FindInRadius(slot.Position, 80, EntityPartition.PLAYER)
        if near > 0
        and (s:IsPlaying('Hide') or s:GetAnimation() == 'IdleHidden') then
            s:Play('Show', true)
        elseif near == 0
        and (s:IsPlaying('Show') or s:GetAnimation() == 'IdleShown') then
            s:Play('Hide', true)
        end
    end
end

---@param player EntityPlayer
---@param collider Entity
---@param _ any
function cnctable:onPlayerCollision(player, collider, _)
    if collider.Type == EntityType.ENTITY_SLOT and collider.Variant == g.CNC_BEGGAR then
        print('game can start but the function is local!')
    end
end

return cnctable