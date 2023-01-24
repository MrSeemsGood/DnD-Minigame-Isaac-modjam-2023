local prompts = {}

--This is all placeholder stuff as I figure things out
prompts.CurProgress = {
	Stage = 1,
	MaxStages = 5
}

prompts.Encounters = {
	{
		text = "Yo mama approaches",
		defaultPips = 20,
		outcomeText = {
			[5] = "you dead as hell",
			[10] = "its a tie!",
			[20] = "she dead as hell",
		},
		outcomeAction = {
			[20] = function() print("Make something happen?") end --Probably a function where something happens
		}
	}
}

return prompts