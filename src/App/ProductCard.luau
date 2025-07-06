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
	self.strokeRef = Roact.createRef() -- Для эффектов наведения
end

-- Получить иконку для категории товара
function ProductCard:getCategoryIcon(category: string?): string
	local categoryConfig = ShopConfig.getCategoryConfig(category or "other")
	return categoryConfig.icon
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

-- Эффект при наведении мыши (как у способностей)
function ProductCard:onCardHover(isHovering: boolean)
	local stroke = self.strokeRef.current
	if stroke then
		local targetTransparency = isHovering and 0.1 or 0.3
		local tween = TweenService:Create(stroke,
			TweenInfo.new(ShopConfig.design.animations.fast, ShopConfig.design.animations.easing, ShopConfig.design.animations.direction),
			{ Transparency = targetTransparency }
		)
		tween:Play()
	end
end

function ProductCard:render()
	local product = self.props.product
	local isMobile = self.platformService:isMobile()
	
	-- Получаем конфигурацию для адаптивности
	local responsiveConfig = ShopConfig.getResponsiveConfig(isMobile)
	local cardDimensions = ShopConfig.getCardDimensions(isMobile)
	
	-- Получаем данные для отображения
	local categoryIcon = self:getCategoryIcon(product.category)
	local categoryColor = self:getCategoryColor(product.category)
	local buttonText, buttonColor, buttonEnabled = self:getButtonState()
	
	-- Адаптивные размеры из конфигурации
	local cardHeight = cardDimensions.height
	local spacing = cardDimensions.spacing
	local typography = responsiveConfig.typography
	local iconSize = isMobile and 28 or 32
	local buttonWidth = isMobile and 85 or 95
	local buttonHeight = cardDimensions.buttonHeight
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, cardHeight),
		BackgroundColor3 = ShopConfig.design.colors.cardBackground,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		
		-- События наведения (как у способностей)
		[Roact.Event.MouseEnter] = function()
			self:onCardHover(true)
		end,
		[Roact.Event.MouseLeave] = function()
			self:onCardHover(false)
		end,
	}, {
		-- Скругление как у иконок способностей
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.medium),
		}),
		
		-- Светящаяся обводка как у иконок способностей
		UIStroke = Roact.createElement("UIStroke", {
			Color = categoryColor,
			Thickness = 2,
			Transparency = 0.3,
			[Roact.Ref] = self.strokeRef, -- Добавляем ref для эффектов
		}),
		
		-- Тень для глубины
		Shadow = Roact.createElement("Frame", {
			Size = UDim2.new(1, 4, 1, 6),
			Position = UDim2.new(0, 2, 0, 3),
			BackgroundColor3 = ShopConfig.design.colors.shadow,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.medium),
			}),
		}),
		
		-- Стильная иконка категории в стиле способностей
		CategoryIcon = Roact.createElement("Frame", {
			Size = UDim2.new(0, iconSize + 8, 0, iconSize + 8),
			Position = UDim2.new(0, ShopConfig.design.spacing.padding.medium + 6, 0, ShopConfig.design.spacing.gaps.medium),
			BackgroundColor3 = categoryColor,
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.round), -- Круглая иконка
			}),
			
			-- Светящаяся обводка иконки
			UIStroke = Roact.createElement("UIStroke", {
				Color = categoryColor,
				Thickness = 2,
				Transparency = 0.3,
			}),
			
			Icon = Roact.createElement("TextLabel", {
				Text = categoryIcon,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = categoryColor,
				TextSize = iconSize * 0.8,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),
		
		-- Основная информация о товаре
		ProductInfo = Roact.createElement("Frame", {
			Size = UDim2.new(1, -(buttonWidth + ShopConfig.design.spacing.padding.large), 1, -ShopConfig.design.spacing.gaps.large),
			Position = UDim2.new(0, iconSize + ShopConfig.design.spacing.padding.large + 8, 0, ShopConfig.design.spacing.gaps.medium),
			BackgroundTransparency = 1,
		}, {
			-- Название товара
			ProductName = Roact.createElement("TextLabel", {
				Text = product.name,
				Size = UDim2.new(1, 0, 0, typography.title + 2),
				Position = UDim2.new(0, 0, 0, 2),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.primary,
				TextSize = typography.title,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
			
			-- Цена товара
			ProductPrice = Roact.createElement("TextLabel", {
				Text = "💰 " .. product.price .. " монет",
				Size = UDim2.new(1, 0, 0, typography.price + 2),
				Position = UDim2.new(0, 0, 0, typography.title + ShopConfig.design.spacing.gaps.small),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.accent,
				TextSize = typography.price,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
			
			-- Описание товара  
			ProductDescription = Roact.createElement("TextLabel", {
				Text = product.description,
				Size = UDim2.new(1, 0, 0, typography.description + 8),
				Position = UDim2.new(0, 0, 0, typography.title + typography.price + ShopConfig.design.spacing.gaps.medium),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.secondary,
				TextSize = typography.description,
				Font = Enum.Font.Gotham,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}),
		}),
		
		-- Стильная кнопка покупки с эффектами
		PurchaseButton = Roact.createElement("TextButton", {
			Text = buttonText,
			Size = UDim2.new(0, buttonWidth, 0, buttonHeight),
			Position = UDim2.new(1, -(buttonWidth + ShopConfig.design.spacing.padding.medium), 0.5, -buttonHeight / 2),
			BackgroundColor3 = buttonColor,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			Active = buttonEnabled,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = typography.button,
			Font = Enum.Font.GothamBold,
			AutoButtonColor = false,
			Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
			
			[Roact.Event.Activated] = buttonEnabled and function()
				self.props.onPurchase(product)
			end or nil,
		}, {
			-- Скругление кнопки
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.medium),
			}),
			
			-- Светящаяся обводка кнопки
			UIStroke = buttonEnabled and Roact.createElement("UIStroke", {
				Color = buttonColor,
				Thickness = 1,
				Transparency = 0.6,
			}) or nil,
			
			-- Градиент кнопки
			UIGradient = buttonEnabled and Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, buttonColor),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(
						math.max(0, buttonColor.R * 255 - 30) / 255,
						math.max(0, buttonColor.G * 255 - 30) / 255,
						math.max(0, buttonColor.B * 255 - 30) / 255
					)),
				}),
				Rotation = 90,
			}) or nil,
			
			-- Тень кнопки
			ButtonShadow = Roact.createElement("Frame", {
				Size = UDim2.new(1, 4, 1, 6),
				Position = UDim2.new(0, 2, 0, 3),
				BackgroundColor3 = buttonColor,
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.medium),
				}),
			}),
		}),
	})
end

return ProductCard
