--!strict
-- src/effects/ShieldAuraVariants.luau
-- Коллекция различных вариантов эффектных аур для способности щита

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ShieldAuraVariants = {}

-- Конфигурации различных вариантов аур
local AURA_VARIANTS = {
	-- 🛡️ КЛАССИЧЕСКАЯ АУРА (текущая)
	classic = {
		name = "Классический щит",
		description = "Простая пульсирующая сфера",
		performance = "Высокая", -- Низкая нагрузка
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		size = Vector3.new(8, 8, 8),
		color = Color3.fromRGB(0, 170, 255),
		transparency = 0.6,
		effects = {"pulse", "glow", "rotation"}
	},
	
	-- ⚡ ЭНЕРГЕТИЧЕСКАЯ АУРА
	energy = {
		name = "Энергетический барьер",
		description = "Быстро пульсирующая энергетическая оболочка",
		performance = "Высокая",
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		size = Vector3.new(7.5, 7.5, 7.5),
		color = Color3.fromRGB(0, 255, 150),
		transparency = 0.7,
		effects = {"fast_pulse", "spark_glow", "energy_rotation"}
	},
	
	-- 🔮 МАГИЧЕСКАЯ АУРА
	magic = {
		name = "Магический барьер",
		description = "Мистическая защитная сфера с рунами",
		performance = "Средняя", -- Чуть больше эффектов
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		size = Vector3.new(8.5, 8.5, 8.5),
		color = Color3.fromRGB(150, 0, 255),
		transparency = 0.5,
		effects = {"magic_pulse", "runic_glow", "magic_particles"}
	},
	
	-- 🌟 ЗВЕЗДНАЯ АУРА (самая эффектная)
	stellar = {
		name = "Звездный щит",
		description = "Космическая защита с эффектом звезд",
		performance = "Средняя",
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		size = Vector3.new(9, 9, 9),
		color = Color3.fromRGB(255, 215, 0),
		transparency = 0.8,
		effects = {"stellar_pulse", "star_glow", "cosmic_rotation", "particles"}
	},
	
	-- 🔥 ОГНЕННАЯ АУРА
	fire = {
		name = "Огненный барьер",
		description = "Пылающая защитная оболочка",
		performance = "Средняя",
		shape = Enum.PartType.Ball,
		material = Enum.Material.Neon,
		size = Vector3.new(8, 8, 8),
		color = Color3.fromRGB(255, 100, 0),
		transparency = 0.6,
		effects = {"fire_pulse", "flame_glow", "heat_distortion"}
	},
	
	-- ❄️ ЛЕДЯНАЯ АУРА
	ice = {
		name = "Ледяной барьер",
		description = "Кристальная защитная сфера",
		performance = "Высокая",
		shape = Enum.PartType.Ball,
		material = Enum.Material.Ice,
		size = Vector3.new(8, 8, 8),
		color = Color3.fromRGB(173, 216, 230),
		transparency = 0.4,
		effects = {"ice_pulse", "crystal_glow", "frost_particles"}
	}
}

-- Функции создания различных эффектов

-- Классическая пульсация
function ShieldAuraVariants.createClassicPulse(shield: Part, config)
	local startTime = tick()
	local connection
	
	connection = RunService.Heartbeat:Connect(function()
		if not shield.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		local pulse = math.sin(elapsed * 3) * 0.3
		shield.Transparency = config.transparency + pulse
	end)
	
	return connection
end

-- Энергетическая пульсация (быстрее)
function ShieldAuraVariants.createEnergyPulse(shield: Part, config)
	local startTime = tick()
	local connection
	
	connection = RunService.Heartbeat:Connect(function()
		if not shield.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		local pulse = math.sin(elapsed * 6) * 0.4
		shield.Transparency = config.transparency + pulse
		
		-- Дополнительный эффект изменения размера
		local sizePulse = math.sin(elapsed * 4) * 0.5
		shield.Size = config.size + Vector3.new(sizePulse, sizePulse, sizePulse)
	end)
	
	return connection
end

-- Магическая пульсация с изменением цвета
function ShieldAuraVariants.createMagicPulse(shield: Part, config)
	local startTime = tick()
	local connection
	
	connection = RunService.Heartbeat:Connect(function()
		if not shield.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		local pulse = math.sin(elapsed * 2) * 0.3
		shield.Transparency = config.transparency + pulse
		
		-- Изменение цвета для магического эффекта
		local colorShift = math.sin(elapsed * 1.5) * 0.5 + 0.5
		shield.Color = Color3.fromRGB(
			math.floor(150 + colorShift * 105),
			math.floor(0 + colorShift * 100),
			255
		)
	end)
	
	return connection
end

-- Звездная пульсация (самая эффектная)
function ShieldAuraVariants.createStellarPulse(shield: Part, config)
	local startTime = tick()
	local connection
	
	connection = RunService.Heartbeat:Connect(function()
		if not shield.Parent then
			connection:Disconnect()
			return
		end
		
		local elapsed = tick() - startTime
		
		-- Сложная пульсация с несколькими гармониками
		local pulse1 = math.sin(elapsed * 2) * 0.2
		local pulse2 = math.sin(elapsed * 3.7) * 0.1
		local pulse3 = math.sin(elapsed * 5.3) * 0.1
		
		shield.Transparency = config.transparency + pulse1 + pulse2 + pulse3
		
		-- Звездное свечение
		local starGlow = math.sin(elapsed * 4) * 0.5 + 0.5
		shield.Color = Color3.fromRGB(
			255,
			math.floor(215 + starGlow * 40),
			math.floor(starGlow * 100)
		)
		
		-- Космическое вращение
		shield.CFrame = shield.CFrame * CFrame.Angles(0.01, 0.02, 0.005)
	end)
	
	return connection
end

-- Создать ауру выбранного варианта
function ShieldAuraVariants.createVariantAura(variant: string, humanoidRootPart: Part): {shield: Part, connections: {RBXScriptConnection}}
	local config = AURA_VARIANTS[variant] or AURA_VARIANTS.classic
	
	-- Создаем основную сферу
	local shield = Instance.new("Part")
	shield.Name = "ShieldAura_" .. variant
	shield.Shape = config.shape
	shield.Material = config.material
	shield.CanCollide = false
	shield.Anchored = true
	shield.Size = config.size
	shield.Color = config.color
	shield.Transparency = config.transparency
	shield.CFrame = humanoidRootPart.CFrame
	
	-- Добавляем свечение
	local pointLight = Instance.new("PointLight")
	pointLight.Color = config.color
	pointLight.Brightness = 2
	pointLight.Range = 12
	pointLight.Parent = shield
	
	local connections = {}
	
	-- Применяем эффекты в зависимости от варианта
	if variant == "classic" then
		table.insert(connections, ShieldAuraVariants.createClassicPulse(shield, config))
	elseif variant == "energy" then
		table.insert(connections, ShieldAuraVariants.createEnergyPulse(shield, config))
	elseif variant == "magic" then
		table.insert(connections, ShieldAuraVariants.createMagicPulse(shield, config))
	elseif variant == "stellar" then
		table.insert(connections, ShieldAuraVariants.createStellarPulse(shield, config))
	else
		-- Дефолтная классическая пульсация
		table.insert(connections, ShieldAuraVariants.createClassicPulse(shield, config))
	end
	
	-- Основное обновление позиции
	local positionConnection = RunService.Heartbeat:Connect(function()
		if not shield.Parent or not humanoidRootPart.Parent then
			for _, conn in ipairs(connections) do
				conn:Disconnect()
			end
			return
		end
		
		shield.CFrame = humanoidRootPart.CFrame
	end)
	
	table.insert(connections, positionConnection)
	
	shield.Parent = workspace
	
	return {
		shield = shield,
		connections = connections
	}
end

-- Получить список доступных вариантов
function ShieldAuraVariants.getAvailableVariants(): {string}
	local variants = {}
	for variant, _ in pairs(AURA_VARIANTS) do
		table.insert(variants, variant)
	end
	return variants
end

-- Получить информацию о варианте
function ShieldAuraVariants.getVariantInfo(variant: string)
	return AURA_VARIANTS[variant]
end

return ShieldAuraVariants
