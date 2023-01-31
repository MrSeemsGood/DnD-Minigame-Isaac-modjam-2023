local yochlol = {}
local g = require("src_dndtable.globals")
local vee = require('src_dndtable.veeHelper')

local YOCHLOL_MOVESPEED_WALK = 3
local YOCHLOL_MOVESPEED_GAS = 6
local YOCHLOL_ATTACK_DECIDE_DISTANCE = 90
local YOCHLOL_SLAM_HIT_DISTANCE = 64
local YOCHLOL_SLAM_COOLDOWN = 60
local YOCHLOL_GAS_COOLDOWN = 120
local YOCHLOL_GAS_DURATION = 120

--[[
    Yochlols slowly walk towards Isaac. They can perform two attacks:
    - do an AoE slam if Isaac is nearby, spawning green creep puddle and a small maggot.
    - turn into a poisonous gas cloud if Isaac is far away, gaining temporary invincibility and increased movement speed.
]]

---@param npc EntityNPC
function yochlol:onNpcUpdate(npc)
    if npc.Variant ~= 2 then return end
    local s = npc:GetSprite()

    if npc.FrameCount == 30 then
        s:Play('Walk', true)
        npc:GetData().slamCooldown = 0
        npc:GetData().gasTurnCooldown = 0
        npc:GetData().gasDuration = 0
    end

    local player = npc:GetPlayerTarget()
    if player then
        if s:IsPlaying('Walk') then
            npc.Velocity = (player.Position - npc.Position):Normalized() * YOCHLOL_MOVESPEED_WALK
            npc:GetData().slamCooldown = npc:GetData().slamCooldown - 1
            npc:GetData().gasTurnCooldown = npc:GetData().gasTurnCooldown - 1

            if player.Position:Distance(npc.Position) < YOCHLOL_ATTACK_DECIDE_DISTANCE
            and npc:GetData().slamCooldown < 0
            and vee.RandomNum(10) == 1 then
                npc.Velocity = Vector.Zero
                npc.Friction = 0
                s:Play('Slam', true)
            end

            if player.Position:Distance(npc.Position) > YOCHLOL_ATTACK_DECIDE_DISTANCE
            and npc:GetData().gasTurnCooldown < 0
            and vee.RandomNum(40) == 1 then
                s:Play('GasTurn', true)
                g.sfx:Play(SoundEffect.SOUND_DEATH_REVERSE)
                npc.Velocity = Vector.Zero
                npc.Friction = 0
            end
        elseif s:IsPlaying('Slam') then
            if s:IsEventTriggered('Slam') then
                g.sfx:Play(SoundEffect.SOUND_MEAT_JUMPS)
                local creep = Isaac.Spawn(1000, EffectVariant.CREEP_GREEN, 0, npc.Position, Vector.Zero, npc):ToEffect()
                creep.Scale = 2
                creep.Timeout = 60

                local maggot = Isaac.Spawn(EntityType.ENTITY_SMALL_MAGGOT, 0, 0, npc.Position, Vector.Zero, npc)
                maggot:ClearEntityFlags(EntityFlag.FLAG_APPEAR)

                if player.Position:Distance(npc.Position) < YOCHLOL_SLAM_HIT_DISTANCE then
                    player:TakeDamage(1, 0, EntityRef(npc), 0)
                end
            end
        end

        if s:IsFinished('Slam') then
            npc.Friction = 1
            npc:GetData().slamCooldown = YOCHLOL_SLAM_COOLDOWN
            s:Play('Walk', true)
        end

        if s:IsFinished('GasTurn') then
            s:Play('Gas', true)
            npc:GetData().gasDuration = YOCHLOL_GAS_DURATION
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
            npc.Friction = 1
        end

        if s:IsPlaying('Gas') then
            if npc:GetData().gasDuration % 6 == 0 then
                local gas = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, npc.Position, Vector.Zero, npc):ToEffect()
                gas.Timeout = 100
            end
            npc:GetData().gasDuration = npc:GetData().gasDuration - 1
            npc.Velocity = (player.Position - npc.Position):Normalized() * YOCHLOL_MOVESPEED_GAS

            if npc:GetData().gasDuration < 0 then
                g.sfx:Play(SoundEffect.SOUND_DEATH_REVERSE)
                s:Play('GasTurnEnd', true)
                npc.Velocity = Vector.Zero
                npc.Friction = 0
            end
        end

        if s:IsFinished('GasTurnEnd') then
            s:Play('Walk', true)
            npc:GetData().gasTurnCooldown = YOCHLOL_GAS_COOLDOWN
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
            npc.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
        end
    end
end

return yochlol