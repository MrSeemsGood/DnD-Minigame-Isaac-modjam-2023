local mod = RegisterMod("DND", 1)
local VeeHelper = include("src_dndtable.veeHelper")
local dnd = include("src_dndtable.dndMinigame")
require("src_dndtable.enemies.invisible_stalker")
include("src_dndtable.enemies.bodak")
DnDMod = mod

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
