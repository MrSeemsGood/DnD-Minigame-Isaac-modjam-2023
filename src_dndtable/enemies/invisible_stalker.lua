local invisStalker = {}

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

    if npc.FrameCount == 1 then
        s:Play('Idle')
        npc:GetData().startingPos = npc.Position
        npc:GetData().closingInCooldown = 0 -- after Invisible stalker is hit, it takes time to retreat.
                                            -- Then it sits and rests for 2 seconds before attempting next attack
    end

    local player = npc:GetPlayerTarget()
    if player then
        if s:IsPlaying('Idle') then
            if npc:GetData().closingInCooldown > 0 then
                npc.Friction = 0
                npc:GetData().closingInCooldown = npc:GetData().closingInCooldown - 1
            else
                npc.Friction = 1
                npc:GetData().closingInCooldown = 60
                s:Play('CloseIn', true)
            end
        elseif s:IsPlaying('CloseIn') then
            npc.Velocity = (player.Position - npc.Position):Normalized() * 5

            -- reset transparency
            resetTransparency(npc)

            setTransparency(npc, math.min(1, (npc.Position - player.Position):Length() / 100))
        end
    end

    if s:IsPlaying('Retreat') then
        if (npc:GetData().startingPos - npc.Position):LengthSquared() > 20 then
            -- retreating
            npc.Velocity = (npc:GetData().startingPos - npc.Position):Normalized() * 7.5
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

    if tookDamage:GetSprite():IsPlaying("CloseIn") then
        tookDamage:GetSprite():Play("Retreat", true)
        resetTransparency(tookDamage)
    end
end

return invisStalker