class('LoopLine').extends(playdate.graphics.sprite)

function LoopLine:init(x, y, width, height)
	LoopLine.super.init(self)
	self.x = x
	self.y = y
	self.width = width
	self.height = height
end

function LoopLine:update(step)
	local x = map(step, 1, 16, 0, self.width)
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	playdate.graphics.setDitherPattern(0.5, playdate.graphics.image.kDitherTypeBayer2x2)
	playdate.graphics.drawLine(x + self.x, self.y, x + self.x, self.y + self.height)
end