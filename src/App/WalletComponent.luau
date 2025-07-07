-- src/App/WalletComponent.luau
-- Современный компонент кошелька в едином стиле проекта

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")

-- Импортируем ShopConfig для единых стилей
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))

--[=[
	WalletComponent
	Современный компонент для отображения монет в едином стиле
	Пропсы:
	- coins (number): текущее количество монет
	- inShop (boolean): если true, позиционируется относительно контейнера
]=]
local WalletComponent = Roact.Component:extend("WalletComponent")

function WalletComponent:render()
	local inShop = self.props.inShop or false
	
	-- Компактные размеры для магазина
	local size = inShop and UDim2.new(1, 0, 1, 0) or UDim2.new(0, 100, 0, 35)
	local position = inShop and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 15, 0, 15)
	local textSize = inShop and 14 or 18
	
	return Roact.createElement("TextLabel", {
		Text = "💰 " .. tostring(self.props.coins or 0),
		Size = size,
		Position = position,
		
		-- ЕДИНЫЕ ЦВЕТА ИЗ SHOPCONFIG
		BackgroundTransparency = 0,
		BackgroundColor3 = ShopConfig.design.colors.background.card,
		TextColor3 = Color3.fromRGB(255, 215, 0), -- Золотой для монет
		
		-- ЕДИНАЯ ТИПОГРАФИКА
		Font = Enum.Font.GothamBold,
		TextSize = textSize,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BorderSizePixel = 0,
		TextStrokeTransparency = 0.2,
		TextStrokeColor3 = ShopConfig.design.shadow.color,
	}, {
		-- ЕДИНОЕ СКРУГЛЕНИЕ
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.small),
		}),
		
		-- СТИЛЬНАЯ РАМКА КАК У МАГАЗИНА И ПАНЕЛИ СПОСОБНОСТЕЙ
		UIStroke = Roact.createElement("UIStroke", {
			Color = ShopConfig.design.colors.accent.primary, -- Синий акцент как у других элементов
			Thickness = ShopConfig.design.stroke.thickness, -- Унифицированная толщина из ShopConfig
			Transparency = 0.3, -- Менее прозрачная для единого стиля
		}),
		
		-- ЕДИНАЯ ТЕНЬ
		WalletShadow = Roact.createElement("Frame", {
			Size = UDim2.new(1, 2, 1, 4),
			Position = UDim2.new(0, 1, 0, 2),
			BackgroundColor3 = ShopConfig.design.shadow.color,
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.small),
			}),
		}),
	})
end

return WalletComponent

