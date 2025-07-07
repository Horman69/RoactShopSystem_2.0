-- Тест основных функций прогресс-баров
-- Запуск: поместить в ServerScriptService и выполнить

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Проверяем структуру файлов
print("🧪 ТЕСТИРОВАНИЕ ПРОГРЕСС-БАРОВ")
print("============================")

-- 1. Проверяем наличие AbilityConfig
local function testAbilityConfig()
    print("\n1️⃣ Проверка AbilityConfig...")
    
    local success, AbilityConfig = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        return ModuleLoader.require("shared/AbilityConfig")
    end)
    
    if success and AbilityConfig then
        print("✅ AbilityConfig загружен успешно")
        print("📊 Количество способностей:", #AbilityConfig)
        
        -- Проверяем конкретные способности
        for _, ability in ipairs(AbilityConfig) do
            if ability.id == "speed_boost" then
                print("⚡ speed_boost: длительность =", ability.baseDuration, "сек, кулдаун =", ability.cooldown, "сек")
            elseif ability.id == "shield_aura" then
                print("🛡️ shield_aura: длительность =", ability.baseDuration, "сек, кулдаун =", ability.cooldown, "сек")
            elseif ability.id == "jump_boost" then
                print("🚀 jump_boost: длительность =", ability.baseDuration, "сек, кулдаун =", ability.cooldown, "сек")
            end
        end
    else
        print("❌ Ошибка загрузки AbilityConfig:", AbilityConfig)
    end
end

-- 2. Проверяем структуру AbilityPanel
local function testAbilityPanel()
    print("\n2️⃣ Проверка AbilityPanel...")
    
    local success, error = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        local AbilityPanel = ModuleLoader.require("App/AbilityPanel")
        print("✅ AbilityPanel загружен успешно")
        
        -- Проверяем, что это Roact компонент
        if AbilityPanel.extend then
            print("✅ AbilityPanel является корректным Roact компонентом")
        else
            print("❌ AbilityPanel не является Roact компонентом")
        end
    end)
    
    if not success then
        print("❌ Ошибка загрузки AbilityPanel:", error)
    end
end

-- 3. Проверяем AbilityService
local function testAbilityService()
    print("\n3️⃣ Проверка AbilityService...")
    
    local success, error = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        local AbilityService = ModuleLoader.require("services/AbilityService")
        local service = AbilityService.new()
        
        print("✅ AbilityService создан успешно")
        
        -- Проверяем основные методы
        if service.getActiveEffects then
            print("✅ Метод getActiveEffects найден")
        end
        if service.isAbilityUnavailableForUI then
            print("✅ Метод isAbilityUnavailableForUI найден")
        end
        if service.getUITimeLeft then
            print("✅ Метод getUITimeLeft найден")
        end
    end)
    
    if not success then
        print("❌ Ошибка создания AbilityService:", error)
    end
end

-- Запускаем тесты
testAbilityConfig()
testAbilityService() 
testAbilityPanel()

print("\n🎯 РЕЗУЛЬТАТ ТЕСТИРОВАНИЯ")
print("=======================")
print("Если все тесты прошли успешно, прогресс-бары готовы к работе!")
print("Следующий шаг: протестировать в игре активацией способностей.")
