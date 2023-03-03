class('TrackRecordButtons').extends(playdate.graphics.sprite)
 
function TrackRecordButtons:init(w, h, x, y, onChange)
	TrackRecordButtons.super.init(self)
	
	self.w = w
	self.h = h
	self.steps = 1
	self.onChange = onChange
	
	self.trackNames = {}
	
	self.activeTrack = 1
	self.activeStep = 1

	local gridImage = playdate.graphics.image.new(w, h)
	self:setImage(gridImage)
	self:moveTo(x + (w/2), y + (h/2))
	self:add()
end

function TrackRecordButtons:load(tracks)
	
	for r=1,#tracks do
		self.trackNames[r] = tracks[r].name
	end
	
	self.cellWidth = self.w/self.steps
	self.cellHeight = self.h/#tracks
	
	self:redrawGrid()
	
	--Focus caret
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	local focusImage = playdate.graphics.image.new(self.cellWidth+8, self.cellHeight+8)
	playdate.graphics.pushContext(focusImage)
		playdate.graphics.setLineWidth(2)
		playdate.graphics.drawRoundRect(2, 2, self.cellWidth+4, self.cellHeight+4, 4)
	playdate.graphics.popContext()
	self.focusSprite = playdate.graphics.sprite.new(focusImage)
	self.focusSprite:moveTo(self.x - self.w/2 + self.cellWidth/2, self.y - self.h/2 + self.cellHeight/2)
	self.focusSprite:add()
	self.focusSprite:setVisible(false)
	self:drawFocused()
end

function TrackRecordButtons:redrawGrid()
	local hMargin = self.cellWidth/2
	local vMargin = self.cellHeight/2
	playdate.graphics.pushContext(self:getImage())
		playdate.graphics.clear(playdate.graphics.kColorBlack)
		for row = 1, #self.trackNames do
				local cX = hMargin + (0) * self.cellWidth
				local cY = vMargin + (row - 1) * self.cellHeight

				playdate.graphics.setColor(playdate.graphics.kColorWhite)
				playdate.graphics.setDitherPattern(0.9, playdate.graphics.image.kDitherTypeScreen)
				if row < 10 then
					playdate.graphics.drawText("0"..row, cX - (self.cellWidth/2) + 2 , cY - (self.cellHeight/2) + 2)
				else
					playdate.graphics.drawText(""..row, cX - (self.cellWidth/2) + 2 , cY - (self.cellHeight/2) + 2)
				end
				
		end
	playdate.graphics.popContext()
end

function TrackRecordButtons:goUp()
	if self.activeTrack > 1 then
		self.activeTrack -= 1
	else
		self.activeTrack = #self.trackNames
	end	
	self:drawFocused()

end

function TrackRecordButtons:goDown()
	if self.activeTrack < #self.trackNames then
		self.activeTrack += 1
	else
		self.activeTrack = 1
	end
	self:drawFocused()
end

function TrackRecordButtons: getCurrentTrack()
	return self.activeTrack
end

function TrackRecordButtons:drawFocused()
	self.focusSprite:moveTo(
		self.x - self.w/2 + (self.cellWidth * self.activeStep) - self.cellWidth/2, 
		self.y - self.h/2 + (self.cellHeight * self.activeTrack) - self.cellHeight/2)
	self.onChange(self.activeTrack, false)
end

function TrackRecordButtons:tap()
	self:redrawGrid()
	self.onChange(self.activeTrack, true)
end

function TrackRecordButtons:canGoDown()
	return true
end

function TrackRecordButtons:canGoUp()
	return true
end

function TrackRecordButtons:setFocus(focus)
	if self.focusSprite ~= nil then self.focusSprite:setVisible(focus) end
end