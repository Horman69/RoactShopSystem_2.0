--!strict
-- debug/QuickCooldownTest.luau
-- Быстрый тест для проверки проблемы с последней способностью

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local AbilityService = ModuleLoader.require("services/AbilityService").new()

local QuickTest = {}

function QuickTest.testSequentialActivation()
    local player = Players.LocalPlayer
    if not player then 
        warn("❌ QuickTest: Игрок не найден")
        return
    end
    
    print("🧪 === ТЕСТ ПОСЛЕДОВАТЕЛЬНОЙ АКТИВАЦИИ СПОСОБНОСТЕЙ ===")
    print("📅 Время начала:", os.date("%H:%M:%S"))
    
    local abilities = {"speed_boost", "shield_aura", "jump_boost"}
    local activationDelay = 2 -- секунд между активациями
    
    -- Активируем все способности последовательно
    for i, abilityId in ipairs(abilities) do
        print(string.format("\n🚀 АКТИВАЦИЯ %d/%d: %s", i, #abilities, abilityId))
        
        local isOwned = AbilityService:isAbilityOwned(player, abilityId)
        local isOnCooldown = AbilityService:isAbilityOnCooldown(player, abilityId)
        
        print("  📊 До активации:")
        print("    • Владение:", isOwned and "✅" or "❌")
        print("    • Кулдаун:", isOnCooldown and "🔒" or "✅")
        
        if isOwned and not isOnCooldown then
            local result = AbilityService:activateAbility(player, abilityId)
            print("  📤 Результат активации:", result.success and "✅ Успех" or "❌ Неудача")
            print("  💬 Сообщение:", result.message)
            
            if result.success then
                -- Запускаем мониторинг для этой способности
                spawn(function()
                    QuickTest.monitorSpecificAbility(abilityId, i == #abilities) -- Особое внимание к последней
                end)
            end
        else
            print("  ⚠️ Способность недоступна для активации")
        end
        
        if i < #abilities then
            print(string.format("  ⏱️ Ожидание %d сек до следующей активации...", activationDelay))
            wait(activationDelay)
        end
    end
    
    print("\n🎯 Все способности активированы! Мониторинг продолжается...")
    print("⚠️ Обратите особое внимание на", abilities[#abilities], "- это последняя способность!")
end

function QuickTest.monitorSpecificAbility(abilityId, isLast)
    local player = Players.LocalPlayer
    if not player then return end
    
    local prefix = isLast and "🔴 ПОСЛЕДНЯЯ" or "🟡"
    print(string.format("%s === МОНИТОРИНГ: %s ===", prefix, abilityId))
    
    local wasOnCooldown = nil
    local monitoringTime = 0
    
    while monitoringTime < 35 do -- Мониторим 35 секунд
        wait(0.5) -- Проверяем каждые 0.5 секунды
        monitoringTime = monitoringTime + 0.5
        
        local isOnCooldown = AbilityService:isAbilityOnCooldown(player, abilityId)
        local isUnavailable = AbilityService:isAbilityUnavailableForUI(player, abilityId)
        local timeLeft = AbilityService:getCooldownTimeLeft(player, abilityId)
        local uiTimeLeft = AbilityService:getUITimeLeft(player, abilityId)
        
        -- Отслеживаем изменения состояния
        if wasOnCooldown ~= nil and wasOnCooldown ~= isOnCooldown then
            local status = isOnCooldown and "🔒 НАЧАЛСЯ" or "✅ ЗАКОНЧИЛСЯ"
            print(string.format("%s [%.1f] %s: Кулдаун %s", prefix, monitoringTime, abilityId, status))
            
            if not isOnCooldown and isLast then
                print("🎉 КРИТИЧЕСКИ ВАЖНО: Последняя способность должна стать доступной СЕЙЧАС!")
                
                -- Дополнительная проверка UI
                wait(0.1)
                local finalUICheck = AbilityService:isAbilityUnavailableForUI(player, abilityId)
                print(string.format("🔍 Финальная проверка UI: %s %s", 
                    abilityId, 
                    finalUICheck and "❌ ВСЕ ЕЩЕ НЕДОСТУПЕН" or "✅ ДОСТУПЕН"
                ))
            end
        end
        
        wasOnCooldown = isOnCooldown
        
        -- Логируем каждые 5 секунд или при важных моментах
        if monitoringTime % 5 == 0 or timeLeft <= 1 then
            print(string.format("%s [%.1f] %s: CD=%.1f UI=%.1f Недоступен=%s", 
                prefix, monitoringTime, abilityId, timeLeft, uiTimeLeft, 
                isUnavailable and "🔒" or "✅"
            ))
        end
        
        -- Выходим если кулдаун закончился
        if timeLeft <= 0 and not isOnCooldown then
            print(string.format("%s [%.1f] %s: Мониторинг завершен - способность готова!", prefix, monitoringTime, abilityId))
            break
        end
    end
end

return QuickTest
