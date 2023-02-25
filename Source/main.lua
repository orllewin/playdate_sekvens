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
import 'CoracleViews/toggle_button'
import 'CoracleViews/divider_vertical'
import 'CoracleViews/divider_horizontal'
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
focusManager:addView(muteTogggle, 4)
focusManager:addView(muteTogggle, 5)

local fwSliderWidth = 95
local fwSliderX = 350
local hwSliderWidth = 40
local hwSliderLeftX = 325
local hwSliderRightX = 373
local row2Y = 57
local row3Y = 93
local row4Y = 133
local row5Y = 165
local row6Y = 200
--label, x, y, width, value, rangeStart, rangeEnd, showValue, listener)
local bpmSlider = MiniSlider("BPM", fwSliderX, 17, fwSliderWidth, 120, 70, 180, 12, true, function(value) 
	if sequencer ~= nil then sequencer:setBPM(value) end
end)

focusManager:addView(bpmSlider, 1)

--delays mix
local delay1Slider = MiniSlider("Dly1", hwSliderLeftX, row2Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay1Mix(value/100.00)
end)

local delay2Slider = MiniSlider("Dly2", hwSliderRightX, row2Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay2Mix(value/100.00)
end)

focusManager:addView(delay1Slider, 2)
focusManager:addView(delay2Slider, 2)

DividerHorizontal(300, 38, 90, 0.4)

--delays feedback
local delay1FeedbackSlider = MiniSlider("Fback", hwSliderLeftX, row3Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay1Feedback(value/100.00)
end)

local delay2FeedbackSlider = MiniSlider("Fback", hwSliderRightX, row3Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay2Feedback(value/100.00)
end)

focusManager:addView(delay1FeedbackSlider, 3)
focusManager:addView(delay2FeedbackSlider, 3)

DividerHorizontal(300, 115, 90, 0.4)

--label, x, y, width, height, active
local loPassToggle = ToggleButton("Lo", 325, row4Y, 40, 30, false, function(active)
	print("Togoel listenber, setting lo pass to " .. tostring(active))
	sequencer:setLoPassActive(active)
end)
local hiPassToggle = ToggleButton("Hi", 375, row4Y, 40, 30, false, function(active)
	print("Togoel listenber, setting hi pass to " .. tostring(active))
	sequencer:setHiPassActive(active)
end)

focusManager:addView(loPassToggle, 4)
focusManager:addView(hiPassToggle, 4)

local loPassSlider = MiniSlider("Freq", hwSliderLeftX, row5Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setLoPassFrquency(map(value, 0, 100, 100, 10000))
end)
local hiPassSlider = MiniSlider("Freq", hwSliderRightX, row5Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setHiPassFrquency(map(value, 0, 100, 100, 10000))
end)

focusManager:addView(loPassSlider, 5)
focusManager:addView(hiPassSlider, 5)

local loPassResSlider = MiniSlider("Res", hwSliderLeftX, row6Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setLoPassResonance(value/100.0)
end)
local hiPassResSlider = MiniSlider("Res", hwSliderRightX, row6Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setHiPassResonance(value/100.0)
end)

focusManager:addView(loPassResSlider, 6)
focusManager:addView(hiPassResSlider, 6)






local divider = Divider(222)
local controls = ControlLabels(font)
local loopLine = LoopLine(15, 20, GRID_WIDTH-15, 200)

grid = SequencerGrid(GRID_WIDTH, 200, 6, 20, 16, function(track, step , value, sample)
	print("Track: ".. track .. " step: " .. step .. " value: " .. value)
	footerLabel:setText("" .. track .. "," .. step .. ": " .. value .. " " .. sample)
	if(sequencer ~= nil) then sequencer:updateStep(track, step, value) end
end)

DividerVertical(292, 22, 190, 0.4)

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