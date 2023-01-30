local mod = RegisterMod("DND", 1)
DnDMod = mod
local g = require("src_dndtable.globals")
local cnc = include("src_dndtable.cncMinigame")
local cncTable = include('src_dndtable.cncTable')

local ettercap = include("src_dndtable.enemies.ettercap")
local invisStalker = include("src_dndtable.enemies.invisibleStalker")
local yochlol = include("src_dndtable.enemies.yochlol")
local bodak = include("src_dndtable.enemies.bodak")
local durrt = include("src_dndtable.enemies.durrt")
local grell = include("src_dndtable.enemies.grell")

-- Sanio, you forgor something :skull:
function mod:OnGameStart(isContinued)
	Isaac.ExecuteCommand('reloadshaders')
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnGameStart)

---@param shaderName string
function mod:OnGetShaderParams(shaderName)
	if shaderName == "DnDMinigame-RenderAboveHUD"
		and not g.game:IsPaused()
	then
		cnc:OnRender()
	end
end

mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.OnGetShaderParams)

function mod:OnPostRender()
	if g.game:IsPaused() then
		cnc:OnRender()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.OnPostRender)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, cnc.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, cnc.OnPostUpdate)
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, cncTable.slotUpdate)

mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_COLLISION, cncTable.onPlayerCollision, 0)

---@param player EntityPlayer
function mod:OnPostPlayerUpdate(player)
	cnc:KeyDelayHandle(player)
	cnc:OnPlayerUpdate(player)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPostPlayerUpdate)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, cnc.OnPreGameExit)

-- ENEMIES --
-- invisible stalker
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, invisStalker.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, invisStalker.onEntityTakeDmg, g.CUSTOM_DUNGEON_ENEMY_TYPE)

-- yochlol
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, yochlol.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)

-- ettercap
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, ettercap.onNpcUpdate, EntityType.ENTITY_BLOATY)
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, ettercap.onProjectileUpdate)

-- bodak
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, bodak.onNpcUpdate, EntityType.ENTITY_VIS)

-- durrt
mod:AddCallback(ModCallbacks.MC_POST_PROJECTILE_UPDATE, durrt.onProjectileUpdate, ProjectileVariant.PROJECTILE_ROCK)
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, durrt.onNpcDeath, g.CUSTOM_DUNGEON_ENEMY_TYPE)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE,  durrt.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)

-- grell
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, grell.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)
