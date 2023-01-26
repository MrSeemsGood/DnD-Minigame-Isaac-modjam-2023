local dnd = {}
local g = require("src_dndtable.globals")
local dndText = include("src_dndtable.prompts")
local state = dndText.GameState --For easier time typing and less space taken
local font = Font()
local blackScreen = Sprite()
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

local function getCenterScreen()
	return Vector(Isaac.GetScreenWidth() / 2, Isaac.GetScreenHeight() / 2)
end

---@param sprite Sprite
local function updateCharacterSprite(sprite, i)
	sprite:ReplaceSpritesheet(12, dndText.CharacterSprites[i])
	sprite:LoadGraphics()
end

local override = false
local hasShitted = false
local numPlayers = 1
local newPlayers = {}

local function initMinigame()
	print("minigame init")
	blackScreen:Load("gfx/ui/dnd_overlay.anm2", true)
	blackScreen:Play("Start", true)
	for i = 1, #characterSprites do
		characterSprites[i]:Load("gfx/001.000_player.anm2", true)
		characterSprites[i]:SetFrame("Happy", 0)
		updateCharacterSprite(characterSprites[i], i)
		characterSprites[i].PlaybackSpeed = 0.5
	end
	font:Load("font/teammeatfont12.fnt")
	Isaac.GetPlayer().ControlsEnabled = false
end

local function resetMinigame()
	state.Active = false
	state.HasRolled = false
	state.NumRolled = 0
	state.PromptProgress = 0
	blackScreen:Reset()
	Isaac.GetPlayer().ControlsEnabled = true
	numConfirmed = 0
	charactersConfirmed = {
		false,
		false,
		false,
		false
	}
	print("minigame reset")
	hasShitted = false
end

local function startNextPrompt()
	state.PromptSelected = 1
	--state.PromptSelected = VeeHelper.GetDifferentRandomNum(state.PromptsSeen, state.MaxPrompts, VeeHelper.RandomRNG)
	state.PromptProgress = state.PromptProgress + 1
	state.NumRolled = 0
	state.HasRolled = false
	print("next pussy")
end

function ChangePlayerCount(i)
	hasShitted = false
	numPlayers = i
end

---@param playerType PlayerType
---@param player EntityPlayer
--Thank you tem
function dnd:SpawnPlayer(playerType, player)
	playerType = playerType or 0
	local controllerIndex = player.ControllerIndex or 0
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

function dnd:WriteText()
	--if g.game:IsPaused() then return end
	local center = getCenterScreen()
	local player1 = Isaac.GetPlayer()

	if Input.IsButtonTriggered(testStartPrompt, player1.ControllerIndex)
		and not state.Active
		and not g.game:IsPaused()
	then
		state.Active = true
		initMinigame()
	elseif state.Active then
		if state.PromptProgress == 0 and blackScreen:IsFinished("Start") then
			font:DrawStringScaled("Welcome to Basements & Monsters!", 0, center.Y - 50, 1.5, 1.5, KColor(1, 1, 1, 1),
				Isaac.GetScreenWidth(), true)
			font:DrawString("Select your character", 0, center.Y - 20, KColor(1, 1, 1, 1), Isaac.GetScreenWidth(), true)

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
					Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, player.ControllerIndex)
						or Input.IsActionTriggered(ButtonAction.ACTION_MENURIGHT, player.ControllerIndex)
						or Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex)
						or Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex)
					)
					and not player:GetData().DNDKeyDelay
					and not g.game:IsPaused()
				then
					if (
						Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, player.ControllerIndex)
							or Input.IsActionTriggered(ButtonAction.ACTION_MENURIGHT, player.ControllerIndex)
						)
						and charactersConfirmed[i] == false
					then
						local num = Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, player.ControllerIndex) and -1 or 1
						local soundToPlay = Input.IsActionTriggered(ButtonAction.ACTION_MENULEFT, player.ControllerIndex) and
							SoundEffect.SOUND_CHARACTER_SELECT_LEFT or SoundEffect.SOUND_CHARACTER_SELECT_RIGHT
						state.SelectedCharacters[i] = state.SelectedCharacters[i] + num
						state.SelectedCharacters[i] = state.SelectedCharacters[i] > 4 and 1 or state.SelectedCharacters[i] < 1 and 4 or
							state.SelectedCharacters[i]
						updateCharacterSprite(characterSprites[i], state.SelectedCharacters[i])
						g.sfx:Play(soundToPlay)
						data.DNDKeyDelay = keyDelay
					end

					if Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player.ControllerIndex)
						and charactersConfirmed[i] == false
					then
						characterSprites[i]:Play("Happy", true)
						charactersConfirmed[i] = true
						g.sfx:Play(SoundEffect.SOUND_THUMBSUP)
						numConfirmed = numConfirmed + 1
						data.DNDKeyDelay = keyDelay
					elseif Input.IsActionTriggered(ButtonAction.ACTION_BOMB, player.ControllerIndex)
						and charactersConfirmed[i] == true
					then
						charactersConfirmed[i] = false
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
				and Input.IsActionTriggered(ButtonAction.ACTION_MENUCONFIRM, player1.ControllerIndex)
				and not player1:GetData().DNDKeyDelay then
				startNextPrompt()
				player1:GetData().DNDKeyDelay = keyDelay
			end
		elseif state.PromptProgress >= 1 then
			local prompt = dndText.Prompts[state.PromptSelected]
			local data = player1:GetData()

			--[[ if Input.IsActionTriggered(Keyboard.KEY_SPACE, player1.ControllerIndex) and not data.DNDKeyDelay then
				if not state.HasRolled then
					state.HasRolled = true
					state.NumRolled = VeeHelper.RandomNum(1, 3)
					textToShow = dndText.Prompts[state.PromptSelected].Outcomes[state.NumRolled]
				else
					if state.PromptProgress < state.MaxPrompts then
						startNextPrompt()
					elseif not state.AdventureEnded then
						textToShow = "Congrorts"
						state.AdventureEnded = true
					elseif state.AdventureEnded then
						resetMinigame()
						state.AdventureEnded = false
					end
				end
				data.DNDKeyDelay = keyDelay
			end ]]

			if not state.HasSelected then
				font:DrawStringScaled(prompt.Title, 0, center.Y - (center.Y * 0.5), 1.5, 1.5, KColor(1, 1, 1, 1), Isaac.GetScreenWidth(), true)
			end

			if prompt.Options then
				for i = 1, #prompt.Options do
					local mult = 0.2
					local middleNum = (math.ceil(#prompt.Options / 2))
					
					if (#prompt.Options % 1 == 0 and i < middleNum) or (#prompt.Options % 2 == 0 and i <= middleNum) then
						mult = mult - (0.15 * (#prompt.Options - i))
					elseif i > middleNum then
						mult = (0.15 * (i - (middleNum))) - (mult / 2)
					end
					mult = mult + (0.05 * #prompt.Options)
					local optionPos = center.Y + (center.Y * mult)
					font:DrawString(prompt.Options[i][2], 0, optionPos, KColor(1, 1, 1, 1), Isaac.GetScreenWidth(), true)
				end
			end
			--[[ if state.HasRolled == false then
				font:DrawString("Press SPACE to roll the dice", center.X, center.Y + 50, KColor(1, 1, 1, 1), Isaac.GetScreenWidth()
					, true)
			else
				font:DrawString("Press SPACE to continue", center.X, center.Y + 50, KColor(1, 1, 1, 1), Isaac.GetScreenWidth(), true)
			end ]]

		end
	end
	if Input.IsButtonTriggered(testEndPrompt, Isaac.GetPlayer().ControllerIndex)
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

function dnd:ScreenBackground()
	if state.Active then
		blackScreen:Render(getCenterScreen(), Vector.Zero, Vector.Zero)
		blackScreen:Update()
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
	end
end

return dnd
