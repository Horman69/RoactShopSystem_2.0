-- Тест всех импортов AppController
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("🧪 ТЕСТИРОВАНИЕ ИМПОРТОВ APPCONTROLLER")
print("====================================")

-- Тест ModuleLoader
local success, ModuleLoader = pcall(function()
    return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
end)

if not success then
    print("❌ ModuleLoader не загружен:", ModuleLoader)
    return
end
print("✅ ModuleLoader загружен")

-- Список всех модулей из AppController
local modules = {
    "Packages/roact",
    "services/CurrencyService", 
    "services/ShopService",
    "services/AbilityService",
    "services/SimplePlatformService",
    "services/SimpleSoundService",
    "shared/AbilityConfig",
    "App/WalletComponent",
    "App/ShopComponent",
    "App/AbilityPanel"
}

-- Тестируем каждый модуль
for _, modulePath in ipairs(modules) do
    local success, result = pcall(function()
        return ModuleLoader.require(modulePath)
    end)
    
    if success then
        print("✅", modulePath, "- загружен успешно")
        
        -- Дополнительная проверка для компонентов Roact
        if string.find(modulePath, "Component") or string.find(modulePath, "Panel") then
            if type(result) == "table" and result.extend then
                print("  📝 Это корректный Roact компонент")
            else
                print("  ⚠️ Возможно, не является Roact компонентом")
            end
        end
    else
        print("❌", modulePath, "- ОШИБКА:", result)
    end
end

-- Тест прямых импортов
print("\n🔍 ТЕСТИРОВАНИЕ ПРЯМЫХ ИМПОРТОВ")
print("==============================")

local directImports = {
    {path = "shared/ShopConfig", name = "ShopConfig"},
    {path = "shared/Types", name = "Types"}
}

for _, import in ipairs(directImports) do
    local success, result = pcall(function()
        return require(ReplicatedStorage:WaitForChild("shared"):WaitForChild(import.name))
    end)
    
    if success then
        print("✅", import.name, "- загружен успешно")
    else
        print("❌", import.name, "- ОШИБКА:", result)
    end
end

print("\n🎯 ТЕСТ ЗАВЕРШЕН")
print("===============")
print("Если все модули загружены успешно, AppController должен работать!")
