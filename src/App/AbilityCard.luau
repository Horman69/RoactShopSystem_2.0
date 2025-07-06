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
	
	-- Состояние hover
	self:setState({
		isHovered = false,
	})
end

-- Изменение цвета рамки при hover
function AbilityCard:onCardHover(isHovering: boolean)
	if self.platformService:isMobile() then return end
	
	self:setState({ isHovered = isHovering })
	
	if self.strokeRef.current then
		local colors = ShopConfig.design.colors
		local animations = ShopConfig.design.animations
		local hoverColor = isHovering and colors.button.buy or Color3.fromRGB(99, 102, 241)
		
		local tween = TweenService:Create(self.strokeRef.current,
			TweenInfo.new(animations.slow, animations.easing, animations.direction),
			{ Color = hoverColor }
		)
		tween:Play()
	end
end

-- Получить состояние кнопки
function AbilityCard:getButtonState(): (string, Color3, boolean)
	local isOwned = self.props.isOwned or false
	local canAfford = self.props.canAfford or true
	
	if isOwned then
		return "КУПЛЕНО", Color3.fromRGB(107, 114, 128), false -- Серый, неактивна
	elseif not canAfford then
		return "НЕ ХВАТАЕТ", Color3.fromRGB(239, 68, 68), false -- Красный, неактивна
	else
		return "КУПИТЬ", Color3.fromRGB(34, 197, 94), true -- Зеленый, активна
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
		BackgroundColor3 = colors.cardBackground,
		BackgroundTransparency = 0,  -- Полностью непрозрачный темный фон
		BorderSizePixel = 0,
		
		-- События наведения
		[Roact.Event.MouseEnter] = function()
			self:onCardHover(true)
		end,
		[Roact.Event.MouseLeave] = function()
			self:onCardHover(false)
		end,
	}, {
		-- Скругление
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.large), -- Большее скругление
		}),
		
		-- Современный градиент фона для способностей
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colors.cardBackground),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 25, 45)), -- Темнее снизу
			}),
			Rotation = 180,
		}),
		
		-- Светящаяся обводка способности
		UIStroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(99, 102, 241), -- Фиолетовый для способностей
			Thickness = 1,
			Transparency = 0.4,
			[Roact.Ref] = self.strokeRef,
		}),
		
		-- Тень для глубины
		Shadow = Roact.createElement("Frame", {
			Size = UDim2.new(1, 6, 1, 8),
			Position = UDim2.new(0, 3, 0, 4),
			BackgroundColor3 = ShopConfig.design.colors.shadow,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.large),
			}),
		}),
		
		-- Основная информация о способности (центрированная)
		AbilityInfo = Roact.createElement("Frame", {
			Size = UDim2.new(1, -100, 1, -config.spacing.gaps.medium), -- Используем конфиг
			Position = UDim2.new(0, config.spacing.padding.medium, 0, config.spacing.gaps.small),
			BackgroundTransparency = 1,
		}, {
			-- Название способности (центрированное)
			AbilityName = Roact.createElement("TextLabel", {
				Text = ability.name,
				Size = UDim2.new(1, 0, 0, titleSize + 2),
				Position = UDim2.new(0, 0, 0, 8),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.primary, -- Темный текст на светлом фоне
				TextSize = titleSize,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			
			-- Цена способности (центрированная)
			AbilityPrice = Roact.createElement("TextLabel", {
				Text = "💰 " .. ability.price .. " монет",
				Size = UDim2.new(1, 0, 0, priceSize + 2),
				Position = UDim2.new(0, 0, 0, titleSize + 10),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.accent, -- Синий акцентный цвет
				TextSize = priceSize,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
			
			-- Описание способности (центрированное)
			AbilityDescription = Roact.createElement("TextLabel", {
				Text = ability.description,
				Size = UDim2.new(1, 0, 0, descSize + 6),
				Position = UDim2.new(0, 0, 0, titleSize + priceSize + 15),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.secondary, -- Серый вторичный текст
				TextSize = descSize,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
		
		-- Кнопка покупки (простая с hover-анимацией)
		PurchaseButton = Roact.createElement("TextButton", {
			Text = buttonText,
			Size = buttonSize,
			Position = UDim2.new(1, -buttonSize.X.Offset - 8, 0.5, -buttonSize.Y.Offset / 2),
			BackgroundColor3 = buttonColor,
			BackgroundTransparency = buttonEnabled and 0 or 0.3,
			BorderSizePixel = 0,
			TextColor3 = Color3.fromRGB(255, 255, 255), -- Белый текст на кнопке -- Белый текст кнопки остается
			TextSize = isMobile and 12 or 13,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
			[Roact.Ref] = self.buttonRef,
			
			-- Событие покупки
			[Roact.Event.Activated] = buttonEnabled and function()
				if self.props.onPurchase then
					self.props.onPurchase(ability)
				end
			end or nil,
			
			-- Простые hover эффекты для кнопки
			[Roact.Event.MouseEnter] = (not isMobile and buttonEnabled) and function(button)
				local hoverColor = Color3.fromRGB(
					math.min(255, buttonColor.R * 255 + 20),
					math.min(255, buttonColor.G * 255 + 20),
					math.min(255, buttonColor.B * 255 + 20)
				)
				
				local tween = TweenService:Create(button,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundColor3 = hoverColor }
				)
				tween:Play()
			end or nil,
			
			[Roact.Event.MouseLeave] = (not isMobile and buttonEnabled) and function(button)
				local tween = TweenService:Create(button,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundColor3 = buttonColor }
				)
				tween:Play()
			end or nil,
		}, {
			-- Скругление кнопки
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
		}),
	})
end

return AbilityCard
