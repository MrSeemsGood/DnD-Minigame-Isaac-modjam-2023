local dndText = {}

dndText.CharacterSprites = {
	"gfx/characters/costumes/character_001_isaac.png",
	"gfx/characters/costumes/character_002_magdalene.png",
	"gfx/characters/costumes/character_003_cain.png",
	"gfx/characters/costumes/character_004_judas.png"
}

---@class GameState
dndText.GameState = {
	Active = false,
	ActiveCharacters = { --Numbers represent how many of each character there is in the game
		0, --Isaac
		0, --Maggy
		0, --Cain
		0, --Judas
	},
	PromptProgress = 0,
	PromptSelected = 1,
	HasSelected = false,
	RollResult = 0,
	OutcomeResult = 0,
	NumAvailableRolls = 1,
	MaxPrompts = 3,
	PromptsSeen = {},
	EncountersSeen = {},
	AdventureEnded = false,
}

---@class RewardType
dndText.RewardType = {
	HEAL = 0,
	TRINKET = 1,
	ITEM = 2,
	KEY = 3,
	BOMB = 4,
	CONSUMABLE = 5,
}

---@class AdvantageType
dndText.AdvantageType = {
	DODGE = 0,
	BURN = 1,
	WEAKNESS = 2,
	SLOW = 3,
	CHARM = 4,
	CONFUSE = 5,
	FREEZE = 6,
	SKIP = 7,
	DAMAGE = 8,
}

---@class Prompt
---@field Title string
---@field Options table<string, string> | table<string, string, PlayerType>
---@field Outcome string[] | table<integer, table<integer, string>>

---@type Prompt[]
dndText.Prompts = {
	--[[ {
		Title = "Yo mama approaches",
		Options = {
			[1] = { "Roll", "Fight her ass" },
			[2] = { "Select", "Get yo ass outta there" },
			[3] = { "Select", "Fucking stab her", PlayerType.PLAYER_JUDAS}
		},
		Outcome = {
			[1] = {
				[1] = "you're fucking dead bro",
				[5] = "you're severely damaged'",
				[10] = "You both barely manage to scrape one another, both of you part ways",
				[15] = "You damage her",
				[20] = "she dead as hell"
			},
			[2] = "You escape",
			[3] = "she dead as hell"
		},
	}, ]]
--[[ 	{
		Title = "Go forward or go backwards?",
		Options = {
			[1] = { "Select", "Forwards" },
			[2] = { "Select", "Backwards" },
			[3] = { "Select", "Upwards" },
			[4] = { "Select", "Speen", PlayerType.PLAYER_ISAAC },
		},
		Outcome = {
			[1] = "You do in fact, go forwards.",
			[2] = "You go backwards before realizing you need to move forward to progress",
			[3] = "You go up!",
			[4] = "SPEEEEEEEEEN",
		},
	}, ]]
	{
		Title = "You feel a grumbling in your stomach with the urge to fart",
		Options = {
			[1] = { "Roll", "Roll the dice bitch" },
			[2] = { "Roll", "Roll the dice but Isaac", PlayerType.PLAYER_ISAAC },
			--[3] = { "Roll", "Roll the dice again" },
			--[4] = { "Roll", "Roll the dice gaming" },
		},
		Outcome = {
			[1] = {
				[1] = "you're fucking dead bro",
				[2] = "nothin hapen",
				[3] = "you did it!!!!!!",
			},
			[2] = {
				[1] = "you're fucking dead bro",
				[2] = "nothin hapen",
				[3] = "you did it!!!!!!",
			},
			--[3] = "Hi",
			--[4] = "Hi",
		},
	},
}

---@type Prompt
dndText.Encounters = {

}

dndText.RarePrompts = {

}

dndText.BossEncounters = {

}

return dndText
