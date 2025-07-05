--!strict
-- src/client/QuickTest.client.luau
-- Быстрый тест системы способностей - ОТКЛЮЧЕН

--[[
Этот файл автоматически активировал способности при запуске.
Теперь отключен для нормальной работы интерфейса.
Для включения тестов раскомментируйте код ниже.
]]

--[[

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

wait(3)

local player = Players.LocalPlayer
if not player.Character or not player.Character:FindFirstChild("Humanoid") then
	return
end

local humanoid = player.Character.Humanoid

print("⚡ Быстрый тест способностей:")
print("  Начальная скорость:", humanoid.WalkSpeed)

-- Импорт и создание сервиса
local ModuleLoader = require(ReplicatedStorage.shared.ModuleLoader)
local AbilityService = ModuleLoader.require("services/AbilityService")
local abilityService = AbilityService.new()

wait(2)

-- Тест ускорения
local result = abilityService:activateAbility(player, "speed_boost")
if result.success then
	print("✅ Ускорение активировано!")
	wait(1)
	print("  Новая скорость:", humanoid.WalkSpeed)
	print("  Эффект завершится через 15 секунд")
	print("  Следующая активация через 30 секунд после завершения")
else
	print("❌ Ошибка:", result.message)
end

]]
