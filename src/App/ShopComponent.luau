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

-- Типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
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
	
	-- Инициализируем PlatformService
	self.platformService = PlatformService.new()
	
	-- Получаем доступные товары
	self:updateProducts()
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

function ShopComponent:render()
	local products = self.state.products or {}
	local productElements = {}
	
	-- 📱 ПОЛНОСТЬЮ АДАПТИВНЫЕ РАЗМЕРЫ ИЗ КОНФИГА
	local config = self.platformService:getConfig()
	local isMobile = self.platformService:isMobile()
	local isTablet = self.platformService:isTablet()
	local screenSize = self.platformService:getScreenSize()
	
	-- 🎯 ЦЕНТРИРОВАННЫЕ КАРТОЧКИ С РОВНЫМИ ОТСТУПАМИ
	local containerWidth = isMobile and (screenSize.X * 0.9) or 480  -- Ширина контейнера магазина
	local sideMargin = 20  -- Отступы с боков
	local maxCardWidth = containerWidth - (sideMargin * 2)  -- Максимальная ширина карточки
	local cardWidth = isMobile and math.min(maxCardWidth, 320) or math.min(maxCardWidth, 420)  -- Адаптивная ширина
	
	-- Центрирование карточки внутри контейнера
	local cardLeftPosition = (containerWidth - cardWidth) / 2
	
	-- Адаптивная высота с учётом размера шрифта - КОМПАКТНЕЕ
	local baseCardHeight = isMobile and 65 or 75  -- Уменьшаем высоту для компактности
	local textLinesHeight = config.buttonTextSize + config.bodyTextSize + (config.bodyTextSize - 2) + (config.spacing * 3)
	local cardHeight = math.max(baseCardHeight, textLinesHeight + (config.padding * 1.5)) -- Меньше отступов
	
	local cardSpacing = config.spacing
	local totalItemHeight = cardHeight + cardSpacing
	local leftPadding = config.padding
	
	for i, product in ipairs(products) do
		productElements["Product" .. i] = Roact.createElement("Frame", {
			Size = UDim2.new(0, cardWidth, 0, cardHeight),
			Position = UDim2.new(0, cardLeftPosition, 0, totalItemHeight * (i - 1) + config.padding), -- Центрированная позиция
			BackgroundColor3 = Color3.fromRGB(20, 30, 45), -- Темная космическая основа
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
		}, {
			-- 💎 АДАПТИВНОЕ СКРУГЛЕНИЕ
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, config.cornerRadius),
			}),
			
			-- 🌈 ГОЛОГРАФИЧЕСКИЙ ГРАДИЕНТ
			HoloGradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 35, 50)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 40, 60)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 45)),
				}),
				Rotation = 45,
			}),
			
			-- ✨ НЕОНОВАЯ ОБВОДКА (ЦВЕТ КАК У СПОСОБНОСТЕЙ)
			NeonStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(80, 80, 80), -- Такой же цвет как у способностей
				Thickness = 2,
				Transparency = 0.5,
			}),
			
			-- 🌟 КОСМИЧЕСКАЯ ТЕНЬ (ЦВЕТ КАК У СПОСОБНОСТЕЙ)
			CosmicShadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(80, 80, 80), -- Такой же цвет как у способностей
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 8, 1, 8),
				Position = UDim2.new(0, -4, 0, 4),
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 20),
				}),
			}),
			
			-- 🎯 ПРОФЕССИОНАЛЬНАЯ ИНФОРМАЦИЯ О ТОВАРЕ
			ProductInfo = Roact.createElement("Frame", {
				-- Оставляем место для кнопки справа
				Size = UDim2.new(1, -(isMobile and 90 or 110), 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
			}, {
				-- Контейнер для текстовой информации с правильными отступами
				TextContainer = Roact.createElement("Frame", {
					Size = UDim2.new(1, -16, 1, -12), -- Внутренние отступы
					Position = UDim2.new(0, 12, 0, 8), -- Отступы от краёв
					BackgroundTransparency = 1,
				}, {
					-- Заголовок товара
					Name = Roact.createElement("TextLabel", {
						Text = product.name,
						Size = UDim2.new(1, 0, 0, 18), -- Фиксированная высота для заголовка
						Position = UDim2.new(0, 0, 0, 0),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = isMobile and 16 or 18,
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextTruncate = Enum.TextTruncate.AtEnd,
					}),
					
					-- Цена товара
					Price = Roact.createElement("TextLabel", {
						Text = "💰 " .. product.price .. " монет",
						Size = UDim2.new(1, 0, 0, 16), -- Фиксированная высота для цены
						Position = UDim2.new(0, 0, 0, 22), -- Под заголовком с отступом
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = isMobile and 14 or 16,
						Font = Enum.Font.GothamBold,
						TextColor3 = Color3.fromRGB(255, 215, 0),
					}),
					
					-- Описание товара
					Description = Roact.createElement("TextLabel", {
						Text = product.description,
						Size = UDim2.new(1, 0, 0, 14), -- Компактная высота для описания
						Position = UDim2.new(0, 0, 0, 42), -- Под ценой с отступом
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						TextSize = isMobile and 12 or 13,
						Font = Enum.Font.Gotham,
						TextColor3 = Color3.fromRGB(180, 180, 180),
						TextWrapped = true,
						TextTruncate = Enum.TextTruncate.AtEnd,
					}),
				}),
			}),
			
			-- 🎮 ПРОФЕССИОНАЛЬНАЯ КНОПКА ПОКУПКИ
			BuyButton = Roact.createElement("TextButton", {
				Text = "КУПИТЬ",
				-- Стандартный размер кнопки
				Size = UDim2.new(0, isMobile and 80 or 90, 0, isMobile and 28 or 32),
				-- Позиционирование справа с отступом, вертикально по центру
				Position = UDim2.new(1, -(isMobile and 88 or 98), 0.5, -(isMobile and 14 or 16)),
				BackgroundColor3 = Color3.fromRGB(34, 197, 94), -- Более современный зелёный
				BackgroundTransparency = 0,
				TextSize = isMobile and 14 or 15, -- Стандартные размеры текста
				Font = Enum.Font.GothamBold,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = false,
				BorderSizePixel = 0,
				-- ТОЛЬКО ОДНО СОБЫТИЕ для предотвращения двойной покупки
				[Roact.Event.Activated] = function()
					if self.props.onPurchase then
						self.props.onPurchase(product)
					end
				end,
				-- ТОЛЬКО для десктопа: hover эффекты
				[Roact.Event.MouseEnter] = not isMobile and function(button)
					-- Профессиональная анимация hover
					local tween = TweenService:Create(button,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundColor3 = Color3.fromRGB(22, 163, 74) } -- Тёмно-зелёный при наведении
					)
					tween:Play()
				end or nil,
				[Roact.Event.MouseLeave] = not isMobile and function(button)
					-- Анимация возврата
					local tween = TweenService:Create(button,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundColor3 = Color3.fromRGB(34, 197, 94) } -- Возврат к базовому зелёному
					)
					tween:Play()
				end or nil,
			}, {
				-- Современное скругление кнопки
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8), -- Умеренное скругление
				}),
			}),
		})
	end

	-- Рассчитываем общую высоту контента с правильными отступами
	local totalContentHeight = totalItemHeight * #products + config.padding
	
	-- 🌌 РАЗМЕР МАГАЗИНА ДОЛЖЕН СООТВЕТСТВОВАТЬ КОНТЕЙНЕРУ
	local shopWidth = containerWidth  -- Используем полную ширину контейнера
	local shopHeight = isMobile and (screenSize.Y * 0.8) or 520  -- Соответствует высоте контейнера
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, shopWidth, 0, shopHeight),
		Position = UDim2.new(0, 0, 0, 0), -- Заполняем весь контейнер с самого верха
		BackgroundColor3 = Color3.fromRGB(10, 15, 25), -- Темная космическая основа
		BackgroundTransparency = 0.2, -- Полупрозрачность для glass эффекта
		BorderSizePixel = 0,
		Visible = self.props.visible,
	}, {
		-- ✨ PREMIUM СКРУГЛЕНИЕ
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 24), -- Более скругленные углы
		}),
		
		-- 🔥 RGB НЕОНОВАЯ ОБВОДКА (ЦВЕТ КАК У СПОСОБНОСТЕЙ)
		NeonBorder = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(80, 80, 80), -- Такой же цвет как у способностей
			Thickness = 3,
			Transparency = 0.3,
		}),
		
		-- 🌟 ЭПИЧЕСКАЯ ТЕНЬ С GLOW ЭФФЕКТОМ (ЦВЕТ КАК У СПОСОБНОСТЕЙ)
		CosmicShadow = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(80, 80, 80), -- Такой же цвет как у способностей
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 16, 1, 16),
			Position = UDim2.new(0, -8, 0, 8),
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 32),
			}),
		}),
		
		-- 🎭 ГОЛОГРАФИЧЕСКИЙ ГРАДИЕНТ
		HologramGradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 25, 40)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 30, 50)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 20, 35)),
			}),
			Rotation = 135,
		}),
		
		-- 🏪 КОМПАКТНЫЙ ЗАГОЛОВОК МАГАЗИНА
		Header = Roact.createElement("TextLabel", {
			Text = "✨ МАГАЗИН ✨", -- Более короткий заголовок
			Size = UDim2.new(1, -60, 0, isMobile and 25 or 30),              -- ЕЩЕ компактнее высота
			Position = UDim2.new(0, 15, 0, isMobile and 5 or 8),             -- Меньше отступы сверху
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = config.headerTextSize,                                 -- Из конфига
			Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextStrokeTransparency = 0,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
		}, {
			-- Неоновый glow для заголовка (цвет как у способностей)
			TextGlow = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(80, 80, 80), -- Такой же цвет как у способностей
				Thickness = 2,
				Transparency = 0.6,
			}),
		}),
		
		-- 🎯 КОМПАКТНАЯ КНОПКА ЗАКРЫТИЯ
		CloseButton = Roact.createElement("TextButton", {
			Text = "X", -- Правильный символ X
			Size = UDim2.new(0, isMobile and 30 or 32, 0, isMobile and 30 or 32),   -- Меньше для мобильных
			Position = UDim2.new(1, isMobile and -38 or -45, 0, isMobile and 6 or 12), -- Ближе к углу
			BackgroundColor3 = Color3.fromRGB(220, 50, 50), -- Ярко-красный
			BackgroundTransparency = 0,
			TextSize = config.buttonTextSize,                                        -- Из конфига
			Font = Enum.Font.GothamBlack,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			AutoButtonColor = false,
			[Roact.Event.Activated] = function()
				if self.props.onClose then
					self.props.onClose()
				end
			end,
			-- ТОЛЬКО для десктопа: анимации hover (на мобильных не нужны)
			[Roact.Event.MouseEnter] = not isMobile and function(button)
				-- Анимация hover - увеличение
				local baseSize = isMobile and 30 or 32
				local hoverSize = baseSize + 4
				
				local tween = TweenService:Create(button,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = UDim2.new(0, hoverSize, 0, hoverSize),
						BackgroundColor3 = Color3.fromRGB(255, 70, 70)
					}
				)
				tween:Play()
			end or nil,
			[Roact.Event.MouseLeave] = not isMobile and function(button)
				-- Анимация возврата к базовому размеру
				local baseSize = isMobile and 30 or 32
				
				local tween = TweenService:Create(button,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Size = UDim2.new(0, baseSize, 0, baseSize),
						BackgroundColor3 = Color3.fromRGB(220, 50, 50)
					}
				)
				tween:Play()
			end or nil,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0), -- Полностью круглая как на скриншоте
			}),
			-- Легкая тень
			Shadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 4, 1, 4),
				Position = UDim2.new(0, -2, 0, 2),
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
		
		-- 📜 ЦЕНТРИРОВАННЫЙ СКРОЛЛИРУЕМЫЙ КОНТЕЙНЕР
		ProductsList = Roact.createElement("ScrollingFrame", {
			-- Используем полную ширину с минимальными отступами
			Size = UDim2.new(1, -10, 1, -(isMobile and 60 or 70)), -- Минимальные отступы по бокам
			Position = UDim2.new(0, 5, 0, isMobile and 50 or 60), -- Центрированная позиция
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, totalContentHeight),
			-- Адаптивная прокрутка
			ScrollBarThickness = isMobile and 8 or 12,
			ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
			ScrollBarImageTransparency = 0.3,
			-- Улучшенная прокрутка на мобильных
			ScrollingEnabled = true,
			CanvasPosition = Vector2.new(0, 0),
		}, productElements)
	})
end

return ShopComponent
