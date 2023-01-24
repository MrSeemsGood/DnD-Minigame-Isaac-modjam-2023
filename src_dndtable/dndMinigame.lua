local dnd = {}
local g = require("src_dndtable.globals")

local font = Font()

local whatDoin = {
	promptProgress = 0,
	curPrompt = 1,
	hasRolled = false,
	numRolled = 0,
	maxPrompts = 3,
	encounteredPrompts = {},
	endGaming = false,
}

local testPrompt = {
	{
		text = "You shit your pants. Now what?",
		outcomes = {
			[1] = "You shit your pants a second time",
			[2] = "Its not that bad and walk it off",
			[3] = "You shove it back into your asshole where it belongs."
		}
	},
	{
		text = "You pissed yourself. Now what?",
		outcomes = {
			[1] = "You attempt to wipe it off but it gets worse",
			[2] = "its fine",
			[3] = "you get a new pair of pants, awesome"
		}
	},
	{
		text = "You farded. Now what?",
		outcomes = {
			[1] = "Everyone knows",
			[2] = "only a couple people know",
			[3] = "no one smells it!"
		}
	},
}

local function initFontText()
	font:Load("font/teammeatfont12.fnt")
end

local testStartPrompt = Keyboard.KEY_J
local testEndPrompt = Keyboard.KEY_K
local prompting = false
local textToShow = "Placeholder!"
local keyDelay = 0

local function startNextPrompt()
	whatDoin.curPrompt = VeeHelper.GetDifferentRandomNum(whatDoin.encounteredPrompts, whatDoin.maxPrompts,
		VeeHelper.RandomRNG)
	whatDoin.promptProgress = whatDoin.promptProgress + 1
	textToShow = testPrompt[whatDoin.curPrompt].text
	whatDoin.numRolled = 0
	whatDoin.hasRolled = false
end

function dnd:WriteText()
	if g.game:IsPaused() then return end
	local pos = Vector(250, 130)
	if Input.IsButtonPressed(testStartPrompt, Isaac.GetPlayer().ControllerIndex) and not prompting then
		prompting = true
		initFontText()
		startNextPrompt()
	elseif prompting then

		if Input.IsButtonPressed(Keyboard.KEY_SPACE, Isaac.GetPlayer().ControllerIndex) and keyDelay == 0 then
			if not whatDoin.hasRolled then
				whatDoin.hasRolled = true
				whatDoin.numRolled = VeeHelper.RandomNum(1, 3)
				textToShow = testPrompt[whatDoin.curPrompt].outcomes[whatDoin.numRolled]
			else
				if whatDoin.promptProgress < whatDoin.maxPrompts then
					startNextPrompt()
				elseif not whatDoin.endGaming then
					textToShow = "Congrorts"
					whatDoin.endGaming = true
				elseif whatDoin.endGaming then
					prompting = false
					whatDoin.hasRolled = false
					whatDoin.numRolled = 0
					whatDoin.promptProgress = 0
					whatDoin.endGaming = false
				end
			end
			keyDelay = 10
		end

		if keyDelay > 0 then
			keyDelay = keyDelay - 1
		end

		font:DrawString(textToShow, pos.X, pos.Y, KColor(1, 1, 1, 1), 50, true)
		if whatDoin.hasRolled == false then
			font:DrawString("Press SPACE to roll the dice", pos.X, pos.Y + 50, KColor(1, 1, 1, 1), 50, true)
		else
			font:DrawString("Press SPACE to continue", pos.X, pos.Y + 50, KColor(1, 1, 1, 1), 50, true)
		end

		if Input.IsButtonPressed(testEndPrompt, Isaac.GetPlayer().ControllerIndex) then
			prompting = false
			whatDoin.hasRolled = false
			whatDoin.numRolled = 0
			whatDoin.promptProgress = 0
		end
	end
end

function dnd:FillScreen()

end

function dnd:OnRender()
	local renderMode = g.game:GetRoom():GetRenderMode()
	if renderMode == RenderMode.RENDER_NULL
		or renderMode == RenderMode.RENDER_NORMAL
		or renderMode == RenderMode.RENDER_WATER_ABOVE
	then
		dnd:WriteText()
	end
end

return dnd
