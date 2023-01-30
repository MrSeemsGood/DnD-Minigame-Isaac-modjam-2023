local cncText = {}

---@class Enum
cncText.PromptType = {
	NORMAL = 0,
	ENEMY = 1,
	BOSS = 2,
	RARE = 3
}

---@class GameState
cncText.GameState = {
	Active = false,
	Characters = {
		Selected = {
			1,
			2,
			3,
			4
		},
		NumActive = {
			0, --Isaac
			0, --Maggy
			0, --Cain
			0, --Judas
		},
		Dead = {
			false,
			false,
			false,
			false
		}
	},
	Inventory = {
		Keys = 0,
		Bombs = 0,
		Coins = 0,
	},
	PromptProgress = 0,
	PromptSelected = 1,
	PromptTypeSelected = cncText.PromptType.NORMAL,
	MaxPrompts = 3,
	HasSelected = false,
	RollResult = 0,
	OutcomeResult = 0,
	NumAvailableRolls = 1,
	PromptsSeen = {},
	EncountersSeen = {},
	EntityFlagsOnNextEncounter = { 0, 0 },
	ScreenShown = false,
	RoomIndexStartedGameFrom = 84,
	AdventureEnded = false,
	HudWasVisible = true,
}

---@class OutcomeEffect
---@field Collectible CollectibleType
---@field Keys integer
---@field Bombs integer
---@field Coins integer
---@field EntityFlagsOnRoomEnter {Flags: EntityFlag, Duration: integer}
---@field StartEncounter integer
---@field ForceNextPrompt {TableToUse: Prompt[], PromptNumber: integer}

---@class Prompt
---@field Title string
---@field Options {OptionType: string, Text: string} | {OptionType: string, Text: string, PlayerType: PlayerType} | {OptionType: string, Text: string, ConsumableNeeded: string}
---@field Outcome string[] | table<integer, table<integer, string>>
---@field Effect OutcomeEffect[] | table<integer, table<integer, OutcomeEffect>>

--Prompts are required to have the following:
--Title
--Options, with at least one option
--Every option must have either "Select" or "Roll" as its first string in its table
--One Outcome for every Option
--If the Option associated with the Outcome is a "Roll", then you must include 3 possible outcomes
--Outcome results for rolls are as follows: 1-5 is a 1, 6-15 is a 2, 16-20 is a 3

--Prompts can optionally have the following:
--Add a PlayerType as an extra entry in an option to require you play a character to select the option
--Add a string named "Key", "Coin", or "Bomb" with a number next to it without spaces (e.g. "Key1") to require a consumable for the option to be selected
--The Effect table, the list of variables for it described above. Setup the same as Options and Title, but only include the numbers you need (e.g. You only want an effect for Option 3, so only include a key with the number 3)

---@type Prompt[]
cncText.Prompts = {
	{
		Title = "You come across a locked chest",
		Options = {
			[1] = { "Select", "Dismiss it" },
			[2] = { "Select", "Unlock it", "Key1" },
			[3] = { "Select", "Throw a coin at it", "Coin1" },
			[4] = { "Select", "Bomb it", "Bomb1" },
			[5] = { "Roll", "Attempt to lock-pick", PlayerType.PLAYER_CAIN },
		},
		Outcome = {
			[1] = "You leave the chest be",
			[2] = "You unlock the chest and get nothing lmao",
			[3] = "Hi",
			[4] = "Hi",
			[5] = {
				[1] = "bich",
				[2] = "bich",
				[3] = "bich"
			}
		},
		Effect = {
			[5] = {
				[1] = {
					Keys = 1
				},

			}
		}
	},
}

---@type Prompt[]
cncText.Encounters = {
	{
		Title = "It's a giant enemy spider",
		Options = {
			[1] = { "Select", "Fight the giant enemy spider" }
		},
		Outcome = {
			[1] = "You fight the giant enemy spider"
		},
		Effect = {
			[1] = {
				StartEncounter = 1600
			}
		}
	}
}

---@type Prompt[]
cncText.RarePrompts = {

}

---@type Prompt[]
cncText.BossEncounters = {

}

---@param promptType integer
---@return Prompt[]
function cncText:GetTableFromPromptType(promptType)
	if promptType == cncText.PromptType.NORMAL then
		return cncText.Prompts
	elseif promptType == cncText.PromptType.ENEMY then
		return cncText.Encounters
	elseif promptType == cncText.PromptType.BOSS then
		return cncText.BossEncounters
	elseif promptType == cncText.PromptType.RARE then
		return cncText.RarePrompts
	end
	return cncText.Prompts
end

return cncText
