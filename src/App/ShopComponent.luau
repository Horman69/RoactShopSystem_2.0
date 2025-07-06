--!strict
-- src/App/ShopComponent.luau
-- Компонент Roact для отображения магазина и покупки товаров
-- Обновлён для работы с новой сервисной архитектурой

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Добавляем TweenService

-- Импортируем через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local ShopService = ModuleLoader.require("services/ShopService")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")
local ProductCard = ModuleLoader.require("App/ProductCard")
local AbilityCard = ModuleLoader.require("App/AbilityCard")
local WalletComponent = ModuleLoader.require("App/WalletComponent")

-- Типы и конфигурация
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))
type Product = Types.Product
type ShopComponentProps = Types.ShopComponentProps

--[=[
	ShopComponent
	Пропсы:
	- onPurchase (function): функция, вызываемая после попытки покупки
	- currentCoins (number): текущее количество монет для отображения
]=]
local ShopComponent = Roact.Component:extend("ShopComponent")

function ShopComponent:init()
	-- Используем переданный сервис или создаем новый (для обратной совместимости)
	self.shopService = self.props.shopService or ShopService.new()
	self.soundService = self.props.soundService
	
	-- Инициализируем PlatformService
	self.platformService = PlatformService.new()
	
	-- Получаем доступные товары
	self:updateProducts()
	
	-- УБРАЛИ: Звук открытия магазина теперь воспроизводится только в AppController
end

-- Обновить список товаров
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
	-- Если изменился updateTrigger, обновляем список товаров
	if self.props.updateTrigger ~= previousProps.updateTrigger then
		self:updateProducts()
	end
end

-- Проверить, владеет ли игрок товаром
function ShopComponent:isProductOwned(product: Product): boolean
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	
	-- Для способностей проверяем через AbilityService
	if product.category == "ability" and product.abilityId then
		return self.shopService.abilityService:isAbilityOwned(player, product.abilityId)
	end
	
	-- Для других товаров (пока что возвращаем false)
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
	
	-- 📱 АДАПТИВНЫЕ РАЗМЕРЫ ИЗ SHOPCONFIG
	local isMobile = self.platformService:isMobile()
	local responsiveConfig = ShopConfig.getResponsiveConfig(isMobile)
	local cardDimensions = ShopConfig.getCardDimensions(isMobile)
	local screenSize = self.platformService:getScreenSize()
	
	-- 🎯 РАЗМЕРЫ КОНТЕЙНЕРА ИЗ SHOPCONFIG
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
	
	local currentY = ShopConfig.design.spacing.gaps.medium
	local cardSpacing = ShopConfig.design.spacing.gaps.medium
	
	-- Сначала способности (если есть)
	if #abilities > 0 then
		-- Заголовок секции способностей
		local abilityCategory = ShopConfig.getCategoryConfig("ability")
		productElements["AbilitiesHeader"] = Roact.createElement("TextLabel", {
			Text = abilityCategory.name,
			Size = UDim2.new(1, -ShopConfig.design.spacing.padding.large, 0, ShopConfig.design.spacing.heights.header),
			Position = UDim2.new(0, ShopConfig.design.spacing.gaps.medium, 0, currentY),
			BackgroundTransparency = 1,
			TextColor3 = abilityCategory.color,
			TextSize = responsiveConfig.typography.header,
			Font = Enum.Font.GothamBlack,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}, {
			UIStroke = Roact.createElement("UIStroke", {
				Color = abilityCategory.color,
				Thickness = 1,
				Transparency = 0.6,
			}),
		})
		
		currentY = currentY + ShopConfig.design.spacing.heights.header + ShopConfig.design.spacing.gaps.medium
		
		-- Карточки способностей
		for i, ability in ipairs(abilities) do
			local cardHeight = cardDimensions.height
			
			productElements["Ability" .. i] = Roact.createElement("Frame", {
				Size = UDim2.new(1, -ShopConfig.design.spacing.padding.large, 0, cardHeight),
				Position = UDim2.new(0, ShopConfig.design.spacing.gaps.medium, 0, currentY),
				BackgroundTransparency = 1,
			}, {
				AbilityCard = Roact.createElement(AbilityCard, {
					ability = ability,
					isOwned = self:isProductOwned(ability),
					canAfford = self:canPlayerAfford(ability),
					onPurchase = function(selectedAbility)
						-- Звук покупки воспроизводится в AppController
						if self.props.onPurchase then
							self.props.onPurchase(selectedAbility)
						end
					end,
				}),
			})
			
			-- Добавляем разделитель между карточками (кроме последней)
			if i < #abilities then
				productElements["AbilityDivider" .. i] = Roact.createElement("Frame", {
					Size = UDim2.new(1, -ShopConfig.design.spacing.padding.xlarge, 0, 1),
					Position = UDim2.new(0, ShopConfig.design.spacing.padding.large, 0, currentY + cardHeight + cardSpacing/2),
					BackgroundColor3 = ShopConfig.design.colors.divider,
					BorderSizePixel = 0,
				})
			end
			
			currentY = currentY + cardHeight + cardSpacing
		end
		
		currentY = currentY + ShopConfig.design.spacing.gaps.medium
	end
	
	-- Потом остальные товары (если есть)
	if #otherProducts > 0 then
		-- Заголовок для других товаров (если есть способности)
		if #abilities > 0 then
			productElements["OtherHeader"] = Roact.createElement("TextLabel", {
				Text = "🛒 ДРУГИЕ ТОВАРЫ",
				Size = UDim2.new(1, -ShopConfig.design.spacing.padding.large, 0, ShopConfig.design.spacing.heights.header),
				Position = UDim2.new(0, ShopConfig.design.spacing.gaps.medium, 0, currentY),
				BackgroundTransparency = 1,
				TextColor3 = ShopConfig.design.colors.text.primary, -- Темный текст на светлом фоне
				TextSize = responsiveConfig.typography.header,
				Font = Enum.Font.GothamBlack,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			}, {
				UIStroke = Roact.createElement("UIStroke", {
					Color = ShopConfig.design.colors.border, -- Обычная серая граница
					Thickness = 1,
					Transparency = 0.3,
				}),
			})
			
			currentY = currentY + ShopConfig.design.spacing.heights.header + ShopConfig.design.spacing.gaps.medium
		end
		
		-- Обычные карточки
		local cardHeight = cardDimensions.height
		
		for i, product in ipairs(otherProducts) do
			productElements["Product" .. i] = Roact.createElement("Frame", {
				Size = UDim2.new(1, -ShopConfig.design.spacing.padding.large, 0, cardHeight),
				Position = UDim2.new(0, ShopConfig.design.spacing.gaps.medium, 0, currentY),
				BackgroundTransparency = 1,
			}, {
				ProductCard = Roact.createElement(ProductCard, {
					product = product,
					isOwned = self:isProductOwned(product),
					canAfford = self:canPlayerAfford(product),
					onPurchase = function(selectedProduct)
						-- Звук покупки воспроизводится в AppController
						if self.props.onPurchase then
							self.props.onPurchase(selectedProduct)
						end
					end,
				}),
			})
			
			-- Добавляем разделитель между карточками (кроме последней)
			if i < #otherProducts then
				productElements["ProductDivider" .. i] = Roact.createElement("Frame", {
					Size = UDim2.new(1, -ShopConfig.design.spacing.padding.xlarge, 0, 1),
					Position = UDim2.new(0, ShopConfig.design.spacing.padding.large, 0, currentY + cardHeight + cardSpacing/2),
					BackgroundColor3 = ShopConfig.design.colors.divider,
					BorderSizePixel = 0,
				})
			end
			
			currentY = currentY + cardHeight + cardSpacing
		end
	end

	-- Финальная высота контента
	local totalContentHeight = currentY + ShopConfig.design.spacing.gaps.medium
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, containerWidth, 0, containerHeight),
		Position = UDim2.new(0.5, -containerWidth/2, 0.5, -containerHeight/2), -- Центрируем по экрану
		BackgroundColor3 = ShopConfig.design.colors.background,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Visible = self.props.visible,
	}, {
		-- ✨ СОВРЕМЕННОЕ СКРУГЛЕНИЕ
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.xlarge),
		}),
		
		-- 🌟 СОВРЕМЕННЫЙ ГРАДИЕНТ ФОНА
		UIGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ShopConfig.design.colors.background),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 15, 30)), -- Темнее снизу
			}),
			Rotation = 180,
		}),
		
		-- 🔷 СВЕТЯЩАЯСЯ ОБВОДКА
		ModernBorder = Roact.createElement("UIStroke", {
			Color = ShopConfig.design.colors.borderAccent,
			Thickness = 2,
			Transparency = 0.5,
		}),
		
		-- 🌟 ЭЛЕГАНТНАЯ ТЕНЬ ДЛЯ ГЛУБИНЫ
		ContainerShadow = Roact.createElement("Frame", {
			Size = UDim2.new(1, 8, 1, 12),
			Position = UDim2.new(0, 4, 0, 6),
			BackgroundColor3 = ShopConfig.design.colors.shadow,
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.xlarge),
			}),
		}),
		
		-- Убрали полоску для более чистого дизайна
		
		-- 🏪 ЗАГОЛОВОК МАГАЗИНА (крупный, смещен влево)
		Header = Roact.createElement("TextLabel", {
			Text = ShopConfig.shop.title,
			Size = UDim2.new(0.7, 0, 0, 65), -- Ширина 70% контейнера, высота 65px
			Position = UDim2.new(0, 25, 0, 5), -- Смещаем влево (было по центру)
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Left, -- Выравнивание по левому краю
			TextSize = responsiveConfig.typography.header + 4, -- Увеличиваем размер еще на 4px
			Font = Enum.Font.GothamBlack,
			TextColor3 = ShopConfig.design.colors.text.primary,
			TextStrokeTransparency = 0.3,
			TextStrokeColor3 = ShopConfig.design.colors.borderAccent,
		}),
		
		-- 💰 КОМПАКТНЫЙ КОШЕЛЕК В МАГАЗИНЕ (правый верхний угол)
		WalletDisplay = Roact.createElement("Frame", {
			Size = UDim2.new(0, ShopConfig.getCurrencyDisplayConfig().blockSize.width, 0, ShopConfig.getCurrencyDisplayConfig().blockSize.height),
			Position = UDim2.new(1, -(ShopConfig.getCurrencyDisplayConfig().blockSize.width + ShopConfig.getCurrencyDisplayConfig().rightOffset), 0, 15),
			BackgroundTransparency = 1,
		}, {
			Wallet = Roact.createElement(WalletComponent, {
				coins = self.props.currentCoins or 0,
				inShop = true,
			}),
		}),
		
		-- 💎 МЕСТО ДЛЯ АЛМАЗОВ (для будущего использования)
		GemsDisplay = Roact.createElement("Frame", {
			Size = UDim2.new(0, ShopConfig.getCurrencyDisplayConfig().blockSize.width, 0, ShopConfig.getCurrencyDisplayConfig().blockSize.height),
			Position = UDim2.new(1, -(ShopConfig.getCurrencyDisplayConfig().blockSize.width * 2 + ShopConfig.getCurrencyDisplayConfig().spacing + ShopConfig.getCurrencyDisplayConfig().rightOffset), 0, 15),
			BackgroundTransparency = 1,
			Visible = false, -- Пока скрыт, можно будет включить позже
		}, {
			GemsLabel = Roact.createElement("TextLabel", {
				Text = "💎 0", -- Заготовка для алмазов
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 0.2,
				BackgroundColor3 = Color3.fromRGB(20, 30, 45),
				TextColor3 = Color3.fromRGB(0, 191, 255), -- Голубой цвет для алмазов
				Font = Enum.Font.GothamBold,
				TextSize = ShopConfig.getCurrencyDisplayConfig().fontSize,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				BorderSizePixel = 0,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),
		
		-- 🎯 СОВРЕМЕННАЯ КНОПКА ЗАКРЫТИЯ
		CloseButton = Roact.createElement("TextButton", {
			Text = ShopConfig.shop.buttons.close,
			Size = UDim2.new(0, isMobile and 30 or 32, 0, isMobile and 30 or 32),
			Position = UDim2.new(1, isMobile and -38 or -45, 0, isMobile and 6 or 12),
			BackgroundColor3 = ShopConfig.design.colors.button.close,
			BackgroundTransparency = 0,
			TextSize = responsiveConfig.typography.button,
			Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.fromRGB(255, 255, 255), -- Белый текст на красной кнопке
			AutoButtonColor = false,
			Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
			[Roact.Event.Activated] = function()
				-- Воспроизводим звук закрытия магазина
				if self.soundService then
					self.soundService:playShopClose()
				end
				
				if self.props.onClose then
					self.props.onClose()
				end
			end,
		}, {
			-- Скругление кнопки
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.round), -- Круглая кнопка
			}),
			
			-- Тень кнопки
			ButtonShadow = Roact.createElement("Frame", {
				Size = UDim2.new(1, 2, 1, 4),
				Position = UDim2.new(0, 1, 0, 2),
				BackgroundColor3 = ShopConfig.design.colors.shadow,
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.round),
				}),
			}),
		}),
		
		-- 📜 СКРОЛЛИРУЕМЫЙ КОНТЕЙНЕР ТОВАРОВ
		ProductsList = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -ShopConfig.design.spacing.gaps.medium, 1, -(ShopConfig.design.spacing.heights.header + ShopConfig.design.spacing.gaps.large)),
			Position = UDim2.new(0, ShopConfig.design.spacing.gaps.small, 0, ShopConfig.design.spacing.heights.header + ShopConfig.design.spacing.gaps.large),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, totalContentHeight),
			ScrollBarThickness = isMobile and 8 or 12,
			ScrollBarImageColor3 = ShopConfig.design.colors.border,
			ScrollBarImageTransparency = 0.3,
			ScrollingEnabled = true,
			CanvasPosition = Vector2.new(0, 0),
		}, productElements)
	})
end

return ShopComponent
