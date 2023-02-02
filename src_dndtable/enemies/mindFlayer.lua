local mindFlayer = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

local MINDFLAYER_ATTACK_COOLDOWN = 60

local MINDFLAYER_PROJECTILE = ProjectileParams()
MINDFLAYER_PROJECTILE.BulletFlags = ProjectileFlags.WIGGLE
local c = MINDFLAYER_PROJECTILE.Color
c:SetColorize(1.5, 1, 2, 1)
MINDFLAYER_PROJECTILE.Color = c
MINDFLAYER_PROJECTILE.WiggleFrameOffset = 15

local PON_PROJECTILE = ProjectileParams()
PON_PROJECTILE.BulletFlags = ProjectileFlags.SMART
PON_PROJECTILE.HomingStrength = 0.5

local function wavyCap()
    Isaac.GetPlayer():UseActiveItem(CollectibleType.COLLECTIBLE_WAVY_CAP, false, true, false, false, ActiveSlot.SLOT_PRIMARY)
    g.sfx:Stop(SoundEffect.SOUND_VAMP_GULP)
end

--[[
    Mindflayer is a BOSS.
    It has 2 phases.
    When entering a boss room, applies Wavy Cap effect to all players.

    First phase:
    - barf a Pon.
    - shoot a row of tears with wiggle effect.

    Second phase (entered when reached 50% health, applies one Wavy Cap effect to all players):
    - moves with increased speed.
    - constantly tries to suck the players into his mouth.
    - a different tear attacks pattern.

]]

---@param npc EntityNPC
function mindFlayer:onNpcUpdate(npc)
    if npc.Variant ~= 10 then return end
    local s = npc:GetSprite()

    local phase = npc:GetData().phase
    if not phase then
        npc:GetData().phase = 1
        npc:GetData().attackCooldown = MINDFLAYER_ATTACK_COOLDOWN
        npc:GetData().projectiles = 0

        npc:AddEntityFlags(EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        wavyCap()
        s:Play('Idle')
        return
    end



    local player = npc:GetPlayerTarget()
    if npc:GetData().helper
    and npc:GetData().helper:Exists() and not npc:GetData().helper:IsDead() then
        npc.Velocity = npc:GetData().helper.Velocity
    else
        local helper = Isaac.Spawn(EntityType.ENTITY_CULTIST, 0, 0, npc.Position, Vector.Zero, npc):ToNPC()
        npc:GetData().helper = helper
    end

    if phase == 1 then
        npc:GetData().attackCooldown = npc:GetData().attackCooldown - 1
        if npc:GetData().attackCooldown <= 0
        and s:IsPlaying('Idle') then
            s:Play('Attack', true)
        end

        if s:IsPlaying('Attack') then
            if s:IsEventTriggered('Attack') then
                g.sfx:Play(SoundEffect.SOUND_BOSS_LITE_HISS)
                npc:GetData().attackCooldown = MINDFLAYER_ATTACK_COOLDOWN + vee.RandomNum(12, 24)

                local attack = vee.RandomNum(1, 2)
                if attack == 1
                and #Isaac.FindByType(EntityType.ENTITY_PON) < 2 then
                    Isaac.Spawn(EntityType.ENTITY_PON, 1, 0, npc.Position, Vector.Zero, npc)
                else
                    npc:GetData().projectiles = 6
                end
            end

            if npc:GetData().projectiles and npc:GetData().projectiles > 0 then
                if npc:GetData().projectiles % 2 == 0 then
                    npc:FireProjectiles(npc.Position, (player.Position - npc.Position):Normalized() * 8, 1, MINDFLAYER_PROJECTILE)
                end
                npc:GetData().projectiles = npc:GetData().projectiles - 1
            end
        end

        if s:IsFinished('Attack') then
            s:Play('Idle')
        end

        if npc.HitPoints / npc.MaxHitPoints < 0.5
        and not s:IsPlaying('PhaseChange') then
            s:Play('PhaseChange', true)
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        end

        if s:IsPlaying('PhaseChange')
        and s:IsEventTriggered('PhaseChange') then
            g.sfx:Play(SoundEffect.SOUND_THE_FORSAKEN_LAUGH)
            wavyCap()
            for _, pon in pairs(Isaac.FindByType(EntityType.ENTITY_PON, 1)) do
                pon = pon:ToNPC()
                pon:Kill()
                pon:FireProjectiles(
                    pon.Position,
                    (pon:GetPlayerTarget().Position - pon.Position):Normalized() * 2,
                    0,
                    PON_PROJECTILE
                )
            end
            npc:GetData().phase = 2
        end
    elseif phase == 2 then
        if s:IsFinished('PhaseChange') then
            s:Play('IdlePhase2')
            npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_ALL
        end

        if s:IsPlaying('IdlePhase2') then
            player:AddVelocity((npc.Position - player.Position):Normalized() * 0.33)

            if npc.FrameCount % 6 == 0 then
                local angle = Vector.FromAngle(vee.RandomNum(360)) * 2
                local p = Isaac.Spawn(EntityType.ENTITY_PROJECTILE, ProjectileVariant.PROJECTILE_NORMAL, 0, npc.Position, angle, npc):ToProjectile()
                p.Color = c
                p.FallingSpeed = -20
                p.FallingAccel = 0.75
            end
        end

    end
end

---@param npc EntityNPC
function mindFlayer:onNpcDeath(npc)
    if npc.Variant ~= 10 then return end

    for i = 0, g.game:GetNumPlayers() do
        Isaac.GetPlayer(0):GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WAVY_CAP, 2)
    end
end

---@param npc EntityNPC
function mindFlayer:onPonNpcUpdate(npc)
    if npc.Variant ~= 1 then return end

    if npc:GetSprite():IsEventTriggered('LandAlt') then
        npc:FireProjectiles(
            npc.Position,
            (npc:GetPlayerTarget().Position - npc.Position):Normalized() * 5,
            0,
            PON_PROJECTILE
        )
    end
end

---@param npc EntityNPC
function mindFlayer:onCultistNpcUpdate(npc)
    if npc.SpawnerType == g.CUSTOM_DUNGEON_ENEMY_TYPE
    and npc.SpawnerVariant == 10 then
        npc.Visible = false
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
        if npc.State ~= NpcState.STATE_IDLE then
            npc.State = NpcState.STATE_IDLE
        end
    end
end


return mindFlayer