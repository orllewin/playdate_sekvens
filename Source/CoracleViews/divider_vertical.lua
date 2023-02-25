class('DividerVertical').extends(playdate.graphics.sprite)

function DividerVertical:init(x, y, height, alpha)
	DividerVertical.super.init(self)
	local dividerImage = playdate.graphics.image.new(3, height)
	playdate.graphics.pushContext(dividerImage)
	local lineImage = playdate.graphics.image.new(3, height)
	playdate.graphics.pushContext(lineImage)
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	playdate.graphics.setLineWidth(1)
	playdate.graphics.drawLine(1, 0, 1, height) 
	playdate.graphics.popContext()
	
	if alpha == nil then
		lineImage:draw(0, 0)
	else
		lineImage:drawFaded(0, 0, alpha, playdate.graphics.image.kDitherTypeHorizontalLine)
	end
			
	playdate.graphics.popContext()
	self:setImage(dividerImage)
	self:moveTo(x, y + (height/2))
	self:add()
end