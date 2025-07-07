-- Тест загрузки AbilityConfig
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🧪 Тестирование загрузки AbilityConfig...")

-- Тест 1: ModuleLoader
local success1, ModuleLoader = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
end)

if success1 then
    print("✅ ModuleLoader загружен успешно")
else
    print("❌ Ошибка загрузки ModuleLoader:", ModuleLoader)
    return
end

-- Тест 2: AbilityConfig через ModuleLoader
local success2, AbilityConfig = pcall(function()
    return ModuleLoader.require("shared/AbilityConfig")
end)

if success2 then
    print("✅ AbilityConfig загружен успешно")
    print("📊 Тип AbilityConfig:", type(AbilityConfig))
    
    -- Проверяем методы
    if AbilityConfig.getAllAbilities then
        print("✅ Метод getAllAbilities найден")
        
        local abilities = AbilityConfig.getAllAbilities()
        print("📊 Количество способностей:", #abilities)
        
        for i, ability in ipairs(abilities) do
            if i <= 3 then -- Показываем только первые 3
                print("  -", ability.id, ":", ability.name, "(длительность:", ability.baseDuration, "кулдаун:", ability.cooldown, ")")
            end
        end
    else
        print("❌ Метод getAllAbilities не найден")
    end
else
    print("❌ Ошибка загрузки AbilityConfig:", AbilityConfig)
end

print("🧪 Тест завершен")
