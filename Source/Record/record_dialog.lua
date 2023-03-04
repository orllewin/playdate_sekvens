import 'CoracleViews/label_left'
import 'CoracleViews/label_centre'
import 'CoracleViews/divider_vertical'
import 'CoracleViews/text_list'
import 'CoracleViews/button'
import 'CoreLibs/keyboard'

class('RecordDialog').extends(playdate.graphics.sprite)

local filename = "rec-"
local recordSprites = {}
local categories = {"Claps", "Cymbals","FX","Hats","Kicks","Perc","Snares","Toms"}
local selectedCategory = "Claps"
local selectedSample = ""

local DIV_X = 190
local SAMPLE_SELECT_LABEL_X = 200
local CATEGORY_X = 200
local SAMPLE_X = 275

local buffer = playdate.sound.sample.new(3, playdate.sound.kFormat16bitMono)
local player = playdate.sound.fileplayer.new()
local samplePlayer = playdate.sound.sampleplayer.new(buffer)

function RecordDialog:init()
	RecordDialog.super.init(self)
end

function RecordDialog:show(track, onSampleSelected)
	
	self.track = track
	self.onSampleSelected = onSampleSelected
	
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeCopy)
	local background = playdate.graphics.image.new(400, 240, playdate.graphics.kColorBlack)
	self:moveTo(200, 120)
	self:setImage(background)
	self:add()
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
	self.headerLabel = LabelLeft("Sample Edit - track " .. track, 4, 3)
	self:addDialogSprite(self.headerLabel)
	
	self.verticalDiv = DividerVertical(DIV_X, 20, 200, 0.4)
	self:addDialogSprite(self.verticalDiv)
	
	self.bLabel = LabelRight("Dismiss", 290, 225)
	self:addDialogSprite(self.bLabel)
	self.aLabel = LabelRight("Sample ->", 390, 225)
	self:addDialogSprite(self.aLabel)
	
	--right items
	self.selectLabel = LabelLeft("Select Sample", SAMPLE_SELECT_LABEL_X, 20)
	self:addDialogSprite(self.selectLabel)
	
	self.sampleList = TextList(playdate.file.listFiles("SamplesDefault/" .. categories[1]), SAMPLE_X, 38, 120, 190, function(index, text)
		selectedSample = text
		print("Sample selected, index: " .. index .. " (" .. selectedSample .. ")")
		self:playSample("SamplesDefault/" .. selectedCategory .. "/" .. selectedSample)
	end)
	self.sampleList:setFocus(false)
	
	self.categoryList = TextList(categories, CATEGORY_X, 38, 65, 200, function(index, text)
		print("Update sample list, index: " .. index .. " (" .. text .. ")")
		selectedCategory = text
		self.sampleList:updateItems(playdate.file.listFiles("SamplesDefault/" .. selectedCategory))
	end)
	self.categoryList:setFocus(true)
	
	-- left items
	self.recordNewLabel = LabelLeft("Record Sample", 4, 20)
	self.recordNewLabel:setAlpha(0.4)
	self:addDialogSprite(self.recordNewLabel)
	
	self.recordPushButton = Button("Hold A to Record", "Recording", 95, 80, 150, 50, function ()
			
	end)
	
	self.recordPreviewButton = Button("Preview", nil, 60, 130, 75, 30, function ()
			samplePlayer:play()
	end)
	
	self.sampleLabel = LabelCentre("Sample Name:", 90, 170)
	self.sampleLabel:setAlpha(0.4)
	self:addDialogSprite(self.sampleLabel)
	self.filenameLabel = LabelCentre(" ", 90, 190)
	self:addDialogSprite(self.filenameLabel)
	self.recordSaveButton = Button("Save", nil, 135, 130, 75, 30, function ()
			self.sampleLabel:setAlpha(1.0)
			self.recordSaveButton:setFocus(false)
			playdate.keyboard.show(filename)
			playdate.keyboard.textChangedCallback = function()
				filename = playdate.keyboard.text
				self.filenameLabel:setText(filename)
			end
			
			playdate.keyboard.keyboardDidHideCallback = function()
				--todo - show toast
				if playdate.file.isdir("UserRecorded") == false then
					playdate.file.mkdir("UserRecorded")
				end
				buffer:save("UserRecorded/" .. filename .. ".pda")
				if self.onSampleSelected ~= nil then self.onSampleSelected(self.track, filename, "UserRecorded/" .. filename .. ".pda") end
				self:dismiss()
			end
	end)
	
	playdate.inputHandlers.push(self:getInputHandler())
end

function RecordDialog:addDialogSprite(sprite)
	table.insert(recordSprites, sprite)
end

function RecordDialog:dismiss()
	playdate.inputHandlers.pop()
	self:remove()
	self.categoryList:removeAll()
	self.recordPushButton:removeAll()
	self.recordPreviewButton:removeAll()
	self.recordSaveButton:removeAll()
	self.sampleList:removeAll()
	for i=1,#recordSprites do
		recordSprites[i]:remove()
	end
end

function RecordDialog:playSample(path)
	player:stop()
	player:load(path)
	player:play()
end

function RecordDialog:startRecording()
	playdate.sound.micinput.recordToSample(buffer, function()
		self:sampleRecorded()
	end)
end

function RecordDialog:stopRecording()
	self:sampleRecorded()
end

function RecordDialog:sampleRecorded()
	samplePlayer:setSample(buffer)
end

function RecordDialog:saveRecording()
	
end

-- See https://sdk.play.date/1.12.3/Inside%20Playdate.html#M-inputHandlers
function RecordDialog:getInputHandler()
	return {
		cranked = function(change, acceleratedChange)
				print("Crank change: " .. change)
				if self.sampleList:isFocused() then
					self.sampleList:cranked(change)
				elseif self.categoryList:isFocused() then
					self.categoryList:cranked(change)
				end
		end,
		BButtonDown = function()
			self:dismiss()
		end,
		AButtonDown = function()
			if self.categoryList:isFocused() then
				self.categoryList:setFocus(false)
				self.sampleList:setFocus(true)
				self.aLabel:setText("Select")
			elseif self.recordPreviewButton:isFocused() then
				self.recordPreviewButton:tap()
			elseif self.recordSaveButton:isFocused() then
				self.recordSaveButton:tap()
			elseif self.recordPushButton:isFocused() then
				self:startRecording()
				self.recordPushButton:setOn()	
			elseif self.sampleList:isFocused() then
				local selectedSamplePath = "SamplesDefault/" .. selectedCategory .. "/" .. selectedSample
				if self.onSampleSelected ~= nil then self.onSampleSelected(self.track, selectedSample, selectedSamplePath) end
				self:dismiss()
			end
		end,
		AButtonUp = function()
			if self.recordPushButton:isFocused() then
				self.recordPushButton:setOff()
				self.recordPushButton:setFocus(false)
				self.recordPreviewButton:setFocus(true)
				self:stopRecording()
				self.aLabel:setText("Preview")
			end
		end,
		leftButtonDown = function()
			if self.recordSaveButton:isFocused() then
				self.recordSaveButton:setFocus(false)
				self.recordPreviewButton:setFocus(true)
			elseif self.sampleList:isFocused() then
				self.sampleList:setFocus(false)
				self.categoryList:setFocus(true)
				self.aLabel:setText("Sample ->")
			elseif self.categoryList:isFocused() then
				self.recordNewLabel:setAlpha(1.0)
				self.selectLabel:setAlpha(0.4)
				self.categoryList:setFocus(false)
				self.recordPushButton:setFocus(true)
				self.aLabel:setText("Record")
			end
		end,
		rightButtonDown = function()
			if self.recordPreviewButton:isFocused() then
				self.recordSaveButton:setFocus(true)
				self.recordPreviewButton:setFocus(false)
				self.aLabel:setText("Save")
			elseif self.recordPushButton:isFocused() then
				self.categoryList:setFocus(true)
				self.recordPushButton:setFocus(false)
				self.recordNewLabel:setAlpha(0.4)
				self.selectLabel:setAlpha(1.0)
				self.aLabel:setText("Sample ->")
			elseif self.categoryList:isFocused() then
				self.categoryList:setFocus(false)
				self.sampleList:setFocus(true)
				self.aLabel:setText("Select")
			elseif self.sampleList:isFocused() then
					self.sampleList:emitSelected()
			end
		end,
		upButtonDown = function()
			if self.recordSaveButton:isFocused() then
				self.recordSaveButton:setFocus(false)
				self.recordPushButton:setFocus(true)
			elseif self.recordPreviewButton:isFocused() then
				self.recordPreviewButton:setFocus(false)
				self.recordPushButton:setFocus(true)
			elseif self.categoryList:isFocused() then
				self.categoryList:goUp()
			elseif self.sampleList:isFocused() then
				self.sampleList:goUp()
			end
		end,
		downButtonDown = function()
			if self.categoryList:isFocused() then
				self.categoryList:goDown()
			elseif self.sampleList:isFocused() then
				self.sampleList:goDown()
			end
		end
	}
end