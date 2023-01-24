local mod = RegisterMod("DND", 1)
local g = require("src_dndtable.globals")
local dnd = include("src_dndtable.dndMinigame")
local invisStalker = include("src_dndtable.enemies.invisible_stalker")
local bodak = include("src_dndtable.enemies.bodak")

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

mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, invisStalker.OnNPCUpdate, g.INVIS_STALKER)
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, invisStalker.OnTakeDamage, g.INVIS_STALKER)
