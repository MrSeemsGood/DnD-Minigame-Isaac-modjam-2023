local grell = {}
local g = require('src_dndtable.globals')
local vee = require('src_dndtable.veeHelper')

--[[
    
]]

local GRELL_MOVESPEED = 4
local GRELL_WHIP_COOLDOWN = 60
local GRELL_WHIP_LENGTH = 170

local GrellSubtype = {
    START_RANDOM = 0,
    START_NORTH_EAST = 1,
    START_NORTH_WEST = 2,
    START_SOUTH_EAST = 3,
    START_SOUTH_WEST = 4
}

local GrellMovement = {
    [GrellSubtype.START_NORTH_EAST] = {'WalkUp', false, -45},
    [GrellSubtype.START_NORTH_WEST] = {'WalkUp', true, -135},
    [GrellSubtype.START_SOUTH_EAST] = {'WalkDown', false, 45},
    [GrellSubtype.START_SOUTH_WEST] = {'WalkDown', true, 135},
}

local function isGridToTurn(room, pos)
    return room:GetGridEntityFromPos(pos)
    and (room:GetGridEntityFromPos(pos):GetType() == GridEntityType.GRID_WALL or room:GetGridEntityFromPos(pos):GetType() == GridEntityType.GRID_DOOR)
end

---@param npc EntityNPC
function grell:onNpcUpdate(npc)
    if npc.Variant ~= 4 then return end
    local s = npc:GetSprite()
    local room = g.game:GetRoom()

    if npc.FrameCount == 30 then
        npc.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYEROBJECTS
        npc:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)

        local startingAnim
        if npc.SubType == 0 then
            startingAnim = GrellMovement[vee.RandomNum(1, 4)]
        else
            startingAnim = GrellMovement[npc.SubType]
        end

        npc:GetData().movement = startingAnim
        npc:GetData().registerCollisionCooldown = 0
        npc:GetData().whipCooldown = 0
    end

    if npc:GetData().movement
    and not s:IsPlaying('Attack') then

        s:Play(npc:GetData().movement[1])
        s.FlipX = npc:GetData().movement[2]
        npc.Velocity = Vector(1, 0):Rotated(npc:GetData().movement[3]) * GRELL_MOVESPEED

        if npc:CollidesWithGrid() then
            if npc:GetData().registerCollisionCooldown <= 0 then
                s.FlipX = false
                local nearestWall = 'south'
                if isGridToTurn(room, npc.Position + Vector(20, 0)) then nearestWall = 'east' end
                if isGridToTurn(room, npc.Position + Vector(-20, 0)) then nearestWall = 'west' end
                if isGridToTurn(room, npc.Position + Vector(0, -20)) then nearestWall = 'north' end

                local currentAngle = npc:GetData().movement[3]
                if currentAngle == -45 then
                    npc:GetData().movement = GrellMovement[nearestWall == 'north' and GrellSubtype.START_SOUTH_EAST or GrellSubtype.START_NORTH_WEST]
                elseif currentAngle == -135 then
                    npc:GetData().movement = GrellMovement[nearestWall == 'north' and GrellSubtype.START_SOUTH_WEST or GrellSubtype.START_NORTH_EAST]
                elseif currentAngle == 45 then
                    npc:GetData().movement = GrellMovement[nearestWall == 'south' and GrellSubtype.START_NORTH_EAST or GrellSubtype.START_SOUTH_WEST]
                elseif currentAngle == 135 then
                    npc:GetData().movement = GrellMovement[nearestWall == 'south' and GrellSubtype.START_NORTH_WEST or GrellSubtype.START_SOUTH_EAST]
                end

                npc:GetData().registerCollisionCooldown = 2
            else
                npc:GetData().registerCollisionCooldown = npc:GetData().registerCollisionCooldown - 1
            end

        end

        npc:GetData().whipCooldown = npc:GetData().whipCooldown - 1

        local player = npc:GetPlayerTarget()
        if player and room:CheckLine(player.Position, npc.Position, 0)
        and npc:GetData().whipCooldown <= 0 then
            local v = player.Position - npc.Position
            local angle = math.abs(v:GetAngleDegrees())

            if v:Length() < GRELL_WHIP_LENGTH and
            ((s.FlipX and math.abs(angle - 180) < 5) or (not s.FlipX and angle < 5)) then
                s:Play('Attack')
                npc.Velocity = Vector.Zero
            end
        end
    end

    if s:IsEventTriggered('Whip') then
        npc:GetData().whipCooldown = GRELL_WHIP_COOLDOWN
        g.sfx:Play(SoundEffect.SOUND_WHIP)
        --
    end
end

return grell