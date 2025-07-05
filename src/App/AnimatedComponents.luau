--!strict
-- src/App/AnimatedComponents.luau
-- Roact компоненты с встроенными анимациями
-- HOC (Higher-Order Components) для легкой интеграции анимаций

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local AnimationService = ModuleLoader.require("services/AnimationService")

local AnimatedComponents = {}

-- Анимированная кнопка с автоматическими эффектами hover/press
local AnimatedButton = Roact.Component:extend("AnimatedButton")

function AnimatedButton:init()
	self.animationService = AnimationService.new()
	self.buttonRef = Roact.createRef()
	
	self.state = {
		isHovered = false,
		isPressed = false,
	}
end

function AnimatedButton:didMount()
	local button = self.buttonRef:getValue()
	if not button then return end
	
	-- Начальная анимация появления
	if self.props.animateOnMount ~= false then
		self.animationService:tweenElement(button, "FADE_IN")
	end
end

function AnimatedButton:onMouseEnter()
	if self.state.isPressed then return end
	
	self:setState({ isHovered = true })
	
	local button = self.buttonRef:getValue()
	if button then
		self.animationService:animateButtonHover(button)
	end
	
	if self.props.onMouseEnter then
		self.props.onMouseEnter()
	end
end

function AnimatedButton:onMouseLeave()
	self:setState({ isHovered = false })
	
	local button = self.buttonRef:getValue()
	if button and not self.state.isPressed then
		self.animationService:animateButtonRelease(button)
	end
	
	if self.props.onMouseLeave then
		self.props.onMouseLeave()
	end
end

function AnimatedButton:onMouseDown()
	self:setState({ isPressed = true })
	
	local button = self.buttonRef:getValue()
	if button then
		self.animationService:animateButtonPress(button)
	end
	
	if self.props.onMouseDown then
		self.props.onMouseDown()
	end
end

function AnimatedButton:onMouseUp()
	self:setState({ isPressed = false })
	
	local button = self.buttonRef:getValue()
	if button then
		if self.state.isHovered then
			self.animationService:animateButtonHover(button)
		else
			self.animationService:animateButtonRelease(button)
		end
	end
	
	if self.props.onMouseUp then
		self.props.onMouseUp()
	end
end

function AnimatedButton:onClick()
	-- Дополнительная анимация при клике
	local button = self.buttonRef:getValue()
	if button and self.props.clickAnimation ~= false then
		-- Краткая вспышка или пульсация
		self.animationService:tweenCustom(button, {
			BackgroundColor3 = self.props.clickColor or Color3.fromRGB(255, 255, 255)
		}, "QUICK", function()
			self.animationService:tweenCustom(button, {
				BackgroundColor3 = self.props.BackgroundColor3 or Color3.fromRGB(70, 120, 200)
			}, "QUICK")
		end)
	end
	
	if self.props.onClick then
		self.props.onClick()
	end
end

function AnimatedButton:render()
	local props = self.props
	
	return Roact.createElement("TextButton", {
		[Roact.Ref] = self.buttonRef,
		
		-- Основные свойства
		Size = props.Size or UDim2.new(0, 100, 0, 40),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(70, 120, 200),
		BackgroundTransparency = props.BackgroundTransparency or 0,
		BorderSizePixel = props.BorderSizePixel or 0,
		
		-- Текст
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or Color3.fromRGB(255, 255, 255),
		TextSize = props.TextSize or 18,
		Font = props.Font or Enum.Font.GothamBold,
		
		-- Отключаем стандартные эффекты Roblox
		AutoButtonColor = false,
		
		-- События
		[Roact.Event.MouseEnter] = function() self:onMouseEnter() end,
		[Roact.Event.MouseLeave] = function() self:onMouseLeave() end,
		[Roact.Event.MouseButton1Down] = function() self:onMouseDown() end,
		[Roact.Event.MouseButton1Up] = function() self:onMouseUp() end,
		[Roact.Event.MouseButton1Click] = function() self:onClick() end,
	}, props[Roact.Children])
end

-- Анимированная панель с эффектами появления/исчезновения
local AnimatedPanel = Roact.Component:extend("AnimatedPanel")

function AnimatedPanel:init()
	self.animationService = AnimationService.new()
	self.panelRef = Roact.createRef()
	
	self.state = {
		visible = self.props.visible ~= false,
		animating = false,
	}
end

function AnimatedPanel:didMount()
	local panel = self.panelRef:getValue()
	if not panel then return end
	
	if self.state.visible then
		-- Анимация появления при монтировании
		local animationType = self.props.enterAnimation or "FADE_IN"
		self.animationService:tweenElement(panel, animationType)
	else
		-- Скрываем сразу если не видимая
		panel.Visible = false
	end
end

function AnimatedPanel:didUpdate(prevProps)
	if self.props.visible ~= prevProps.visible then
		self:animateVisibilityChange()
	end
end

function AnimatedPanel:animateVisibilityChange()
	local panel = self.panelRef:getValue()
	if not panel or self.state.animating then return end
	
	self:setState({ animating = true })
	
	if self.props.visible then
		-- Показываем панель
		panel.Visible = true
		local animationType = self.props.enterAnimation or "SHOP_OPEN"
		
		self.animationService:tweenElement(panel, animationType, function()
			self:setState({ 
				visible = true,
				animating = false,
			})
			
			if self.props.onEnterComplete then
				self.props.onEnterComplete()
			end
		end)
	else
		-- Скрываем панель
		local animationType = self.props.exitAnimation or "SHOP_CLOSE"
		
		self.animationService:tweenElement(panel, animationType, function()
			panel.Visible = false
			self:setState({ 
				visible = false,
				animating = false,
			})
			
			if self.props.onExitComplete then
				self.props.onExitComplete()
			end
		end)
	end
end

function AnimatedPanel:render()
	local props = self.props
	
	return Roact.createElement("Frame", {
		[Roact.Ref] = self.panelRef,
		
		Size = props.Size or UDim2.new(0, 400, 0, 300),
		Position = props.Position or UDim2.new(0.5, -200, 0.5, -150),
		BackgroundColor3 = props.BackgroundColor3 or Color3.fromRGB(28, 28, 30),
		BackgroundTransparency = props.BackgroundTransparency or 0.05,
		BorderSizePixel = props.BorderSizePixel or 0,
		Visible = props.visible ~= false,
	}, props[Roact.Children])
end

-- Анимированный список с stagger эффектом
local AnimatedList = Roact.Component:extend("AnimatedList")

function AnimatedList:init()
	self.animationService = AnimationService.new()
	self.itemRefs = {}
	
	self.state = {
		animatedItems = {},
	}
end

function AnimatedList:didMount()
	-- Анимируем элементы с задержкой
	if self.props.staggerAnimation ~= false then
		self:animateItems()
	end
end

function AnimatedList:didUpdate(prevProps)
	-- Если изменился список элементов, анимируем новые
	if self.props.items ~= prevProps.items then
		self:animateItems()
	end
end

function AnimatedList:animateItems()
	spawn(function()
		wait(0.1) -- Небольшая задержка для рендеринга
		
		local elements = {}
		for i, ref in ipairs(self.itemRefs) do
			local element = ref:getValue()
			if element then
				table.insert(elements, element)
			end
		end
		
		if #elements > 0 then
			local animationType = self.props.itemAnimation or "SLIDE_IN_LEFT"
			local staggerDelay = self.props.staggerDelay or 0.1
			
			self.animationService:animateStagger(elements, animationType, staggerDelay, function()
				if self.props.onAnimationComplete then
					self.props.onAnimationComplete()
				end
			end)
		end
	end)
end

function AnimatedList:render()
	local props = self.props
	local items = props.items or {}
	
	-- Очищаем старые рефы
	self.itemRefs = {}
	
	local children = {}
	
	for i, item in ipairs(items) do
		local itemRef = Roact.createRef()
		table.insert(self.itemRefs, itemRef)
		
		children["Item" .. i] = Roact.createElement("Frame", {
			[Roact.Ref] = itemRef,
			Size = props.itemSize or UDim2.new(1, 0, 0, 50),
			Position = UDim2.new(0, 0, 0, (i - 1) * (props.itemSpacing or 60)),
			BackgroundTransparency = 1,
		}, {
			Content = props.renderItem and props.renderItem(item, i) or nil
		})
	end
	
	return Roact.createElement("Frame", {
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
	}, children)
end

-- HOC для добавления анимаций к любому компоненту
function AnimatedComponents.withAnimation(Component, defaultAnimations)
	defaultAnimations = defaultAnimations or {}
	
	local WrappedComponent = Roact.Component:extend("AnimatedWrapper")
	
	function WrappedComponent:init()
		self.animationService = AnimationService.new()
		self.elementRef = Roact.createRef()
	end
	
	function WrappedComponent:didMount()
		local element = self.elementRef:getValue()
		if element and self.props.enterAnimation then
			self.animationService:tweenElement(element, self.props.enterAnimation)
		end
	end
	
	function WrappedComponent:playAnimation(animationType: string, onComplete: (() -> ())?)
		local element = self.elementRef:getValue()
		if element then
			self.animationService:tweenElement(element, animationType, onComplete)
		end
	end
	
	function WrappedComponent:render()
		return Roact.createElement(Component, Roact.joinDictionaries(self.props, {
			[Roact.Ref] = self.elementRef,
			playAnimation = function(animationType, onComplete)
				self:playAnimation(animationType, onComplete)
			end,
		}))
	end
	
	return WrappedComponent
end

AnimatedComponents.Button = AnimatedButton
AnimatedComponents.Panel = AnimatedPanel
AnimatedComponents.List = AnimatedList

return AnimatedComponents
