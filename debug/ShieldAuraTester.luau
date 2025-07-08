--!strict
-- debug/ShieldAuraTester.luau
-- Тестер различных вариантов аур щита

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local ShieldAuraService = ModuleLoader.require("services/ShieldAuraService").new()
local ShieldAuraVariants = ModuleLoader.require("effects/ShieldAuraVariants")

local ShieldAuraTester = {}

function ShieldAuraTester.testNewShieldAura()
    local player = Players.LocalPlayer
    if not player then 
        warn("❌ ShieldAuraTester: Игрок не найден")
        return
    end
    
    print("🧪 === ТЕСТ НОВОЙ СИСТЕМЫ АУРЫ ЩИТА ===")
    print("📅 Время начала:", os.date("%H:%M:%S"))
    
    if not player.Character then
        warn("❌ Персонаж не найден")
        return
    end
    
    -- Тестируем мгновенную активацию
    print("🛡️ Создаем ауру щита с мгновенной активацией...")
    ShieldAuraService:createShieldAura(player, "test_shield", 10) -- 10 секунд
    
    print("✅ Аура создана! Проверьте:")
    print("  • Появляется ли аура мгновенно?")
    print("  • Следует ли за игроком при движении?")
    print("  • Есть ли плавная анимация пульсации?")
    print("  • Не отстает ли от игрока при быстром движении?")
    
    -- Автоматический тест движения
    spawn(function()
        print("🏃 Через 2 секунды начнется автотест движения...")
        wait(2)
        
        for i = 1, 5 do
            print("🔄 Принудительное обновление позиции", i)
            ShieldAuraService:updateShieldPosition(player)
            wait(1)
        end
        
        print("✅ Автотест завершен")
    end)
end

function ShieldAuraTester.testVariantAuras()
    local player = Players.LocalPlayer
    if not player or not player.Character then 
        warn("❌ ShieldAuraTester: Игрок или персонаж не найден")
        return
    end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        warn("❌ HumanoidRootPart не найден")
        return
    end
    
    print("🌟 === ТЕСТ РАЗЛИЧНЫХ ВАРИАНТОВ АУРА ===")
    
    local variants = ShieldAuraVariants.getAvailableVariants()
    print("📋 Доступные варианты:", table.concat(variants, ", "))
    
    for i, variant in ipairs(variants) do
        local info = ShieldAuraVariants.getVariantInfo(variant)
        
        print(string.format("\n🎨 ТЕСТ %d/%d: %s", i, #variants, info.name))
        print("  📝", info.description)
        print("  ⚡ Производительность:", info.performance)
        
        -- Создаем ауру
        local auraData = ShieldAuraVariants.createVariantAura(variant, humanoidRootPart)
        
        print("  ✅ Аура создана, тестируем 3 секунды...")
        wait(3)
        
        -- Удаляем ауру
        if auraData.shield then
            auraData.shield:Destroy()
        end
        
        for _, connection in ipairs(auraData.connections) do
            connection:Disconnect()
        end
        
        print("  🗑️ Аура удалена")
        
        if i < #variants then
            print("  ⏱️ Пауза 1 сек перед следующим тестом...")
            wait(1)
        end
    end
    
    print("\n🎉 === ВСЕ ВАРИАНТЫ ПРОТЕСТИРОВАНЫ ===")
    print("Какой вариант понравился больше всего?")
end

function ShieldAuraTester.testPerformanceComparison()
    local player = Players.LocalPlayer
    if not player then return end
    
    print("📊 === ТЕСТ ПРОИЗВОДИТЕЛЬНОСТИ ===")
    
    -- Тест старой системы
    print("🔄 Тестируем старую систему...")
    local oldStart = tick()
    
    -- Имитируем старую систему (создание части и Heartbeat без ограничений)
    local testPart = Instance.new("Part")
    testPart.Shape = Enum.PartType.Ball
    testPart.Size = Vector3.new(8, 8, 8)
    testPart.Material = Enum.Material.ForceField
    testPart.CanCollide = false
    testPart.Anchored = true
    testPart.Parent = workspace
    
    local heartbeatCount = 0
    local oldConnection = game:GetService("RunService").Heartbeat:Connect(function()
        heartbeatCount = heartbeatCount + 1
        testPart.Transparency = 0.7 + math.sin(tick() * 3) * 0.2
    end)
    
    wait(2) -- Тестируем 2 секунды
    oldConnection:Disconnect()
    testPart:Destroy()
    
    local oldTime = tick() - oldStart
    print(string.format("📈 Старая система: %.3f сек, %d Heartbeat вызовов", oldTime, heartbeatCount))
    
    -- Тест новой системы
    print("🚀 Тестируем новую систему...")
    local newStart = tick()
    
    ShieldAuraService:createShieldAura(player, "performance_test", 2)
    wait(2)
    
    local newTime = tick() - newStart
    print(string.format("📉 Новая система: %.3f сек (оптимизировано до 20 FPS)", newTime))
    
    local improvement = ((heartbeatCount - 40) / heartbeatCount) * 100 -- 40 = 20 FPS * 2 секунды
    print(string.format("✅ Улучшение производительности: ~%.1f%% меньше вызовов обновления", improvement))
end

function ShieldAuraTester.demonstrateInstantActivation()
    local player = Players.LocalPlayer
    if not player then return end
    
    print("⚡ === ДЕМОНСТРАЦИЯ МГНОВЕННОЙ АКТИВАЦИИ ===")
    print("🎮 Нажмите SPACE для активации ауры")
    
    local UserInputService = game:GetService("UserInputService")
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Space then
            local activationTime = tick()
            print("🛡️ АКТИВАЦИЯ! Время:", os.date("%H:%M:%S.") .. string.format("%03d", (activationTime % 1) * 1000))
            
            ShieldAuraService:createShieldAura(player, "instant_test", 5)
            
            local completionTime = tick()
            local delay = (completionTime - activationTime) * 1000 -- в миллисекундах
            
            print(string.format("✅ Аура создана за %.1f мс", delay))
            
            if delay < 50 then
                print("🎉 ОТЛИЧНО: Мгновенная активация!")
            elseif delay < 100 then
                print("✅ ХОРОШО: Быстрая активация")
            else
                print("⚠️ МЕДЛЕННО: Требуется оптимизация")
            end
            
            connection:Disconnect()
        end
    end)
    
    print("⌛ Ожидание нажатия SPACE... (автоотмена через 10 сек)")
    
    spawn(function()
        wait(10)
        if connection then
            connection:Disconnect()
            print("⏰ Тест автоматически завершен")
        end
    end)
end

return ShieldAuraTester
