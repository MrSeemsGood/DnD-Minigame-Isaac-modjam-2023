local mod = RegisterMod("DND", 1)
DnDMod = mod
local globals = require("src_dndtable.globals")
local dnd = include("src_dndtable.dndMinigame")

local invisStalker = require("src_dndtable.enemies.invisible_stalker")
local yochlol = require("src_dndtable.enemies.yochlol")
local bodak = require("src_dndtable.enemies.bodak")

---@param shaderName string
function mod:OnGetShaderParams(shaderName)
	if shaderName == "DnDMinigame-RenderAboveHUD" then
		dnd:OnRender()
	end
end

mod:AddCallback(ModCallbacks.MC_GET_SHADER_PARAMS, mod.OnGetShaderParams)

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
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, invisStalker.onNpcUpdate, globals.ENTITY_DND_ENEMY)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, invisStalker.onEntityTakeDmg, globals.ENTITY_DND_ENEMY)

-- yochlol
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, yochlol.onNpcUpdate, globals.ENTITY_DND_ENEMY)

--- bodak
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, bodak.onNpcUpdate, EntityType.ENTITY_VIS)
mod:AddCallback(ModCallbacks.MC_POST_LASER_UPDATE, bodak.onLaserUpdate)

