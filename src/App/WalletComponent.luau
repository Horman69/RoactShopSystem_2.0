-- src/App/WalletComponent.luau
-- Компонент Roact для отображения баланса монет пользователя

local Roact = require(game.ReplicatedStorage.Packages.roact)

--[=[
	WalletComponent
	Пропсы:
	- coins (number): текущее количество монет
]=]
local WalletComponent = Roact.Component:extend("WalletComponent")

function WalletComponent:render()
	return Roact.createElement("TextLabel", {
		Text = "Монеты: " .. tostring(self.props.coins),
		Size = UDim2.new(0, 220, 0, 50),
		Position = UDim2.new(0, 10, 0, 10),
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		TextColor3 = Color3.fromRGB(255, 215, 0),
		Font = Enum.Font.GothamBlack,
		TextSize = 32,
		BorderSizePixel = 0,
	}, {
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
	})
end

return WalletComponent
