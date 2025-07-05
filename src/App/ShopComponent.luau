--!strict
-- src/App/ShopComponent.luau
-- Компонент Roact для отображения магазина и покупки товаров
-- Обновлён для работы с новой сервисной архитектурой

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local ShopService = ModuleLoader.require("services/ShopService")

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
	
	-- Увеличиваем отступы между карточками (было 80, стало 100)
	local cardHeight = 80
	local cardSpacing = 20 -- отступ между карточками
	local totalItemHeight = cardHeight + cardSpacing
	
	for i, product in ipairs(products) do
		productElements["Product" .. i] = Roact.createElement("Frame", {
			Size = UDim2.new(0, 350, 0, cardHeight),
			Position = UDim2.new(0, 20, 0, totalItemHeight * (i - 1) + 10), -- добавляем отступ сверху
			BackgroundColor3 = Color3.fromRGB(45, 45, 50), -- чуть светлее для лучшего контраста
			BorderSizePixel = 0,
		}, {
			-- Современное скругление
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			
			-- Тень карточки
			Shadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 4, 1, 4),
				Position = UDim2.new(0, -2, 0, 3),
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),
			}),
			
			-- Тонкая рамка
			Border = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(70, 70, 70),
				Thickness = 1,
				Transparency = 0.3,
			}),
			
			-- Информация о товаре
			ProductInfo = Roact.createElement("Frame", {
				Size = UDim2.new(0, 220, 1, 0),
				BackgroundTransparency = 1,
			}, {
				Name = Roact.createElement("TextLabel", {
					Text = product.name,
					Size = UDim2.new(1, 0, 0, 25),
					Position = UDim2.new(0, 15, 0, 8),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 20,
					Font = Enum.Font.GothamBold,
					TextColor3 = Color3.fromRGB(255, 255, 255),
				}),
				Price = Roact.createElement("TextLabel", {
					Text = "💰 " .. product.price .. " монет",
					Size = UDim2.new(1, 0, 0, 20),
					Position = UDim2.new(0, 15, 0, 33),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 16,
					Font = Enum.Font.GothamBold,
					TextColor3 = Color3.fromRGB(255, 215, 0),
				}),
				Description = Roact.createElement("TextLabel", {
					Text = product.description,
					Size = UDim2.new(1, 0, 0, 20),
					Position = UDim2.new(0, 15, 0, 53),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextSize = 14,
					Font = Enum.Font.Gotham,
					TextColor3 = Color3.fromRGB(200, 200, 200),
					TextWrapped = true,
				}),
			}),
			
			-- Кнопка покупки с простой анимацией
			BuyButton = Roact.createElement("TextButton", {
				Text = "Купить",
				Size = UDim2.new(0, 100, 0, 40),
				Position = UDim2.new(0, 235, 0, 20),
				BackgroundColor3 = Color3.fromRGB(0, 170, 255),
				TextSize = 18,
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = false,
				[Roact.Event.Activated] = function()
					-- Вызываем колбэк родительского компонента
					if self.props.onPurchase then
						self.props.onPurchase(product)
					end
				end,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		})
	end

	-- Рассчитываем общую высоту контента
	local totalContentHeight = totalItemHeight * #products + 20
	
	-- Возвращаем обычный магазин
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 400, 0, math.min(420, totalContentHeight + 40)),
		Position = UDim2.new(0, 0, 0, 120),
		BackgroundColor3 = Color3.fromRGB(28, 28, 30), -- Темно-серый как у AbilityPanel
		BackgroundTransparency = 0.05, -- Почти непрозрачный
		BorderSizePixel = 0,
		Visible = self.props.visible,
	}, {
		-- Современное скругление
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 16),
		}),
		
		-- Профессиональная тень панели
		Shadow = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.8,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 6, 1, 6),
			Position = UDim2.new(0, -3, 0, 3),
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 19),
			}),
		}),
		
		-- Тонкая рамка панели
		Border = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(60, 60, 60),
			Thickness = 1,
			Transparency = 0.5,
		}),
		
		-- Заголовок магазина
		Header = Roact.createElement("TextLabel", {
			Text = "🛒 Магазин способностей",
			Size = UDim2.new(1, -60, 0, 30), -- Уменьшили ширину, чтобы освободить место для кнопки
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextSize = 20,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(255, 255, 255),
		}),
		
		-- Кнопка закрытия (крестик)
		CloseButton = Roact.createElement("TextButton", {
			Text = "✕",
			Size = UDim2.new(0, 30, 0, 30),
			Position = UDim2.new(1, -40, 0, 10), -- Правый верхний угол
			BackgroundColor3 = Color3.fromRGB(200, 60, 60), -- Красный цвет
			TextSize = 18,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			AutoButtonColor = false,
			[Roact.Event.Activated] = function()
				-- Вызываем колбэк для закрытия магазина
				if self.props.onClose then
					self.props.onClose()
				end
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			-- Тень для кнопки
			ButtonShadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 2, 1, 2),
				Position = UDim2.new(0, -1, 0, 2),
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}),
			}),
		}),
		
		-- Скроллируемый контейнер товаров
		ProductsList = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -20, 1, -60),
			Position = UDim2.new(0, 10, 0, 50),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, totalContentHeight),
			ScrollBarThickness = 8,
			ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
		}, productElements)
	})
end

return ShopComponent
