local g = {}

g.game = Game()
g.sfx = SFXManager()
g.DM_BEGGAR = Isaac.GetEntityVariantByName("DnD table")
g.CUSTOM_DUNGEON_ENEMY_TYPE = Isaac.GetEntityTypeByName("Invisible Stalker")
g.DND_PLAYER_TECHNICAL = Isaac.GetItemIdByName("[TECHNICAL] Average DND Player")

return g
