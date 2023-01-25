local dndText = {}

dndText.GameState = {
	SelectedCharacters = {

	},
	PromptProgress = 0,
	PromptSelected = 1,
	HasRolled = false,
	NumRolled = 0,
	MaxPrompts = 3,
	PromptsSeen = {},
	EncountersSeen = {},
	AdventureEnded = false,
}

dndText.RewardType = {
	HEAL = 0,
	TRINKET = 1,
	ITEM = 2,
	KEY = 3,
	BOMB = 4,
	CONSUMABLE = 5,
}

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

dndText.OptionType = {
	ROLL = 0,
	ACCEPT = 1,
	DECLINE = 2,
}


dndText.Prompts = {
	{
		Text = "Yo mama approaches",
		Options = {
			[1] = { dndText.OptionType.ROLL, "Fight her ass" },
			[2] = { dndText.OptionType.DECLINE, "Get yo ass outta there" },
			[3] = { dndText.OptionType.ACCEPT, "Fucking stab her", PlayerType.PLAYER_JUDAS}
		},
		Outcome = {
			[1] = {
				[1] = "you're fucking dead bro",
				[5] = "you're severely damaged'",
				[10] = "You both barely manage to scrape one another, both of you part ways",
				[15] = {dndText.AdvantageType.DAMAGE, "You damage her"},
				[20] = {dndText.RewardType.ITEM, "she dead as hell"},
			},
			[2] = "You escape",
			[3] = {dndText.RewardType.ITEM, "she dead as hell"}
		},
	}
}

dndText.Encounters = {

}

dndText.RarePrompts = {

}

dndText.BossEncounters = {

}

return dndText
