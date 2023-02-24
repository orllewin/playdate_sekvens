class('MuteToggle').extends(playdate.graphics.sprite)
 
function MuteToggle:init(w, h, x, y, onChange)
	MuteToggle.super.init(self)
	
	self.w = w
	self.h = h
	self.steps = 1
	self.onChange = onChange
	
	self.tracks = {}
	
	self.activeTrack = 1
	self.activeStep = 1

	local gridImage = playdate.graphics.image.new(w, h)
	self:setImage(gridImage)
	self:moveTo(x + (w/2), y + (h/2))
	self:add()
end

function MuteToggle:load(tracks)
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
		table.insert(self.data, values)--todo - can we just use index here?
		table.insert(self.trackNames, tracks[r].name)--todo - can we just use index here?
		self.tracks[r] = false
	end
	
	self.cellWidth = self.w/self.steps
	self.cellHeight = self.h/#tracks
	
	self:redrawGrid()
	
	--Focus caret
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	local focusImage = playdate.graphics.image.new(self.cellWidth+8, self.cellHeight+8)
	playdate.graphics.pushContext(focusImage)
		playdate.graphics.setLineWidth(2)
		playdate.graphics.drawRect(2, 2, self.cellWidth+4, self.cellHeight+4)
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
		for row = 1, #self.data do
			for column = 1, self.steps do
				local cX = hMargin + (column - 1) * self.cellWidth
				local cY = vMargin + (row - 1) * self.cellHeight
				
				local value = self.data[row][column]
				playdate.graphics.setColor(playdate.graphics.kColorWhite)
				if(self.tracks[row] == false)then
					--NOT muted
					playdate.graphics.setDitherPattern(0.8, playdate.graphics.image.kDitherTypeScreen)
					playdate.graphics.fillRect(cX - (self.cellWidth/2) + 2 , cY - (self.cellHeight/2) + 2, self.cellWidth-4, self.cellHeight-4)
				else
					--MUTED
					playdate.graphics.setColor(playdate.graphics.kColorWhite)
					playdate.graphics.fillRect(cX - (self.cellWidth/2) + 2 , cY - (self.cellHeight/2) + 2, self.cellWidth-4, self.cellHeight-4)
				end
			end
		end
	playdate.graphics.popContext()
end

function MuteToggle:goUp()
	if self.activeTrack > 1 then
		self.activeTrack -= 1
	else
		self.activeTrack = #self.data
	end	
	self:drawFocused()

end

function MuteToggle:goDown()
	if self.activeTrack < #self.data then
		self.activeTrack += 1
	else
		self.activeTrack = 1
	end
	self:drawFocused()
end

function MuteToggle:drawFocused()
	self.focusSprite:moveTo(
		self.x - self.w/2 + (self.cellWidth * self.activeStep) - self.cellWidth/2, 
		self.y - self.h/2 + (self.cellHeight * self.activeTrack) - self.cellHeight/2)
	self.onChange(self.activeTrack, self.tracks[self.activeTrack], false)
end

function MuteToggle:tap()
	self.tracks[self.activeTrack] = not self.tracks[self.activeTrack]
	self:redrawGrid()
	self.onChange(self.activeTrack, self.tracks[self.activeTrack], true)
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