--!strict
-- debug/GreenShieldTester.luau
-- Тест зеленого цвета ауры щита

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GreenShieldTester = {}

function GreenShieldTester.testGreenShield()
    local player = Players.LocalPlayer
    if not player then 
        warn("❌ GreenShieldTester: Игрок не найден")
        return
    end
    
    print("🟢 === ТЕСТ ЗЕЛЕНОГО ЩИТА ===")
    print("📅 Время:", os.date("%H:%M:%S"))
    
    -- Загружаем новый сервис ауры
    local success, ShieldAuraService = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        return ModuleLoader.require("services/ShieldAuraService").new()
    end)
    
    if not success then
        warn("❌ Ошибка загрузки ShieldAuraService:", ShieldAuraService)
        return
    end
    
    print("✅ ShieldAuraService загружен успешно")
    
    -- Создаем зеленую ауру
    print("🟢 Создаем зеленую ауру щита...")
    ShieldAuraService:createShieldAura(player, "green_test", 10)
    
    print("✅ Зеленая аура создана!")
    print("🔍 Проверьте:")
    print("  • Цвет ауры зеленый (0, 255, 100)")
    print("  • Размер увеличен (12x12x12)")
    print("  • Прозрачность профессиональная (~85%)")
    print("  • Мягкая пульсация")
    
    -- Автоматический тест цветов
    spawn(function()
        wait(3)
        print("🔄 Сравниваем с другими цветами...")
        
        -- Создаем синюю ауру для сравнения
        print("🔵 Создаем синюю ауру для сравнения...")
        
        -- Временно создаем синюю ауру (старый цвет)
        local blueAura = Instance.new("Part")
        blueAura.Name = "BlueShieldComparison"
        blueAura.Shape = Enum.PartType.Ball
        blueAura.Material = Enum.Material.ForceField
        blueAura.CanCollide = false
        blueAura.Anchored = true
        blueAura.Size = Vector3.new(12, 12, 12)
        blueAura.Color = Color3.fromRGB(0, 170, 255) -- Старый синий цвет
        blueAura.Transparency = 0.85
        
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            blueAura.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(15, 0, 0) -- Сбоку
            blueAura.Parent = workspace
            
            print("🔵 Синяя аура создана сбоку для сравнения")
            print("🟢 Зеленая - новый цвет")
            print("🔵 Синяя - старый цвет")
            
            wait(5)
            blueAura:Destroy()
            print("🗑️ Синяя аура удалена")
        end
    end)
end

function GreenShieldTester.testColorVariants()
    local player = Players.LocalPlayer
    if not player or not player.Character then return end
    
    print("🎨 === ТЕСТ РАЗЛИЧНЫХ ОТТЕНКОВ ЗЕЛЕНОГО ===")
    
    local greenVariants = {
        {name = "Яркий зеленый", color = Color3.fromRGB(0, 255, 100)},
        {name = "Лесной зеленый", color = Color3.fromRGB(34, 139, 34)},
        {name = "Неоновый зеленый", color = Color3.fromRGB(57, 255, 20)},
        {name = "Темно-зеленый", color = Color3.fromRGB(0, 100, 0)},
        {name = "Изумрудный", color = Color3.fromRGB(80, 200, 120)},
    }
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    for i, variant in ipairs(greenVariants) do
        print(string.format("🟢 Тест %d/%d: %s", i, #greenVariants, variant.name))
        
        -- Создаем ауру варианта
        local testAura = Instance.new("Part")
        testAura.Name = "GreenVariant_" .. i
        testAura.Shape = Enum.PartType.Ball
        testAura.Material = Enum.Material.Neon
        testAura.CanCollide = false
        testAura.Anchored = true
        testAura.Size = Vector3.new(12, 12, 12)
        testAura.Color = variant.color
        testAura.Transparency = 0.85
        testAura.CFrame = humanoidRootPart.CFrame
        testAura.Parent = workspace
        
        -- Добавляем свечение
        local light = Instance.new("PointLight")
        light.Color = variant.color
        light.Brightness = 1.5
        light.Range = 15
        light.Parent = testAura
        
        print("  ✅ Создан:", variant.name)
        wait(2)
        
        testAura:Destroy()
        print("  🗑️ Удален")
        
        if i < #greenVariants then
            wait(0.5)
        end
    end
    
    print("🎉 Все варианты протестированы!")
    print("🟢 Какой оттенок зеленого понравился больше?")
end

function GreenShieldTester.activateRealGreenShield()
    print("🟢 === АКТИВАЦИЯ РЕАЛЬНОГО ЗЕЛЕНОГО ЩИТА ===")
    
    local player = Players.LocalPlayer
    if not player then return end
    
    -- Загружаем AbilityService
    local success, AbilityService = pcall(function()
        local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
        return ModuleLoader.require("services/AbilityService").new()
    end)
    
    if not success then
        warn("❌ Ошибка загрузки AbilityService")
        return
    end
    
    -- Выдаем способность если нет
    if not AbilityService:isAbilityOwned(player, "shield_aura") then
        AbilityService:grantAbility(player, "shield_aura")
        print("🔧 Способность щита выдана")
    end
    
    -- Активируем щит
    print("🚀 Активируем зеленый щит через способность...")
    local result = AbilityService:activateAbility(player, "shield_aura")
    
    if result.success then
        print("✅ УСПЕХ: Зеленый щит активирован!")
        print("🟢 Проверьте зеленую ауру вокруг персонажа")
        print("💬", result.message)
    else
        print("❌ Ошибка активации:", result.message)
    end
end

return GreenShieldTester
