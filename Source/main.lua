import 'CoreLibs/sprites'
import 'CoreLibs/graphics'
import 'CoreLibs/timer'
import 'Coracle/coracle'
import 'Coracle/math'
import 'Coracle/string_utils'
import 'Coracle/vector'
import 'Views/focus_manager'
import 'Views/label'
import 'Views/sequencer_grid'
import 'Views/mute_toggle'
import 'Views/track_record_buttons'
import 'Views/rotary_encoder'
import 'Views/two_part_effect'
import 'Views/loop_line'
import 'CoracleViews/label_right'
import 'CoracleViews/label_left'
import 'CoracleViews/label_centre'
import 'CoracleViews/toggle_button'
import 'CoracleViews/divider_vertical'
import 'CoracleViews/divider_horizontal'
import 'Views/mini_slider'
import 'Record/record_dialog'
import 'sequencer'

local graphics <const> = playdate.graphics

GRID_WIDTH = 242
KNOB_OFFSET = 14
SEQ_HEIGHT = 200
SEQ_MUTATE_LABEL = "B+Up/Down"
MUTE_MUTATE_LABEL = "Mute/Unmute"

font = playdate.graphics.font.new("Fonts/font-rains-1x")
playdate.graphics.setFont(font)

playdate.graphics.sprite.setBackgroundDrawingCallback(function(x, y, width, height)
	playdate.graphics.setColor(playdate.graphics.kColorBlack)
	playdate.graphics.fillRect(0, 0, 400, 240)
end)

local headerLabel = Label(4, 10, "XXXXXXXXXXXXXXXXXXXXX", font)
local footerLabel = Label(4, 232, "XXXXXXXXXXXXXXXXXXXXX", font)
local navLabel = LabelRight("Tk Mute ->", 390, 225)
local mutateLabel = LabelRight(SEQ_MUTATE_LABEL, 290, 225)
local sequencer = nil
local grid = nil

local fxFocusManager = FocusManager(function(direction)
		--onUnhandled left or right
		if direction == -1 then
			focusLeftToMute()
		elseif direction == 1 then
			focusWrapToRec()
		end
	end)
	
local muteFocusManager = FocusManager(function(direction)
	--onUnhandled left or right
	if direction == -1 then
		focusLeftToSequencerGrid()
	elseif direction == 1 then
		focusRightToFx()
	end
end)

-- Record
local recordDialog = RecordDialog()
local recFocusManager = FocusManager(function(direction)
	--onUnhandled left or right
	if direction == -1 then
		focusLeftToFx()
	elseif direction == 1 then
		focusRightToSequencerGrid()
	end
end)

local trackRecordButtons = TrackRecordButtons(20, SEQ_HEIGHT, 3, 18, function(track, muted, userTap)
	if userTap then
		-- NOOP
	else
		footerLabel:setText("" .. track .. ": " .. grid:getTrackName(track))
	end
end)
recFocusManager:addView(trackRecordButtons, 1)
-- Record end

local muteLabel = LabelCentre("Mute", GRID_WIDTH + 27, 3)
muteLabel:setAlpha(0.4)
local muteTogggle = MuteToggle(20, SEQ_HEIGHT, GRID_WIDTH + 17, 20, function(track, muted, userTap)
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
muteFocusManager:addView(muteTogggle, 1)

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

fxFocusManager:addView(bpmSlider, 1)

--delays mix
local delay1Slider = MiniSlider("Dly1", hwSliderLeftX, row2Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay1Mix(value/100.00)
end)

local delay2Slider = MiniSlider("Dly2", hwSliderRightX, row2Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay2Mix(value/100.00)
end)

fxFocusManager:addView(delay1Slider, 2)
fxFocusManager:addView(delay2Slider, 2)

DividerHorizontal(300, 38, 90, 0.4)

--delays feedback
local delay1FeedbackSlider = MiniSlider("Fback", hwSliderLeftX, row3Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay1Feedback(value/100.00)
end)

local delay2FeedbackSlider = MiniSlider("Fback", hwSliderRightX, row3Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setDelay2Feedback(value/100.00)
end)

fxFocusManager:addView(delay1FeedbackSlider, 3)
fxFocusManager:addView(delay2FeedbackSlider, 3)

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

fxFocusManager:addView(loPassToggle, 4)
fxFocusManager:addView(hiPassToggle, 4)

local loPassSlider = MiniSlider("Freq", hwSliderLeftX, row5Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setLoPassFrquency(map(value, 0, 100, 100, 10000))
end)
local hiPassSlider = MiniSlider("Freq", hwSliderRightX, row5Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setHiPassFrquency(map(value, 0, 100, 100, 10000))
end)

fxFocusManager:addView(loPassSlider, 5)
fxFocusManager:addView(hiPassSlider, 5)

local loPassResSlider = MiniSlider("Res", hwSliderLeftX, row6Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setLoPassResonance(value/100.0)
end)
local hiPassResSlider = MiniSlider("Res", hwSliderRightX, row6Y, hwSliderWidth, 0, 0, 100, 6, false, function(value) 
	sequencer:setHiPassResonance(value/100.0)
end)

fxFocusManager:addView(loPassResSlider, 6)
fxFocusManager:addView(hiPassResSlider, 6)

local loopLine = LoopLine(15, 20, GRID_WIDTH-15, SEQ_HEIGHT)

grid = SequencerGrid(GRID_WIDTH - 20, SEQ_HEIGHT, 26, 20, 16, function(track, step , value, sample)
	print("Track: ".. track .. " step: " .. step .. " value: " .. value)
	footerLabel:setText("" .. track .. "," .. step .. ": " .. value .. " " .. sample)
	if(sequencer ~= nil) then 
		sequencer:updateStep(track, step, value) 
	end
end)

DividerVertical(292, 22, 190, 0.4)

sequencer = Sequencer("sequencer.json", function(name, tracks)
	headerLabel:setText(name)
	print("Loaded samplepack: " .. name .. " containing " .. #tracks .. " tracks")
	grid:load(tracks)
	muteTogggle:load(tracks)
	trackRecordButtons:load(tracks)
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
	if fxFocusManager:isHandlingInput() then
		fxFocusManager:turnFocusedView(change)
	end
	playdate.graphics.sprite.update()

	if sequencer:playing() then
		loopLine:update(sequencer:getStep())
	end
	
	playdate.timer.updateTimers()
end


function playdate.leftButtonDown() grid:goLeft() end
function playdate.rightButtonDown() grid:goRight() end

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

--LEFT BUTTON
function playdate.BButtonDown()
	if muteFocusManager:isHandlingInput() then
		muteFocusManager:tapFocusedView(change)
	elseif fxFocusManager:isHandlingInput() then
		fxFocusManager:tapFocusedView(change)
	elseif recFocusManager:isHandlingInput() then
		showRecordDialog()
	else
		mutateStep = true
	end
end

--RIGHT BUTTON
function playdate.AButtonDown()
	if(mutateStep)then
		grid:toggleValue()
	else
		if recFocusManager:isHandlingInput() then
			focusWrapToGrid()
		elseif(muteFocusManager:isHandlingInput()) then
			focusRightToFx()
		elseif fxFocusManager:isHandlingInput() then
			focusWrapToRec()
		else
			grid:setFocus(false)
			muteFocusManager:start()
			muteFocusManager:push()--focus manager now in charge
			navLabel:setText("Effects ->")
			mutateLabel:setText(MUTE_MUTATE_LABEL)
			muteLabel:setAlpha(1.0)
		end
	end
end

function focusWrapToRec()
	fxFocusManager:unfocus()
	fxFocusManager:pop()
	recFocusManager:start()
	recFocusManager:push()--focus manager now in charge
	navLabel:setText("Seq Grid ->")
end

function focusWrapToGrid()
	print("focusWrapToGrid()")
	recFocusManager:unfocus()
	recFocusManager:pop()
	grid:setFocus(true)
	navLabel:setText("Tk Mute ->")
	muteLabel:setAlpha(0.4)
	mutateLabel:setText(SEQ_MUTATE_LABEL)
end

function focusLeftToFx()
	recFocusManager:unfocus()
	recFocusManager:pop()
	if not fxFocusManager:hasStarted() then fxFocusManager:start() end
	fxFocusManager:push()--focus manager now in charge
	fxFocusManager:refocus()
	navLabel:setText("Track rec. ->")
	muteLabel:setAlpha(0.4)
	mutateLabel:setText(" ")
end

function focusRightToFx()
	muteFocusManager:unfocus()
	muteFocusManager:pop()
	if not fxFocusManager:hasStarted() then fxFocusManager:start() end
	fxFocusManager:push()--focus manager now in charge
	fxFocusManager:refocus()
	navLabel:setText("Track rec. ->")
	muteLabel:setAlpha(0.4)
	mutateLabel:setText(" ")
end

function focusLeftToMute()
	fxFocusManager:unfocus()
	fxFocusManager:pop()
	muteFocusManager:start()
	muteFocusManager:push()--focus manager now in charge
	navLabel:setText("Effects ->")
	mutateLabel:setText(MUTE_MUTATE_LABEL)
	muteLabel:setAlpha(1.0)
end

function focusLeftToSequencerGrid()
	muteFocusManager:unfocus()
	muteFocusManager:pop()
	grid:setFocus(true)
	navLabel:setText("Tk Mute ->")
	muteLabel:setAlpha(0.4)
	mutateLabel:setText(SEQ_MUTATE_LABEL)
end

function focusRightToSequencerGrid()
	recFocusManager:unfocus()
	recFocusManager:pop()
	grid:setFocus(true)
	navLabel:setText("Tk Mute ->")
	muteLabel:setAlpha(0.4)
	mutateLabel:setText(SEQ_MUTATE_LABEL)
end

function playdate.BButtonUp()
	mutateStep = false
end

function playdate.AButtonUp()
	
end

function showRecordDialog()
	sequencer:stop()
	recordDialog:show(trackRecordButtons:getCurrentTrack())
end