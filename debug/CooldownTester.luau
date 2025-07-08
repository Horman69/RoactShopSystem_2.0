--!strict
-- debug/CooldownTester.luau
-- Инструмент для тестирования кулдаунов способностей в реальном времени

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local AbilityService = ModuleLoader.require("services/AbilityService").new()

local CooldownTester = {}

function CooldownTester.testBasicAbilities()
    local player = Players.LocalPlayer
    if not player then 
        warn("❌ CooldownTester: Игрок не найден")
        return
    end
    
    print("🧪 === ТЕСТИРОВАНИЕ КУЛДАУНОВ СПОСОБНОСТЕЙ ===")
    print("📅 Время начала:", os.date("%H:%M:%S"))
    
    local abilities = {"speed_boost", "shield_aura", "jump_boost"}
    
    for i, abilityId in ipairs(abilities) do
        print("\n🔬 ТЕСТ", i, "- Способность:", abilityId)
        
        -- Проверяем начальное состояние
        local isOwned = AbilityService:isAbilityOwned(player, abilityId)
        local isOnCooldown = AbilityService:isAbilityOnCooldown(player, abilityId)
        local timeLeft = AbilityService:getCooldownTimeLeft(player, abilityId)
        local uiTimeLeft = AbilityService:getUITimeLeft(player, abilityId)
        
        print("  📊 Статус:")
        print("    • Владение:", isOwned and "✅ Есть" or "❌ Нет")
        print("    • Кулдаун:", isOnCooldown and "🔒 Активен" or "✅ Готов")
        print("    • Время кулдауна:", string.format("%.2f сек", timeLeft))
        print("    • UI время:", string.format("%.2f сек", uiTimeLeft))
        
        -- Если способность готова и принадлежит игроку, активируем
        if isOwned and not isOnCooldown then
            print("  🚀 Активируем способность...")
            local result = AbilityService:activateAbility(player, abilityId)
            
            if result.success then
                print("  ✅ Активация успешна:", result.message)
                
                -- Мониторим состояние в течение нескольких секунд
                spawn(function()
                    for t = 1, 35 do -- Мониторим 35 секунд
                        wait(1)
                        
                        local currentCooldown = AbilityService:isAbilityOnCooldown(player, abilityId)
                        local currentTimeLeft = AbilityService:getCooldownTimeLeft(player, abilityId)
                        local currentUITime = AbilityService:getUITimeLeft(player, abilityId)
                        local isUnavailable = AbilityService:isAbilityUnavailableForUI(player, abilityId)
                        
                        if t <= 10 or currentTimeLeft > 0 or t % 5 == 0 then
                            print(string.format("    ⏱️ T+%02d сек | Кулдаун: %s | Осталось: %.1f | UI: %.1f | Недоступен: %s", 
                                t,
                                currentCooldown and "🔒" or "✅",
                                currentTimeLeft,
                                currentUITime,
                                isUnavailable and "🔒" or "✅"
                            ))
                        end
                        
                        -- Важный момент: когда кулдаун заканчивается
                        if t > 1 and not currentCooldown and currentTimeLeft <= 0 then
                            print("    🎉 КУЛДАУН ЗАКОНЧИЛСЯ на T+" .. t .. " сек!")
                            break
                        end
                    end
                end)
            else
                print("  ❌ Ошибка активации:", result.message)
            end
        end
        
        wait(2) -- Небольшая пауза между тестами
    end
    
    print("\n🏁 === ТЕСТИРОВАНИЕ ЗАВЕРШЕНО ===")
end

function CooldownTester.continuousMonitor()
    local player = Players.LocalPlayer
    if not player then return end
    
    print("📡 === НЕПРЕРЫВНЫЙ МОНИТОРИНГ КУЛДАУНОВ ===")
    print("⚠️ Для остановки перезагрузите скрипт")
    
    local abilities = {"speed_boost", "shield_aura", "jump_boost"}
    local previousStates = {}
    
    -- Инициализируем предыдущие состояния
    for _, abilityId in ipairs(abilities) do
        previousStates[abilityId] = AbilityService:isAbilityUnavailableForUI(player, abilityId)
    end
    
    spawn(function()
        while true do
            wait(0.1) -- Проверяем каждые 100 мс
            
            for _, abilityId in ipairs(abilities) do
                local currentState = AbilityService:isAbilityUnavailableForUI(player, abilityId)
                local previousState = previousStates[abilityId]
                
                -- Отслеживаем изменения состояния
                if previousState ~= currentState then
                    local timeStamp = os.date("%H:%M:%S")
                    if previousState and not currentState then
                        print(string.format("🟢 [%s] %s стал ДОСТУПЕН (кулдаун закончился)", timeStamp, abilityId))
                    elseif not previousState and currentState then
                        print(string.format("🔴 [%s] %s стал НЕДОСТУПЕН (кулдаун начался)", timeStamp, abilityId))
                    end
                    
                    previousStates[abilityId] = currentState
                end
            end
        end
    end)
end

function CooldownTester.testQuickActivations()
    local player = Players.LocalPlayer
    if not player then return end
    
    print("⚡ === ТЕСТ БЫСТРЫХ АКТИВАЦИЙ ===")
    
    -- Пытаемся быстро активировать одну способность несколько раз
    local abilityId = "speed_boost"
    
    for i = 1, 5 do
        print("\n🔄 Попытка", i, "активации", abilityId)
        local result = AbilityService:activateAbility(player, abilityId)
        print("  📤 Результат:", result.success and "✅ Успех" or "❌ Неудача")
        print("  💬 Сообщение:", result.message)
        
        wait(0.5) -- Небольшая пауза между попытками
    end
end

-- Публичный API
return {
    testBasicAbilities = CooldownTester.testBasicAbilities,
    continuousMonitor = CooldownTester.continuousMonitor,
    testQuickActivations = CooldownTester.testQuickActivations,
}
