local mod = RegisterMod("DND", 1)
DnDMod = mod
local g = require("src_dndtable.globals")
local dnd = include("src_dndtable.dndMinigame")
local ettercap = require("src_dndtable.enemies.ettercap")
local invisStalker = require("src_dndtable.enemies.invisible_stalker")
local yochlol = require("src_dndtable.enemies.yochlol")
local bodak = require("src_dndtable.enemies.bodak")

function mod:OnGameStart(isContinued)
	Isaac.ExecuteCommand('reloadshaders')
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, mod.OnGameStart)

---@param shaderName string
function mod:OnGetShaderParams(shaderName)
	if shaderName == "DnDMinigame-RenderAboveHUD"
		and not g.game:IsPaused()
	then
		dnd:OnRender()
	end
end

mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.OnGetShaderParams)

function mod:OnPostRender()
	if g.game:IsPaused() then
		dnd:OnRender()
	end
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.OnPostRender)

function mod:OnPostUpdate()

end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnPostUpdate)

---@param player EntityPlayer
function mod:OnPostPlayerUpdate(player)
	dnd:KeyDelayHandle(player)
end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPostPlayerUpdate)

mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, dnd.OnPreGameExit)

-- invisible stalker
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, invisStalker.onNpcUpdate, g.INVIS_STALKER)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, invisStalker.onEntityTakeDmg, g.INVIS_STALKER)

-- yochlol
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, yochlol.onNpcUpdate, g.INVIS_STALKER)

-- ettercap
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, ettercap.onNpcUpdate, EntityType.ENTITY_BLOATY)

--- bodak
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, bodak.onNpcUpdate, EntityType.ENTITY_VIS)
mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, bodak.onLaserUpdate)
