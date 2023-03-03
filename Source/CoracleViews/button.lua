import 'CoracleViews/label_centre'

class('Button').extends()

function Button:init(label, pressedLabel, xx, yy, w, h, listener)
	Button.super.init(self)
	
	self.hasFocus = false
	
	self.listener = listener
	
	self.label = LabelCentre(label, xx, yy, 0.4)
	
	self.onSprite = nil
	if pressedLabel ~= nil then
		local onImage = playdate.graphics.image.new(w, h)
		playdate.graphics.pushContext(onImage)
		playdate.graphics.setColor(playdate.graphics.kColorWhite)
		playdate.graphics.fillRoundRect(2, 2, w - 6, h - 6, 5) 
		playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
		local font = playdate.graphics.getFont()
		local recWidth = font:getTextWidth(pressedLabel)
		playdate.graphics.drawText(pressedLabel, (w - recWidth)/2, (h - 8)/2)
		playdate.graphics.popContext()
		self.onSprite = playdate.graphics.sprite.new(onImage)
		self.onSprite:moveTo(xx, yy +8)
		self.onSprite:add()
		self.onSprite:setVisible(false)
	end
	
	local focusedImage = playdate.graphics.image.new(w + 6, h + 6)
	playdate.graphics.pushContext(focusedImage)
	playdate.graphics.setColor(playdate.graphics.kColorWhite)
	playdate.graphics.setLineWidth(2)
	playdate.graphics.drawRoundRect(1, 1, w + 3, h + 3, 5) 
	playdate.graphics.setLineWidth(1)
	playdate.graphics.popContext()
	self.focusedSprite = playdate.graphics.sprite.new(focusedImage)
	self.focusedSprite:moveTo(xx, yy +8)
	self.focusedSprite:add()
	self.focusedSprite:setVisible(false)
end

function Button:removeAll()
	self.label:remove()
	self.focusedSprite:remove()
	if self.onSprite ~= nil then self.onSprite:remove() end
end

function Button:setOn()
	print("Button:setOn()")
	self.onSprite:setVisible(true)
end

function Button:setOff()
	print("Button:setOff()")
	self.onSprite:setVisible(false)
end

function Button:isFocused()
	return self.hasFocus
end

function Button:setFocus(focus)
	self.hasFocus = focus
	self.focusedSprite:setVisible(focus)
	
	if focus then
		self.label:setAlpha(1)
	else
		self.label:setAlpha(0.4)
	end
end

function Button:tap()	
	self.focusedSprite:moveBy(0, 1)
	playdate.timer.new(200, function()
		self.focusedSprite:moveBy(0, -1)
		if self.listener ~= nil then self.listener() end
	end)
end
