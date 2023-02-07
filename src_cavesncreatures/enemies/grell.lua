local grell = {}
local g = require('src_cavesncreatures.globals')
local vee = require('src_cavesncreatures.veeHelper')

--[[
    Grells fly digonally around the room, bouncing off of walls.
    - when Isaac lines up with them horizontally and is in their line of sight,
    they will whip him. the whip deals damage and paralyzes Isaac for 1.5 seconds, disabling his movement.
]]

local GRELL_MOVESPEED = 4
local GRELL_WHIP_COOLDOWN = 60
local GRELL_WHIP_LENGTH = 170
local WHIP_PARALYSIS_DURATION = 40
local PLAYER_PARALYSIS_COLOR = Color(1, 1, 1, 1)
PLAYER_PARALYSIS_COLOR:SetColorize(1, 1, 1, 1)

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
---@param checkCooldown boolean
---@param player? EntityPlayer|Entity
local function isPlayerInWhipRange(npc, checkCooldown, player)
    player = player or npc:GetPlayerTarget()
    if checkCooldown and npc:GetData().whipCooldown > 0 then return false end

    local sprite = npc:GetSprite()

    if not player or not player.Visible
    or not g.game:GetRoom():CheckLine(player.Position, npc.Position, 0) then
        return false
    end

    local v = player.Position - npc.Position
    local angle = math.abs(v:GetAngleDegrees())

    if v:Length() > GRELL_WHIP_LENGTH or
    (sprite.FlipX and math.abs(angle - 180) > 7.5) or (not sprite.FlipX and angle > 7.5) then
        return false
    end

    return true
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

        if isPlayerInWhipRange(npc, true) then
            s:Play('Attack')
            npc.Velocity = Vector.Zero
        end
    end

    if s:IsEventTriggered('Whip') then
        npc:GetData().whipCooldown = GRELL_WHIP_COOLDOWN
        g.sfx:Play(SoundEffect.SOUND_WHIP)
        for i = 0, g.game:GetNumPlayers() - 1 do
            local player = Isaac.GetPlayer(i)
            if isPlayerInWhipRange(npc, false, player) then
                player:TakeDamage(1, 0, EntityRef(npc), 0)
                player:GetData().paralysisData = {duration = WHIP_PARALYSIS_DURATION, startingPos = player.Position}
                player:SetColor(PLAYER_PARALYSIS_COLOR, WHIP_PARALYSIS_DURATION, 1, true, false)
            end
        end
    end
end

---@param player EntityPlayer
function grell:onPlayerUpdate(player)
    if player:GetData().paralysisData then
        player:GetData().paralysisData.duration = player:GetData().paralysisData.duration - 1

        if player:GetData().paralysisData.duration > 0 then
            player.Velocity = Vector.Zero
            player.Position = player:GetData().paralysisData.startingPos
        end
    end
end

return grell