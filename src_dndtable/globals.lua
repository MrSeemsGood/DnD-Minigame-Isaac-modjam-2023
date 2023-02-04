local g = {}

g.game = Game()
g.sfx = SFXManager()
g.music = MusicManager()
g.CNC_BEGGAR = Isaac.GetEntityVariantByName("CnC Table")
g.CNC_EMPTY_TABLE = Isaac.GetEntityVariantByName("CnC Table (Empty)")
g.CUSTOM_DUNGEON_ENEMY_TYPE = Isaac.GetEntityTypeByName("Invisible Stalker")
g.DND_PLAYER_TECHNICAL = Isaac.GetItemIdByName("[TECHNICAL] Average DND Player")

g.GameState = {
	ShouldStart = false,
	GameActive = false,
	BeggarInitSeed = 0,
	HasWon = false,
	HasLost = false,
	PickupsCollected = {
		Coins = 0,
		Keys = 0,
		Bombs = 0
	}
}

g.DungeonVariant = {
	INVISIBLE_STALKER = 1,
	YOCHLOL = 2,
	DURRT = 3,
	GRELL = 4,
	MIND_FLAYER = 10,
}

g.AllDungeonEnemies = {
	{g.CUSTOM_DUNGEON_ENEMY_TYPE, g.DungeonVariant.INVISIBLE_STALKER},
	{g.CUSTOM_DUNGEON_ENEMY_TYPE, g.DungeonVariant.YOCHLOL},
	{g.CUSTOM_DUNGEON_ENEMY_TYPE, g.DungeonVariant.DURRT},
	{g.CUSTOM_DUNGEON_ENEMY_TYPE, g.DungeonVariant.GRELL, 0},
	{EntityType.ENTITY_PON, 1},
	{EntityType.ENTITY_BLOATY, 3},
	{EntityType.ENTITY_VIS, 0, 3},
}

return g
