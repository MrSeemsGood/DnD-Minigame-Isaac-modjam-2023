local ettercap = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

--[[
    Ettercaps acts similarly to Bloaties, wandering around the room and occasionally stop to attack.
    - their attack still spews green creep, but instead of normal tears,
    they will shoot egg tears that spawn cobwebs and spiders when landing.
]]

local AnimToDirection = {
    ['AttackDown'] = {
        [true] = Vector(0, 1),
        [false] = Vector(0, 1)
    },
    ['AttackUp'] = {
        [true] = Vector(0, -1),
        [false] = Vector(0, -1)
    },
    ['AttackRight'] = {
        [true] = Vector(-1, 0),
        [false] = Vector(1, 0)
    },
    ['AttackUpRight'] = {
        [true] = Vector(-0.71, -0.71),
        [false] = Vector(0.71, -0.71)
    },
    ['AttackDownRight'] = {
        [true] = Vector(-0.71, 0.71),
        [false] = Vector(0.71, 0.71)
    },
}

---@param npc EntityNPC
function ettercap:onNpcUpdate(npc)
    if npc.Variant ~= 3 then return end
    local s = npc:GetSprite()

    if npc.FrameCount == 30 then

    end

    if s:IsEventTriggered('ShootAlt') then
        print(s:GetAnimation() .. " " .. tostring(s.FlipX))

        local shootingDir = AnimToDirection[s:GetAnimation()][s.FlipX]
        local numProj = vee.RandomNum(4, 6)

        for _ = 1, numProj do
            local proj = Isaac.Spawn(
                EntityType.ENTITY_PROJECTILE,
                ProjectileVariant.PROJECTILE_TEAR,
                0,
                npc.Position,
                Vector.FromAngle(shootingDir:GetAngleDegrees() + vee.RandomNum(-10, 10)):Resized(vee.RandomNum(3, 5)),
                npc
            ):ToProjectile()

            proj.FallingSpeed = -18
            proj.FallingAccel = vee.RandomNum(10, 25) / 25

            proj:GetData().webTear = true

            proj:GetSprite():Load('gfx/009.633_egg.anm2', true)
            proj:GetSprite():Play(vee.RandomNum() < 0.5 and 'Stone2Idle' or 'Stone3Idle')
        end

        g.sfx:Play(SoundEffect.SOUND_BOSS_GURGLE_ROAR)
    end
end

---@param projectile EntityProjectile
function ettercap:onProjectileUpdate(projectile)
    if not projectile:GetData().webTear then return end

    if projectile.Height > -5 and projectile:Exists() then
        local room = g.game:GetRoom()

        if not room:GetGridEntityFromPos(projectile.Position)
        and vee.RandomNum() < 0.75 then
            Isaac.GridSpawn(GridEntityType.GRID_SPIDERWEB, 0,
                room:GetGridPosition(room:GetGridIndex(projectile.Position)),
            false)
        end

        if #Isaac.FindByType(EntityType.ENTITY_SPIDER, 0, 0) < 3 then
            EntityNPC.ThrowSpider(projectile.Position, nil, projectile.Position, false, -15)
        end
        g.sfx:Play(SoundEffect.SOUND_BOIL_HATCH, 1, 15, false, 1, 0)

        Isaac.Spawn(1000, EffectVariant.CREEP_WHITE, 0, projectile.Position, Vector.Zero, projectile)

        -- spawn tear poof
        local splash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 0, projectile.Position, Vector.Zero, projectile)
		splash:SetColor(projectile.Color, 100, 1, false, false)

        projectile:Remove()
    end

    if projectile:CollidesWithGrid() then
        local splash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 0, projectile.Position, Vector.Zero, projectile)
		splash:SetColor(projectile.Color, 100, 1, false, false)

        projectile:Remove()
    end
end

return ettercap
