class('MuteToggle').extends(playdate.graphics.sprite)
 
function MuteToggle:init(w, h, x, y, onChange)
	MuteToggle.super.init(self)
	
	self.w = w
	self.h = h
	self.steps = 1
	self.onChange = onChange
	
	self.tracksMuted = {}
	self.trackNames = {}
	
	self.activeTrack = 1

	local gridImage = playdate.graphics.image.new(w, h)
	self:setImage(gridImage)
	self:moveTo(x + (w/2), y + (h/2))
	self:add()
end

function MuteToggle:load(tracks)
	
	for r=1,#tracks do
		self.trackNames[r] = tracks[r].name
		self.tracksMuted[r] = false
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

function MuteToggle:redrawGrid()
	local hMargin = self.cellWidth/2
	local vMargin = self.cellHeight/2
	playdate.graphics.pushContext(self:getImage())
		playdate.graphics.clear(playdate.graphics.kColorBlack)
		for row = 1, #self.tracksMuted do
				local cX = hMargin + (0) * self.cellWidth
				local cY = vMargin + (row - 1) * self.cellHeight

				playdate.graphics.setColor(playdate.graphics.kColorWhite)
				if(self.tracksMuted[row] == false)then
					--NOT muted
					playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeScreen)
					playdate.graphics.fillRect(cX - (self.cellWidth/2) + 2 , cY - (self.cellHeight/2) + 2, self.cellWidth-4, self.cellHeight-4)
				else
					--MUTED
					playdate.graphics.setColor(playdate.graphics.kColorWhite)
					playdate.graphics.fillRect(cX - (self.cellWidth/2) + 2 , cY - (self.cellHeight/2) + 2, self.cellWidth-4, self.cellHeight-4)
				end
		end
	playdate.graphics.popContext()
end

function MuteToggle:goUp()
	if self.activeTrack > 1 then
		self.activeTrack -= 1
	else
		self.activeTrack = #self.tracksMuted
	end	
	self:drawFocused()

end

function MuteToggle:goDown()
	if self.activeTrack < #self.tracksMuted then
		self.activeTrack += 1
	else
		self.activeTrack = 1
	end
	self:drawFocused()
end

function MuteToggle:drawFocused()
	self.focusSprite:moveTo(
		self.x - self.w/2 + (self.cellWidth) - self.cellWidth/2, 
		self.y - self.h/2 + (self.cellHeight * self.activeTrack) - self.cellHeight/2)
	self.onChange(self.activeTrack, self.tracksMuted[self.activeTrack], false)
end

function MuteToggle:tap()
	self.tracksMuted[self.activeTrack] = not self.tracksMuted[self.activeTrack]
	self:redrawGrid()
	self.onChange(self.activeTrack, self.tracksMuted[self.activeTrack], true)
end

function MuteToggle:canGoDown()
	return true
end

function MuteToggle:canGoUp()
	return true
end

function MuteToggle:setFocus(focus)
	if self.focusSprite ~= nil then self.focusSprite:setVisible(focus) end
end