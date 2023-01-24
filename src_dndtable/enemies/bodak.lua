local bodak = {}
local g = require('src_dndtable.globals')

---@param npc EntityNPC
function bodak:onNpcUpdate(npc)
    if npc.Variant ~= 3 then return end
    local s = npc:GetSprite()

    print(s:GetAnimation())

    
end

---@param npc EntityNPC
function bodak:onPreNpcUpdate(npc)
    if npc.Variant ~= 3 then return end

    
end

return bodak