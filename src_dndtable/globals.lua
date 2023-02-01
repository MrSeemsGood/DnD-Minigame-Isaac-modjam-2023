local g = {}

g.game = Game()
g.sfx = SFXManager()
g.music = MusicManager()
g.CNC_BEGGAR = Isaac.GetEntityVariantByName("CnC Table")
g.CUSTOM_DUNGEON_ENEMY_TYPE = Isaac.GetEntityTypeByName("Invisible Stalker")
g.DND_PLAYER_TECHNICAL = Isaac.GetItemIdByName("[TECHNICAL] Average DND Player")

return g
