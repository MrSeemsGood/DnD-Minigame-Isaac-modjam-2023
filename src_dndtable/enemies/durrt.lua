local durrt = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

--[[
    Durrts wander around the room very slowly, not attempting to follow Isaac.
    - if Isaac stays diagonal to them and is in their line of sight, they roll towards him with an increased speed.
    they deal full heart of contact damage while rolling.
    - they can occasionally pick up nearby rocks and throw them at Isaac.
]]

local DURRT_MOVESPEED_NORMAL = 2
local DURRT_MOVESPEED_ROLLING = 10
local DURRT_ATTACK_DISTANCE = 200
local DURRT_ROLLING_COOLDOWN = 120
local DURRT_THROW_COOLDOWN = 30

local AnimToDirection = {
    ['WalkUp'] = Vector(0, -1),
    ['WalkDown'] = Vector(0, 1),
    ['WalkRight'] = Vector(1, 0),
    ['WalkLeft'] = Vector(-1, 0)
}

        -- CHANNEL YOUR INNER YANDERE DEV
---@param npc EntityNPC
function durrt:onNpcUpdate(npc)
    if npc.Variant ~= 3 then return end
    local s = npc:GetSprite()
    local player = npc:GetPlayerTarget()
    local room = g.game:GetRoom()

    if npc.FrameCount == 30 then
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
        npc:GetData().rollCooldown = 0
        npc:GetData().throwCooldown = 0
    end

    if s:IsPlaying('RollStart')
    or s:IsPlaying('RollEnd')
    or s:IsPlaying('Pick')
    or s:IsPlaying('Throw') then
        npc.Velocity = Vector.Zero
    end

    --print(s:GetAnimation())
    if npc:GetData().throwCooldown then
        npc:GetData().throwCooldown = npc:GetData().throwCooldown - 1
    end

    --? do we only want to play it when it's moving, maybe? or not play it at all?
    --npc:PlaySound(SoundEffect.SOUND_STONE_WALKER, 0.75, vee.RandomNum(60, 120), false, 1)

    if (s:GetAnimation() == 'Idle'
    or s:IsFinished('WalkUp')
    or s:IsFinished('WalkDown')
    or s:IsFinished('WalkRight')
    or s:IsFinished('WalkLeft')
    or s:IsFinished('RollEnd')
    or s:IsFinished('Throw')
    or npc:CollidesWithGrid())
    and not
        (s:IsPlaying('RollStart')
        or s:IsPlaying('RollDown')
        or s:IsPlaying('RollUp'))
    then
        local nearbyRocks = {}

        for i = 0, room:GetGridSize() do
            local grid = room:GetGridEntity(i)

            if grid and grid:GetType() == GridEntityType.GRID_ROCK
            and grid.State == 1 then
                if room:GetGridPosition(i):Distance(npc.Position) < 60 then
                    table.insert(nearbyRocks, grid)
                end
            end
        end

        if player and npc:GetData().throwCooldown and npc:GetData().throwCooldown <= 0
        and #nearbyRocks > 0 and vee.RandomNum(2) == 1 then
            npc:GetData().rockToPickup = nearbyRocks[vee.RandomNum(#nearbyRocks)]
            s:Play('Pick')
        else
            local availableDirectionAnims = {}

            for k, v in pairs(AnimToDirection) do
                local grid = room:GetGridEntityFromPos(npc.Position + v * 40)

                if not grid or grid:GetType() == GridEntityType.GRID_NULL
                or grid:GetType() == GridEntityType.GRID_DECORATION
                or grid:GetType() == GridEntityType.GRID_SPIDERWEB then
                    table.insert(availableDirectionAnims, k)
                end
            end

            local nextDirectionAnim = availableDirectionAnims[vee.RandomNum(#availableDirectionAnims)]
            nextDirectionAnim = nextDirectionAnim or 'WalkDown'

            s.FlipX = false
            s:Play(nextDirectionAnim, true)
            npc.Velocity = AnimToDirection[nextDirectionAnim] * DURRT_MOVESPEED_NORMAL
        end
    end

    -- Rolling attack
    if player and npc:GetData().rollCooldown and npc:GetData().rollCooldown <= 0
    and player.Position:Distance(npc.Position) < DURRT_ATTACK_DISTANCE
    and room:CheckLine(npc.Position, player.Position, 0) then
        local playerAngle = (player.Position - npc.Position):GetAngleDegrees()
        --[[
            Isaac -135            Isaac -45
                        DURRT
            Isaac 135             Isaac 45
        ]]

        if s:IsPlaying('WalkUp')
        and (math.abs(playerAngle + 135) < 10 or math.abs(playerAngle + 45) < 10) then
            s:Play('RollStart')
            -- {animation to play, angle to roll, whether to flip X the animation or not}
            npc:GetData().rollAnim = {
                'RollUp',
                playerAngle,
                math.abs(playerAngle + 135) < 10
            }
        elseif s:IsPlaying('WalkDown')
        and (math.abs(playerAngle - 135) < 10 or math.abs(playerAngle - 45) < 10) then
            s:Play('RollStart')
            npc:GetData().rollAnim = {
                'RollDown',
                playerAngle,
                math.abs(playerAngle - 135) < 10
            }
        elseif s:IsPlaying('WalkRight')
        and (math.abs(playerAngle + 45) < 10 or math.abs(playerAngle - 45) < 10) then
            s:Play('RollStart')
            npc:GetData().rollAnim = {
                math.abs(playerAngle + 45) < 10 and 'RollUp' or 'RollDown',
                playerAngle,
                false
            }
        elseif s:IsPlaying('WalkLeft')
        and (math.abs(playerAngle + 135) < 10 or math.abs(playerAngle - 135) < 10) then
            s:Play('RollStart')
            npc:GetData().rollAnim = {
                math.abs(playerAngle + 135) < 10 and 'RollUp' or 'RollDown',
                playerAngle,
                true
            }
        end
    end

    if s:IsPlaying('Pick')
    and s:IsEventTriggered('PickRock') then
        -- spawn projectile
        local p = Isaac.Spawn(
            EntityType.ENTITY_PROJECTILE,
            ProjectileVariant.PROJECTILE_ROCK,
            0,
            npc.Position,
            Vector.Zero,
            npc
        ):ToProjectile()
        p.Height = -90

        --? maybe it's needed?
        --p:AddProjectileFlags(ProjectileFlags.GHOST)

        ---@type Sprite
        local rockSprite = npc:GetData().rockToPickup:GetSprite()
        p:GetSprite():Load(rockSprite:GetFilename(), true)
        p:GetSprite():SetFrame(rockSprite:GetAnimation(), rockSprite:GetFrame())

        npc:GetData().rockToPickup:Destroy()

    elseif s:IsFinished('Pick') then
        s:Play('Throw')
    elseif s:IsPlaying('Throw')
    and s:IsEventTriggered('ThrowRock') then
        npc:GetData().throwCooldown = DURRT_THROW_COOLDOWN
    end

    if s:IsFinished('RollStart') then
        npc.CollisionDamage = 2
        s:Play(npc:GetData().rollAnim[1])
        s.FlipX = npc:GetData().rollAnim[3]
        npc.Velocity = Vector.FromAngle(npc:GetData().rollAnim[2]) * DURRT_MOVESPEED_ROLLING
    end

    if s:IsPlaying('RollUp')
    or s:IsPlaying('RollDown') then
        if npc:CollidesWithGrid() then
            npc:PlaySound(SoundEffect.SOUND_ROCK_CRUMBLE, 1, 2, false, 1)
            npc:GetData().rollCooldown = DURRT_ROLLING_COOLDOWN
            s:Play('RollEnd', true)
            npc.CollisionDamage = 1
            if npc:GetData().rollAnim[3] then
                s.FlipX = true
            end
        end
    elseif npc:GetData().rollCooldown then
        npc:GetData().rollCooldown = npc:GetData().rollCooldown - 1
    end
end

---@param proj EntityProjectile
function durrt:onProjectileUpdate(proj)
    if proj.SpawnerType ~= g.CUSTOM_DUNGEON_ENEMY_TYPE or proj.SpawnerVariant ~= 3 then return end

    if proj.SpawnerEntity then
        local dur = proj.SpawnerEntity:ToNPC()
        if dur:GetSprite():IsEventTriggered('ThrowRock') then
            local dir = dur:GetPlayerTarget().Position - dur.Position
            proj:GetData().launched = true
            proj.Velocity = dir:Normalized() * 7.5
            proj.FallingSpeed = -5
            proj.FallingAccel = 0.75
        elseif not proj:GetData().launched then
            proj.FallingSpeed = 0
            proj.FallingAccel = 0
        end
    end
end

function durrt:onNpcDeath(npc)
    if npc.Variant == 3 then
        npc:PlaySound(SoundEffect.SOUND_ROCK_CRUMBLE, 1, 2, false, 1)
    end
end

return durrt