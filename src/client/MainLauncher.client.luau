--!strict
-- src/client/MainLauncher.client.luau
-- Главный запуск интерфейса - загружает AppController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Ждем загрузки игрока
local player = Players.LocalPlayer
repeat
	wait()
until player.Character

print("🚀 MainLauncher: Запуск главного интерфейса...")

-- Очищаем старые UI
local function cleanupOldUI()
	local playerGui = player:WaitForChild("PlayerGui")
	local oldUIs = { "MainApp", "TestScreenGui", "ShopApp", "AbilityUI", "MainInterfaceUI" }
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
print("📦 MainLauncher: Загружаем ModuleLoader...")
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))

print("📦 MainLauncher: Загружаем Roact...")
local Roact = ModuleLoader.require("Packages/roact")

print("📦 MainLauncher: Загружаем AppController...")
local AppController = ModuleLoader.require("App/AppController")

print("🔧 MainLauncher: AppController загружен, тип:", type(AppController))

-- Монтируем AppController - он содержит весь функционал (магазин + способности)
print("📱 MainLauncher: Монтируем AppController...")

local success, result = pcall(function()
	local appElement = Roact.createElement(AppController)
	print("🎯 MainLauncher: Элемент создан:", appElement)
	local appHandle = Roact.mount(appElement, player:WaitForChild("PlayerGui"), "MainApp")
	print("🎯 MainLauncher: Монтирование завершено:", appHandle)
	return appHandle
end)

if success then
	print("✅ MainLauncher: Главный интерфейс успешно загружен!")
else
	print("❌ MainLauncher: Ошибка при монтировании:", result)
end
print("📋 MainLauncher: Проверяем, что создалось...")

wait(1)
local playerGui = player:WaitForChild("PlayerGui")
local mainApp = playerGui:FindFirstChild("MainApp")
if mainApp then
	print("✅ MainApp создан успешно!")
	print("📊 Количество дочерних элементов:", #mainApp:GetChildren())
else
	print("❌ MainApp НЕ создан!")
end
