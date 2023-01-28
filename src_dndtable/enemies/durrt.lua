local durrt = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

local DURRT_MOVESPEED_NORMAL = 3
local DURRT_MOVESSPEED_ROLLING = 10
local DURRT_ROLLING_COOLDOWN = 120
local DURRT_THROW_COOLDOWN = 90

---@param npc EntityNPC
function durrt:onNpcUpdate(npc)
    if npc.Variant ~= 3 then return end
    local s = npc:GetSprite()

    if npc.FrameCount == 1 then
        npc:GetData().rollCooldown = 0
        npc:GetData().throwCooldown = 0
    end

    -- wolkin
    if s:GetAnimation() == 'Idle' then
        s:Play('WalkUp')
    end

    if s:IsFinished('WalkUp')
    or s:IsFinished('WalkDown')
    or s:IsFinished('WalkRight') then
        local next = vee.RandomNum(100)

        if next < 25 then
            s:Play('WalkUp', true)
            npc.Velocity = Vector(0, -1) * DURRT_MOVESPEED_NORMAL
        elseif next < 50 then
            s:Play('WalkDown', true)
            npc.Velocity = Vector(0, 1) * DURRT_MOVESPEED_NORMAL
        elseif next < 75 then
            s:Play('WalkRight', true)
            npc.Velocity = Vector(1, 0) * DURRT_MOVESPEED_NORMAL
        else
            s.FlipX = true
            s:Play('WalkRight', true)
            npc.Velocity = Vector(-1, 0) * DURRT_MOVESPEED_NORMAL
        end
    end
    --
end

return durrt