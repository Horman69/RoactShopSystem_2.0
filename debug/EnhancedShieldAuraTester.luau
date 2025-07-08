--!strict
-- debug/EnhancedShieldAuraTester.luau
-- Тестер для демонстрации улучшенной деликатной ауры щита

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))

-- Функция безопасного получения сервиса
local function getShieldAuraService()
	local success, shieldService = pcall(function()
		return ModuleLoader.LoadModule("ShieldAuraService")
	end)
	
	if success and shieldService then
		return shieldService
	else
		warn("⚠️ EnhancedShieldAuraTester: Не удалось загрузить ShieldAuraService:", shieldService)
		return nil
	end
end

local EnhancedShieldAuraTester = {}

function EnhancedShieldAuraTester.runTests()
	print("🧪 === Тестер улучшенной ауры щита ===")
	print("📋 Новые улучшения:")
	print("   • Размер ауры увеличен до 12x12x12")
	print("   • Базовая прозрачность: 0.85 (очень деликатная)")
	print("   • Амплитуда пульсации: 0.08 (едва заметная)")
	print("   • Скорость пульсации: 1.5 (медленная и спокойная)")
	print("   • Яркость свечения: 0.8 (мягкое свечение)")
	print("   • Радиус свечения: 16 (широкое распределение)")
	print("   • Диапазон прозрачности: 0.82-0.95 (всегда очень прозрачно)")
	print("   • Еще более медленное вращение")
	print("")
	
	local player = Players.LocalPlayer
	if not player then
		warn("❌ Игрок не найден")
		return
	end
	
	local shieldService = getShieldAuraService()
	if not shieldService then
		warn("❌ ShieldAuraService недоступен")
		return
	end
	
	print("🛡️ Тестирование деликатной ауры щита...")
	print("Управление:")
	print("   [1] - Активировать ауру на 10 сек")
	print("   [2] - Активировать ауру на 30 сек (для длительного наблюдения)")
	print("   [3] - Удалить все ауры")
	print("   [4] - Показать статистику")
	print("")
	
	-- Счетчики для статистики
	local stats = {
		auraCount = 0,
		activations = 0,
		totalDuration = 0
	}
	
	-- Обработчик клавиш
	local connection
	connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.One then
			print("🟢 Активация деликатной ауры на 10 секунд...")
			shieldService:createShieldAura(player, "enhanced_test_shield_10", 10)
			stats.activations = stats.activations + 1
			stats.totalDuration = stats.totalDuration + 10
			
		elseif input.KeyCode == Enum.KeyCode.Two then
			print("🟢 Активация деликатной ауры на 30 секунд (для детального наблюдения)...")
			shieldService:createShieldAura(player, "enhanced_test_shield_30", 30)
			stats.activations = stats.activations + 1
			stats.totalDuration = stats.totalDuration + 30
			
		elseif input.KeyCode == Enum.KeyCode.Three then
			print("🔴 Удаление всех аур...")
			shieldService:removeAllShieldAuras(player)
			
		elseif input.KeyCode == Enum.KeyCode.Four then
			print("📊 === Статистика тестирования ===")
			print("   Активаций:", stats.activations)
			print("   Общая длительность:", stats.totalDuration, "сек")
			print("   Среднее время:", stats.activations > 0 and (stats.totalDuration / stats.activations) or 0, "сек")
			print("")
			
		elseif input.KeyCode == Enum.KeyCode.Escape then
			print("🚪 Завершение тестирования...")
			connection:Disconnect()
			shieldService:removeAllShieldAuras(player)
		end
	end)
	
	print("✅ Тестер запущен! Нажмите [Esc] для выхода")
	
	-- Автодемонстрация
	spawn(function()
		wait(2)
		print("🎬 Автодемонстрация: показываем деликатную ауру на 15 секунд...")
		shieldService:createShieldAura(player, "auto_demo_enhanced", 15)
		stats.activations = stats.activations + 1
		stats.totalDuration = stats.totalDuration + 15
	end)
end

-- Функция для сравнения старых и новых настроек
function EnhancedShieldAuraTester.showComparison()
	print("📊 === Сравнение настроек ауры ===")
	print("")
	print("СТАРЫЕ НАСТРОЙКИ:")
	print("   Размер: 10x10x10")
	print("   Базовая прозрачность: 0.8")
	print("   Амплитуда пульсации: 0.15")
	print("   Скорость пульсации: 2")
	print("   Яркость свечения: 1.2")
	print("   Диапазон прозрачности: 0.75-0.95")
	print("")
	print("НОВЫЕ НАСТРОЙКИ (УЛУЧШЕННЫЕ):")
	print("   Размер: 12x12x12 (+20%)")
	print("   Базовая прозрачность: 0.85 (+6% прозрачности)")
	print("   Амплитуда пульсации: 0.08 (-47% навязчивости)")
	print("   Скорость пульсации: 1.5 (-25% быстроты)")
	print("   Яркость свечения: 0.8 (-33% яркости)")
	print("   Диапазон прозрачности: 0.82-0.95 (более узкий)")
	print("")
	print("РЕЗУЛЬТАТ: Аура стала более деликатной, менее навязчивой")
	print("и более профессиональной на вид!")
end

return EnhancedShieldAuraTester
