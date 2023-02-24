class('Switch').extends(playdate.graphics.sprite)

--todo - this is implementation specific, it's not reusable at all
function Switch:init(x, y, text, active)
	Switch.super.init(self)
	self.label = Label(x - 19, y + 10, text, font)
	self.label:setOpacity(0.2)
	
	self.active = active
	self.hasFocus = false
	
	--focus image
	local focusWidth = 48
	local focusHeight = 57
	local focusedImage = playdate.graphics.image.new(focusWidth, focusHeight)
	playdate.graphics.pushContext(focusedImage)
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	playdate.graphics.setDitherPattern(0.0, playdate.graphics.image.kDitherTypeBayer8x8)
	playdate.graphics.setLineWidth(2)
	playdate.graphics.drawRoundRect(1, 1, focusWidth - 2, focusHeight - 2, 5) 
	playdate.graphics.setLineWidth(1)
	playdate.graphics.popContext()
	self.focusedSprite = playdate.graphics.sprite.new(focusedImage)
	self.focusedSprite:moveTo(x - focusWidth/2 + 3, y + focusHeight/2 + 15)
	self.focusedSprite:add()
	self.focusedSprite:setVisible(false)
	
	--active image
	playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	local activeImage = playdate.graphics.image.new(45, 30)
	playdate.graphics.pushContext(activeImage)
		local offImage = playdate.graphics.image.new(25, 8)
		playdate.graphics.pushContext(offImage)
			playdate.graphics.drawText("OFF", 0, 0)
		playdate.graphics.popContext()
		offImage:drawFaded(7, 10, 0.4, playdate.graphics.image.kDitherTypeBayer2x2)
	playdate.graphics.popContext()
	
	self:setImage(activeImage)
	self:moveTo(x - 16, y + 45)
	
	
	--inactive image
	
	self:add()
end

function Switch:tap()
	
	if self.active then
		print("Switch is active, turning off")
		--make inactive
		playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
		playdate.graphics.setColor(playdate.graphics.kColorWhite)
		local inactive = playdate.graphics.image.new(45, 30)
		playdate.graphics.pushContext(inactive)
		local offImage = playdate.graphics.image.new(25, 8)
		playdate.graphics.pushContext(offImage)
			playdate.graphics.drawText("OFF", 0, 0)
		playdate.graphics.popContext()
		offImage:drawFaded(7, 10, 0.4, playdate.graphics.image.kDitherTypeBayer2x2)
		playdate.graphics.popContext()
		self:setImage(inactive)
		self.active = false
	else
		print("Switch is inactive, turning on")
		--make active
		local active = playdate.graphics.image.new(30, 8)
		active:clear(playdate.graphics.kDrawModeFillBlack)
		playdate.graphics.pushContext(active)
		playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
		playdate.graphics.setColor(playdate.graphics.kColorWhite)
			playdate.graphics.drawText("ON", 2, 0)
		playdate.graphics.popContext()
		self:setImage(active)
		self.active = true
		
	end
end

function Switch:setFocus(focus)
	self.hasFocus = focus
	self.focusedSprite:setVisible(focus)
	self:update()
end
	