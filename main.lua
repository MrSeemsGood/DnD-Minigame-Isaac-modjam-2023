local mod = RegisterMod("DND", 1)
local VeeHelper = require("src_dndtable.veeHelper")
DnDMod = mod

--[[function mod:OnPostRender()

end
mod:AddCallback(ModCallbacks.MC_POST_RENDER, mod.OnPostRender)

function mod:OnPostUpdate()

end
mod:AddCallback(ModCallbacks.MC_POST_UPDATE, mod.OnPostUpdate)

---@param player EntityPlayer
function mod:OnPostPlayerUpdate(player)

end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE)--]]

require("src_dndtable.enemies.invisible_stalker")
include("src_dndtable.enemies.bodak")