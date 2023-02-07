local mod = RegisterMod("Caves N' Creatures", 1)
local g = require("src_cavesncreatures.globals")
local cnc = include("src_cavesncreatures.cncMinigame")
local cncTable = include('src_cavesncreatures.cncTable')

local ettercap = include("src_cavesncreatures.enemies.ettercap")
local invisStalker = include("src_cavesncreatures.enemies.invisibleStalker")
local yochlol = include("src_cavesncreatures.enemies.yochlol")
local bodak = include("src_cavesncreatures.enemies.bodak")
local durrt = include("src_cavesncreatures.enemies.durrt")
local grell = include("src_cavesncreatures.enemies.grell")
local mindFlayer = include('src_cavesncreatures.enemies.mindFlayer')

--![Look at this dog under Visual Studio Code's preview](https://cdn.discordapp.com/attachments/305511626277126144/1070385115496194088/IMG_4569.PNG)
local thisDogLovesYou

-- Sanio, you forgor something :skull:
function mod:OnGameStart(isContinued)
	Isaac.ExecuteCommand('reloadshaders')
end

mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnGameStart)

---@param shaderName string
function mod:OnGetShaderParams(shaderName)
	if shaderName == "CNCMinigame-RenderAboveHUD"
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

function mod:OnPostUpdate()
	cncTable:slotUpdate()
	cnc:OnPostUpdate()
end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnPostUpdate)

mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, cnc.OnNewRoom)
mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, cnc.OnPrePickupCollision)
mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, cnc.OnCNCRoomClear)
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, cnc.OnCNCPlayerCache)
mod:AddCallback(ModCallbacks.MC_POST_BOMB_INIT,
	cnc.LampOilRopeBombsYouWantItItsYourMyFriendAsLongAsYouGotThemInTheMinigame)

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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, durrt.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)

-- grell
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, grell.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, grell.onPlayerUpdate)

-- mind flayer
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mindFlayer.onNpcUpdate, g.CUSTOM_DUNGEON_ENEMY_TYPE)
mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, mindFlayer.onNpcDeath, g.CUSTOM_DUNGEON_ENEMY_TYPE)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mindFlayer.onPonNpcUpdate, EntityType.ENTITY_PON)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, mindFlayer.onCultistNpcUpdate, EntityType.ENTITY_CULTIST)
