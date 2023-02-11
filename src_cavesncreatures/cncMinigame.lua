local cnc = {}
local g = require("src_cavesncreatures.globals")
local VeeHelper = require("src_cavesncreatures.veeHelper")
local cncText = include("src_cavesncreatures.prompts")

---@class GameState
local gameState = {
	Active = false,
	Characters = {
		Selected = {
			1,
			2,
			3,
			4
		},
		Confirmed = {
			false,
			false,
			false,
			false
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
	NumConfirmed = 0,
	OptionSelected = 0,
	OptionSelectedSaved = 0,
	ScreenShown = false,
	PromptProgress = 0,
	PromptSelected = 1,
	PromptTypeSelected = cncText.PromptType.NORMAL,
	MaxPrompts = 6,
	HasSelected = false,
	HasRolled = false,
	HOLUPLETHIMCOOK = false,
	RollResult = 0,
	OutcomeResult = 0,
	NumAvailableRolls = 1,
	PromptsSeen = {},
	EncountersSeen = {},
	EncounterStarted = false,
	EncounterCleared = false,
	RoomIndexStartedGameFrom = 0,
	AdventureEnded = false,
	HudWasVisible = true,
}
local debug = false

---@type GameState
local state = {}
VeeHelper.CopyOverTable(gameState, state)
local font = Font()
local timerFont = Font()
local background = Sprite()
local characters = Sprite()
local optionCursor = Sprite()
local dice = Sprite()
local diceFlash = Sprite()
local bossVs = Sprite()
local testStartPrompt = Keyboard.KEY_J
local testEndPrompt = Keyboard.KEY_K
local KEY_DELAY = 10
local renderPrompt = {
	Title = {},
	Options = {},
	Outcome = {}
}
local TRANSITION_Y_TARGET = 25
local TRANSITION_ALPHA_SPEED = 0.04
local TRANSITION_Y_SPEED = 0.75
---@enum FadeContext
local FadeContext = {
	IDLE = 0,
	TITLESCREEN_DOWN = 1,
	PROMPT_INIT = 2,
	OPTION_SELECT = 3,
	OPTION_SELECT_ROLL = 4,
	ROLL_EXTRA_UP = 5,
	ROLL_EXTRA_DOWN = 6,
	OUTCOME_UP = 7,
	PROMPT_NEXT = 8,
	ENCOUNTER_NEXT = 9,
	ENCOUNTER_WIN = 10,
	BOSS_WIN = 11
}
local fadeType = "AllDown"
local transitionY = {
	Title = 0,
	Prompt = 0,
	Characters = 0,
	Dice = 0
}
local transitionAlpha = {
	Title = 1,
	Prompt = 1,
	Characters = 1,
	Dice = 1
}
local characterFrameOffset = 0
local characterFrameOffsetTimer = 30
local diceFlashAlpha = 0
local roomIndexOnMinigameClear
local resetting = false

---@type Stats
local statsTable = {
	DamageFlat = 0,
	DamageMult = 1,
	TearsFlat = 0,
	TearsMult = 1,
	Luck = 0,
	Range = 0,
	ShotSpeed = 0,
	Speed = 0
}
---@type EntityPlayer[]
local cncPlayers = {}

--[[
	Sprites for:
	-- Active items
	-- Chargebars
	-- Inventory
	--? do we need to give players trinkets and consumables, or should we remove those?
]]
---@type Sprite[]
local cncPlayerActiveItems = {
	Sprite(),
	Sprite(),
	Sprite(),
	Sprite(),
}

for _, s in pairs(cncPlayerActiveItems) do
	s:Load('gfx/cnc_player_active_item.anm2', true)
	s:Play('item')
end

---@type Sprite[]
local cncPlayerActiveChargebars = {
	Sprite(),
	Sprite(),
	Sprite(),
	Sprite(),
}

for _, s in pairs(cncPlayerActiveChargebars) do
	s:Load('gfx/cnc_player_active_chargebar.anm2', true)
	s:Play('charge_unknown')
end

local cncInventory = Sprite()
cncInventory:Load('gfx/cnc_inventory.anm2', true)
cncInventory:SetFrame('inventory', 0)

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
---@param stringLengthLimit integer
function cnc:separateText(stringTable, stringLengthLimit)
	if type(stringTable) == "table" then
		
		local hashtag = true
		while hashtag do
			for i = 1, #stringTable do
				if string.find(stringTable[i], "#") ~= nil then
					local curText = stringTable[i]
					local line1, line2 = string.find(curText, "#")
					local nextLine = string.sub(curText, line2 + 1, -1)
					stringTable[i] = string.sub(curText, 1, line1 - 1)
					table.insert(stringTable, i + 1, nextLine)
					break
				elseif i == #stringTable then
					hashtag = false
				end
			end
		end

		local tooLong = true
		local freezePreventChecker = 0
		while tooLong and freezePreventChecker < 1000 do
			for i = 1, #stringTable do
				if font:GetStringWidth(stringTable[i]) > stringLengthLimit then
					--Isaac.DebugString("Current length: "..tostring(font:GetStringWidth(stringTable[i])))
					local curText = stringTable[i]
					local currentLine = curText
					local indexEnd = 1
					while font:GetStringWidth(string.sub(currentLine, 1, indexEnd)) < stringLengthLimit do
						indexEnd = indexEnd + 1
						--Isaac.DebugString("Finding lower than limit: "..tostring(indexEnd))
						if string.sub(currentLine, 1, indexEnd) == string.sub(currentLine, 1, -1) then break end
					end
					indexEnd = indexEnd - 1
					local indexStart = indexEnd
					while string.sub(currentLine, indexStart, indexEnd) ~= " " do
						indexStart = indexStart - 1
						indexEnd = indexEnd - 1
						--Isaac.DebugString("Finding a space: "..tostring(indexStart))
						if indexStart == 1 then break end
					end
					currentLine = string.sub(currentLine, 1, indexStart)
					local nextLine = string.sub(curText, indexEnd, -1)
					stringTable[i] = currentLine
					table.insert(stringTable, i + 1, nextLine)
					--Isaac.DebugString("Current line: "..currentLine.. " "..tostring(i))
					--Isaac.DebugString("Next line: "..nextLine.. " "..tostring(i+1))
				elseif i == #stringTable then
					--print("no longer long")
					tooLong = false
				end
			end

			freezePreventChecker = freezePreventChecker + 1
			if freezePreventChecker == 10000 then
				tooLong = false
				break
				--print('Terminated after ' .. tostring(freezePreventChecker) .. " attempts")
			end
		end
	end

	return stringTable
end

function cnc:RollDice()
	local num = VeeHelper.RandomNum(1, 20)
	state.RollResult = num
	state.OutcomeResult = num < 6 and 1 or num < 16 and 2 or num <= 20 and 3 or 2
	state.NumAvailableRolls = state.NumAvailableRolls - 1
end

function cnc:IsInCNCRoom()
	local roomDescData = g.game:GetLevel():GetCurrentRoomDesc().Data
	local roomVariant = roomDescData.OriginalVariant
	local isDefaultRoom = roomDescData.Type == RoomType.ROOM_DEFAULT and (roomVariant >= 1600 and roomVariant <= 1619)
	local isBossRoom = roomDescData.Type == RoomType.ROOM_BOSS and (roomVariant >= 16000 and roomVariant <= 16002)

	if state.Active and (isDefaultRoom or isBossRoom) then
		return true
	else
		return false
	end
end

---@return OutcomeEffect | nil
function cnc:GetPromptEffects()
	local curPrompt = cncText:GetTableFromPromptType(state.PromptTypeSelected)
	if curPrompt[state.PromptSelected] then
		if curPrompt[state.PromptSelected].Effect and curPrompt[state.PromptSelected].Effect[state.OptionSelectedSaved] then
			local effects = curPrompt[state.PromptSelected].Effect[state.OptionSelectedSaved]
			effects = effects[state.OutcomeResult] ~= nil and effects[state.OutcomeResult] or effects
			return effects
		end
	end
end

---@return boolean | nil
function cnc:IsRollOption()
	if renderPrompt.Options[state.OptionSelected]
		and renderPrompt.Options[state.OptionSelected][1]
	then
		return renderPrompt.Options[state.OptionSelected][1] == "Roll"
	end
end

--TODO: Change how dead players are detected, removing them from the table upon death
--TODO: Differenciate "Table is empty because no players are spawned yet" vs "Table is empty because all players died in the minigame"
function cnc:AreAllPlayersDead()
	local allDead = true
	for _, player in ipairs(cncPlayers) do
		if not player:IsDead() or player:Exists() then
			allDead = false
			break
		end
	end
	return allDead
end

----------------------
--  INITIATE STUFF  --
----------------------

local function initMinigame()
	state.Active = true
	g.GameState.GameActive = true
	g.GameState.ShouldStart = false
	state.ScreenShown = true
	state.HudWasVisible = g.game:GetHUD():IsVisible()
	background:Load("gfx/cnc_background.anm2", true)
	background:Play("Start", true)
	background.PlaybackSpeed = 0.5
	characters:Load("gfx/cnc_background.anm2", true)
	characters:Play("Start", true)
	optionCursor:Load("gfx/cnc_cursor_option.anm2", true)
	optionCursor:Play(optionCursor:GetDefaultAnimation(), true)
	dice:Load("gfx/cnc_d20.anm2", true)
	dice:SetFrame("Idle", 0)
	dice.PlaybackSpeed = 0.5
	diceFlash:Load("gfx/cnc_d20.anm2", true)
	diceFlash:SetFrame("Idle", 0)
	diceFlash.Scale = Vector(0.5, 0.5)
	bossVs:Load("gfx/ui/boss/versusscreen.anm2", true)
	font:Load("font/teammeatfont12.fnt")
	timerFont:Load("font/pftempestasevencondensed.fnt")
	Isaac.GetPlayer().ControlsEnabled = false
	g.music:Fadeout(0.03)
	--print("minigame init")
end

local function initCharacterSelect()
	local players = getPlayers()
	g.game:GetHUD():SetVisible(false)
	characters:SetFrame("Title" .. tonumber(#players), 0)
	fadeType = "CharacterUp"
	g.music:Fadein(Music.MUSIC_BOSS_OVER, Options.MusicVolume, 0.03)
end

local function resetMinigame()
	--print("but its actually reset eyy")
	renderPrompt = {
		Title = {},
		Options = {},
		Outcome = {}
	}
	transitionY = {
		Title = 0,
		Prompt = 0,
		Characters = 0,
		Dice = 0
	}
	transitionAlpha = {
		Title = 1,
		Prompt = 1,
		Characters = 1,
		Dice = 1
	}
	background:Reset()
	characters:Reset()
	dice:Reset()
	diceFlash:Reset()
	bossVs:Reset()
	diceFlashAlpha = 0
	Isaac.GetPlayer().ControlsEnabled = true
	cncPlayers = {}
	for _, player in ipairs(VeeHelper.GetAllPlayers()) do
		local data = player:GetData()
		if data.CNC_PreviousCollisionClass ~= nil then
			player.GridCollisionClass = data.CNC_PreviousCollisionClass
			data.CNC_PreviousCollisionClass = nil
		end
		if data.CNC_PreviousEntityCollissionClass ~= nil then
			player.EntityCollisionClass = data.CNC_PreviousEntityCollissionClass
			data.CNC_PreviousEntityCollissionClass = nil
		end
		if data.CNC_CouldBeTargeted ~= nil then
			if data.CNC_CouldBeTargeted then
				player:ClearEntityFlags(EntityFlag.FLAG_NO_TARGET)
			end
			data.CNC_CouldBeTargeted = nil
		end
		if data.CNC_WasVisible ~= nil then
			player.Visible = true
			data.CNC_WasVisible = nil
		end
		if data.CNC_WereBombsEmpty ~= nil then
			if data.CNC_WereBombsEmpty == true then
				player:AddBombs( -1)
			end
			data.CNC_WereBombsEmpty = nil
		end
	end
	if state.AdventureEnded then
		g.GameState.PickupsCollected.Coins = math.floor(state.Inventory.Coins / 2)
		g.GameState.PickupsCollected.Keys = math.floor(state.Inventory.Keys / 2)
		g.GameState.PickupsCollected.Bombs = math.floor(state.Inventory.Bombs / 2)
		g.GameState.HasWon = true
	else
		g.GameState.HasLost = true
	end
	g.GameState.BeggarInitSeed = 0
	g.GameState.GameActive = false
	VeeHelper.CopyOverTable(gameState, state)
	g.game:GetHUD():SetVisible(state.HudWasVisible)
	resetting = false
end

local function startMinigameReset()
	--print("reset attempt")
	if not roomIndexOnMinigameClear and not resetting then
		for _, player in ipairs(cncPlayers) do
			if not player:IsDead() then
				player.GridCollisionClass = GridCollisionClass.COLLISION_NONE
				player.Position = Vector(1000, 1000)
				player:Die()
				player:GetSprite():Play("Death", true)
				player:GetSprite():SetLastFrame()
			end
		end
		roomIndexOnMinigameClear = state.RoomIndexStartedGameFrom
		--print(roomIndexOnMinigameClear)
		--print("minigame reset")
		fadeType = "AllDown"
		resetting = true
	end
end

function cnc:tryStartRoomEncounter()
	local effects = cnc:GetPromptEffects()
	if effects then
		if effects.StartEncounter then
			if not state.EncounterStarted then
				local roomType = state.PromptTypeSelected == cncText.PromptType.BOSS and "boss" or "default"
				Isaac.ExecuteCommand("goto s." .. roomType .. "." .. tostring(effects.StartEncounter))
				state.EncounterStarted = true
			end
		end
	end
end

local selectNextPrompt = true
local function applyEffectsOnNewPrompt()
	if state.PromptProgress > 0 then
		local effects = cnc:GetPromptEffects()
		if not effects then return end
		if effects.ForceNextPrompt then
			selectNextPrompt = false
			state.PromptTypeSelected = effects.ForceNextPrompt.PromptType
			if effects.ForceNextPrompt.PromptNumber then
				state.PromptSelected = effects.ForceNextPrompt.PromptNumber
			end
		end
		if not effects.StartEncounter then
			if effects.Keys then
				state.Inventory.Keys = math.max(0, state.Inventory.Keys + effects.Keys)
			end
			if effects.Bombs then
				state.Inventory.Bombs = math.max(0, state.Inventory.Bombs + effects.Bombs)
			end
			if effects.Coins then
				state.Inventory.Coins = math.max(0, state.Inventory.Coins + effects.Coins)
			end
			if effects.Collectible then
				for _, player in ipairs(cncPlayers) do
					if not player:IsDead() then
						player:AddCollectible(effects.Collectible, 12, false)
					end
				end
			end
		end
	end
end

local function applyEffectsOnRoomEnter()
	local effects = cnc:GetPromptEffects()

	if effects then
		if (effects.ApplyStatus or effects.ApplyStatusPlayer) then
			for _, ent in ipairs(Isaac.GetRoomEntities()) do
				if ent:ToNPC() and ent:IsActiveEnemy(false) then
					if effects.ApplyStatus then
						cncText:ApplyStatusEffect(ent:ToNPC(), effects.ApplyStatus[1], effects.ApplyStatus[2])
					end
					if effects.DamageEnemies then
						ent:AddEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
						ent:TakeDamage(effects.DamageEnemies, 0, EntityRef(ent), 0)
						ent:ClearEntityFlags(EntityFlag.FLAG_NO_FLASH_ON_DAMAGE)
					end
				end
				if ent:ToPlayer() then
					if effects.ApplyStatusPlayer then
						cncText:ApplyStatusEffect(ent:ToPlayer(), effects.ApplyStatus[1], effects.ApplyStatus[2])
					end
				end
			end
		end
		for _, player in ipairs(cncPlayers) do
			if effects.Stats or effects.StatsTemp then
				if effects.Stats then
					local data = player:GetData()

					if not data.CNC_MinigameStats then
						data.CNC_MinigameStats = {}
						VeeHelper.CopyOverTable(statsTable, data.CNC_MinigameStats)
					else
						for stat, num in pairs(effects.Stats) do
							data.CNC_MinigameStats[stat] = data.CNC_MinigameStats[stat] + num
						end
					end
				end
				if effects.StatsTemp then
					local data = player:GetData()

					if not data.CNC_MinigameStatsTemp then
						data.CNC_MinigameStatsTemp = {}
						VeeHelper.CopyOverTable(statsTable, data.CNC_MinigameStatsTemp)
					else
						for stat, num in pairs(effects.Stats) do
							data.CNC_MinigameStatsTemp[stat] = num
						end
					end
				end
				player:AddCacheFlags(CacheFlag.CACHE_ALL)
				player:EvaluateItems()
			end
		end
	end
end

local function applyEffectsOnOutcome()
	local effects = cnc:GetPromptEffects()

	if effects then
		for _, player in ipairs(cncPlayers) do
			if effects.DamagePlayers then
				player:TakeDamage(effects.DamagePlayers, DamageFlag.DAMAGE_NO_PENALTIES, EntityRef(player), 0)
			end
			if not effects.StartEncounter then
				if effects.AddMaxHearts then
					player:AddMaxHearts(effects.AddMaxHearts)
				end
				if effects.AddHearts and effects.AddHearts[1] then
					for subType, num in pairs(effects.AddHearts) do
						local num = num * 2
						if subType == HeartSubType.HEART_HALF or subType == HeartSubType.HEART_HALF_SOUL then
							num = num / 2
						end
						if subType == HeartSubType.HEART_HALF or subType == HeartSubType.HEART_FULL or
							subType == HeartSubType.HEART_SCARED then
							player:AddHearts(num)
						elseif subType == HeartSubType.HEART_HALF_SOUL or subType == HeartSubType.HEART_SOUL then
							player:AddSoulHearts(num)
						elseif subType == HeartSubType.HEART_ETERNAL then
							player:AddEternalHearts(num)
						elseif subType == HeartSubType.HEART_DOUBLEPACK then
							player:AddHearts(num * 2)
						elseif subType == HeartSubType.HEART_BLACK then
							player:AddBlackHearts(num)
						elseif subType == HeartSubType.HEART_GOLDEN then
							player:AddGoldenHearts(num)
						elseif subType == HeartSubType.HEART_BLENDED then
							while player:GetHearts() < player:GetMaxHearts() and num >= 0.5 do
								player:AddHearts(1)
								num = num - 0.5
							end
							if num >= 0.5 then
								local amount = math.floor(num)
								player:AddSoulHearts(amount)
								num = num - amount
								if num == 0.5 then
									player:AddSoulHearts(1)
								end
							end
						elseif subType == HeartSubType.HEART_BONE then
							player:AddBoneHearts(num)
						elseif subType == HeartSubType.HEART_ROTTEN then
							player:AddRottenHearts(num)
						end
					end
				end
			end
		end
	end
end

---@param rng RNG
---@param spawnPos Vector
local function spawnRewardsOnRoomClear(rng, spawnPos)
	local effects = cnc:GetPromptEffects()
	local vel = Vector.Zero

	if effects then
		for _, player in ipairs(cncPlayers) do
			if not player:IsDead() then
				if effects.AddHearts and effects.AddHearts[1] then
					for subType, num in pairs(effects.AddHearts) do
						for _ = 1, num do
							local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
							local seed = rng:GetSeed()
							g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART, pos, vel, nil, subType,
								seed)
						end
					end
				end
				if effects.AddMaxHearts then
					player:AddMaxHearts(effects.AddMaxHearts)
				end
			end
		end
		if effects.Collectible then
			local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
			local seed = rng:GetSeed()
			g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, pos, vel, nil, effects.Collectible,
				seed)
		end
		if effects.Coins then
			local coinsToSpawn = effects.Coins
			while coinsToSpawn >= 10 do
				local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
				local seed = rng:GetSeed()
				g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, nil, CoinSubType.COIN_DIME,
					seed)
				coinsToSpawn = coinsToSpawn - 10
			end
			if coinsToSpawn >= 5 then
				local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
				local seed = rng:GetSeed()
				g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, nil, CoinSubType.COIN_NICKEL,
					seed)
				coinsToSpawn = coinsToSpawn - 5
			end
			for _ = 1, coinsToSpawn do
				local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
				local seed = rng:GetSeed()
				g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COIN, pos, vel, nil, CoinSubType.COIN_PENNY,
					seed)
			end
		end
		if effects.Keys then
			for _ = 1, effects.Keys do
				local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
				local seed = rng:GetSeed()
				g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_KEY, pos, vel, nil, KeySubType.KEY_NORMAL,
					seed)
			end
		end
		if effects.Bombs then
			for _ = 1, effects.Bombs do
				local pos = g.game:GetRoom():FindFreePickupSpawnPosition(spawnPos)
				local seed = rng:GetSeed()
				g.game:Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_BOMB, pos, vel, nil, BombSubType.BOMB_NORMAL,
					seed)
			end
		end
	end
end

--TODO: Edit this maybe
function cnc:startNextPrompt()
	fadeType = "TitlePromptUp"
	selectNextPrompt = true
	applyEffectsOnNewPrompt()

	dice:Play("Idle", true)
	state.PromptProgress = state.PromptProgress + 1
	state.RollResult = 0
	state.OutcomeResult = 0
	state.HasSelected = false
	state.HasRolled = false
	state.NumAvailableRolls = 1
	state.EncounterCleared = false
	state.EncounterStarted = false
	state.OptionSelected = 1
	state.OptionSelectedSaved = 1

	local promptTable = cncText:GetTableFromPromptType(state.PromptTypeSelected)

	if selectNextPrompt then
		if state.PromptProgress == state.MaxPrompts then
			state.PromptTypeSelected = cncText.PromptType.BOSS
		elseif state.PromptProgress % 2 == 0 then
			state.PromptTypeSelected = cncText.PromptType.ENEMY
		elseif VeeHelper.RandomNum(1, 50) == 50 then
			state.PromptTypeSelected = cncText.PromptType.RARE
		else
			state.PromptTypeSelected = cncText.PromptType.NORMAL
		end

		promptTable = cncText:GetTableFromPromptType(state.PromptTypeSelected)
		if state.PromptTypeSelected == cncText.PromptType.NORMAL or state.PromptTypeSelected == cncText.PromptType.ENEMY then
			local tableToUse = state.PromptTypeSelected == cncText.PromptType.ENEMY and state.EncountersSeen or
				state.PromptsSeen
			if #tableToUse == 0 then
				state.PromptSelected = VeeHelper.RandomNum(1, #promptTable)
			else
				state.PromptSelected = VeeHelper.GetDifferentRandomNum(tableToUse, #promptTable, VeeHelper.RandomRNG)
			end
			if tableToUse == state.EncountersSeen then
				table.insert(state.EncountersSeen, state.PromptSelected)
			else
				table.insert(state.PromptsSeen, state.PromptSelected)
			end
		else
			state.PromptSelected = VeeHelper.RandomNum(1, #promptTable)
		end
	end
	local prompt = promptTable[state.PromptSelected]
	--print(promptTable, prompt, prompt.Title)
	local title = cnc:separateText({ prompt.Title }, 230)
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

--TODO: Edit this maybe
local function initFirstPrompt()
	local player1 = Isaac.GetPlayer()
	background:Play("TransitionIn", true)
	characters:SetFrame(tostring(#getPlayers()), 0)
	cnc:startNextPrompt()
	player1:GetData().CNC_KeyDelay = KEY_DELAY
	fadeType = "AllUp"
	state.RoomIndexStartedGameFrom = g.game:GetLevel():GetCurrentRoomIndex()
	cnc:spawnCNCPlayers()
	if player1.Visible then
		player1:GetData().CNC_WasVisible = true
		player1.Visible = false
	end
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
	optionCursor:Render(Vector(posX, posY + 8), Vector.Zero, Vector.Zero)
	optionCursor:Update()
end

local function renderDiceOption(text, posY, hasCursor)
	if cnc:IsRollOption() then
		local posX = getCenterScreen().X
		posX = posX - (font:GetStringWidth(text) / 2)
		posX = hasCursor and posX - 32 or posX - 16
		if diceFlash:GetAnimation() ~= "Idle" then
			diceFlash:Play("Idle", true)
			diceFlash.Scale = Vector(0.5, 0.5)
		end
		diceFlash:Render(Vector(posX, posY + 8), Vector.Zero, Vector.Zero)
		diceFlash:Update()
		diceFlash.Color = Color(1, 1, 1, 1)
	end
end

---@param stringTable table
---@param startingPos number
---@param textType? string
local function renderText(stringTable, startingPos, textType)
	local center = getCenterScreen()
	local nextLineMult = 0.15
	local posPerLineMult = -0.02
	--Previous posPerLineMult: textType == "Title" and -0.05 or 0.05
	local lineSpacingMult = textType == "Title" and 100 or 125

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
			and i == state.OptionSelected
			and transitionY.Prompt == 0
		then
			if #stringTable > 1 then
				renderCursor(text, posY)
			end
			renderDiceOption(text, posY, #stringTable > 1)
		end

		local yOffset = textType == "Title" and transitionY.Title or transitionY.Prompt
		local alphaOffset = textType == "Title" and transitionAlpha.Title or transitionAlpha.Prompt
		font:DrawString(text, posX, posY + yOffset, KColor(1, 1, 1, alphaOffset), boxLength, true)
	end
end

function cnc:CharacterSelect()
	local player1 = Isaac.GetPlayer()
	local players = getPlayers()

	for i, player in ipairs(players) do
		local data = player:GetData()
		if (
			isTriggered(ButtonAction.ACTION_MENULEFT, player)
			or isTriggered(ButtonAction.ACTION_MENURIGHT, player)
			or isTriggered(ButtonAction.ACTION_MENUCONFIRM, player)
			or isTriggered(ButtonAction.ACTION_BOMB, player)
			)
			and not player:GetData().CNC_KeyDelay
			and not g.game:IsPaused()
			and transitionY.Characters == 0
		then
			if (
				isTriggered(ButtonAction.ACTION_MENULEFT, player)
				or isTriggered(ButtonAction.ACTION_MENURIGHT, player)
				)
				and state.Characters.Confirmed[i] == false
			then
				local num = isTriggered(ButtonAction.ACTION_MENULEFT, player) and -1 or 1
				local soundToPlay = isTriggered(ButtonAction.ACTION_MENULEFT, player) and
					SoundEffect.SOUND_CHARACTER_SELECT_LEFT or SoundEffect.SOUND_CHARACTER_SELECT_RIGHT
				state.Characters.Selected[i] = state.Characters.Selected[i] + num
				state.Characters.Selected[i] = state.Characters.Selected[i] > 4 and 1 or
					state.Characters.Selected[i] < 1 and 4 or
					state.Characters.Selected[i]
				g.sfx:Play(soundToPlay)
				data.CNC_KeyDelay = KEY_DELAY
			end

			if isTriggered(ButtonAction.ACTION_MENUCONFIRM, player)
				and state.Characters.Confirmed[i] == false
			then
				state.Characters.NumActive[state.Characters.Selected[i]] = state.Characters.NumActive
					[state.Characters.Selected[i]] +
					1
				state.Characters.Confirmed[i] = true
				g.sfx:Play(SoundEffect.SOUND_THUMBSUP)
				state.NumConfirmed = state.NumConfirmed + 1
				data.CNC_KeyDelay = KEY_DELAY
			elseif isTriggered(ButtonAction.ACTION_BOMB, player)
				and state.Characters.Confirmed[i] == true
			then
				state.Characters.Confirmed[i] = false
				state.Characters.NumActive[state.Characters.Selected[i]] = state.Characters.NumActive
					[state.Characters.Selected[i]] -
					1
				state.NumConfirmed = state.NumConfirmed - 1
				data.CNC_KeyDelay = KEY_DELAY
			end
		end
	end
	if state.NumConfirmed >= #players
		and isTriggered(ButtonAction.ACTION_MENUCONFIRM, player1)
		and not player1:GetData().CNC_KeyDelay
		and not g.game:IsPaused()
	then
		background:Play("FadeOutTitle", true)
		fadeType = "AllDown"
	end
end

--TODO: Clean this
function cnc:OnPromptTransition()
	if not state.HasSelected then
		if fadeType == "PromptDown" and transitionY.Prompt == TRANSITION_Y_TARGET then
			if cnc:IsRollOption() then
				if dice:GetAnimation() ~= "Roll" and not state.HOLUPLETHIMCOOK then
					dice:Play("Roll", true)
					state.HOLUPLETHIMCOOK = true
				end
			else
				state.HasSelected = true
				applyEffectsOnOutcome()
				fadeType = "PromptUp"
				local data = Isaac.GetPlayer():GetData()
				data.CNC_KeyDelay = KEY_DELAY + 120
			end
		end
	else
		if state.EncounterCleared then
			if background:IsFinished("FadeIn") and not state.AdventureEnded then
				if state.PromptProgress == state.MaxPrompts then
					state.AdventureEnded = true
					startMinigameReset()
					--print("you won bitch!")
				else
					renderPrompt.Title = { "Room Cleared!" }
					renderPrompt.Outcome = { "You defeat the creatures,", "moving onto the next room..." }
					fadeType = "AllUp"
					Isaac.ExecuteCommand("goto s.default.2")
					background:Play("TransitionIn", true)
					--print("go back to your playmate")
				end
			end
		elseif background:IsPlaying("FadeIn") and background:GetFrame() == 40 then
			background:Stop()
			startMinigameReset()
		elseif fadeType == "AllDown" and transitionY.Prompt == TRANSITION_Y_TARGET then
			if cnc:AreAllPlayersDead() and not state.EncounterStarted then
				startMinigameReset()
			else
				if not state.EncounterStarted and (
					state.PromptTypeSelected == cncText.PromptType.ENEMY
					or state.PromptTypeSelected == cncText.PromptType.BOSS
					)
				then
					cnc:tryStartRoomEncounter()
				end
			end
		end
		if fadeType == "TitlePromptDown" and transitionY.Prompt == TRANSITION_Y_TARGET then
			cnc:startNextPrompt()
		end
	end
end

--TODO: Clean this
function cnc:DiceAnimation()
	if dice:GetAnimation() ~= "Idle" then
		local dicePos = Vector(getCenterScreen().X + 205, getCenterScreen().Y + 95 + transitionY.Dice)
		dice.Color = Color(1, 1, 1, transitionAlpha.Dice)
		dice:RenderLayer(0, dicePos, Vector.Zero, Vector.Zero)
		dice:Update()
		if dice:IsFinished("Roll") then
			state.HasRolled = true
			dice:SetFrame("Result", state.RollResult - 1)
			diceFlash:SetFrame("Result", state.RollResult - 1)
			diceFlash.Scale = Vector(1, 1)
			diceFlashAlpha = 1.4
		end
		if diceFlashAlpha > 0 then
			if diceFlashAlpha <= 1 then
				diceFlash.Color = Color(1, 1, 1, diceFlashAlpha)
				diceFlash:RenderLayer(1, dicePos, Vector.Zero, Vector.Zero)
				diceFlash:Update()
			end
			diceFlashAlpha = diceFlashAlpha - 0.02
		elseif fadeType == "PromptDown"
			and state.HasRolled and dice:GetAnimation() == "Result"
			and state.HOLUPLETHIMCOOK
		then
			if state.NumAvailableRolls == 0 then
				state.HasSelected = true
				applyEffectsOnOutcome()
			end
			renderPrompt.Options = { { "Roll", "Roll again" }, { "Select", "Use this roll" } }
			state.OptionSelected = 1
			fadeType = "PromptUp"
			state.HOLUPLETHIMCOOK = false
		end
	end
end

--TODO: Clean this
function cnc:MinigameLogic()
	local player1 = Isaac.GetPlayer()

	if (
		g.GameState.ShouldStart
		or (Input.IsButtonTriggered(testStartPrompt, player1.ControllerIndex) and debug)
		)
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
			local data = player1:GetData()

			if isTriggered(ButtonAction.ACTION_MENUCONFIRM, player1)
				and not g.game:IsPaused()
				and not data.CNC_KeyDelay
				and transitionY.Prompt == 0
				and state.ScreenShown
			then
				if not state.HasSelected then
					local prompt = cncText:GetTableFromPromptType(state.PromptTypeSelected)
					local outcomeText = prompt[state.PromptSelected].Outcome[state.OptionSelectedSaved]

					if cnc:IsRollOption() then
						cnc:RollDice()
						if not state.HasRolled then
							if outcomeText[state.OptionSelectedSaved][3] then
								local characterIndex = outcomeText[state.OptionSelectedSaved][3] + 1

								if state.Characters.NumActive[characterIndex] > 1 then
									state.NumAvailableRolls = state.Characters.NumActive[characterIndex] - 1
								end
							end
						end
					end
					--print(prompt, prompt[state.PromptSelected], prompt[state.PromptSelected].Outcome, outcomeText, state.PromptTypeSelected, state.PromptSelected, state.OptionSelectedSaved)
					if outcomeText[state.OutcomeResult] then
						outcomeText = outcomeText[state.OutcomeResult]
					end

					renderPrompt.Outcome = cnc:separateText({ outcomeText }, 300)
					fadeType = "PromptDown"
				else
					if cnc:IsRollOption()
						and state.NumAvailableRolls > 0
					then
						cnc:RollDice()
					else
						if (
							cnc:AreAllPlayersDead()
							or (
							state.PromptTypeSelected == cncText.PromptType.ENEMY
							or state.PromptTypeSelected == cncText.PromptType.BOSS
							)
							and not state.EncounterCleared
							)
						then
							fadeType = "AllDown"
							background:Play("TransitionOut", true)
						else
							fadeType = "TitlePromptDown"
						end
					end
				end
				data.CNC_KeyDelay = KEY_DELAY + 20
			end

			cnc:OnPromptTransition()
			if state.ScreenShown and not state.EncounterCleared then
				cnc:DiceAnimation()
			end

			renderText(renderPrompt.Title, -80, "Title")

			if not state.HasSelected then
				if renderPrompt.Options[2] ~= nil then
					if (
						isTriggered(ButtonAction.ACTION_MENUUP, player1)
						or isTriggered(ButtonAction.ACTION_MENUDOWN, player1)
						)
						and not data.CNC_KeyDelay
						and not g.game:IsPaused()
						and transitionY.Prompt == 0
						and state.ScreenShown
					then
						state.OptionSelected = isTriggered(ButtonAction.ACTION_MENUUP, player1) and
							state.OptionSelected - 1
							or state.OptionSelected + 1
						state.OptionSelected = state.OptionSelected < 1 and #renderPrompt.Options or
							state.OptionSelected > #renderPrompt.Options and 1
							or state.OptionSelected
						local soundToPlay = isTriggered(ButtonAction.ACTION_MENUUP, player1) and
							SoundEffect.SOUND_CHARACTER_SELECT_LEFT or SoundEffect.SOUND_CHARACTER_SELECT_RIGHT
						g.sfx:Play(soundToPlay)
						data.CNC_KeyDelay = KEY_DELAY
						if not state.HasRolled then
							state.OptionSelectedSaved = state.OptionSelected
						end
					end
				end
				renderText(renderPrompt.Options, 0, "Option")
				if state.HasRolled then
					renderText({ "You have additional characters who can roll", "Roll again?" }, -50)
				end
			else
				renderText(renderPrompt.Outcome, 0)
			end
		end
	end
	if Input.IsButtonTriggered(testEndPrompt, player1.ControllerIndex)
		and not Isaac.GetPlayer():GetData().CNC_KeyDelay
		and not g.game:IsPaused()
		and debug
	then
		startMinigameReset()
		Isaac.GetPlayer():GetData().CNC_KeyDelay = KEY_DELAY
	end
end

function cnc:RenderScreen()
	if state.Active and state.ScreenShown then
		local center = getCenterScreen()
		local transitionPos = Vector(center.X, center.Y + transitionY.Characters)

		if background:IsFinished("FadeOutTitle") then
			initFirstPrompt()
		end
		if state.PromptProgress == 0 then
			cnc:AnimationTimer()
			if string.sub(characters:GetAnimation(), 1, 5) == "Title" then
				background:RenderLayer(0, center, Vector.Zero, Vector.Zero) --Black background
				background:RenderLayer(1, center, Vector.Zero, Vector.Zero) --Frame
				background:RenderLayer(16, center, Vector.Zero, Vector.Zero) --Frame but animated
				background:RenderLayer(7, center, Vector.Zero, Vector.Zero) --Debug frame
				background:RenderLayer(8, center, Vector.Zero, Vector.Zero) -- Title

				for i = 1, tonumber(string.sub(characters:GetAnimation(), 6, -1)) do
					local startingFrame = (i * 3) - 3
					local selectFrame = (i * 3) - 1
					local frameToUse = state.Characters.Confirmed[i] and selectFrame or
						(startingFrame + characterFrameOffset)
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
				background:RenderLayer(0, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(1, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(16, center, Vector.Zero, Vector.Zero)
				background:RenderLayer(7, center, Vector.Zero, Vector.Zero)
				for i = 1, tonumber(characters:GetAnimation()) do
					local startingFrame = (i * 2) - 2
					local characterLayer = state.Characters.Selected[i] + 2
					characters:RenderLayer(characterLayer, transitionPos, Vector.Zero, Vector.Zero)
					characters:SetLayerFrame(characterLayer, startingFrame + characterFrameOffset)
				end
				characters:RenderLayer(2, transitionPos, Vector.Zero, Vector.Zero)
				characters:SetLayerFrame(2, 0 + characterFrameOffset)
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
function cnc:spawnCNCPlayers()
	for i, player in ipairs(getPlayers()) do
		local playerType = state.Characters.Selected[i] - 1
		local lastPlayerIndex = g.game:GetNumPlayers() - 1

		if lastPlayerIndex >= 63 then
			return
		else
			Isaac.ExecuteCommand('addplayer ' .. playerType .. ' ' .. player.ControllerIndex)
			local strawman = Isaac.GetPlayer(lastPlayerIndex + 1)
			strawman.Parent = player
			strawman:AddCollectible(g.CNC_PLAYER_TECHNICAL)
			strawman.ControlsEnabled = false
			if playerType == PlayerType.PLAYER_ISAAC then
				player:AddBombs( -1)
			end
			table.insert(cncPlayers, strawman)
			Game():GetHUD():AssignPlayerHUDs()
		end
	end
end

--TOOO: Clean this
local playCavesMusic = false
function cnc:OnNewRoom()
	local roomDescData = g.game:GetLevel():GetCurrentRoomDesc().Data
	local roomVariant = roomDescData.OriginalVariant
	local players = VeeHelper.GetAllPlayers()
	if state.Active then
		if (
			not cnc:IsInCNCRoom() and (roomVariant ~= 2 or g.game:GetLevel():GetCurrentRoomIndex() ~= GridRooms.ROOM_DEBUG_IDX)) then
			--print("in a room you should or shouldn't be in")
			local boyFound = false
			for _, slot in ipairs(Isaac.FindByType(EntityType.ENTITY_SLOT, g.CNC_BEGGAR)) do
				boyFound = true
				if g.GameState.BeggarInitSeed ~= 0 then
					if slot.InitSeed == g.GameState.BeggarInitSeed then
						--print("boy located")
						for _, player in ipairs(players) do
							player.Position = Vector(slot.Position.X, slot.Position.Y + 50)
						end
					end
				end
			end
			if not boyFound then
				g.GameState = {
					ShouldStart = false,
					GameActive = false,
					BeggarInitSeed = 0,
					HasWon = false,
					HasLost = false,
					PickupsCollected = {
						Coins = 0,
						Keys = 0,
						Bombs = 0
					}
				}
			end
			resetMinigame()
			return
		elseif g.music:IsEnabled() and roomDescData.Type ~= RoomType.ROOM_BOSS then
			playCavesMusic = true
			g.music:Disable()
		end
	end
	if cnc:IsInCNCRoom() and state.ScreenShown then
		state.ScreenShown = false
		g.game:ShowHallucination(0, BackdropType.CAVES)
		g.sfx:Stop(SoundEffect.SOUND_DEATH_CARD)
		for i = 0, 447 do
			local gridEnt = g.game:GetRoom():GetGridEntity(i)
			if gridEnt and gridEnt:ToRock() then
				local sprite = gridEnt:GetSprite()

				sprite:ReplaceSpritesheet(0, "gfx/grid/rocks_caves.png")
				sprite:LoadGraphics()
			end
		end
		applyEffectsOnRoomEnter()
		g.game:GetRoom():KeepDoorsClosed()
	end
	if state.Active and roomVariant == 2 then
		for doorSlot = 0, DoorSlot.NUM_DOOR_SLOTS do
			local door = g.game:GetRoom():GetDoor(doorSlot)
			if door then
				g.game:GetRoom():RemoveDoor(doorSlot)
			end
		end
	end
	for _, player in ipairs(players) do
		if cnc:IsInCNCRoom()
			and not player:HasCollectible(g.CNC_PLAYER_TECHNICAL)
		then
			local data = player:GetData()
			if data.CNC_PreviousCollisionClass == nil then
				data.CNC_PreviousCollisionClass = player.GridCollisionClass
			end
			if data.CNC_PreviousEntityCollissionClass == nil then
				data.CNC_PreviousEntityCollissionClass = player.EntityCollisionClass
			end
			if data.CNC_CouldBeTargeted == nil then
				data.CNC_CouldBeTargeted = player:HasEntityFlags(EntityFlag.FLAG_NO_TARGET)
			end
			if data.CNC_WasVisible == nil then
				data.CNC_WasVisible = player.Visible
			end
			if data.CNC_WereBombsEmpty == nil then
				data.CNC_WereBombsEmpty = player:GetNumBombs() == 0
				if data.CNC_WereBombsEmpty == true then
					player:AddBombs(1)
				end
			end
			player.GridCollisionClass = GridCollisionClass.COLLISION_NONE
			player.EntityCollisionClass = EntityCollisionClass.ENTCOLL_NONE
			player.Visible = false
			player:AddEntityFlags(EntityFlag.FLAG_NO_TARGET)
			if GetPtrHash(player) ~= GetPtrHash(Isaac.GetPlayer()) then
				player.Position = Vector( -1000, -1000)
			end
		end
	end
end

---@param pickup EntityPickup
---@param collider Entity
---@param low boolean
function cnc:OnPrePickupCollision(pickup, collider, low)
	if collider.Type == EntityType.ENTITY_PLAYER then
		local sprite = pickup:GetSprite()

		if cnc:IsInCNCRoom()
			and (
			pickup.Variant == PickupVariant.PICKUP_COIN
			or pickup.Variant == PickupVariant.PICKUP_KEY
			or pickup.Variant == PickupVariant.PICKUP_BOMB
			)
		then
			if not pickup:IsDead() then
				if pickup.Variant == PickupVariant.PICKUP_COIN then
					state.Inventory.Coins = state.Inventory.Coins + pickup:GetCoinValue()
				elseif pickup.Variant == PickupVariant.PICKUP_KEY then
					local value = pickup.SubType == KeySubType.KEY_DOUBLEPACK and 2 or 1
					state.Inventory.Keys = state.Inventory.Keys + value
				elseif pickup.Variant == PickupVariant.PICKUP_BOMB then
					local value = pickup.SubType == BombSubType.BOMB_DOUBLEPACK and 2 or 1
					state.Inventory.Bombs = state.Inventory.Bombs + value
				end
				sprite:Play("Collect", true)
				pickup:Die()
				pickup:PlayPickupSound()
			end
			return true
		end
	end
end

---@param rng RNG
---@param spawnPos Vector
function cnc:OnCNCRoomClear(rng, spawnPos)
	if cnc:IsInCNCRoom() then
		spawnRewardsOnRoomClear(rng, spawnPos)
		for _, player in ipairs(cncPlayers) do
			local data = player:GetData()
			if data.CNC_MinigameStatsTemp then
				VeeHelper.CopyOverTable(statsTable, data.CNC_MinigameStatsTemp)
			end
			player:AddCacheFlags(CacheFlag.CACHE_ALL)
			player:EvaluateItems()
		end
		for doorSlot = 1, DoorSlot.NUM_DOOR_SLOTS do
			local door = g.game:GetRoom():GetDoor(doorSlot)
			if door then
				door:GetSprite():Stop()
				door:GetSprite():SetFrame(door.OpenAnimation, 0)
			end
		end
		return true
	end
end

--TODO: Clean this
function cnc:OnPostUpdate()
	local allDead = #cncPlayers > 0 and cnc:AreAllPlayersDead() or false
	local hasPickup = false

	if state.Active then
		if allDead
			and background:GetAnimation() ~= "FadeIn"
			and cnc:IsInCNCRoom()
		then
			background:Play("FadeIn", true)
			state.ScreenShown = true

			-- If all players died during the boss fight, remove Wavy Cap effects.
			for _ = 0, g.game:GetNumPlayers() do
				Isaac.GetPlayer(0):GetEffects():RemoveCollectibleEffect(CollectibleType.COLLECTIBLE_WAVY_CAP, 2)
			end
		end
		if roomIndexOnMinigameClear then
			if roomIndexOnMinigameClear ~= 0 then
				g.game:StartRoomTransition(roomIndexOnMinigameClear, Direction.NO_DIRECTION, RoomTransitionAnim.FADE)
				g.sfx:Stop(SoundEffect.SOUND_ISAACDIES)
				g.sfx:Stop(SoundEffect.SOUND_DEATH_BURST_SMALL)
			end
			roomIndexOnMinigameClear = nil
			return
		end
	end
	if allDead then return end

	if playCavesMusic then
		g.music:Enable()
		g.music:Fadein(Music.MUSIC_CAVES, Options.MusicVolume, 0.05)
		playCavesMusic = false
	end

	for i, player in ipairs(cncPlayers) do
		if not player:IsDead() and player:Exists() then
			if not player:IsDead() and player:Exists() and player.QueuedItem.Item ~= nil then
				hasPickup = true
			end
		elseif not state.Characters.Dead[i] and state.Active then
			local characterLayer = state.Characters.Selected[i] + 2
			state.Characters.Dead[i] = true
			if state.Characters.NumActive[i] > 0 then
				state.Characters.NumActive[i] = state.Characters.NumActive[i] - 1
			end
			characters:ReplaceSpritesheet(characterLayer, "gfx/ui/cnc_heads_dead.png")
			characters:LoadGraphics()
		end
	end
	if state.Active then
		if cnc:IsInCNCRoom() then
			local effects = cnc:GetPromptEffects()

			if effects and effects.ApplyDarkness then
				g.game:Darken(1, 30)
			end
		end
		if state.EncounterStarted
			and g.game:GetRoom():IsClear()
			and not state.EncounterCleared
		then
			local noPickups = false

			-- Okay so my logic here is that hearts can only drop from the boss fight,
			-- and you don't really care about those anymore since you either won or died.
			-- So please *actually* trigger the room clear even if there are hearts in one.
			if #Isaac.FindByType(EntityType.ENTITY_PICKUP) == #Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_HEART) then
				noPickups = true
			else
				for _, pedestal in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do
					if pedestal.SubType == 0
						and not hasPickup
						and
						#Isaac.FindByType(EntityType.ENTITY_PICKUP) ==
						#Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)
					then
						noPickups = true
					end
				end
			end

			if noPickups then
				state.EncounterCleared = true
				background:Play("FadeIn", true)
				state.ScreenShown = true
			end
		end
	end
end

---@param player EntityPlayer
function cnc:OnPlayerUpdate(player)
	if state.Active then
		if player.ControlsEnabled == true then
			if not player:HasCollectible(g.CNC_PLAYER_TECHNICAL)
				or (player:HasCollectible(g.CNC_PLAYER_TECHNICAL) and not cnc:IsInCNCRoom()) then
				player.ControlsEnabled = false
			end
		elseif not state.ScreenShown and GetPtrHash(player) == GetPtrHash(Isaac.GetPlayer()) then
			for _, cncPlayer in ipairs(cncPlayers) do
				if not cncPlayer:IsDead() then
					player.Position = Vector(cncPlayer.Position.X, cncPlayer.Position.Y) + VeeHelper.DirectionToVector(player:GetHeadDirection()):Resized(25)
					if player.Visible then
						player.Visible = false
					end
					return
				end
			end
		end
	end
end

---@param player EntityPlayer
---@param cacheFlag CacheFlag
function cnc:OnCNCPlayerCache(player, cacheFlag)
	if player:HasCollectible(g.CNC_PLAYER_TECHNICAL) then
		local data = player:GetData()
		local stats = {}
		VeeHelper.CopyOverTable(statsTable, stats)
		---@cast stats Stats

		if data.CNC_MinigameStats then
			for stat, num in pairs(data.CNC_MinigameStats) do
				stats[stat] = num
			end
		end
		if data.CNC_MinigameStatsTemp then
			for stat, num in pairs(data.CNC_MinigameStatsTemp) do
				stats[stat] = stats[stat] + num
			end
		end

		if cacheFlag == CacheFlag.CACHE_DAMAGE then
			player.Damage = (player.Damage * stats.DamageMult) + stats.DamageFlat
		elseif cacheFlag == CacheFlag.CACHE_FIREDELAY then
			player.MaxFireDelay = (player.MaxFireDelay * stats.TearsMult) + stats.TearsMult
		elseif cacheFlag == CacheFlag.CACHE_RANGE then
			player.TearRange = player.TearRange + stats.Range
		elseif cacheFlag == CacheFlag.CACHE_SHOTSPEED then
			player.ShotSpeed = player.ShotSpeed + stats.ShotSpeed
		elseif cacheFlag == CacheFlag.CACHE_LUCK then
			player.Luck = player.Luck + stats.Luck
		elseif cacheFlag == CacheFlag.CACHE_SPEED then
			player.MoveSpeed = player.MoveSpeed + stats.Speed
		end
	end
end

---------------------
--  TIMER HANDLES  --
---------------------

---@param player EntityPlayer
function cnc:KeyDelayHandle(player)
	local data = player:GetData()
	if data.CNC_KeyDelay then
		if data.CNC_KeyDelay > 0 then
			data.CNC_KeyDelay = data.CNC_KeyDelay - 1
		else
			data.CNC_KeyDelay = nil
		end
	end
end

function cnc:HandleTransitions()
	local alpha = {
		p = transitionAlpha.Prompt,
		t = transitionAlpha.Title,
		c = transitionAlpha.Characters,
		d = transitionAlpha.Dice
	}
	local y = {
		p = transitionY.Prompt,
		t = transitionY.Title,
		c = transitionY.Characters,
		d = transitionY.Dice
	}
	if fadeType == "TitlePromptDown" then
		if alpha.p > 0 then
			alpha.p = alpha.p - TRANSITION_ALPHA_SPEED
		end
		if alpha.t > 0 then
			alpha.t = alpha.t - TRANSITION_ALPHA_SPEED
		end
		if alpha.d > 0 then
			alpha.d = alpha.d - TRANSITION_ALPHA_SPEED
		end
		if y.p < TRANSITION_Y_TARGET then
			y.p = y.p + TRANSITION_Y_SPEED
		end
		if y.t < TRANSITION_Y_TARGET then
			y.t = y.t + TRANSITION_Y_SPEED
		end
		if y.d < TRANSITION_Y_TARGET then
			y.d = y.d + TRANSITION_Y_SPEED
		end
	elseif fadeType == "TitlePromptUp" then
		if alpha.p < 1 then
			alpha.p = alpha.p + TRANSITION_ALPHA_SPEED
		end
		if alpha.t < 1 then
			alpha.t = alpha.t + TRANSITION_ALPHA_SPEED
		end
		if alpha.d < 1 then
			alpha.d = alpha.d + TRANSITION_ALPHA_SPEED
		end
		if y.p > 0 then
			y.p = y.p - TRANSITION_Y_SPEED
		end
		if y.t > 0 then
			y.t = y.t - TRANSITION_Y_SPEED
		end
		if y.d > 0 then
			y.d = y.d - TRANSITION_Y_SPEED
		end
	elseif fadeType == "PromptDown" then
		if alpha.p > 0 then
			alpha.p = alpha.p - TRANSITION_ALPHA_SPEED
		end
		if y.p < TRANSITION_Y_TARGET then
			y.p = y.p + TRANSITION_Y_SPEED
		end
	elseif fadeType == "PromptUp" then
		if alpha.p < 1 then
			alpha.p = alpha.p + TRANSITION_ALPHA_SPEED
		end
		if y.p > 0 then
			y.p = y.p - TRANSITION_Y_SPEED
		end
	elseif fadeType == "CharacterUp" then
		if alpha.c < 1 then
			alpha.c = alpha.c + TRANSITION_ALPHA_SPEED
		end
		if y.c > 0 then
			y.c = y.c - TRANSITION_Y_SPEED
		end
	elseif fadeType == "CharacterDown" then
		if alpha.c > 0 then
			alpha.c = alpha.c - TRANSITION_ALPHA_SPEED
		end
		if y.c < TRANSITION_Y_TARGET then
			y.c = y.c + TRANSITION_Y_SPEED
		end
	elseif fadeType == "AllDown" then
		if alpha.p > 0 then
			alpha.p = alpha.p - TRANSITION_ALPHA_SPEED
		end
		if alpha.t > 0 then
			alpha.t = alpha.t - TRANSITION_ALPHA_SPEED
		end
		if alpha.c > 0 then
			alpha.c = alpha.c - TRANSITION_ALPHA_SPEED
		end
		if alpha.d > 0 then
			alpha.d = alpha.d - TRANSITION_ALPHA_SPEED
		end
		if y.p < TRANSITION_Y_TARGET then
			y.p = y.p + TRANSITION_Y_SPEED
		end
		if y.t < TRANSITION_Y_TARGET then
			y.t = y.t + TRANSITION_Y_SPEED
		end
		if y.c < TRANSITION_Y_TARGET then
			y.c = y.c + TRANSITION_Y_SPEED
		end
		if y.d < TRANSITION_Y_TARGET then
			y.d = y.d + TRANSITION_Y_SPEED
		end
	elseif fadeType == "AllUp" then
		if alpha.p < 1 then
			alpha.p = alpha.p + TRANSITION_ALPHA_SPEED
		end
		if alpha.t < 1 then
			alpha.t = alpha.t + TRANSITION_ALPHA_SPEED
		end
		if alpha.c < 1 then
			alpha.c = alpha.c + TRANSITION_ALPHA_SPEED
		end
		if alpha.d < 1 then
			alpha.d = alpha.d + TRANSITION_ALPHA_SPEED
		end
		if y.p > 0 then
			y.p = y.p - TRANSITION_Y_SPEED
		end
		if y.t > 0 then
			y.t = y.t - TRANSITION_Y_SPEED
		end
		if y.c > 0 then
			y.c = y.c - TRANSITION_Y_SPEED
		end
		if y.d > 0 then
			y.d = y.d - TRANSITION_Y_SPEED
		end
	end
	for name, value in pairs(y) do
		if value < 0 then
			y[name] = 0
		elseif value > TRANSITION_Y_TARGET then
			y[name] = TRANSITION_Y_TARGET
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
	transitionAlpha.Dice = alpha.d
	transitionY.Prompt = y.p
	transitionY.Title = y.t
	transitionY.Characters = y.c
	transitionY.Dice = y.d
end

function cnc:AnimationTimer()
	if g.game:IsPaused() then return end
	if characterFrameOffsetTimer > 0 then
		characterFrameOffsetTimer = characterFrameOffsetTimer - 1
	else
		characterFrameOffset = characterFrameOffset == 0 and 1 or 0
		characterFrameOffsetTimer = 30
	end
end

local timer = -1
local timerMillisecond = 0
function cnc:RoomTimer()
	if cnc:IsInCNCRoom() then
		local effects = cnc:GetPromptEffects()

		if effects and effects.TimeLimit and not state.ScreenShown then
			if not g.game:GetRoom():IsClear() then
				local timerColor = KColor(1, 1, 1, 1)
				if timer == -1 then
					timer = effects.TimeLimit
				elseif not g.game:IsPaused() then
					if timerMillisecond > 0 then
						timerMillisecond = timerMillisecond - 1
					else
						if timer > 0 then
							timer = timer - 1
							timerMillisecond = 60
						end
					end
					if timer <= 10 and timer > 0 then
						timerColor = KColor(1, 0.5, 0.5, 1)
					elseif timer <= 0 then
						timerColor = KColor(1, 0, 0, 1)
						if timerMillisecond == 0 then
							for _, player in ipairs(cncPlayers) do
								if not player:IsDead() then
									player:Die()
								end
							end
						end
					end
				end
				local center = getCenterScreen()
				local timerText = tostring(timer)
				local timerTextMillisecond = tostring(timerMillisecond)
				if timer < 10 then
					timerText = "0" .. timerText
				end
				if timerMillisecond < 10 then
					timerTextMillisecond = "0" .. timerTextMillisecond
				end

				timerFont:DrawString(timerText .. ":" .. timerTextMillisecond, 0, center.Y - 150, timerColor,
					Isaac.GetScreenWidth()
					, true)
			elseif timer ~= -1 then
				timer = -1
				timerMillisecond = 0
			end
		elseif timer ~= -1 then
			timer = -1
			timerMillisecond = 0
		end
	end
end

function cnc:RenderPlayersActiveItem()
	for i, player in ipairs(cncPlayers) do
		if player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) and player:GetActiveItem(ActiveSlot.SLOT_PRIMARY) ~= -1 then
			local gfx = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)).GfxFileName

			if gfx and gfx ~= "" then
				cncPlayerActiveItems[i]:ReplaceSpritesheet(0, gfx)
				cncPlayerActiveItems[i]:LoadGraphics()
				cncPlayerActiveItems[i]:Render(Vector(32 + 48 * (i - 1), 32))

				local maxCharge = Isaac.GetItemConfig():GetCollectible(player:GetActiveItem(ActiveSlot.SLOT_PRIMARY)).MaxCharges
				local charge = player:GetActiveCharge(ActiveSlot.SLOT_PRIMARY)

				if maxCharge == 3 or maxCharge == 4 or maxCharge == 6 then
					cncPlayerActiveChargebars[i]:SetFrame("charge_" .. tostring(charge) .. "_" .. tostring(maxCharge), 0)
				end

				cncPlayerActiveChargebars[i]:Render(Vector(64 + 48 * (i - 1), 32))
			end
		end
	end
end

function cnc:RenderInventory()
	if state.Active then
		local inv = state.Inventory

		cncInventory:Render(Vector(20, 192))
		Isaac.RenderText(tostring(inv['Coins']), 28, 170, 1, 1, 1, 1)
		Isaac.RenderText(tostring(inv['Bombs']), 28, 186, 1, 1, 1, 1)
		Isaac.RenderText(tostring(inv['Keys']), 28, 202, 1, 1, 1, 1)
	end
end

------------
--  MISC  --
------------

---@param bomb EntityBomb
function cnc:LampOilRopeBombsYouWantItItsYourMyFriendAsLongAsYouGotThemInTheMinigame(bomb)
	if bomb.SpawnerEntity and bomb.SpawnerEntity:ToPlayer() and state.Active then
		if state.Inventory.Bombs >= 0 then
			bomb:Remove()
			g.sfx:Stop(SoundEffect.SOUND_FETUS_LAND)
			bomb.SpawnerEntity:ToPlayer():AddBombs(1)
		elseif state.Inventory.Bombs > 0 then
			state.Inventory.Bombs = state.Inventory.Bombs - 1
		end
	end
end

function cnc:OnRender()
	local renderMode = g.game:GetRoom():GetRenderMode()
	if renderMode == RenderMode.RENDER_NULL
		or renderMode == RenderMode.RENDER_NORMAL
		or renderMode == RenderMode.RENDER_WATER_ABOVE
	then
		cnc:RenderScreen()
		cnc:MinigameLogic()
		cnc:HandleTransitions()
		cnc:RoomTimer()
		cnc:RenderInventory()

		if cnc:IsInCNCRoom() then
			cnc:RenderPlayersActiveItem()
		end
	end
end

function cnc:OnPreGameExit()
	resetMinigame()
	g.GameState = {
		ShouldStart = false,
		GameActive = false,
		BeggarInitSeed = 0,
		HasWon = false,
		HasLost = false,
		PickupsCollected = {
			Coins = 0,
			Keys = 0,
			Bombs = 0
		}
	}
end

return cnc
