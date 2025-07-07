--!strict
-- src/App/ShopComponent.luau
-- Компонент магазина в минималистичном стиле панели способностей

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local ShopService = ModuleLoader.require("services/ShopService")
local SimpleSoundService = ModuleLoader.require("services/SimpleSoundService")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")
local ProductCard = ModuleLoader.require("App/ProductCard")

-- Типы и конфигурация
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type Product = Types.Product

local ShopComponent = Roact.Component:extend("ShopComponent")

function ShopComponent:init()
	self.shopService = self.props.shopService or ShopService
	self.soundService = self.props.soundService or SimpleSoundService
	self.platformService = PlatformService
	
	self:setState({
		products = {}
	})
	
	self:updateProducts()
end

-- Обновляем список товаров
function ShopComponent:updateProducts()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	
	local availableProducts = self.shopService:getAvailableProducts(player)
	self:setState({
		products = availableProducts
	})
end

-- Обновляем товары при изменении пропсов
function ShopComponent:didUpdate(previousProps)
	if self.props.updateTrigger ~= previousProps.updateTrigger then
		self:updateProducts()
	end
end

-- Проверить, владеет ли игрок товаром
function ShopComponent:isProductOwned(product: Product): boolean
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	
	if product.category == "ability" and product.abilityId then
		return self.shopService.abilityService:isAbilityOwned(player, product.abilityId)
	end
	
	return false
end

-- Проверить, может ли игрок позволить себе товар
function ShopComponent:canPlayerAfford(product: Product): boolean
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	
	return self.shopService.currencyService:hasEnoughCoins(player, product.price)
end

function ShopComponent:render()
	local products = self.state.products or {}
	local productElements = {}
	
	local isMobile = self.platformService:isMobile()
	local responsiveConfig = ShopConfig.getResponsiveConfig(isMobile)
	local cardDimensions = ShopConfig.getCardDimensions(isMobile)
	local screenSize = self.platformService:getScreenSize()
	
	-- Размеры контейнера как у панели способностей
	local containerConfig = responsiveConfig.container
	local containerWidth = isMobile and (screenSize.X * containerConfig.widthPercent) or containerConfig.width
	local containerHeight = isMobile and (screenSize.Y * containerConfig.heightPercent) or containerConfig.height
	
	-- Разделяем товары по категориям
	local abilities = {}
	local otherProducts = {}
	
	for _, product in ipairs(products) do
		if product.category == "ability" then
			table.insert(abilities, product)
		else
			table.insert(otherProducts, product)
		end
	end
	
	local currentY = 40 -- Уменьшили отступ под заголовок для поднятия категории "СПОСОБНОСТИ"
	local cardSpacing = ShopConfig.design.spacing.gaps.medium
	
	-- Создаем карточки способностей
	if #abilities > 0 then
		-- Заголовок категории "СПОСОБНОСТИ" с красивой обводкой
		productElements["AbilitiesCategory"] = Roact.createElement("TextLabel", {
			Text = "СПОСОБНОСТИ",
			Size = UDim2.new(1, -24, 0, 45), -- Увеличили высоту с 35 до 45
			Position = UDim2.new(0, 12, 0, currentY),
			BackgroundTransparency = 1,
			TextColor3 = ShopConfig.design.colors.text.primary,
			TextSize = 32, -- Увеличили с 24 до 32
			Font = ShopConfig.design.colors.text.fonts.bold,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			-- Стильная обводка как у заголовка магазина
			TextStrokeTransparency = 0,
			TextStrokeColor3 = ShopConfig.design.colors.accent.primary,
		})
		
		currentY = currentY + 55 -- Увеличили отступ после заголовка категории
		
		for i, ability in ipairs(abilities) do
			local cardHeight = cardDimensions.height
			
			productElements["Ability" .. i] = Roact.createElement("Frame", {
				Size = UDim2.new(1, -24, 0, cardHeight),
				Position = UDim2.new(0, 12, 0, currentY),
				BackgroundTransparency = 1,
			}, {
				ProductCard = Roact.createElement(ProductCard, {
					product = ability,
					isOwned = self:isProductOwned(ability),
					canAfford = self:canPlayerAfford(ability),
					currentCoins = self.props.currentCoins or 0,
					onPurchase = function()
						if self.props.onPurchase then
							self.props.onPurchase(ability)
						end
					end,
				})
			})
			
			currentY = currentY + cardHeight + cardSpacing
		end
	end
	
	-- Создаем карточки других товаров
	if #otherProducts > 0 then
		for i, product in ipairs(otherProducts) do
			local cardHeight = cardDimensions.height
			
			productElements["Product" .. i] = Roact.createElement("Frame", {
				Size = UDim2.new(1, -24, 0, cardHeight),
				Position = UDim2.new(0, 12, 0, currentY),
				BackgroundTransparency = 1,
			}, {
				ProductCard = Roact.createElement(ProductCard, {
					product = product,
					isOwned = self:isProductOwned(product),
					canAfford = self:canPlayerAfford(product),
					currentCoins = self.props.currentCoins or 0,
					onPurchase = function()
						if self.props.onPurchase then
							self.props.onPurchase(product)
						end
					end,
				})
			})
			
			currentY = currentY + cardHeight + cardSpacing
		end
	end
	
	local totalContentHeight = currentY + ShopConfig.design.spacing.gaps.medium
	
	-- Минималистичный контейнер в стиле панели способностей
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, containerWidth, 0, containerHeight),
		Position = UDim2.new(0, 0, 0, 0),
		-- Цвета как у панели способностей
		BackgroundColor3 = ShopConfig.design.colors.background.secondary,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Visible = self.props.visible,
	}, {
		-- Скругление как у панели способностей
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.container),
		}),
		
		-- Стильная рамка как у кнопок способностей
		Border = Roact.createElement("UIStroke", {
			Color = ShopConfig.design.colors.accent.primary, -- Синий акцент как у заголовков
			Thickness = ShopConfig.design.stroke.thickness,
			Transparency = 0.3, -- Менее прозрачная
		}),
		
		-- Простая тень как у панели способностей
		Shadow = Roact.createElement("Frame", {
			BackgroundColor3 = ShopConfig.design.shadow.color,
			BackgroundTransparency = ShopConfig.design.shadow.transparency,
			BorderSizePixel = 0,
			Size = UDim2.new(1, ShopConfig.design.shadow.offset.x * 2, 1, ShopConfig.design.shadow.offset.y * 2),
			Position = UDim2.new(0, -ShopConfig.design.shadow.offset.x, 0, ShopConfig.design.shadow.offset.y),
			ZIndex = -1,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.container + 3),
			}),
		}),
		
		-- Стильный заголовок магазина с обводкой
		Header = Roact.createElement("TextLabel", {
			Text = ShopConfig.shop.title,
			Size = UDim2.new(0.6, 0, 0, 40),
			Position = UDim2.new(0, 12, 0, 10),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextSize = responsiveConfig.typography.header,
			Font = ShopConfig.design.colors.text.fonts.bold,
			TextColor3 = ShopConfig.design.colors.text.primary,
			-- Стильная обводка на заглавную надпись
			TextStrokeTransparency = 0,
			TextStrokeColor3 = ShopConfig.design.colors.accent.primary,
		}),
		
		-- Контейнер баланса монет со стильной рамкой
		CoinBalanceContainer = Roact.createElement("Frame", {
			Size = UDim2.new(0, 120, 0, 32),
			Position = UDim2.new(1, -200, 0, 14), -- Сдвинули левее с -170 до -200
			BackgroundColor3 = ShopConfig.design.colors.background.card,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			-- Стильная рамка как у основных контейнеров
			UIStroke = Roact.createElement("UIStroke", {
				Color = ShopConfig.design.colors.accent.primary, -- Синий акцент
				Thickness = 2, -- Увеличили толщину для выделения баланса
				Transparency = 0, -- Полностью видимая рамка для выделения
			}),
			
			-- Текст баланса внутри контейнера
			CoinBalance = Roact.createElement("TextLabel", {
				Text = "💰 " .. (self.props.currentCoins or 0),
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.primary,
				TextSize = 16,
				Font = ShopConfig.design.colors.text.fonts.bold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}),
		}),
		
		-- Простая кнопка закрытия
		CloseButton = Roact.createElement("TextButton", {
			Text = "×",
			Size = UDim2.new(0, 36, 0, 36),
			Position = UDim2.new(1, -48, 0, 12),
			BackgroundColor3 = ShopConfig.design.colors.button.close,
			BackgroundTransparency = 0,
			TextSize = 20,
			Font = ShopConfig.design.colors.text.fonts.bold,
			TextColor3 = ShopConfig.design.colors.text.button,
			AutoButtonColor = false,
			Modal = true,
			[Roact.Event.Activated] = function()
				if self.soundService then
					self.soundService:playShopClose()
				end
				
				if self.props.onClose then
					self.props.onClose()
				end
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.button),
			}),
		}),
		
		-- Простой скроллируемый список товаров
		ProductsList = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -12, 1, -60),
			Position = UDim2.new(0, 6, 0, 54),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, totalContentHeight),
			ScrollBarThickness = isMobile and 6 or 8,
			ScrollBarImageColor3 = ShopConfig.design.colors.border.primary,
			ScrollBarImageTransparency = 0.4,
			ScrollingEnabled = true,
		}, productElements)
	})
end

return ShopComponent
