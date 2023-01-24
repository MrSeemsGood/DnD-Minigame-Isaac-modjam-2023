local g = {}

g.game = Game()
g.mod = DnDMod
g.sfx = SFXManager()
g.DM_BEGGAR = Isaac.GetEntityVariantByName("DnD table")
g.ENTITY_DND_ENEMY = Isaac.GetEntityTypeByName("Invisible stalker")

return g