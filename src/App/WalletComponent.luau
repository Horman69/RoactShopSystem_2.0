-- src/App/WalletComponent.luau
-- Компонент Roact для отображения баланса монет пользователя

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")

--[=[
	WalletComponent
	Пропсы:
	- coins (number): текущее количество монет
]=]
local WalletComponent = Roact.Component:extend("WalletComponent")

function WalletComponent:init()
	-- Инициализируем PlatformService
	self.platformService = PlatformService.new()
end

function WalletComponent:render()
	-- 📱 ПРОСТЫЕ АДАПТИВНЫЕ РАЗМЕРЫ
	local config = self.platformService:getConfig()
	
	return Roact.createElement("TextLabel", {
		Text = "Монеты: " .. tostring(self.props.coins),
		Size = config.walletSize,
		Position = UDim2.new(0, config.padding, 0, config.padding),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		TextColor3 = Color3.fromRGB(255, 215, 0),
		Font = Enum.Font.GothamBlack,
		TextSize = config.headerTextSize,
		BorderSizePixel = 0,
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, config.cornerRadius),
		}),
	})
end

return WalletComponent
