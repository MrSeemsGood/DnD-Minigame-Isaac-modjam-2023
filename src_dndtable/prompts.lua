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
---@field Speed number

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

---@type Prompt[]
cncText.Prompts = {

	-- 1: ROCKS WITH GOLD
	{
		Title = "You come across a giant rock with shiny nuggets sticking out of it.",
		Options = {
			[1] = { "Select", "Leave it be." },
			[2] = { "Roll", "Try to break it with your hands." },
			[3] = { "Select", "Bomb it.", "Bomb1"}
		},
		Outcome = {
			[1] = "You walk into the next room.",
			[2] = {
				[1] = "You hurt yourself trying to tear the nuggets off.",
				[2] = "You tried tearing the precious parts off, to no avail.",
				[3] = "You can tear some pieces off just fine.",
			},
			[3] = "The bomb you placed does quick work of the rock.",
		},
		Effect = {
			[2] = {
				[1] = {
					DamagePlayers = 1,
					Coins = 1
				},
				[2] = {
					Coins = 1
				},
				[3] = {
					Coins = 3
				},
			},
			[3] = {
				Bombs = -1,
				Coins = 5
			},
		}
	},
	-- 2: BAG ON A CLIFF
	{
		Title = "You notice a cloth bag on a small cliff above. You can climb the rope to get to it.",
		Options = {
			[1] = { "Select", "Leave it be." },
			[2] = { "Roll", "Try to climb the rope." },
		},
		Outcome = {
			[1] = "You walk into the next room.",
			[2] = {
				[1] = "The rope breaks as soon as you start climbing it.",
				[2] = "THe rope breaks as you've almost reach the bag. You fall down.",
				[3] = "You succesfully climb the rope.",
			},
		},
		Effect = {
			[2] = {
				[2] = {
					Stats = {
						Speed = -0.1
					}
				},
				[3] = {
					Coins = 3,
					Keys = 1,
					Bombs = 1
				},
			},
		}
	},
	-- 3: OLD DRESSING TABLE
	{
		Title = "You come across a vintage dressing table.",
		Options = {
			[1] = { "Select", "Leave it be." },
			[2] = { "Roll", "Search it." },
			[3] = { "Select", "Bomb it.", "Bomb1"}
		},
		Outcome = {
			[1] = "You walk into the next room.",
			[2] = {
				[1] = "You find a lipstick.",
				[2] = "You find a perfume.",
				[3] = "You find a bunch of old jewelry.",
			},
			[3] = "Nothing happens when you bomb it.",
		},
		Effect = {
			[2] = {
				[1] = {
					Collectible = CollectibleType.COLLECTIBLE_MOMS_LIPSTICK
				},
				[2] = {
					Collectible = CollectibleType.COLLECTIBLE_MOMS_PERFUME
				},
				[3] = {
					Collectible = CollectibleType.COLLECTIBLE_MOMS_RING
				},
			},
		}
	},
	-- 4: OLD BOOKCASE
	{
		Title = "You come across a giant bookcase. It is very old, barely holding itself together.",
		Options = {
			[1] = { "Select", "Leave it be." },
			[2] = { "Roll", "Search it for books." },
			[3] = { "Roll", "You decide to crush the bookcase down and then search it.", PlayerType.PLAYER_ISAAC}
		},
		Outcome = {
			[1] = "You walk into the next room. Right as you leave, you hear a loud thud as the bookcase finally collapses under its own weight.",
			[2] = {
				[1] = "You tilt the bookcase too much and it falls down on you.",
				[2] = "All books here are extremely old and fragile. You can't find anything useful.",
				[3] = "You find a book and take it with you!",
			},
			[3] = {
				[1] = "You take one of the books with you. It looks relatively new.",
				[2] = "You take one of the books with you. It looks relatively new.",
				[3] = "You take one of the books with you. It looks relatively new.",
			},
		},
		Effect = {
			[2] = {
				[1] = {
					DamagePlayers = 1,
				},
				[2] = {
					Collectible = CollectibleType.COLLECTIBLE_MISSING_PAGE_2
				},
				[3] = {
					Collectible = CollectibleType.COLLECTIBLE_TELEPATHY_BOOK
				},
			},
			[3] = {
				[1] = {
					Collectible = CollectibleType.COLLECTIBLE_BOOK_OF_SHADOWS
				},
				[2] = {
					Collectible = CollectibleType.COLLECTIBLE_BOOK_OF_BELIAL
				},
				[3] = {
					Collectible = CollectibleType.COLLECTIBLE_TELEPATHY_BOOK
				},
			},
		}
	},
	-- 5: STRANGER
	{
		Title = "A shady figure is approaching you, extending his hand towards.",
		Options = {
			[1] = { "Select", "You shake his hand." },
			[2] = { "Select", "You back off and keep going." },
			[3] = { "Roll", "You decide to offer a deal.", "Coin2"},
			[4] = { "Select", "You smile back very politely.", PlayerType.PLAYER_MAGDALENE},
		},
		Outcome = {
			[1] = "The stranger wishes you the best of luck in traversing these caves.",
			[2] = "The stranger frowns, calls you rude and leaves.",
			[3] = {
				[1] = "The stranger steals the coins you offer him and runs into the dark.",
				[2] = "The stranger is not a merchant. He has nothing to offer you.",
				[3] = "The stranger is excited. They'd been craving for a new customer!"
			},
			[4] = "The stranger blushes and welcomes you to the caves with a special gift.",
		},
		Effect = {
			[1] = {
				StatsTemp = {
					DamageMult = 1.1
				}
			},
			[3] = {
				[1] = {
					Coins = -2
				},
				[3] = {
					Coins = -2,
					Collectible = CollectibleType.COLLECTIBLE_BOT_FLY
				}
			},
			[4] = {
				Coins = 2,
				Bombs = 2
			},
		}
	},
	-- 6: PITCH BLACK
	{
		Title = "You enter a cavern. It's pitch black. Completely",
		Options = {
			[1] = { "Roll", "You walk through very carefully." },
			[2] = { "Select", "You pass through.", PlayerType.PLAYER_CAIN},
			[3] = { "Select", "You lit the fuse on a bomb to observe the cavern.", "Bomb1"},
		},
		Outcome = {
			[1] = {
				[1] = "You do not notice a spike trap in the middle of a cavern.",
				[2] = "You notice a spike trap, but you aren't very careful around it.",
				[3] = "You notice a spike trap and barely pass through without getting hurt."
			},
			[2] = "You are used to the darkness, you manage to dodge a spike trap and even pick something up!",
			[3] = "You see a spike trap in the middle of the room. You cross right before the bomb explodes.",
		},
		Effect = {
			[1] = {
				[1] = {
					DamagePlayers = 2
				},
				[2] = {
					DamagePlayers = 1
				}
			},
			[2] = {
				Bombs = -1
			},
			[3] = {
				Keys = 1
			}
		}
	},
	--7: INNOCENT BEGGAR
	{
		Title = "You come across a beggar who asks for but a measely penny to help them get through the day.",
		Options = {
			[1] = { "Select", "Pay no notice to the beggar" },
			[2] = { "Select", "Give a coin to the beggar", "Coin1" },
			[3] = { "Select", "'Trade' with the beggar", PlayerType.PLAYER_CAIN },
		},
		Outcome = {
			[1] = "You move forwards through the caves, leaving the beggar for dead.",
			[2] = "You part ways with your penny and give it to the beggar. He thanks you and reveals himself to be a wizard! A magical spell grants you +1 damage to assist in defeating your foes.",
			[3] = "You offer some coins in exchange for any valuables they have. They give you a tooth, but you run off the moment it's in your hands. A curse is enacted upon you from the beggar, you feel slower!"
		},
		Effect = {
			[2] = {
				Coins = -1,
				Stats = {
					DamageFlat = 1
				}
			},
			[3] = {
				Stats = {
					Speed = -0.3
				},
				Collectible = CollectibleType.COLLECTIBLE_DEAD_TOOTH
			}
		}
	}
}

---@type Prompt[]
cncText.Encounters = {

	-- 1: INVISIBLE STALKERS
	{
		Title = "You enter a mysterious haunted hallway...",
		Options = {
			[1] = { "Roll", "How quiet of a prey are you?" },
			[2] = { "Select", "Show its inhabitants your devilish powers.", PlayerType.PLAYER_JUDAS }
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
	-- 2: BODAKS
	{
		Title = "You see strange creatures. Their skin is deathly pale and white...",
		Options = {
			[1] = { "Roll", "Are the undead craving for flesh?" },
			[2] = { "Select", "You decide to distract their attention with shiny metal.", "Coin3" }
		},
		Outcome = {
			[1] = {
				[1] = "You encounter Bodaks and their lesser undead friends.",
				[2] = "You encounter 2 Bodaks. However, the room is a bit too tight...",
				[3] = "You encounter 4 Bodaks.",
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
				ApplyStatus = { StatusEffect = cncText.StatusEffect.CONFUSION, Duration = 60 }
			}
		}
	},
	-- 3: YOCHLOLS
	{
		Title = "You encounter weird oozy creatures.#Their flesh melts off of them and piles back together.",
		Options = {
			[1] = { "Roll", "You try to lure them out into the open." }
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
	-- 4: ETTERCAPS
	{
		Title = "You enter the lair of Ettercaps, spider-like aberrations.",
		Options = {
			[1] = { "Roll", "You try to sneak out through the smallest cavern." }
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
	-- 5: DURRTS
	{
		Title = "A group of massive animated boulders stands in your way!",
		Options = {
			[1] = { "Roll", "You try to remain neutral to them and not cause aggression." },
			[2] = { "Select", "You reasonably decide to bomb them.", "Bomb1" },
			[3] = { "Select", "Can Stone giants be compassionate?", PlayerType.PLAYER_MAGDALENE }
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
				ApplyStatus = { StatusEffect = cncText.StatusEffect.CHARMED, Duration = 90 },
				Keys = 2,
				Coins = 3,
				Collectible = CollectibleType.COLLECTIBLE_SMALL_ROCK
			}
		}
	},
	-- 6: GRELLS
	{
		Title = "You encounter floating brains with tentacles and a beak. Oh, Mother Nature!",
		Options = {
			[1] = { "Roll", "You try to remain unnoticed." },
			[2] = { "Select", "You try to sneak by.", PlayerType.PLAYER_CAIN }
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
		Title = "You find an impatient, brown anthropomorphic furry creature pointing to the next room",
		Options = {
			[1] = { "Select", "Follow its directions" },
			[2] = { "Roll", "Roll a dice" },
			[3] = { "Select", "Disobey its directions" }
		},
		Outcome = {
			[1] = "You walk into the next room, wondering what all that was about.",
			[2] = {
				[1] = "You rolled a low number. Disappointed, they throw you into the next room.",
				[2] = "You rolled an ok enogh number to catch the creature's attention. They give you a penny for your troubles.",
				[3] = "You rolled a high number. Impressed, the creature ",
			},
			[3] = "The creature's eyes glow bright as lightning strikes down around them from the ceiling. They utter a phrase spoken in legend before you're smited down.",
		},
		Effect = {
			[3] = {
				DamagePlayers = 24
			}
		}
	},
}

---@type Prompt[]
cncText.BossEncounters = {
	{
		Title = "As you approach the next room, a migraine starts growing on you. It feels like somebody's trying to control your mind...",
		Options = {
			[1] = { "Roll", "Choose the hallway to proceed." },
			[2] = { "Select", "Go back the previous room." }
		},
		Outcome = {
			[1] = {
				[1] = "You can't run away from The Mind Flayer.",
				[2] = "You can't run away from The Mind Flayer.",
				[3] = "You can't run away from The Mind Flayer."
			},
			[2] = "You can't run away from The Mind Flayer."
		},
		Effect = {
			[1] = {
				[1] = {
					StartEncounter = 16001
				},
				[2] = {
					StartEncounter = 16000
				},
				[3] = {
					StartEncounter = 16002
				}
			},
			[2] = {
				StartEncounter = 16002
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
