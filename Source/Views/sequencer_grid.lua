class('SequencerGrid').extends(playdate.graphics.sprite)
 
function SequencerGrid:init(w, h, x, y, steps, onChange)
	SequencerGrid.super.init(self)
	
	self.w = w
	self.h = h
	self.steps = steps
	self.onChange = onChange
	
	self.activeTrack = 1
	self.activeStep = 1

	local gridImage = playdate.graphics.image.new(w, h)
	self:setImage(gridImage)
	self:moveTo(x + (w/2), y + (h/2))
	self:add()
	
	local focusImage = playdate.graphics.image.new(5, 5)
	self.focusSprite = playdate.graphics.sprite.new(focusImage)
	self.focusSprite:moveTo(0, 0)
	self.focusSprite:add()
end

function SequencerGrid:load(tracks)
	--self.data[self.activeTrack][self.activeStep] = 0
	self.data = {}
	self.trackNames = {}
	
	--for each sample/track
	for r=1,#tracks do
		local track = tracks[r]
		local pattern = track.pattern
		local values = {}
		for v=1, #pattern do
			values[v] = pattern[v]
		end
		table.insert(self.data, values)
		table.insert(self.trackNames, tracks[r].name)
	end
	
	self.cellWidth = self.w/self.steps
	self.cellHeight = self.h/#tracks
	
	self:redrawGrid()
	
	--Focus caret
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	local focusImage = playdate.graphics.image.new(self.cellWidth+8, self.cellHeight+8)
	playdate.graphics.pushContext(focusImage)
		playdate.graphics.setLineWidth(2)
		playdate.graphics.drawRoundRect(2, 2, self.cellWidth+4, self.cellHeight+4, 5)
	playdate.graphics.popContext()
	self.focusSprite:setImage(focusImage)
	self.focusSprite:moveTo(self.x - self.w/2 + self.cellWidth/2, self.y - self.h/2 + self.cellHeight/2)
	
	self:drawFocused()
end

function SequencerGrid:redrawGrid()
	local hMargin = self.cellWidth/2
	local vMargin = self.cellHeight/2
	playdate.graphics.pushContext(self:getImage())
		playdate.graphics.clear(playdate.graphics.kColorBlack)
		for row = 1, #self.data do
			for column = 1, self.steps do
				local cX = hMargin + (column - 1) * self.cellWidth
				local cY = vMargin + (row - 1) * self.cellHeight
				
				local value = self.data[row][column]
				playdate.graphics.setColor(playdate.graphics.kColorWhite)
				if(value == 0)then
					playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeScreen)
					playdate.graphics.fillRect(cX-2, cY-2, 4, 4)
				else
					--There's method in this madness, rather than just value/10 I'm switching dither pattern based on aesthetics
					--Reverse order to short-circuit and save some cycles with the most likely values:
					if value == -1 then
						playdate.graphics.setColor(playdate.graphics.kColorWhite)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, 2, self.cellHeight)
					elseif value == 10 then
						playdate.graphics.setDitherPattern(0.0, playdate.graphics.image.kDitherTypeBayer8x8)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 9 then
						playdate.graphics.setDitherPattern(0.1, playdate.graphics.image.kDitherTypeDiagonalLine)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 8 then
						playdate.graphics.setDitherPattern(0.2, playdate.graphics.image.kDitherTypeScreen)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 7 then
						playdate.graphics.setDitherPattern(0.3, playdate.graphics.image.kDitherTypeDiagonalLine)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 6 then
						playdate.graphics.setDitherPattern(0.4, playdate.graphics.image.kDitherTypeBayer8x8)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 5 then
						playdate.graphics.setDitherPattern(0.5, playdate.graphics.image.kDitherTypeBayer4x4)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 4 then
						playdate.graphics.setDitherPattern(0.6, playdate.graphics.image.kDitherTypeBayer4x4)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 3 then
						playdate.graphics.setDitherPattern(0.7, playdate.graphics.image.kDitherTypeDiagonalLine)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 2 then
						playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeScreen)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					elseif value == 1 then
						playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeBayer8x8)
						playdate.graphics.fillRect(cX - self.cellWidth/2, cY - self.cellHeight/2, self.cellWidth, self.cellHeight)
					end
				end
			end
		end
	playdate.graphics.popContext()
end

function SequencerGrid:goLeft()
	if self.activeStep > 1 then
		self.activeStep -= 1
	else
		self.activeStep = self.steps
	end
	
	self:drawFocused()
end

function SequencerGrid:goRight()
	if self.activeStep < self.steps then
		self.activeStep += 1
	else
		self.activeStep = 1
	end
	
	self:drawFocused()
end

function SequencerGrid:goUp()
	if self.activeTrack > 1 then
		self.activeTrack -= 1
	else
		self.activeTrack = #self.data
	end
	
	self:drawFocused()
end

function SequencerGrid:goDown()
	if self.activeTrack < #self.data then
		self.activeTrack += 1
	else
		self.activeTrack = 1
	end
	
	self:drawFocused()
end

function SequencerGrid:toggleValue()
	if self.data[self.activeTrack][self.activeStep] > 0 then
		self.data[self.activeTrack][self.activeStep] = 0
	else
		self.data[self.activeTrack][self.activeStep] = 10
	end
	
	self:redrawGrid()
	self:callListener()
end

function SequencerGrid:valueUp()
	if self.data[self.activeTrack][self.activeStep] < 10 then
		self.data[self.activeTrack][self.activeStep] += 1
		self:redrawGrid()
		self:callListener()
	end
end

function SequencerGrid:valueDown()
	if self.data[self.activeTrack][self.activeStep] > -1 then
		self.data[self.activeTrack][self.activeStep] -= 1
		self:redrawGrid()
		self:callListener()
	end
end

function SequencerGrid:drawFocused()
	self.focusSprite:moveTo(
		self.x - self.w/2 + (self.cellWidth * self.activeStep) - self.cellWidth/2, 
		self.y - self.h/2 + (self.cellHeight * self.activeTrack) - self.cellHeight/2)
		self:callListener()
end

function SequencerGrid:setFocus(focus)
	self.hasFocus = focus
	self.focusSprite:setVisible(focus)
end

function SequencerGrid:getTrackName(index)
	return self.trackNames[index]
end

function SequencerGrid:callListener()
	local name = self.trackNames[self.activeTrack]
	if name == nil then name = "???" end
	self.onChange(self.activeTrack, self.activeStep, self.data[self.activeTrack][self.activeStep], name)
end