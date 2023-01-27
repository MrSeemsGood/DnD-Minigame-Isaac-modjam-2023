local g = {}

g.game = Game()
g.sfx = SFXManager()
g.DM_BEGGAR = Isaac.GetEntityVariantByName("DnD table")
g.INVIS_STALKER = Isaac.GetEntityTypeByName("Invisible Stalker")

return g
