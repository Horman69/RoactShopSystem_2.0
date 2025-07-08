--!strict
-- debug/ShieldBugFixer.luau
-- Быстрое тестирование исправления ошибки с ауроой щита

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShieldBugFixer = {}

function ShieldBugFixer.testShieldActivation()
    local player = Players.LocalPlayer
    if not player then 
        warn("❌ ShieldBugFixer: Игрок не найден")
        return
    end
    
    print("🧪 === ТЕСТ ИСПРАВЛЕНИЯ ОШИБКИ ЩИТА ===")
    print("📅 Время:", os.date("%H:%M:%S"))
    
    -- Пытаемся загрузить AbilityService
    local success, AbilityService = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        return ModuleLoader.require("services/AbilityService").new()
    end)
    
    if not success then
        warn("❌ Ошибка загрузки AbilityService:", AbilityService)
        return
    end
    
    print("✅ AbilityService загружен успешно")
    
    -- Проверяем доступность способности щита
    local hasShield = AbilityService:isAbilityOwned(player, "shield_aura")
    print("🛡️ Владение щитом:", hasShield and "✅ Есть" or "❌ Нет")
    
    -- Если нет щита, выдаем его
    if not hasShield then
        print("🔧 Выдаем способность щита...")
        AbilityService:grantAbility(player, "shield_aura")
        hasShield = AbilityService:isAbilityOwned(player, "shield_aura")
        print("🛡️ После выдачи:", hasShield and "✅ Есть" or "❌ Все еще нет")
    end
    
    if not hasShield then
        warn("❌ Не удалось получить способность щита")
        return
    end
    
    -- Пытаемся активировать щит
    print("🚀 Активируем способность щита...")
    
    local result = AbilityService:activateAbility(player, "shield_aura")
    
    if result.success then
        print("✅ УСПЕХ: Щит активирован!")
        print("💬 Сообщение:", result.message)
        print("🛡️ Проверьте появление ауры вокруг персонажа")
        
        -- Мониторим состояние щита
        spawn(function()
            for i = 1, 10 do
                wait(1)
                local isOnCooldown = AbilityService:isAbilityOnCooldown(player, "shield_aura")
                local timeLeft = AbilityService:getCooldownTimeLeft(player, "shield_aura")
                
                print(string.format("⏱️ T+%d сек: Кулдаун=%s, Осталось=%.1f", 
                    i, 
                    isOnCooldown and "🔒" or "✅", 
                    timeLeft
                ))
                
                if not isOnCooldown then
                    print("🎉 Щит снова готов к использованию!")
                    break
                end
            end
        end)
        
    else
        print("❌ ОШИБКА: Не удалось активировать щит")
        print("💬 Сообщение:", result.message)
        
        local isOnCooldown = AbilityService:isAbilityOnCooldown(player, "shield_aura")
        if isOnCooldown then
            local timeLeft = AbilityService:getCooldownTimeLeft(player, "shield_aura")
            print("🔒 Щит на кулдауне, осталось:", timeLeft, "сек")
        end
    end
end

function ShieldBugFixer.testAbilityConfig()
    print("🔧 === ТЕСТ ЗАГРУЗКИ AbilityConfig ===")
    
    local success, AbilityConfig = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        return ModuleLoader.require("shared/AbilityConfig")
    end)
    
    if not success then
        warn("❌ Ошибка загрузки AbilityConfig:", AbilityConfig)
        return
    end
    
    print("✅ AbilityConfig загружен успешно")
    
    -- Проверяем методы
    local allAbilities = AbilityConfig.getAllAbilities()
    print("📊 Всего способностей:", #allAbilities)
    
    -- Ищем способность щита
    local shieldAbility = AbilityConfig.getAbilityById("shield_aura")
    if shieldAbility then
        print("🛡️ Способность щита найдена:")
        print("  • Имя:", shieldAbility.name)
        print("  • Длительность:", shieldAbility.baseDuration, "сек")
        print("  • Кулдаун:", shieldAbility.cooldown, "сек")
        print("  • Эффекты:", #shieldAbility.effects)
    else
        warn("❌ Способность щита не найдена в конфигурации!")
    end
end

function ShieldBugFixer.testPlayerStatsService()
    print("🔧 === ТЕСТ PlayerStatsService ===")
    
    local success, PlayerStatsService = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        return ModuleLoader.require("services/PlayerStatsService").new()
    end)
    
    if not success then
        warn("❌ Ошибка загрузки PlayerStatsService:", PlayerStatsService)
        return
    end
    
    print("✅ PlayerStatsService загружен успешно")
    print("🔧 Проверьте логи на предмет загрузки ShieldAuraService")
end

function ShieldBugFixer.fullTest()
    print("🧪 === ПОЛНЫЙ ТЕСТ СИСТЕМЫ ЩИТА ===")
    print("📅 Начало:", os.date("%H:%M:%S"))
    
    ShieldBugFixer.testAbilityConfig()
    wait(1)
    
    ShieldBugFixer.testPlayerStatsService()
    wait(1)
    
    ShieldBugFixer.testShieldActivation()
    
    print("🏁 === ТЕСТ ЗАВЕРШЕН ===")
end

return ShieldBugFixer
