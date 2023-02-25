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
import 'Views/divider'
import 'Views/control_labels'
import 'Views/loop_line'
import 'CoracleViews/label_right'
import 'CoracleViews/label_left'
import 'CoracleViews/label_centre'
import 'CoracleViews/divider_vertical'
import 'Views/mini_slider'
import 'sequencer'

local graphics <const> = playdate.graphics

GRID_WIDTH = 242
KNOB_OFFSET = 14

font = playdate.graphics.font.new("Fonts/font-rains-1x")
playdate.graphics.setFont(font)

playdate.graphics.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
	playdate.graphics.setColor(playdate.graphics.kColorBlack)
	playdate.graphics.fillRect(0, 0, 400, 240)
end)

local headerLabel = Label(4, 8, "XXXXXXXXXXXXXXXXXXXXX", font)
local footerLabel = Label(4, 232, "XXXXXXXXXXXXXXXXXXXXX", font)
local sequencer = nil
local grid = nil

local focusManager = FocusManager()

local muteLabel = Label(GRID_WIDTH + 12, 8, "Mute", font)
muteLabel:setOpacity(0.4)
local muteTogggle = MuteToggle(20, 200, GRID_WIDTH + 17, 20, function(track, muted, userTap)
	if userTap then
		if sequencer ~= nil then 
			sequencer:setTrackMute(track, muted) 
			if muted then
				footerLabel:setText("" .. track .. ": " .. grid:getTrackName(track) .. " Muted")
			else
				footerLabel:setText("" .. track .. ": " .. grid:getTrackName(track) .. " Unmuted")
			end
		end
	else
			footerLabel:setText("" .. track .. ": " .. grid:getTrackName(track))
	end
end)
focusManager:addView(muteTogggle, 1)
focusManager:addView(muteTogggle, 2)
focusManager:addView(muteTogggle, 3)



--label, x, y, width, value, rangeStart, rangeEnd, showValue, listener)
local bpmSlider = MiniSlider("BPM", 353, 20, 90, 120, 70, 180, true, function(value) 
	if sequencer ~= nil then sequencer:setBPM(value) end
end)

focusManager:addView(bpmSlider, 1)

local delaySlider = MiniSlider("Dly Mix", 353, 60, 90, 0, 0, 100, true, function(value) 
	sequencer:setDelayMix(value/100.00)
end)

focusManager:addView(delaySlider, 2)


local divider = Divider(222)
local controls = ControlLabels(font)
local loopLine = LoopLine(15, 20, GRID_WIDTH-15, 200)

grid = SequencerGrid(GRID_WIDTH, 200, 6, 20, 16, function(track, step , value, sample)
	print("Track: ".. track .. " step: " .. step .. " value: " .. value)
	footerLabel:setText("" .. track .. "," .. step .. ": " .. value .. " " .. sample)
	if(sequencer ~= nil) then sequencer:updateStep(track, step, value) end
end)

DividerVertical(296, 8, 205, 0.4)

sequencer = Sequencer("sequencer.json", function(name, tracks)
	headerLabel:setText(name)
	print("Loaded samplepack: " .. name .. " containing " .. #tracks .. " tracks")
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