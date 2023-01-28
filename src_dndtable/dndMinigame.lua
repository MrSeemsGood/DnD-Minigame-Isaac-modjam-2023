local dnd = {}
local g = require("src_dndtable.globals")
local VeeHelper = include("src_dndtable.veeHelper")
local dndText = include("src_dndtable.prompts")
---@type GameState
local state = {}
VeeHelper.CopyOverTable(dndText.GameState, state)
local font = Font()
local background = Sprite()
local optionCursor = Sprite()
local dice = Sprite()
local diceFlash = Sprite()
local characterSprites = {
	Sprite(),
	Sprite(),
	Sprite(),
	Sprite()
}
local charactersConfirmed = {
	false,
	false,
	false,
	false
}
local characterOffsets = {
	{
		0
	},
	{
		-0.1,
		0.1
	},
	{
		-0.2,
		0,
		0.2
	},
	{
		-0.3,
		-0.1,
		0.1,
		0.3
	},
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
local globalAlpha = 1
local globalYOffset = 0

local function getCenterScreen()
	return Vector(Isaac.GetScreenWidth() / 2, Isaac.GetScreenHeight() / 2)
end

---@param sprite Sprite
local function updateCharacterSprite(sprite, i)
	sprite:ReplaceSpritesheet(12, dndText.CharacterSprites[i])
	sprite:LoadGraphics()
end

local override = true
local hasShitted = false
local numPlayers = 1
local newPlayers = {}

local function initMinigame()
	state.Active = true
	background:Load("gfx/ui/dndminigame_background.anm2", true)
	background:Play("Start", true)
	optionCursor:Load("gfx/ui/dndminigame_cursor_option.anm2", true)
	optionCursor:Play(optionCursor:GetDefaultAnimation(), true)
	dice:Load("gfx/ui/dndminigame_d20.anm2", true)
	diceFlash:Load("gfx/ui/dndminigame_d20.anm2", true)
	diceFlash:SetFrame("Result", 0)
	for i = 1, #characterSprites do
		characterSprites[i]:Load("gfx/001.000_player.anm2", true)
		characterSprites[i]:SetFrame("Happy", 0)
		updateCharacterSprite(characterSprites[i], i)
		characterSprites[i].PlaybackSpeed = 0.5
	end
	font:Load("font/teammeatfont12.fnt")
	Isaac.GetPlayer().ControlsEnabled = false
	print("minigame init")
end

local function resetMinigame()
	VeeHelper.CopyOverTable(dndText.GameState, state)
	renderPrompt = {
		Title = {},
		Options = {},
		Outcome = {}
	}
	background:Reset()
	Isaac.GetPlayer().ControlsEnabled = true
	numConfirmed = 0
	optionSelected = 1
	charactersConfirmed = {
		false,
		false,
		false,
		false
	}
	print("minigame reset")
	hasShitted = false
end

local function transitionText()
	globalYOffset = 15
	globalAlpha = 0
end

local function startNextPrompt()
	state.PromptSelected = 1
	--state.PromptSelected = VeeHelper.GetDifferentRandomNum(state.PromptsSeen, state.MaxPrompts, VeeHelper.RandomRNG)
	state.PromptProgress = state.PromptProgress + 1
	state.RollResult = 0
	state.OutcomeResult = 0
	state.HasSelected = false
	state.NumAvailableRolls = 1
	optionSelected = 1
	local prompt = dndText.Prompts[state.PromptSelected]
	renderPrompt.Options = {}
	for i, option in ipairs(prompt.Options) do
		local shouldCreate = true
		--print(state.ActiveCharacters[1], state.ActiveCharacters[2], state.ActiveCharacters[3], state.ActiveCharacters[4])
		if option[3]
			and state.ActiveCharacters[option[3] + 1] == 0
		then
			shouldCreate = false
		end
		if shouldCreate then
			renderPrompt.Options[i] = {}
			renderPrompt.Options[i][1] = option[1]
			renderPrompt.Options[i][2] = option[2]
			renderPrompt.Options[i][3] = option[3]
		end
	end
	local title = {prompt.Title}
	local shit = 0
	while string.find(title[#title], "#") ~= nil do
		local curText = title[#title]
		local line1, line2 = string.find(curText, "#")
		local nextLine = string.sub(curText, line2 + 1, -1)
		title[#title] = string.sub(curText, 1, line1 -1)
		table.insert(title, nextLine)
	end
	renderPrompt.Title = title
end

---@param numPlayers integer
local function initFirstPrompt(numPlayers)
	local player1 = Isaac.GetPlayer()
	background:SetFrame(tostring(numPlayers), 0)
	startNextPrompt()
	player1:GetData().DNDKeyDelay = keyDelay
end

function ChangePlayerCount(i)
	hasShitted = false
	numPlayers = i
end

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
		local numOffset = (#stringTable > 2 and #stringTable % 2 == 0) and 0 or 1

		if (#stringTable % 2 == 0 and i <= middleNum) or i < middleNum then
			mult = mult - (nextLineMult * ((#stringTable + numOffset) - i))
		elseif (#stringTable % 2 == 0 and i > middleNum) or (i >= middleNum and #stringTable > 1) then
			mult = (nextLineMult * (i - (middleNum))) - (mult / 2)
		end
		mult = mult + (posPerLineMult * #stringTable)
		local posY = center.Y + startingPos + (lineSpacingMult * mult)
		local text = textType == "Option" and stringTable[i][2] or stringTable[i]

		if textType == "Option"
			and #stringTable > 1 and i == optionSelected
			and globalYOffset == 0
		then
			renderCursor(text, posY + 8)
		end

		font:DrawString(text, posX, posY + globalYOffset, KColor(1, 1, 1, globalAlpha), boxLength, true)
	end
end

---@param action ButtonAction
---@param player EntityPlayer
local function isTriggered(action, player)
	return Input.IsActionTriggered(action, player.ControllerIndex)
end

local function rollDice()
	local num = VeeHelper.RandomNum(1, 20)
	state.RollResult = num
	state.OutcomeResult = num < 6 and 1 or num < 16 and 2 or num <= 20 and 3 or 2
	state.NumAvailableRolls = state.NumAvailableRolls - 1
end

---@param playerType PlayerType
---@param player EntityPlayer
--Thank you tem
local function spawnDNDPlayer(playerType, player)
	playerType = playerType or 0
	local controllerIndex = player or 0
	local lastPlayerIndex = g.game:GetNumPlayers() - 1

	if lastPlayerIndex >= 63 then
		return nil
	else
		Isaac.ExecuteCommand('addplayer ' .. playerType .. ' ' .. controllerIndex)
		local strawman = Isaac.GetPlayer(lastPlayerIndex + 1)
		strawman.Parent = player
		Game():GetHUD():AssignPlayerHUDs()
		return strawman
	end
end

function dnd:RenderCharacterSelect()
	local center = getCenterScreen()
	local player1 = Isaac.GetPlayer()

	--renderText({ "Welcome to Caves n' Creatures!" }, -0.5, "Title", 1.5)
	--renderText({ "Select your character" }, -0.3)

	local players = newPlayers[1] ~= nil and newPlayers or VeeHelper.GetAllMainPlayers()
	if #players > 4 then players = { players[1], players[2], players[3], players[4] } end

	if override and not hasShitted then
		newPlayers = {}
		for _ = 1, numPlayers do
			table.insert(newPlayers, player1)
		end
		hasShitted = true
	end
	for i = 1, #players do
		local player = players[i]
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
				state.CharacterSelect[i] = state.CharacterSelect[i] + num
				state.CharacterSelect[i] = state.CharacterSelect[i] > 4 and 1 or state.CharacterSelect[i] < 1 and 4 or
					state.CharacterSelect[i]
				updateCharacterSprite(characterSprites[i], state.CharacterSelect[i])
				g.sfx:Play(soundToPlay)
				data.DNDKeyDelay = keyDelay
			end

			if isTriggered(ButtonAction.ACTION_MENUCONFIRM, player)
				and charactersConfirmed[i] == false
			then
				characterSprites[i]:Play("Happy", true)
				state.ActiveCharacters[state.CharacterSelect[i]] = state.ActiveCharacters[state.CharacterSelect[i]] + 1
				charactersConfirmed[i] = true
				g.sfx:Play(SoundEffect.SOUND_THUMBSUP)
				numConfirmed = numConfirmed + 1
				data.DNDKeyDelay = keyDelay
			elseif isTriggered(ButtonAction.ACTION_BOMB, player)
				and charactersConfirmed[i] == true
			then
				charactersConfirmed[i] = false
				state.ActiveCharacters[state.CharacterSelect[i]] = state.ActiveCharacters[state.CharacterSelect[i]] - 1
				numConfirmed = numConfirmed - 1
				data.DNDKeyDelay = keyDelay
			end
		end

		if charactersConfirmed[i] == false
			and characterSprites[i]:GetFrame() > 0 then
			characterSprites[i]:SetFrame(characterSprites[i]:GetFrame() - 1)
		elseif charactersConfirmed[i] == true
			and characterSprites[i]:GetFrame() == 6
		then
			characterSprites[i]:Stop()
		end
		characterSprites[i]:Render(Vector((center.X + (center.X * characterOffsets[#players][i])), center.Y + 50),
			Vector.Zero, Vector.Zero)
		characterSprites[i]:Update()
	end
	if numConfirmed >= #players
		and isTriggered(ButtonAction.ACTION_MENUCONFIRM, player1)
		and not player1:GetData().DNDKeyDelay then
		initFirstPrompt(#players)
	end
end

function dnd:WriteText()
	local player1 = Isaac.GetPlayer()

	if Input.IsButtonTriggered(testStartPrompt, player1.ControllerIndex)
		and not state.Active
		and not g.game:IsPaused()
	then
		initMinigame()
	elseif state.Active then
		if state.PromptProgress == 0 and background:IsFinished("Start") then
			background:Play("Title")
		elseif state.PromptProgress == 0 and background:IsFinished("Title") then
			dnd:RenderCharacterSelect()
		elseif state.PromptProgress >= 1 then
			local prompt = dndText.Prompts[state.PromptSelected]
			local data = player1:GetData()

			if isTriggered(ButtonAction.ACTION_MENUCONFIRM, player1)
				and not g.game:IsPaused()
				and not data.DNDKeyDelay
			then
				if not state.HasSelected then
					if renderPrompt.Options[optionSelected][1] == "Roll" then
						rollDice()
					end
					local characterIndex = renderPrompt.Options[optionSelected][3] + 1

					if state.OutcomeResult < 3
						and characterIndex ~= nil
						and state.ActiveCharacters[characterIndex] > 1
					then
						state.NumAvailableRolls = state.ActiveCharacters[characterIndex] - 1
					end
					state.HasSelected = true
				else
					if renderPrompt.Options[optionSelected][1] == "Roll"
						and state.NumAvailableRolls > 0 then
						rollDice()
					else
						startNextPrompt()
					end
				end
				data.DNDKeyDelay = keyDelay
			end

			if dice:GetAnimation() ~= "Idle" then
				dice:Render(getCenterScreen(), Vector.Zero, Vector.Zero)
			end

			if not state.HasSelected then
				renderText(renderPrompt.Title, -120, "Title")
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
				renderText(renderPrompt.Options, 25, "Option")
			else
				if renderPrompt.Options[optionSelected][1] == "Roll" then
					renderText({ state.RollResult }, 0.2)
					if state.NumAvailableRolls > 0 then
						renderText({ "You have more players, roll again" }, 0)
					else
						renderText({ prompt.Outcome[optionSelected][state.OutcomeResult] }, 0)
					end
				else
					renderText({ prompt.Outcome[optionSelected] }, 0)
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

---@param player EntityPlayer
function dnd:KeyDelayHandle(player)
	local data = player:GetData()
	if data.DNDKeyDelay then
		if data.DNDKeyDelay > 0 then
			data.DNDKeyDelay = data.DNDKeyDelay - 1
		else
			data.DNDKeyDelay = nil
		end
	end
end

function dnd:HandleTransitionText()
	if globalAlpha < 1 then
		globalAlpha = globalAlpha + 0.05
	end
	if globalYOffset > 0 then
		globalYOffset = globalYOffset - 0.5
	end
end

local headOffset = 0
local headOffsetTimer = 30
function dnd:AnimationTimer()
	if headOffsetTimer > 0 then
		headOffsetTimer = headOffsetTimer - 1
	else
		headOffset = headOffset == 0 and 1 or 0
		headOffsetTimer = 30
	end
end

function dnd:ScreenBackground()
	if state.Active then
		local center = getCenterScreen()
		if state.PromptProgress == 0 then
			background:Render(center, Vector.Zero, Vector.Zero)
		elseif state.PromptProgress > 0 then
			dnd:AnimationTimer()
			if background:GetAnimation() == "1"
				or background:GetAnimation() == "2"
				or background:GetAnimation() == "3"
				or background:GetAnimation() == "4"
			then
				background:RenderLayer(0, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(1, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(7, center, Vector.Zero, Vector.Zero)
				for i = 1, tonumber(background:GetAnimation()) do
					local startingFrame = (i * 2) - 2
					local characterLayer = state.CharacterSelect[i] + 2
					background:RenderLayer(characterLayer, center, Vector.Zero, Vector.Zero)
					background:SetLayerFrame(characterLayer, startingFrame + headOffset)
				end
				background:RenderLayer(2, center, Vector.Zero, Vector.Zero)
				background:SetLayerFrame(2, 0 + headOffset)
			end
		end
		background:Update()
	end
end

function dnd:OnPreGameExit()
	resetMinigame()
end

function dnd:OnRender()
	local renderMode = g.game:GetRoom():GetRenderMode()
	if renderMode == RenderMode.RENDER_NULL
		or renderMode == RenderMode.RENDER_NORMAL
		or renderMode == RenderMode.RENDER_WATER_ABOVE
	then
		dnd:ScreenBackground()
		dnd:WriteText()
		dnd:HandleTransitionText()
	end
end

return dnd
