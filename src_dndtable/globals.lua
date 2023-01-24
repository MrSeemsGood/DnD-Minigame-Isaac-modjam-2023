local g = {}

g.game = Game()
g.sfx = SFXManager()
g.DM_BEGGAR = Isaac.GetEntityVariantByName("DnD Table")
g.SLOT_DND_TABLE = 88
g.INVIS_STALKER = Isaac.GetEntityTypeByName("Invisible Stalker")

return g
