local cncText = {}

---@class Enum
cncText.PromptType = {
	NORMAL = 0,
	ENEMY = 1,
	BOSS = 2,
	RARE = 3
}

---@class OutcomeEffect
---@field Collectible CollectibleType
---@field Keys integer
---@field Bombs integer
---@field Coins integer
---@field EntityFlagsOnRoomEnter {Flags: EntityFlag, Duration: integer}
---@field StartEncounter integer
---@field ForceNextPrompt {PromptType: integer, PromptNumber: integer}

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
		Title = "Hey",
		Options = {
			[1] = {"Select", "Do it"},
			[2] = {"Roll", "Roll it"},
			[3] = {"Roll", "Roll it but Isaac", PlayerType.PLAYER_ISAAC},
		},
		Outcome = {
			[1] = "Don't mind me",
			[2] = {
				[1] = "You failure",
				[2] = "it alright",
				[3] = ":)"
			},
			[3] = {
				[1] = "You failure",
				[2] = "it alright",
				[3] = ":)"
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
				StartEncounter = 1600,
				Keys = 1,
				Coins = 1,
				Bombs = 1,
				Collectible = CollectibleType.COLLECTIBLE_SAD_ONION
			}
		}
	}
}

---@type Prompt[]
cncText.RarePrompts = {
	{
		Title = "Holy crap luis#its a rare prompt",
		Options = {
			[1] = {"Select", "Do it"},
			[2] = {"Roll", "Roll it"}
		},
		Outcome = {
			[1] = "Don't mind me",
			[2] = {
				[1] = "You failure",
				[2] = "it alright",
				[3] = ":)"
			}
		}
	},
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
