--!strict
-- src/App/AbilityCard.luau
-- Простой компонент карточки способности для магазина
-- Минималистичный дизайн с крупными элементами

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")

-- Конфигурация
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))

-- Типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type Ability = Types.Ability

-- Пропсы компонента
export type AbilityCardProps = {
	ability: Ability,
	isOwned: boolean?,
	canAfford: boolean?,
	onPurchase: (ability: Ability) -> (),
}

-- Компонент карточки способности
local AbilityCard = Roact.Component:extend("AbilityCard")

function AbilityCard:init()
	self.platformService = PlatformService.new()
	self.buttonRef = Roact.createRef()
	self.strokeRef = Roact.createRef()
	self.cardRef = Roact.createRef()
	
	-- Состояние hover
	self:setState({
		isHovered = false,
	})
end

-- Современные эффекты при наведении на карточку способности
function AbilityCard:onCardHover(isHovering: boolean)
	if self.platformService:isMobile() then return end
	
	self:setState({ isHovered = isHovering })
	
	-- Эффект для обводки
	if self.strokeRef.current then
		local targetTransparency = isHovering and 0.1 or 0.4
		local strokeTween = TweenService:Create(self.strokeRef.current,
			TweenInfo.new(ShopConfig.design.animations.duration, ShopConfig.design.animations.easing),
			{ Transparency = targetTransparency }
		)
		strokeTween:Play()
	end
	
	-- Плавный hover-эффект масштабирования карточки
	if self.cardRef.current then
		local targetScale = isHovering and 1.02 or 1.0
		local scaleTween = TweenService:Create(self.cardRef.current,
			TweenInfo.new(ShopConfig.design.animations.duration, ShopConfig.design.animations.easing),
			{ Size = UDim2.new(targetScale, 0, targetScale, 0) }
		)
		scaleTween:Play()
	end
end

-- Современные эффекты при взаимодействии с кнопкой
function AbilityCard:onButtonHover(isHovering: boolean)
	local button = self.buttonRef.current
	if button then
		local targetScale = isHovering and 1.05 or 1.0
		local targetTransparency = isHovering and 0.1 or 0.0
		
		local scaleTween = TweenService:Create(button,
			TweenInfo.new(ShopConfig.design.animations.duration, ShopConfig.design.animations.easing),
			{ 
				Size = UDim2.new(0, button.Size.X.Offset * targetScale, 0, button.Size.Y.Offset * targetScale),
				BackgroundTransparency = targetTransparency
			}
		)
		scaleTween:Play()
	end
end

function AbilityCard:onButtonPress()
	local button = self.buttonRef.current
	if button then
		-- Быстрый эффект нажатия
		local pressTween = TweenService:Create(button,
			TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
			{ Size = UDim2.new(0, button.Size.X.Offset * 0.95, 0, button.Size.Y.Offset * 0.95) }
		)
		pressTween:Play()
		
		-- Возвращение к нормальному размеру
		pressTween.Completed:Connect(function()
			local releaseTween = TweenService:Create(button,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
				{ Size = UDim2.new(0, button.Size.X.Offset / 0.95, 0, button.Size.Y.Offset / 0.95) }
			)
			releaseTween:Play()
		end)
	end
end

-- Получить состояние кнопки (унифицированное)
function AbilityCard:getButtonState(): (string, Color3, boolean)
	local isOwned = self.props.isOwned or false
	local canAfford = self.props.canAfford or true
	
	if isOwned then
		return ShopConfig.shop.buttons.owned, ShopConfig.design.colors.button.owned, false
	elseif not canAfford then
		return ShopConfig.shop.buttons.cantAfford, ShopConfig.design.colors.button.cantAfford, false
	else
		return ShopConfig.shop.buttons.buy, ShopConfig.design.colors.button.buy, true
	end
end

function AbilityCard:render()
	local ability = self.props.ability
	local isMobile = self.platformService:isMobile()
	
	-- Получаем конфигурацию
	local config = ShopConfig.getResponsiveConfig(isMobile)
	local dimensions = ShopConfig.getCardDimensions(isMobile)
	local colors = ShopConfig.design.colors
	local animations = ShopConfig.design.animations
	
	-- Получаем данные для отображения
	local buttonText, buttonColor, buttonEnabled = self:getButtonState()
	
	-- Используем размеры из конфигурации
	local cardHeight = dimensions.height
	local titleSize = config.typography.title
	local priceSize = config.typography.price
	local descSize = config.typography.description
	local buttonSize = isMobile and UDim2.new(0, 75, 0, dimensions.buttonHeight) or UDim2.new(0, 85, 0, dimensions.buttonHeight)
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundColor3 = ShopConfig.design.colors.background.card,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		[Roact.Ref] = self.cardRef,
		
		-- Современные события наведения
		[Roact.Event.MouseEnter] = function()
			self:onCardHover(true)
		end,
		[Roact.Event.MouseLeave] = function()
			self:onCardHover(false)
		end,
	}, {
		-- Современное скругление карточки
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.card),
		}),
		
		-- Современный градиент фона для способностей
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ShopConfig.design.colors.background.card),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(
					math.max(0, ShopConfig.design.colors.background.card.R * 255 - 15) / 255,
					math.max(0, ShopConfig.design.colors.background.card.G * 255 - 15) / 255,
					math.max(0, ShopConfig.design.colors.background.card.B * 255 - 15) / 255
				)),
			}),
			Rotation = 180,
		}),
		
		-- Современная светящаяся обводка способности
		UIStroke = Roact.createElement("UIStroke", {
			Color = ShopConfig.design.colors.accent.primary,
			Thickness = ShopConfig.design.stroke.thickness,
			Transparency = 0.4,
			[Roact.Ref] = self.strokeRef,
		}),
		
		-- Современная тень для глубины
		Shadow = Roact.createElement("Frame", {
			Size = UDim2.new(1, ShopConfig.design.shadow.offset.x * 2, 1, ShopConfig.design.shadow.offset.y * 2),
			Position = UDim2.new(0, ShopConfig.design.shadow.offset.x, 0, ShopConfig.design.shadow.offset.y),
			BackgroundColor3 = ShopConfig.design.shadow.color,
			BackgroundTransparency = ShopConfig.design.shadow.transparency,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.card),
			}),
		}),
		
		-- Основная информация о способности (центрированная)
		AbilityInfo = Roact.createElement("Frame", {
			Size = UDim2.new(1, -100, 1, -config.spacing.gaps.medium), -- Используем конфиг
			Position = UDim2.new(0, config.spacing.padding.medium, 0, config.spacing.gaps.small),
			BackgroundTransparency = 1,
		}, {
			-- Название способности (современная типографика)
			AbilityName = Roact.createElement("TextLabel", {
				Text = ability.name,
				Size = UDim2.new(1, 0, 0, titleSize + 2),
				Position = UDim2.new(0, 0, 0, 8),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.primary,
				TextSize = titleSize,
				Font = ShopConfig.design.colors.text.fonts.bold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			
			-- Цена способности (с золотым акцентом)
			AbilityPrice = Roact.createElement("TextLabel", {
				Text = "💰 " .. ability.price .. " монет",
				Size = UDim2.new(1, 0, 0, priceSize + 2),
				Position = UDim2.new(0, 0, 0, titleSize + 10),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.accent,
				TextSize = priceSize,
				Font = ShopConfig.design.colors.text.fonts.bold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			
			-- Описание способности (современная типографика)
			AbilityDescription = Roact.createElement("TextLabel", {
				Text = ability.description,
				Size = UDim2.new(1, 0, 0, descSize + 6),
				Position = UDim2.new(0, 0, 0, titleSize + priceSize + 15),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.secondary,
				TextSize = descSize,
				Font = ShopConfig.design.colors.text.fonts.regular,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
		
		-- Современная кнопка покупки с эффектами
		PurchaseButton = Roact.createElement("TextButton", {
			Text = buttonText,
			Size = buttonSize,
			Position = UDim2.new(1, -buttonSize.X.Offset - 8, 0.5, -buttonSize.Y.Offset / 2),
			BackgroundColor3 = buttonColor,
			BackgroundTransparency = buttonEnabled and 0 or 0.3,
			BorderSizePixel = 0,
			TextColor3 = ShopConfig.design.colors.text.button,
			TextSize = isMobile and 12 or 13,
			Font = ShopConfig.design.colors.text.fonts.bold,
			AutoButtonColor = false,
			Modal = true, -- Отключаем стандартные звуки Roblox
			[Roact.Ref] = self.buttonRef,
			
			-- Современные события кнопки
			[Roact.Event.MouseEnter] = (not isMobile and buttonEnabled) and function()
				self:onButtonHover(true)
			end or nil,
			[Roact.Event.MouseLeave] = (not isMobile and buttonEnabled) and function()
				self:onButtonHover(false)
			end or nil,
			[Roact.Event.MouseButton1Down] = buttonEnabled and function()
				self:onButtonPress()
			end or nil,
			[Roact.Event.Activated] = buttonEnabled and function()
				if self.props.onPurchase then
					self.props.onPurchase(ability)
				end
			end or nil,
		}, {
			-- Современное скругление кнопки
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.button),
			}),
			
			-- Светящаяся обводка кнопки
			UIStroke = buttonEnabled and Roact.createElement("UIStroke", {
				Color = buttonColor,
				Thickness = ShopConfig.design.stroke.thickness,
				Transparency = 0.6,
			}) or nil,
			
			-- Современный градиент кнопки
			UIGradient = buttonEnabled and Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, buttonColor),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(
						math.max(0, buttonColor.R * 255 - 25) / 255,
						math.max(0, buttonColor.G * 255 - 25) / 255,
						math.max(0, buttonColor.B * 255 - 25) / 255
					)),
				}),
				Rotation = 90,
			}) or nil,
			
			-- Современная тень кнопки
			ButtonShadow = Roact.createElement("Frame", {
				Size = UDim2.new(1, ShopConfig.design.shadow.offset.x * 2, 1, ShopConfig.design.shadow.offset.y * 2),
				Position = UDim2.new(0, ShopConfig.design.shadow.offset.x, 0, ShopConfig.design.shadow.offset.y),
				BackgroundColor3 = buttonColor,
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.button),
				}),
			}),
		}),
	})
end

return AbilityCard

