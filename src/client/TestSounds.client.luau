--!strict
-- src/client/TestSounds.client.luau
-- Тестовый скрипт для проверки звуковых эффектов

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local SoundService = ModuleLoader.require("services/SoundService")

local player = Players.LocalPlayer

wait(2) -- Ждём инициализацию

-- Создаём экземпляр сервиса звуков
local soundService = SoundService.new()

print("=== ТЕСТ ЗВУКОВЫХ ЭФФЕКТОВ ===")
print("Нажмите клавиши для тестирования звуков:")
print("1 - Звук покупки")
print("2 - Звук магазина")
print("3 - Звук способности")
print("4 - Звук ошибки/кулдауна")

-- Обработчик нажатий клавиш
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	if input.KeyCode == Enum.KeyCode.One then
		print("🔊 Тестируем звук покупки...")
		soundService:playPurchaseSound()
	elseif input.KeyCode == Enum.KeyCode.Two then
		print("🔊 Тестируем звук магазина...")
		soundService:playShopToggleSound()
	elseif input.KeyCode == Enum.KeyCode.Three then
		print("🔊 Тестируем звук способности...")
		soundService:playAbilityUseSound()
	elseif input.KeyCode == Enum.KeyCode.Four then
		print("🔊 Тестируем звук ошибки/кулдауна...")
		soundService:playAbilityCooldownSound()
	end
end)

print("=== ТЕСТ ГОТОВ К ИСПОЛЬЗОВАНИЮ ===")
