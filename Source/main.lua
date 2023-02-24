import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'Coracle/coracle'
import 'Coracle/math'
import 'Coracle/string_utils'
import 'Coracle/vector'
import 'Views/focus_manager'
import 'Views/label'
import 'Views/sequencer_grid'
import 'Views/mute_toggle'
import 'Views/rotary_encoder'
import 'Views/two_part_effect'
import 'Views/switch'
import 'Views/divider'
import 'Views/control_labels'
import 'Views/loop_line'
import 'sequencer'

GRID_WIDTH = 242
KNOB_OFFSET = 14

local footerMessage = "Unknown"

playdate.graphics.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
	playdate.graphics.setColor(playdate.graphics.kColorBlack)
	playdate.graphics.fillRect(0, 0, 400, 240)
end)

font = playdate.graphics.font.new("Fonts/font-rains-1x")
playdate.graphics.setFont(font)

local sequencer = nil
local grid = nil

local focusManager = FocusManager()

local muteLabel = Label(GRID_WIDTH + 26, 8, "Mute", font)
muteLabel:setOpacity(0.4)
local muteTogggle = MuteToggle(20, 200, GRID_WIDTH + 17, 20, function(track, muted, userTap)
	if userTap then
		if sequencer ~= nil then 
			sequencer:setTrackMute(track, muted) 
			if muted then
				footerMessage = "" .. track .. ": " .. grid:getTrackName(track) .. " Muted"
			else
				footerMessage = "" .. track .. ": " .. grid:getTrackName(track) .. " Unmuted"
			end
		end
	else
			footerMessage = "" .. track .. ": " .. grid:getTrackName(track)
	end
	

	
end)
focusManager:addView(muteTogggle, 1)
focusManager:addView(muteTogggle, 2)

--Turn the knob to the left, you will cut the highs. Turn the knob to the right, you will cut the lows.
local filterEffect = TwoPartEffect(font, Vector(305 + KNOB_OFFSET, 8), "Filter", "NULL")
filterEffect:setAmountLabelRenderValues(-1, 1, true)
filterEffect:setAmountListener(function(normalised, mapped)
	if sequencer ~= nil then sequencer:setFilterCutoff(mapped) end
end)
filterEffect:setTopValue(0.5)
focusManager:addView(filterEffect:getTopFocusView(), 1)

--todo 0 unused, filter is always on
filterEffect:setMixListener(function(normalised, mapped)
	
end)
focusManager:addView(filterEffect:getBottomFocusView(), 2)

-- End of single pole

local bpmLabel = Label(360 + KNOB_OFFSET, 8, "BPM", font)
bpmLabel:setOpacity(0.4)
local bpmEncoder = RotaryEncoder(360 + KNOB_OFFSET, 38, function(normalised, mapped)	
	if sequencer ~= nil then sequencer:setBPM(mapped) end
end, font)
bpmEncoder:setLabelRenderValues(10, 200, false)--bpm range, render as int
bpmEncoder:setValue(0.58)
focusManager:addView(bpmEncoder, 1)

--Delay mix
local mixLabel = Label(360 + KNOB_OFFSET, 83, "Mix", font)
mixLabel:setOpacity(0.4)
local mixEncoder = RotaryEncoder(360 + KNOB_OFFSET, 113, function(normalised, mapped)	
	sequencer:setDelayMix(normalised)
end, font)
focusManager:addView(mixEncoder, 2)

local divider = Divider(222)
local controls = ControlLabels(font)
local loopLine = LoopLine(15, 20, GRID_WIDTH-15, 200)

grid = SequencerGrid(GRID_WIDTH, 200, 6, 20, 16, function(track, step , value, sample)
	print("Track: ".. track .. " step: " .. step .. " value: " .. value)
	footerMessage = "" .. track .. "," .. step .. ": " .. value .. " " .. sample
	if(sequencer ~= nil) then sequencer:updateStep(track, step, value) end
end)

local samplePackName = "Loading..."
sequencer = Sequencer("sequencer.json", function(name, tracks)
	samplePackName = name
	print("Loaded samplepack: " .. samplePackName .. " containing " .. #tracks .. " tracks")
	grid:load(tracks)
	muteTogggle:load(tracks)
end)

-- Menus
local menu = playdate.getSystemMenu()
local checkmarkMenuItem, error = menu:addCheckmarkMenuItem("PO-Sync", false, function(value)
		print("Po-Sync enabled: ", value)
		if sequencer ~= nil then sequencer:poSyncActive(value) end
end)

sequencer:play()

function playdate.update()
	local change = crankChange()
	if focusManager:isHandlingInput() then
		focusManager:turnFocusedView(change)
	end
	playdate.graphics.sprite.update()

	playdate.graphics.drawText(samplePackName, 3, 4)
	playdate.graphics.drawText(footerMessage, 2, 228)
	if sequencer:playing() then
		loopLine:update(sequencer:getStep())
	end
end

function playdate.leftButtonDown()
	grid:goLeft()
end

function playdate.rightButtonDown()
	grid:goRight()
end

function playdate.BButtonDown()
	if(mutateStep)then
		grid:toggleValue()
	else
		if focusManager:isHandlingInput() then
			focusManager:unfocus()
			focusManager:pop()--focus manager now in charge
		else
			focusManager:start()
			focusManager:push()--focus manager now in charge
		end
	end
end

function playdate.upButtonDown()
	if(mutateStep)then
		grid:valueUp()
	else
		grid:goUp()
	end
end

function playdate.downButtonDown()
	if(mutateStep)then
		grid:valueDown()
	else
		grid:goDown()
	end
	
end

function playdate.AButtonDown()
	if focusManager:isHandlingInput() then
		focusManager:tapFocusedView(change)
	else
		mutateStep = true
	end
	
end

function playdate.AButtonUp()
	mutateStep = false
end