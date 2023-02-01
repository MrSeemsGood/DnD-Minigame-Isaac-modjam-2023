local cncText = {}

---@enum PromptType
cncText.PromptType = {
	NORMAL = 0,
	ENEMY = 1,
	BOSS = 2,
	RARE = 3
}

---@enum StatusEffect
---- Duration is equivalent to frames. For NPCs, 1 second = 30 frames
---- Burn and Poison deals damage every 20 frames, starting from 2 frames, capping at 122 for NPCs and 2 for players
---- Charm can be given a duration of -1 for perma-charm
---- All statuses except bleed and slow have a max duration of 5 seconds, or 150 frames
---- Bleed is the only effect without a duration
cncText.StatusEffect = {
	BURN = 0,
	CHARMED = 1,
	CONFUSION = 2,
	FEAR = 3,
	FREEZE = 4,
	MIDAS_FREEZE = 5,
	POISON = 6,
	SHRINK = 7,
	SLOW = 8,
	BLEED = 9
}

---@class Stats
---@field DamageFlat number
---@field DamageMult number
---@field TearsFlat number
---@field TearsMult number
---@field Luck number
---@field Range number
---@field ShotSpeed number

---@class OutcomeEffect
---@field Collectible CollectibleType
---@field Keys integer
---@field Bombs integer
---@field Coins integer
---@field AddHearts table<HeartSubType, integer>
---@field AddMaxHearts integer
---@field StartEncounter integer
---@field ForceNextPrompt {PromptType: PromptType, PromptNumber: integer}
---@field DamagePlayers integer --Effects past this point are encounter-exclusive and won't do anything outside of them!
---@field ApplyStatus {StatusEffect: StatusEffect, Duration: integer}
---@field ApplyStatusPlayer {StatusEffect: StatusEffect, Duration: integer}
---@field DamageEnemies number
---@field ApplyDarkness boolean
---@field TimeLimit integer --Time limit is in seconds. All players die if the room is not cleared within the set time limit
---@field Stats Stats
---@field StatsTemp Stats

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
--The Effect table, the list of variables for it described above. Setup the same as Options and Title, but only include the numbers you need (e.g. You only want an effect for Option 3, so only include an effect for the index of 3)

---@type Prompt[]
cncText.Prompts = {
	{
		Title = "Hey",
		Options = {
			[1] = { "Select", "Do it" },
			[2] = { "Select", "You should kill yourself NOW" }
		},
		Outcome = {
			[1] = "Don't mind me",
			[2] = "You obey LowTierGod",
		},
		Effect = {
			[2] = {
				DamagePlayers = 10
			}
		}
	},
}

---@type Prompt[]
cncText.Encounters = {
	--The following prompt has everything possible so you know how its setup
	--[[ 	{
		Title = "Wow that's a lot of options#This hashtag makes another line",
		Options = {
			[1] = {"Select", "Basic Select Option"},
			[2] = {"Roll", "Basic Roll Option"},
			[3] = {"Select", "This option only appears when Isaac is in your party", PlayerType.PLAYER_ISAAC},
			[4] = {"Select", "Love about it", PlayerType.PLAYER_MAGDALENA},
			[5] = {"Select", "Greed about it", PlayerType.PLAYER_CAIN},
			[6] = {"Select", "Stab about it", PlayerType.PLAYER_JUDAS},
			[7] = {"Select", "This option appears if you have at least 1 key", "Key1"},
			[8] = {"Select", "Same as above but for 2 bombs", "Bomb2"},
			[9] = {"Select", "Same as above but for 5 coins", "Coin5"},
			[10] = {"Select", "Start an encounter"}
		},
		Outcome = {
			[1] = "You selected this option!",
			[2] = {
				[1] = "You rolled a 1-5",
				[2] = "You rolled a 6-15",
				[3] = "You rolled a 16-20"
			},
			[3] = "You have Isaac in your party!#Holy shit another line",
			[4] = "You have Maggy in your party!#You can't apply hashtags to Options though",
			[5] = "You have Cain in your party!",
			[6] = "You have Judas in your party!",
			[7] = "You used a key",
			[8] = "You used 2 bombs",
			[9] = "You spent 5 dabloons"
		},
		Effect = {
			[2] = {
				[1] = {
					DamagePlayers = 1 -- Damages all players for half a heart. Please don't give these a negative number.
				},
				[2] = {
					AddHearts = { --All hearts available listed in the HeartSubType table in the luadocs
						[HeartSubType.HEART_SOUL] = 1, --gives every player 1 full soul heart. Please don't give these a negative number.
						[HeartSubType.HEART_HALF] = 2, --heals every player 1 full red heart.
						[HeartSubType.HEART_FULL] = 1 -- heals every player 1 full red heart, again! 
					}
				},
				[3] = {
					Collectible = CollectibleType.COLLECTIBLE_SAD_ONION, --All players get a Sad Onion
					Stats = { --All stats available listed above in the "Stats" class. Stats lasts the minigame
						DamageFlat = 1, --You get +1 damage
						DamageMult = 2, --You get x2 damage
						Luck = -2 --minus 2 luck for the rest of the run oh shit!
					},
					StatsTemp = { --Only relevant in enemy encounters, lasting the encounter until the room is cleared. As such, Luck is not useful unless you have an item that uses the luck stat.
						TearsFlat = 3 --You get a -3 tears delay for the room. Remember that these do NOT equate to the HUD stat!
					}
				},
			},
			[7] = {
				Keys = -1 --You need to set whether the pickup is actually consumed or not yourself!
			},
			[8] = {
				Bombs = -2
			},
			[9] = {
				Coins = -5
			},
			[10] = {
				StartEncounter = 1600,
				ApplyStatus = {cncText.StatusEffect.BURN, 22},
				DamageEnemies = 1, --All enemies take 1 damage
				ApplyDarkness = true, --Permanent darkness for the room!
				TimeLimit = 5, --YOU HAVE FIVE SECONDS TO CLEAR THE ROOM OR EVERYONE FUCKING D I E S
				Keys = 1, --Everything here and below is on-room-clear
				Coins = 1,
				Bombs = 1,
				Collectible = CollectibleType.COLLECTIBLE_SAD_ONION,
				AddHearts = {
					[HeartSubType.HEART_SOUL] = 1, --Spawns a full soul heart
					[HeartSubType.HEART_HALF] = 2, --Spawns 2 half red hearts
					[HeartSubType.HEART_FULL] = 1 --Spawns a full red heart
				},
				AddMaxHearts = 1 --Adds 1 empty red heart
			}
		}
	}, ]]

	--[[
		ENEMY ENCOUNTERS
	--]]

	-- INVISIBLE STALKERS
	{
		Title = "You enter a mysterious haunted hallway...",
		Options = {
			[1] = {"Roll", "How quiet of a prey are you?"},
			[2] = {"Select", "Show its inhabitants your devilish powers.", PlayerType.PLAYER_JUDAS}
		},
		Outcome = {
			[1] = {
				[1] = "You are very clumsy and attract a big pack of Invisible Stalkers.",
				[2] = "Only the most sensitive Stalkers notice your presence.",
				[3] = "You are extremely cautious and remain almost unnoticed by the Stalkers."
			},
			[2] = "The power of Belial helps you scare off the weakened creatures."
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 1602,
					Coins = 2,
					Collectible = CollectibleType.COLLECTIBLE_OUIJA_BOARD
				},
				[2] = {
					StartEncounter = 1600,
					Coins = 3,
					Bombs = 1,
					Collectible = CollectibleType.COLLECTIBLE_OUIJA_BOARD
				},
				[3] = {
					StartEncounter = 1601,
					Keys = 1,
					Coins = 3,
					Bombs = 1,
					Collectible = CollectibleType.COLLECTIBLE_OUIJA_BOARD
				}
			},
			[2] = {
				StartEncounter = 1601,
				Coins = 2,
				Keys = 1,
				Bombs = 1,
				Collectible = CollectibleType.COLLECTIBLE_OUIJA_BOARD
			}
		}
	},
	-- BODAKS
	{
		Title = "You see strange creatures. Their skin is deathly pale and white...",
		Options = {
			[1] = {"Roll", "Are the undead craving for flesh?"},
			[2] = {"Select", "You decide to distract their attention with shiny metal.", "Coin3"}
		},
		Outcome = {
			[1] = {
				[1] = "You encounter Bodaks and their lesser undead friends.",
				[2] = "You encounter 2 Bodaks. However, the room is a bit too tight...",
				[3] = "You encounter 4 Bodaks. They don't seem too interested in you.",
			},
			[2] = "The creatures seem very excited with the coins you threw."
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 1608,
					Keys = 1,
					Coins = 2,
				},
				[2] = {
					StartEncounter = 1604,
					Keys = 2,
					Bombs = 1,
				},
				[3] = {
					StartEncounter = 1606,
					Keys = 2,
					Coins = 1,
					Bombs = 2,
				}
			},
			[2] = {
				StartEncounter = 1608,
				Keys = 1,
				Bombs = 1,
				ApplyStatus = {StatusEffect = cncText.StatusEffect.CONFUSION, Duration = 60}
			}
		}
	},
	-- YOCHLOLS
	{
		Title = "You encounter weird oozy creatures.#Their flesh melts off of them and piles back together.",
		Options = {
			[1] = {"Roll", "These creatures emit deadly gases,#so you try to lure them out into the open"}
		},
		Outcome = {
			[1] = {
				[1] = "One of them has you trapped in a dead-end!",
				[2] = "You lead one of the creatures into a long thin hallway...",
				[3] = "You succeed."
			}
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 1607,
					Coins = 3,
					Keys = 1,
				},
				[2] = {
					StartEncounter = 1603,
					Keys = 2,
					Bombs = 1,
				},
				[3] = {
					StartEncounter = 1605,
					Keys = 1,
					Coins = 2,
					Bombs = 2,
				}
			}
		}
	},
	-- ETTERCAPS
	{
		Title = "You enter the lair of Ettercaps, spider-like aberrations.",
		Options = {
			[1] = {"Roll", "You try to sneak out through the smallest cavern."}
		},
		Outcome = {
			[1] = {
				[1] = "Unfortunately, this is the biggest one!",
				[2] = "You encounter a medium-sized cavern.",
				[3] = "You enter the smallest cavern in the lair."
			}
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 1609,
					Coins = 3,
					Keys = 1,
					Collectible = CollectibleType.COLLECTIBLE_MUTANT_SPIDER
				},
				[2] = {
					StartEncounter = 1610,
					Keys = 2,
					Bombs = 1,
					Collectible = CollectibleType.COLLECTIBLE_TINYTOMA
				},
				[3] = {
					StartEncounter = 1611,
					Keys = 1,
					Coins = 2,
					Bombs = 2,
					Collectible = CollectibleType.COLLECTIBLE_INTRUDER
				}
			}
		}
	},
	-- DURRTS
	{
		Title = "A group of massive animated boulders stands in your way!",
		Options = {
			[1] = {"Roll", "You try to remain neutral to them and not cause aggression."},
			[2] = {"Select", "You reasonably decide to bomb them.", "Bomb1"},
			[3] = {"Select", "Can Stone giants be compassionate?", PlayerType.PLAYER_MAGDALENE}
		},
		Outcome = {
			[1] = {
				[1] = "Stone giants do not recognize your peaceful motifs.",
				[2] = "Stone giants question your intentions.",
				[3] = "Only the least wise giants decide to stand in your way."
			},
			[2] = "The explosion cleans up some space but reveals more enemies!",
			[3] = "They can. All around is stone, all is soft inside."
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 1613,
					Keys = 1,
					Coins = 1,
					Collectible = CollectibleType.COLLECTIBLE_SMALL_ROCK
				},
				[2] = {
					StartEncounter = 1615,
					Keys = 2,
					Collectible = CollectibleType.COLLECTIBLE_SMALL_ROCK
				},
				[3] = {
					StartEncounter = 1612,
					Keys = 1,
					Coins = 2,
					Collectible = CollectibleType.COLLECTIBLE_SMALL_ROCK
				}
			},
			[2] = {
				StartEncounter = 1614,
				Coins = 1,
				Keys = 1,
				Collectible = CollectibleType.COLLECTIBLE_SMALL_ROCK
			},
			[3] = {
				StartEncounter = 1612,
				ApplyStatus = {StatusEffect = cncText.StatusEffect.CHARMED, Duration = 90},
				Keys = 2,
				Coins = 3,
				Collectible = CollectibleType.COLLECTIBLE_SMALL_ROCK
			}
		}
	},
	-- GRELLS
	{
		Title = "You encounter floating brains with tentacles and a beak. Oh, mother Nature!",
		Options = {
			[1] = {"Roll", "You try to remain unnoticed."},
			[2] = {"Select", "You try to sneak by.", PlayerType.PLAYER_CAIN}
		},
		Outcome = {
			[1] = {
				[1] = "The creatures swarm you.",
				[2] = "The creatures are hesitant.",
				[3] = "The creatures are distracted."
			},
			[2] = "The creatures are distracted and you sneak by most of them."
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 1617,
					Keys = 1,
					Coins = 2
				},
				[2] = {
					StartEncounter = 1618,
					Keys = 2,
					Coins = 1
				},
				[3] = {
					StartEncounter = 1618,
					Keys = 1,
					Coins = 2,
				}
			},
			[2] = {
				StartEncounter = 1616,
				Coins = 3,
				Keys = 2,
			}
		}
	},
}

---@type Prompt[]
cncText.RarePrompts = {
	{
		Title = "Holy crap luis#its a rare prompt",
		Options = {
			[1] = { "Select", "Do it" },
			[2] = { "Roll", "Roll it" }
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
	{
		Title = "lmao its monstro",
		Options = {
			[1] = { "Select", "Dunk his ass" }
		},
		Outcome = {
			[1] = "You proceed to show this fool#whos in charge"
		},
		Effect = {
			[1] = {

			}
		}
	}
}

---@param promptType PromptType
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

---@param ent EntityNPC | EntityPlayer
---@param status StatusEffect
---@param duration integer
function cncText:ApplyStatusEffect(ent, status, duration)
	local ref = EntityRef(ent)

	if status == cncText.StatusEffect.BURN then
		ent:AddBurn(ref, duration, 3.5)
	elseif status == cncText.StatusEffect.CHARMED then
		ent:AddCharmed(ref, duration)
	elseif status == cncText.StatusEffect.CONFUSION then
		ent:AddConfusion(ref, duration, false)
	elseif status == cncText.StatusEffect.FEAR then
		ent:AddFear(ref, duration)
	elseif status == cncText.StatusEffect.FREEZE then
		ent:AddFreeze(ref, duration)
	elseif status == cncText.StatusEffect.MIDAS_FREEZE then
		ent:AddMidasFreeze(ref, duration)
	elseif status == cncText.StatusEffect.POISON then
		ent:AddPoison(ref, duration, 3.5)
	elseif status == cncText.StatusEffect.SHRINK then
		ent:AddShrink(ref, duration)
	elseif status == cncText.StatusEffect.SLOW then
		ent:AddSlowing(ref, duration, 0.5, Color(1, 1, 1, 1, 0.5, 0.5, 0.5))
	elseif status == cncText.StatusEffect.BLEED then
		ent:AddEntityFlags(EntityFlag.FLAG_BLEED_OUT)
	end
end

return cncText
