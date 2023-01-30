local cnc = {}
local g = require("src_dndtable.globals")
local VeeHelper = include("src_dndtable.veeHelper")
local cncText = include("src_dndtable.prompts")
---@type GameState
local state = {}
VeeHelper.CopyOverTable(cncText.GameState, state)
local font = Font()
local background = Sprite()
local characters = Sprite()
local optionCursor = Sprite()
local dice = Sprite()
local diceFlash = Sprite()
local charactersConfirmed = {
	false,
	false,
	false,
	false
}
local testStartPrompt = Keyboard.KEY_J
local testEndPrompt = Keyboard.KEY_K
local keyDelay = 10
local numConfirmed = 0
local optionSelected = 1
local renderPrompt = {
	Title = {},
	Options = {},
	Outcome = {}
}
local yTarget = 25
local alphaSpeed = 0.04
local ySpeed = 0.75
local fadeType = "AllDown"
local transitionY = {
	Title = 0,
	Prompt = 0,
	Characters = 0
}
local transitionAlpha = {
	Title = 1,
	Prompt = 1,
	Characters = 1
}
local headOffset = 0
local headOffsetTimer = 30
local roomIndexOnMinigameClear = 0

---@type EntityPlayer[]
local dndPlayers = {

}

--------------------------
--  BASIC HELPER STUFF  --
--------------------------

local function getCenterScreen()
	return Vector(Isaac.GetScreenWidth() / 2, Isaac.GetScreenHeight() / 2)
end

local function getPlayers()
	local players = VeeHelper.GetAllMainPlayers()
	if #players > 4 then players = { players[1], players[2], players[3], players[4] } end
	return players
end

---@param action ButtonAction
---@param player EntityPlayer
local function isTriggered(action, player)
	return Input.IsActionTriggered(action, player.ControllerIndex)
end

---@param stringTable table
function cnc:separateTextByHashtag(stringTable)
	while string.find(stringTable[#stringTable], "#") ~= nil do
		local curText = stringTable[#stringTable]
		local line1, line2 = string.find(curText, "#")
		local nextLine = string.sub(curText, line2 + 1, -1)
		stringTable[#stringTable] = string.sub(curText, 1, line1 - 1)
		stringTable.insert(stringTable, nextLine)
	end
	return stringTable
end

function cnc:RollDice()
	local num = VeeHelper.RandomNum(1, 20)
	state.RollResult = num
	state.OutcomeResult = num < 6 and 1 or num < 16 and 2 or num <= 20 and 3 or 2
	state.NumAvailableRolls = state.NumAvailableRolls - 1
end

function cnc:IsInDNDRoom()
	local roomVariant = g.game:GetLevel():GetCurrentRoomDesc().Data.OriginalVariant
	if roomVariant >= 1600 and roomVariant <= 1620 then
		return true
	else
		return false
	end
end

----------------------
--  INITIATE STUFF  --
----------------------

local function initMinigame()
	state.Active = true
	state.ScreenShown = true
	state.HudWasVisible = g.game:GetHUD():IsVisible()
	state.RoomIndexStartedGameFrom = g.game:GetLevel():GetCurrentRoomIndex()
	background:Load("gfx/cnc_background.anm2", true)
	background:Play("Start", true)
	background.PlaybackSpeed = 0.5
	characters:Load("gfx/cnc_background.anm2", true)
	characters:Play("Start", true)
	optionCursor:Load("gfx/cnc_cursor_option.anm2", true)
	optionCursor:Play(optionCursor:GetDefaultAnimation(), true)
	dice:Load("gfx/cnc_d20.anm2", true)
	diceFlash:Load("gfx/cnc_d20.anm2", true)
	diceFlash:SetFrame("Result", 0)
	font:Load("font/teammeatfont12.fnt")
	Isaac.GetPlayer().ControlsEnabled = false
	print("minigame init")
end

local function initCharacterSelect()
	local players = getPlayers()
	g.game:GetHUD():SetVisible(false)
	characters:SetFrame("Title" .. tonumber(#players), 0)
	fadeType = "CharacterUp"
end

local function resetMinigame()
	renderPrompt = {
		Title = {},
		Options = {},
		Outcome = {}
	}
	background:Reset()
	characters:Reset()
	Isaac.GetPlayer().ControlsEnabled = true
	numConfirmed = 0
	optionSelected = 1
	charactersConfirmed = {
		false,
		false,
		false,
		false
	}
	for _, player in ipairs(dndPlayers) do
		player.GridCollisionClass = GridCollisionClass.COLLISION_NONE
		player.Position = Vector(1000, 1000)
		player:Die()
		player:GetSprite():Play("Death", true)
		player:GetSprite():SetLastFrame()
	end
	for _, player in ipairs(VeeHelper.GetAllPlayers()) do
		local data = player:GetData()
		if data.CNC_PreviousCollisionClass then
			player.GridCollisionClass = player:GetData().CNC_PreviousCollisionClass
		end
	end
	g.game:GetHUD():SetVisible(state.HudWasVisible)
	roomIndexOnMinigameClear = state.RoomIndexStartedGameFrom
	VeeHelper.CopyOverTable(cncText.GameState, state)
	print("minigame reset")
	fadeType = "AllDown"
end

function cnc:startNextPrompt()
	fadeType = "TitlePromptUp"
	local selectNextPrompt = true
	local promptTypeToUse = cncText.Prompts

	if state.PromptProgress > 0 then
		local curPrompt = cncText:GetTableFromPromptType(state.PromptTypeSelected)
		if curPrompt[state.PromptSelected] then
			if curPrompt[state.PromptSelected].Effect[optionSelected] then
				local effects = curPrompt[state.PromptSelected].Effect[optionSelected][state.OutcomeResult] or
					curPrompt[state.PromptSelected].Effect[optionSelected]
				if effects.Keys then
					state.Inventory.Keys = state.Inventory.Keys + effects.Keys
				end
				if effects.Bombs then
					state.Inventory.Bombs = state.Inventory.Bombs + effects.Bombs
				end
				if effects.Coins then
					state.Inventory.Coins = state.Inventory.Coins + effects.Coins
				end
				if effects.Collectible then

				end
				if effects.EntityFlagsOnRoomEnter then
					state.EntityFlagsOnNextEncounter = effects.EntityFlagsOnRoomEnter
				end
				if effects.ForceNextPrompt then
					selectNextPrompt = false
					promptTypeToUse = effects.ForceNextPrompt.TableToUse
					if effects.ForceNextPrompt.PromptNumber then
						state.PromptSelected = effects.ForceNextPrompt.PromptNumber
					end
				end
				if effects.StartEncounter then
					Isaac.ExecuteCommand("goto s.default." .. tostring(effects.StartEncounter))
				end
			end
		end
	end
	state.PromptProgress = state.PromptProgress + 1
	state.RollResult = 0
	state.OutcomeResult = 0
	state.HasSelected = false
	state.NumAvailableRolls = 1
	optionSelected = 1

	if selectNextPrompt then
		state.PromptSelected = 1
		--state.PromptSelected = VeeHelper.GetDifferentRandomNum(state.PromptsSeen, state.MaxPrompts, VeeHelper.RandomRNG)
		if state.PromptProgress == 3 then
			promptTypeToUse = cncText.Encounters
		elseif state.PromptProgress == state.MaxPrompts then
			promptTypeToUse = cncText.BossEncounters
		elseif VeeHelper.RandomNum(1, 50) == 50 then
			promptTypeToUse = cncText.RarePrompts
		end
	end
	local prompt = promptTypeToUse[state.PromptSelected]
	local title = cnc:separateTextByHashtag({ prompt.Title })
	renderPrompt.Title = title
	renderPrompt.Options = {}
	for _, option in ipairs(prompt.Options) do
		local optionRequirment = option[3]
		local shouldCreate = true

		if optionRequirment then
			if type(optionRequirment) == "number"
				and state.Characters.NumActive[optionRequirment + 1] == 0
			then
				shouldCreate = false
			elseif type(optionRequirment) == "string"
				and (
				(
					string.sub(optionRequirment, 1, 3) ~= "Key"
						and string.sub(optionRequirment, 1, 4) ~= "Bomb"
						and string.sub(optionRequirment, 1, 4) ~= "Coin"
					)
					or (
					string.sub(optionRequirment, 1, 3) == "Key"
						and state.Inventory.Keys < tonumber(string.sub(optionRequirment, 4, -1))
					)
					or (
					string.sub(optionRequirment, 1, 4) == "Bomb"
						and state.Inventory.Bombs < tonumber(string.sub(optionRequirment, 5, -1))
					)
					or (
					string.sub(optionRequirment, 1, 4) == "Coin"
						and state.Inventory.Coins < tonumber(string.sub(optionRequirment, 5, -1))
					)
				)
			then
				shouldCreate = false
			end
		end
		if shouldCreate then
			local names = {
				[PlayerType.PLAYER_ISAAC] = "Isaac",
				[PlayerType.PLAYER_MAGDALENA] = "Maggy",
				[PlayerType.PLAYER_CAIN] = "Cain",
				[PlayerType.PLAYER_JUDAS] = "Judas",
			}
			local prefix = ""
			if type(optionRequirment) == "number" then
				prefix = names[optionRequirment]
				prefix = "[" .. prefix .. "] "
			elseif type(optionRequirment) == "string" then
				local name = string.sub(optionRequirment, 1, 3) == "Key" and string.sub(optionRequirment, 1, 3) or
					string.sub(optionRequirment, 1, 4)
				local num = name == "Key" and string.sub(optionRequirment, 4, -1) or
					string.sub(optionRequirment, 5, -1)
				if name == "Key" then
					prefix = "-" .. num .. " " .. name
				elseif name == "Bomb" then
					prefix = "-" .. num .. " " .. name
				elseif name == "Coin" then
					prefix = "-" .. num .. " " .. name
				end
				prefix = "[" .. prefix .. "] "
			end
			local prompt = {}
			prompt[1] = option[1]
			prompt[2] = prefix .. option[2]
			prompt[3] = optionRequirment
			table.insert(renderPrompt.Options, prompt)
		end
	end
end

local function initFirstPrompt()
	local player1 = Isaac.GetPlayer()
	background:Play("Frame", true)
	characters:SetFrame(tostring(#getPlayers()), 0)
	cnc:startNextPrompt()
	player1:GetData().DNDKeyDelay = keyDelay
	fadeType = "AllUp"
	state.RoomIndexStartedGameFrom = g.game:GetLevel():GetCurrentRoomIndex()
	cnc:spawnDNDPlayers()
	Isaac.ExecuteCommand("goto s.default.2")
end

-----------------
--  RUN STUFF  --
-----------------

---@param text string
---@param posY number
local function renderCursor(text, posY)
	local posX = getCenterScreen().X
	posX = posX - (font:GetStringWidth(text) / 2)
	optionCursor:Render(Vector(posX, posY), Vector.Zero, Vector.Zero)
	optionCursor:Update()
end

---@param stringTable table
---@param startingPos number
---@param textType? string
---@param scale? number
local function renderText(stringTable, startingPos, textType, scale)
	local center = getCenterScreen()
	local nextLineMult = 0.15
	local posPerLineMult = (textType == "Title" and (#stringTable < 4 and 0.15 or #stringTable >= 4 and 0.1)) or 0.05
	local lineSpacingMult = 125

	local posX = textType == "Title" and (center.X - 120) or 0
	local boxLength = textType == "Title" and 235 or Isaac.GetScreenWidth()

	for i = 1, #stringTable do
		local mult = 0.2
		local middleNum = (math.ceil(#stringTable / 2))

		if #stringTable % 2 == 0 then
			mult = 0.1
		end
		if i < middleNum then
			mult = mult - (nextLineMult * (middleNum - i))
		elseif i > middleNum then
			mult = mult + (nextLineMult * (i - middleNum))
		end

		mult = mult + (posPerLineMult * #stringTable)
		local posY = center.Y + startingPos + (lineSpacingMult * mult)
		local text = textType == "Option" and stringTable[i][2] or stringTable[i]

		if textType == "Option"
			and #stringTable > 1 and i == optionSelected
			and transitionY.Prompt == 0
		then
			renderCursor(text, posY + 8)
		end
		local yOffset = textType == "Title" and transitionY.Title or transitionY.Prompt
		local alphaOffset = textType == "Title" and transitionAlpha.Title or transitionAlpha.Prompt
		font:DrawString(text, posX, posY + yOffset, KColor(1, 1, 1, alphaOffset), boxLength, true)
	end
end

function cnc:CharacterSelect()
	local player1 = Isaac.GetPlayer()
	local players = getPlayers()

	--[[ if CNCDebug.Enabled then
		players = {}
		for _ = 1, CNCDebug.NumPlayers do
			table.insert(players, player1)
		end
	end ]]
	for i, player in ipairs(players) do
		local data = player:GetData()
		if (
			isTriggered(ButtonAction.ACTION_MENULEFT, player)
				or isTriggered(ButtonAction.ACTION_MENURIGHT, player)
				or isTriggered(ButtonAction.ACTION_MENUCONFIRM, player)
				or isTriggered(ButtonAction.ACTION_BOMB, player)
			)
			and not player:GetData().DNDKeyDelay
			and not g.game:IsPaused()
		then
			if (
				isTriggered(ButtonAction.ACTION_MENULEFT, player)
					or isTriggered(ButtonAction.ACTION_MENURIGHT, player)
				)
				and charactersConfirmed[i] == false
			then
				local num = isTriggered(ButtonAction.ACTION_MENULEFT, player) and -1 or 1
				local soundToPlay = isTriggered(ButtonAction.ACTION_MENULEFT, player) and
					SoundEffect.SOUND_CHARACTER_SELECT_LEFT or SoundEffect.SOUND_CHARACTER_SELECT_RIGHT
				state.Characters.Selected[i] = state.Characters.Selected[i] + num
				state.Characters.Selected[i] = state.Characters.Selected[i] > 4 and 1 or state.Characters.Selected[i] < 1 and 4 or
					state.Characters.Selected[i]
				g.sfx:Play(soundToPlay)
				data.DNDKeyDelay = keyDelay
			end

			if isTriggered(ButtonAction.ACTION_MENUCONFIRM, player)
				and charactersConfirmed[i] == false
			then
				state.Characters.NumActive[state.Characters.Selected[i]] = state.Characters.NumActive[state.Characters.Selected[i]] +
					1
				charactersConfirmed[i] = true
				g.sfx:Play(SoundEffect.SOUND_THUMBSUP)
				numConfirmed = numConfirmed + 1
				data.DNDKeyDelay = keyDelay
			elseif isTriggered(ButtonAction.ACTION_BOMB, player)
				and charactersConfirmed[i] == true
			then
				charactersConfirmed[i] = false
				state.Characters.NumActive[state.Characters.Selected[i]] = state.Characters.NumActive[state.Characters.Selected[i]] -
					1
				numConfirmed = numConfirmed - 1
				data.DNDKeyDelay = keyDelay
			end
		end
	end
	if numConfirmed >= #players
		and isTriggered(ButtonAction.ACTION_MENUCONFIRM, player1)
		and not player1:GetData().DNDKeyDelay
		and not g.game:IsPaused()
	then
		background:Play("FadeOutTitle", true)
		fadeType = "AllDown"
	end
end

function cnc:MinigameLogic()
	local player1 = Isaac.GetPlayer()

	if Input.IsButtonTriggered(testStartPrompt, player1.ControllerIndex)
		and not state.Active
		and not g.game:IsPaused()
	then
		initMinigame()
	elseif state.Active then
		if state.PromptProgress == 0 and background:IsFinished("Start") and characters:GetAnimation() == "Start" then
			initCharacterSelect()
		elseif state.PromptProgress == 0
			and string.sub(characters:GetAnimation(), 1, 5) == "Title"
			and not background:IsPlaying("FadeOutTitle")
		then
			cnc:CharacterSelect()
		elseif state.PromptProgress >= 1 then
			local prompt = cncText.Prompts[state.PromptSelected]
			local data = player1:GetData()

			if isTriggered(ButtonAction.ACTION_MENUCONFIRM, player1)
				and not g.game:IsPaused()
				and not data.DNDKeyDelay
			then
				if not state.HasSelected then
					local outcomeText = prompt.Outcome[optionSelected]
					if renderPrompt.Options[optionSelected][1] == "Roll" then
						cnc:RollDice()
						local characterIndex = renderPrompt.Options[optionSelected][3] + 1

						if state.OutcomeResult < 3
							and characterIndex ~= nil
							and state.Characters.NumActive[characterIndex] > 1
						then
							state.NumAvailableRolls = state.Characters.NumActive[characterIndex] - 1
						end
						outcomeText = outcomeText[state.OutcomeResult]
					end
					renderPrompt.Outcome = cnc:separateTextByHashtag({ outcomeText })
					fadeType = "PromptDown"
				else
					if renderPrompt.Options[optionSelected][1] == "Roll"
						and state.NumAvailableRolls > 0 then
						cnc:RollDice()
					else
						fadeType = "TitlePromptDown"
					end
				end
				data.DNDKeyDelay = keyDelay
			end

			if dice:GetAnimation() ~= "Idle" then
				dice:Render(getCenterScreen(), Vector.Zero, Vector.Zero)
			end

			renderText(renderPrompt.Title, -120, "Title")

			if not state.HasSelected then
				if fadeType == "PromptDown" and transitionY.Prompt == yTarget then
					state.HasSelected = true
					fadeType = "PromptUp"
				end
			else
				if fadeType == "AllDown" and state.PromptTypeSelected == cncText.PromptType.ENEMY then

				elseif fadeType == "TitlePromptDown" and transitionY.Prompt == yTarget then
					cnc:startNextPrompt()
				end
			end

			if not state.HasSelected then
				if renderPrompt.Options[2] ~= nil then
					if (
						isTriggered(ButtonAction.ACTION_MENUUP, player1)
							or isTriggered(ButtonAction.ACTION_MENUDOWN, player1)
						)
						and not data.DNDKeyDelay
						and not g.game:IsPaused()
					then
						optionSelected = isTriggered(ButtonAction.ACTION_MENUUP, player1) and
							optionSelected - 1
							or optionSelected + 1
						optionSelected = optionSelected < 1 and #renderPrompt.Options or optionSelected > #renderPrompt.Options and 1
							or optionSelected
						local soundToPlay = isTriggered(ButtonAction.ACTION_MENUUP, player1) and
							SoundEffect.SOUND_CHARACTER_SELECT_LEFT or SoundEffect.SOUND_CHARACTER_SELECT_RIGHT
						g.sfx:Play(soundToPlay)
						data.DNDKeyDelay = keyDelay
						print(optionSelected)
					end
				end
				renderText(renderPrompt.Options, 0, "Option")
			else
				if renderPrompt.Options[optionSelected][1] == "Roll" then
					renderText({ state.RollResult }, 0.2)
					if state.NumAvailableRolls > 0 then
						renderText({ "You have more players, roll again" }, 0)
					else
						renderText(renderPrompt.Outcome, 0)
					end
				else
					renderText(renderPrompt.Outcome, 0)
				end
			end
		end
	end
	if Input.IsButtonTriggered(testEndPrompt, player1.ControllerIndex)
		and not Isaac.GetPlayer():GetData().DNDKeyDelay
		and not g.game:IsPaused()
	then
		resetMinigame()
		Isaac.GetPlayer():GetData().DNDKeyDelay = keyDelay
	end
end

function cnc:RenderScreen()
	if state.Active then
		local center = getCenterScreen()
		local transitionPos = Vector(center.X, center.Y + transitionY.Characters)
		if background:IsFinished("FadeOutTitle") then
			initFirstPrompt()
		end
		if state.PromptProgress == 0 then
			cnc:AnimationTimer()
			if string.sub(characters:GetAnimation(), 1, 5) == "Title" then
				--background:RenderLayer(0, center, Vector.Zero, Vector.Zero) --Black background
				background:RenderLayer(1, center, Vector.Zero, Vector.Zero) --Frame
				background:RenderLayer(7, center, Vector.Zero, Vector.Zero) --Debug frame
				background:RenderLayer(8, center, Vector.Zero, Vector.Zero) -- Title

				for i = 1, tonumber(string.sub(characters:GetAnimation(), 6, -1)) do
					local startingFrame = (i * 2) - 2
					local selectFrame = (i * 3) - 1
					local frameToUse = charactersConfirmed[i] and selectFrame or (startingFrame + headOffset)
					local characterLayer = state.Characters.Selected[i] + 10
					characters:RenderLayer(characterLayer, transitionPos, Vector.Zero, Vector.Zero) --Characters
					characters:SetLayerFrame(characterLayer, frameToUse)
					characters:RenderLayer(10, transitionPos, Vector.Zero, Vector.Zero) --Character Circle
					characters:SetLayerFrame(10, frameToUse)
					characters:RenderLayer(15, transitionPos, Vector.Zero, Vector.Zero) --Character Arrows
					characters:SetLayerFrame(15, frameToUse)
				end
			else
				background:Render(center, Vector.Zero, Vector.Zero)
			end
		elseif state.PromptProgress > 0 then
			cnc:AnimationTimer()
			if characters:GetAnimation() == "1"
				or characters:GetAnimation() == "2"
				or characters:GetAnimation() == "3"
				or characters:GetAnimation() == "4"
			then
				--background:RenderLayer(0, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(1, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(7, center, Vector.Zero, Vector.Zero)
				for i = 1, tonumber(characters:GetAnimation()) do
					local startingFrame = (i * 2) - 2
					local characterLayer = state.Characters.Selected[i] + 2
					characters:RenderLayer(characterLayer, transitionPos, Vector.Zero, Vector.Zero)
					characters:SetLayerFrame(characterLayer, startingFrame + headOffset)
				end
				characters:RenderLayer(2, transitionPos, Vector.Zero, Vector.Zero)
				characters:SetLayerFrame(2, 0 + headOffset)
			end
		end
		characters.Color = Color(1, 1, 1, transitionAlpha.Characters)
		characters:Update()
		background:Update()
	end
end

--------------------------
-- PLAYER/ROOM HANDLING --
--------------------------

--Thank you tem
function cnc:spawnDNDPlayers()
	for i, player in ipairs(getPlayers()) do
		local playerType = state.Characters.Selected[i] - 1
		local lastPlayerIndex = g.game:GetNumPlayers() - 1

		if lastPlayerIndex >= 63 then
			return
		else
			Isaac.ExecuteCommand('addplayer ' .. playerType .. ' ' .. player.ControllerIndex)
			local strawman = Isaac.GetPlayer(lastPlayerIndex + 1)
			strawman.Parent = player
			strawman:AddCollectible(g.DND_PLAYER_TECHNICAL)
			strawman.ControlsEnabled = false
			table.insert(dndPlayers, strawman)
			Game():GetHUD():AssignPlayerHUDs()
		end
	end
end

function cnc:OnNewRoom()
	local players = VeeHelper.GetAllPlayers()
	for i, player in ipairs(players) do
		if cnc:IsInDNDRoom() and not player:HasCollectible(g.DND_PLAYER_TECHNICAL) then
			player:GetData().CNC_PreviousCollisionClass = player.GridCollisionClass
			player.GridCollisionClass = GridCollisionClass.COLLISION_NONE
			player.Position = Vector(-1000, -1000)
		end
	end
end

function cnc:OnPostUpdate()
	local allDead = true
	for i, player in ipairs(dndPlayers) do
		if not player:IsDead() then
			allDead = false
		elseif not state.Characters.Dead[i] and state.Active then
			state.Characters.Dead[i] = true
			if state.Characters.NumActive[i] > 0 then
				state.Characters.NumActive[i] = state.Characters.NumActive[i] - 1
			end
			characters:ReplaceSpritesheet(i + 2, "gfx/ui/cnc_heads_dead.png")
			characters:LoadGraphics()
		end
	end
	if state.Active == false
		and roomIndexOnMinigameClear ~= 0
		and allDead
	then
		g.sfx:Stop(SoundEffect.SOUND_ISAACDIES)
		g.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
		g.game:StartRoomTransition(roomIndexOnMinigameClear, Direction.NO_DIRECTION, RoomTransitionAnim.FADE)
		roomIndexOnMinigameClear = 0
	end
end

---@param player EntityPlayer
function cnc:OnPlayerUpdate(player)
	if state.Active and player.ControlsEnabled == true then
		if not player:HasCollectible(g.DND_PLAYER_TECHNICAL)
			or (player:HasCollectible(g.DND_PLAYER_TECHNICAL) and not cnc:IsInDNDRoom()) then
			player.ControlsEnabled = false
		end
	end
end

---------------------
--  TIMER HANDLES  --
---------------------

---@param player EntityPlayer
function cnc:KeyDelayHandle(player)
	local data = player:GetData()
	if data.DNDKeyDelay then
		if data.DNDKeyDelay > 0 then
			data.DNDKeyDelay = data.DNDKeyDelay - 1
		else
			data.DNDKeyDelay = nil
		end
	end
end

function cnc:HandleTransitions()
	local alpha = {
		p = transitionAlpha.Prompt,
		t = transitionAlpha.Title,
		c = transitionAlpha.Characters
	}
	local y = {
		p = transitionY.Prompt,
		t = transitionY.Title,
		c = transitionY.Characters
	}
	if fadeType == "TitlePromptDown" then
		if alpha.p > 0 then
			alpha.p = alpha.p - alphaSpeed
		end
		if alpha.t > 0 then
			alpha.t = alpha.t - alphaSpeed
		end
		if y.p < yTarget then
			y.p = y.p + ySpeed
		end
		if y.t < yTarget then
			y.t = y.t + ySpeed
		end
	elseif fadeType == "TitlePromptUp" then
		if alpha.p < 1 then
			alpha.p = alpha.p + alphaSpeed
		end
		if alpha.t < 1 then
			alpha.t = alpha.t + alphaSpeed
		end
		if y.p > 0 then
			y.p = y.p - ySpeed
		end
		if y.t > 0 then
			y.t = y.t - ySpeed
		end
	elseif fadeType == "PromptDown" then
		if alpha.p > 0 then
			alpha.p = alpha.p - alphaSpeed
		end
		if y.p < yTarget then
			y.p = y.p + ySpeed
		end
	elseif fadeType == "PromptUp" then
		if alpha.p < 1 then
			alpha.p = alpha.p + alphaSpeed
		end
		if y.p > 0 then
			y.p = y.p - ySpeed
		end
	elseif fadeType == "CharacterUp" then
		if alpha.c < 1 then
			alpha.c = alpha.c + alphaSpeed
		end
		if y.c > 0 then
			y.c = y.c - ySpeed
		end
	elseif fadeType == "CharacterDown" then
		if alpha.c > 0 then
			alpha.c = alpha.c - alphaSpeed
		end
		if y.c < yTarget then
			y.c = y.c + ySpeed
		end
	elseif fadeType == "AllDown" then
		if alpha.p > 0 then
			alpha.p = alpha.p - alphaSpeed
		end
		if alpha.t > 0 then
			alpha.t = alpha.t - alphaSpeed
		end
		if alpha.c > 0 then
			alpha.c = alpha.c - alphaSpeed
		end
		if y.p < yTarget then
			y.p = y.p + ySpeed
		end
		if y.t < yTarget then
			y.t = y.t + ySpeed
		end
		if y.c < yTarget then
			y.c = y.c + ySpeed
		end
	elseif fadeType == "AllUp" then
		if alpha.p < 1 then
			alpha.p = alpha.p + alphaSpeed
		end
		if alpha.t < 1 then
			alpha.t = alpha.t + alphaSpeed
		end
		if alpha.c < 1 then
			alpha.c = alpha.c + alphaSpeed
		end
		if y.p > 0 then
			y.p = y.p - ySpeed
		end
		if y.t > 0 then
			y.t = y.t - ySpeed
		end
		if y.c > 0 then
			y.c = y.c - ySpeed
		end
	end
	for name, value in pairs(y) do
		if value < 0 then
			y[name] = 0
		elseif value > yTarget then
			y[name] = yTarget
		end
	end
	for name, value in pairs(alpha) do
		if value < 0 then
			alpha[name] = 0
		elseif value > 1 then
			alpha[name] = 1
		end
	end
	transitionAlpha.Prompt = alpha.p
	transitionAlpha.Title = alpha.t
	transitionAlpha.Characters = alpha.c
	transitionY.Prompt = y.p
	transitionY.Title = y.t
	transitionY.Characters = y.c
end

function cnc:AnimationTimer()
	if g.game:IsPaused() then return end
	if headOffsetTimer > 0 then
		headOffsetTimer = headOffsetTimer - 1
	else
		headOffset = headOffset == 0 and 1 or 0
		headOffsetTimer = 30
	end
end

------------
--  MISC  --
------------

function cnc:OnRender()
	local renderMode = g.game:GetRoom():GetRenderMode()
	if renderMode == RenderMode.RENDER_NULL
		or renderMode == RenderMode.RENDER_NORMAL
		or renderMode == RenderMode.RENDER_WATER_ABOVE
	then
		cnc:RenderScreen()
		cnc:MinigameLogic()
		cnc:HandleTransitions()
	end
end

function cnc:OnPreGameExit()
	resetMinigame()
end

return cnc
