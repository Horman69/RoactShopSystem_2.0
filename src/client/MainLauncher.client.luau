--!strict
-- src/client/MainLauncher.client.luau
-- Главный запуск интерфейса - загружает AppController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Ждем загрузки игрока
local player = Players.LocalPlayer
repeat wait() until player.Character

print("🚀 MainLauncher: Запуск главного интерфейса...")

-- Очищаем старые UI
local function cleanupOldUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local oldUIs = {"MainApp", "TestScreenGui", "ShopApp", "AbilityUI", "MainInterfaceUI"}
	for _, uiName in ipairs(oldUIs) do
		local oldUI = playerGui:FindFirstChild(uiName)
		if oldUI then
			oldUI:Destroy()
			print("🧹 Очищен старый UI:", uiName)
		end
	end
end

cleanupOldUI()

-- Небольшая задержка для загрузки
wait(0.5)

-- Загружаем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local AppController = ModuleLoader.require("App/AppController")

-- Монтируем AppController - он содержит весь функционал (магазин + способности)
print("📱 MainLauncher: Монтируем AppController...")
local appElement = Roact.createElement(AppController)
local appHandle = Roact.mount(appElement, player:WaitForChild("PlayerGui"), "MainApp")

print("✅ MainLauncher: Главный интерфейс успешно загружен!")
