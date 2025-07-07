--!strict
-- src/App/ProductCard.luau
-- Профессиональный компонент карточки товара для магазина
-- Поддерживает все типы товаров с адаптивным дизайном

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")

-- Типы и конфигурация
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))
type Product = Types.Product

-- Пропсы компонента
export type ProductCardProps = {
	product: Product,
	isOwned: boolean?,
	canAfford: boolean?,
	onPurchase: (product: Product) -> (),
}

-- Компонент карточки товара
local ProductCard = Roact.Component:extend("ProductCard")

function ProductCard:init()
	self.platformService = PlatformService.new()
	self.strokeRef = Roact.createRef() -- Для эффектов наведения на обводку
	self.cardRef = Roact.createRef() -- Для эффектов масштабирования карточки
	self.buttonRef = Roact.createRef() -- Для эффектов кнопки
end

-- Получить цвет для категории
function ProductCard:getCategoryColor(category: string?): Color3
	local categoryConfig = ShopConfig.getCategoryConfig(category or "other")
	return categoryConfig.color
end

-- Получить состояние кнопки
function ProductCard:getButtonState(): (string, Color3, boolean)
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

-- Простые эффекты без анимации для лучшей производительности
function ProductCard:onCardHover(isHovering: boolean)
	local card = self.cardRef.current
	if card then
		-- Простое изменение цвета фона при наведении на карточку
		if isHovering then
			card.BackgroundColor3 = ShopConfig.design.colors.background.cardHover
		else
			card.BackgroundColor3 = ShopConfig.design.colors.background.card
		end
	end
end

function ProductCard:onButtonHover(isHovering: boolean)
	local button = self.buttonRef.current
	if button then
		-- Простое изменение прозрачности без анимации
		button.BackgroundTransparency = isHovering and 0.1 or 0.0
	end
end

function ProductCard:onButtonPress()
	-- Убираем анимацию нажатия - только звуковая обратная связь
end

function ProductCard:render()
	local product = self.props.product
	local isMobile = self.platformService:isMobile()
	
	-- Получаем конфигурацию для адаптивности
	local responsiveConfig = ShopConfig.getResponsiveConfig(isMobile)
	local cardDimensions = ShopConfig.getCardDimensions(isMobile)
	
	-- Получаем данные для отображения
	local categoryColor = self:getCategoryColor(product.category)
	local buttonText, buttonColor, buttonEnabled = self:getButtonState()
	
	-- Адаптивные размеры из конфигурации
	local cardHeight = cardDimensions.height
	local spacing = cardDimensions.spacing
	local typography = responsiveConfig.typography
	local buttonWidth = isMobile and 85 or 95
	local buttonHeight = cardDimensions.buttonHeight
	
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
		
		-- Современная светящаяся обводка
		UIStroke = Roact.createElement("UIStroke", {
			Color = categoryColor,
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
		
		-- Основная информация о товаре
		ProductInfo = Roact.createElement("Frame", {
			Size = UDim2.new(1, -(buttonWidth + ShopConfig.design.spacing.padding.large), 1, -ShopConfig.design.spacing.gaps.large),
			Position = UDim2.new(0, ShopConfig.design.spacing.padding.large, 0, ShopConfig.design.spacing.gaps.medium),
			BackgroundTransparency = 1,
		}, {
			-- Название товара (современная типографика)
			ProductName = Roact.createElement("TextLabel", {
				Text = product.name,
				Size = UDim2.new(1, 0, 0, typography.title + 2),
				Position = UDim2.new(0, 0, 0, 2),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.primary,
				TextSize = typography.title,
				Font = ShopConfig.design.colors.text.fonts.bold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			
			-- Цена товара (с золотым акцентом)
			ProductPrice = Roact.createElement("TextLabel", {
				Text = "💰 " .. product.price .. " монет",
				Size = UDim2.new(1, 0, 0, typography.price + 2),
				Position = UDim2.new(0, 0, 0, typography.title + ShopConfig.design.spacing.gaps.small),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.accent,
				TextSize = typography.price,
				Font = ShopConfig.design.colors.text.fonts.bold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
			
			-- Описание товара (современная типографика)
			ProductDescription = Roact.createElement("TextLabel", {
				Text = product.description,
				Size = UDim2.new(1, 0, 0, typography.description + 8),
				Position = UDim2.new(0, 0, 0, typography.title + typography.price + ShopConfig.design.spacing.gaps.medium),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.secondary,
				TextSize = typography.description,
				Font = ShopConfig.design.colors.text.fonts.regular,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
		
		-- Современная кнопка покупки с эффектами
		PurchaseButton = Roact.createElement("TextButton", {
			Text = buttonText,
			Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
			Position = UDim2.new(1, -(buttonWidth + ShopConfig.design.spacing.padding.medium), 0.5, -buttonHeight / 2),
			BackgroundColor3 = buttonColor,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Active = buttonEnabled,
			TextColor3 = ShopConfig.design.colors.text.button,
			TextSize = typography.button + 4, -- Увеличили шрифт кнопки "Купить"
			Font = ShopConfig.design.colors.text.fonts.bold,
			AutoButtonColor = false,
			Modal = true, -- Отключаем стандартные звуки Roblox
			[Roact.Ref] = self.buttonRef,
			
			-- Современные события кнопки
			[Roact.Event.MouseEnter] = buttonEnabled and function()
				self:onButtonHover(true)
			end or nil,
			[Roact.Event.MouseLeave] = buttonEnabled and function()
				self:onButtonHover(false)
			end or nil,
			[Roact.Event.MouseButton1Down] = buttonEnabled and function()
				self:onButtonPress()
			end or nil,
			[Roact.Event.Activated] = buttonEnabled and function()
				self.props.onPurchase(product)
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
		}),
	})
end

return ProductCard

