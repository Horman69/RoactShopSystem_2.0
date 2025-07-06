-- src/App/WalletComponent.luau
-- Простой компонент Roact для отображения баланса монет пользователя

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")

--[=[
	WalletComponent
	Простой компонент для отображения монет
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
	local textSize = inShop and 14 or 18 -- Меньший шрифт в магазине
	
	return Roact.createElement("TextLabel", {
		Text = "💰 " .. tostring(self.props.coins or 0),
		Size = size,
		Position = position,
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromRGB(20, 30, 45),
		TextColor3 = Color3.fromRGB(255, 215, 0),
		Font = Enum.Font.GothamBold,
		TextSize = textSize, -- Используем переменную размера
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Center,
		BorderSizePixel = 0,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 6), -- Немного меньше скругление для компактности
		}),
	})
end

return WalletComponent
