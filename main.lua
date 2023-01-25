local mod = RegisterMod("DND", 1)
DnDMod = mod
local globals = require("src_dndtable.globals")
local VeeHelper = include("src_dndtable.veeHelper")
local dnd = include("src_dndtable.dndMinigame")

local invisStalker = require("src_dndtable.enemies.invisible_stalker")
local yochlol = require("src_dndtable.enemies.yochlol")
local bodak = require("src_dndtable.enemies.bodak")

function mod:OnPostRender()
	dnd:OnRender()
end

mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.OnPostRender)

function mod:OnPostUpdate()

end

mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnPostUpdate)

---@param player EntityPlayer
function mod:OnPostPlayerUpdate(player)

end

mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OnPostPlayerUpdate)

-- invisible stalker
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, invisStalker.onNpcUpdate, globals.ENTITY_DND_ENEMY)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, invisStalker.onEntityTakeDmg, globals.ENTITY_DND_ENEMY)

-- yochlol
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, yochlol.onNpcUpdate, globals.ENTITY_DND_ENEMY)

--- bodak
mod:AddCallback(ModCallbacks.MC_PRE_NPC_UPDATE, bodak.onPreNpcUpdate, EntityType.ENTITY_BLACK_GLOBIN_BODY)
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, bodak.onNpcUpdate, EntityType.ENTITY_BLACK_GLOBIN_BODY)
