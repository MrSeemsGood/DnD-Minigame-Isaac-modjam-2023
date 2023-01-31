local invisStalker = {}
local g = require("src_dndtable.globals")

--[[
    Invisible Stalkers start stationary.
    - on a room start, they wake up and start chasing Isaac,
    becoming more transparent the closer they are to him. Once hit, they become fully opaque
    and return to their starting position, where they remain idle for a while before starting the next approach. 
]]

local STALKER_MOVESPEED_ATTACK = 6.75
local STALKER_MOVESPEED_RETREAT = 10
local STALKER_ATTACK_COOLDOWN = 48

---@param entity Entity
local function setTransparency(entity, newTransparency)
    -- 0 - completely transparent; 1 - completely opaque
    entity.Color = entity.Color * Color(1, 1, 1, newTransparency, 0, 0, 0)
end

---@param entity Entity
local function resetTransparency(entity)
    setTransparency(entity, 1 / entity.Color.A)
end

---@param npc EntityNPC
function invisStalker:onNpcUpdate(npc)
    if npc.Variant ~= 1 then return end
    local s = npc:GetSprite()

    if npc.FrameCount == 30 then
        s:Play('Idle', true)
        npc:GetData().startingPos = npc.Position
        npc:GetData().closingInCooldown = 0
    end

    local player = npc:GetPlayerTarget()
    if player then
        if s:IsPlaying('Idle') then
            if npc:GetData().closingInCooldown > 0 then
                npc.Friction = 0
                npc:GetData().closingInCooldown = npc:GetData().closingInCooldown - 1
            else
                npc.Friction = 1
                npc:GetData().closingInCooldown = STALKER_ATTACK_COOLDOWN
                g.sfx:Play(SoundEffect.SOUND_THE_FORSAKEN_LAUGH)
                s:Play('AttackStart', true)
            end
        elseif s:IsFinished('AttackStart') then
            g.sfx:Play(SoundEffect.SOUND_BIRD_FLAP)
            s:Play('Attack', true)
        elseif s:IsPlaying('Attack') then
            npc.Velocity = (player.Position - npc.Position):Normalized() * STALKER_MOVESPEED_ATTACK

            -- reset transparency
            resetTransparency(npc)

            setTransparency(npc, math.min(1, (npc.Position - player.Position):Length() / 300 - 0.15))
        end
    end

    if s:IsPlaying('Retreat') then
        if (npc:GetData().startingPos - npc.Position):LengthSquared() > 25 then
            -- retreating
            npc.Velocity = (npc:GetData().startingPos - npc.Position):Normalized() * STALKER_MOVESPEED_RETREAT
        else
            -- resting
            npc.Friction = 0
            npc.Velocity = Vector.Zero
            s:Play('Idle', true)
        end
    end
end

---@param tookDamage Entity
---@param source EntityRef
function invisStalker:onEntityTakeDmg(tookDamage, amount, damageFlags, source, countdownFrames)
    if tookDamage.Variant ~= 1 then return end

    if tookDamage:GetSprite():IsPlaying('Attack') then
        tookDamage:GetSprite():Play('Retreat', true)
        g.sfx:Play(SoundEffect.SOUND_BOSS_LITE_HISS)
        resetTransparency(tookDamage)
    end
end

return invisStalker