local ettercap = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

--[[
    Ettercaps acts similarly to Bloaties, wandering around the room and occasionally stop to attack.
    - their attack still spews green creep, but instead of normal tears,
    they will shoot egg tears that spawn cobwebs and spiders when landing.
]]

---@param npc EntityNPC
function ettercap:onNpcUpdate(npc)
    if npc.Variant ~= 3 then return end
    local s = npc:GetSprite()

    if npc.FrameCount == 30 then
        npc:GetData().attacks = -1
    end

    if s:IsEventTriggered('Shoot') then
        npc:GetData().attacks = 0
    end

    if npc:GetData().attacks > -1 and npc:GetData().attacks < 8 then
        npc:GetData().attacks = npc:GetData().attacks + 1

        for _, entity in pairs(Isaac.GetRoomEntities()) do
            if entity.FrameCount == 0 and (not entity.SpawnerEntity or entity.SpawnerType == EntityType.ENTITY_BLOATY) then
                if entity.Type == EntityType.ENTITY_PROJECTILE then
                    entity:GetData().webTear = true
                    local c = entity.Color
                    c:SetColorize(1, 1, 1, 1)
                    entity:SetColor(c, 100, 1, false, false)
                    entity:GetSprite():Load('gfx/009.633_egg.anm2', true)
                    if vee.RandomNum() < 0.5 then
                        entity:GetSprite():Play('Stone2Idle')
                    else
                        entity:GetSprite():Play('Stone3Idle')
                    end
                    entity:ToProjectile():AddFallingAccel(vee.RandomNum(10, 25) / (-100))
                end
            end
        end

        g.sfx:Stop(SoundEffect.SOUND_BOSS_GURGLE_ROAR)
    elseif npc:GetData().attacks >= 8 then
        npc:GetData().attacks = -1
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

        -- spawn tear poof
        local splash = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TEAR_POOF_A, 0, projectile.Position, Vector.Zero, projectile)
		splash:SetColor(projectile.Color, 100, 1, false, false)

        projectile:Remove()
    end
end

return ettercap
