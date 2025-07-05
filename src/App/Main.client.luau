local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Packages = ReplicatedStorage:WaitForChild("Packages")
local Roact = require(Packages:WaitForChild("roact"))

local Wallet = require(ReplicatedStorage:WaitForChild("Shop"):WaitForChild("Wallet"))
local WalletComponent = require(ReplicatedStorage:WaitForChild("App"):WaitForChild("WalletComponent"))
local ShopComponent = require(ReplicatedStorage:WaitForChild("App"):WaitForChild("ShopComponent"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Главный компонент приложения
local Main = Roact.Component:extend("Main")

function Main:init()
	-- Создаём кошелёк с начальными монетами
	self.wallet = Wallet.new(200)
	self:setState({ coins = self.wallet:getCoins() })
end

-- Функция для добавления монет (например, по кнопке)
function Main:addCoins()
	self.wallet:addCoins(50)
	self:setState({ coins = self.wallet:getCoins() })
end

-- Функция вызывается после покупки товара
function Main:onPurchase(product)
	-- Можно добавить логику добавления товара в инвентарь
	self:setState({ coins = self.wallet:getCoins() })
end

function Main:render()
	return Roact.createElement("ScreenGui", {}, {
		MainFrame = Roact.createElement("Frame", {
			Size = UDim2.new(0, 400, 0, 400),
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 0, 0),
		}, {
			Wallet = Roact.createElement(WalletComponent, {
				coins = self.state.coins,
			}),
			AddButton = Roact.createElement("TextButton", {
				Text = "+50 монет",
				Size = UDim2.new(0, 120, 0, 40),
				Position = UDim2.new(0, 10, 0, 70),
				BackgroundColor3 = Color3.fromRGB(100, 200, 100),
				TextSize = 20,
				["MouseButton1Click"] = function()
					self:addCoins()
				end,
			}),
			Shop = Roact.createElement(ShopComponent, {
				wallet = self.wallet,
				onPurchase = function(product)
					self:onPurchase(product)
				end,
			}),
		}),
	})
end

-- Монтируем главный компонент в PlayerGui
Roact.mount(Roact.createElement(Main), playerGui, "MainApp")
