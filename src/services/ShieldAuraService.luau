--!strict
-- src/services/ShieldAuraService.luau
-- Улучшенная система ауры щита с мгновенной активацией и эффективной анимацией

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))

-- Интерфейс сервиса ауры щита
type ShieldAuraServiceInterface = {
	createShieldAura: (self: ShieldAuraServiceInterface, player: Player, abilityId: string, duration: number) -> (),
	removeShieldAura: (self: ShieldAuraServiceInterface, player: Player, abilityId: string) -> (),
	removeAllShieldAuras: (self: ShieldAuraServiceInterface, player: Player) -> (),
	updateShieldPosition: (self: ShieldAuraServiceInterface, player: Player) -> (),
}

local ShieldAuraService = {} :: ShieldAuraServiceInterface
ShieldAuraService.__index = ShieldAuraService

-- Состояние активных щитов
local activeShields: {[Player]: {[string]: {shield: Part, connection: RBXScriptConnection, tween: Tween?}}} = {}

-- Конфигурация
local SHIELD_CONFIG = {
	-- Визуальные параметры
	SIZE = Vector3.new(12, 12, 12),
	SPHERE_COLOR = Color3.fromRGB(0, 255, 100), -- Ярко-зеленая сфера
	OUTLINE_COLOR = Color3.fromRGB(0, 200, 255), -- Голубая обводка
	BASE_TRANSPARENCY = 0.85,
	PULSE_AMPLITUDE = 0.08,

	-- Анимация
	APPEAR_TIME = 0.3,
	DISAPPEAR_TIME = 0.4,
	PULSE_SPEED = 1.5,

	-- Производительность
	UPDATE_INTERVAL = 0.05,

	-- Эффекты
	GLOW_BRIGHTNESS = 0.8,
	GLOW_RANGE = 16,
}

function ShieldAuraService.new(): ShieldAuraServiceInterface
	local self = setmetatable({}, ShieldAuraService)
	
	-- Подписываемся на события игроков
	Players.PlayerRemoving:Connect(function(player)
		self:removeAllShieldAuras(player)
	end)
	
	print("ShieldAuraService: Сервис инициализирован")
	return self
end

-- Создать ауру щита с мгновенной активацией
function ShieldAuraService:createShieldAura(player: Player, abilityId: string, duration: number)
	-- Удаляем предыдущий щит если есть
	self:removeShieldAura(player, abilityId)
	
	local character = player.Character
	if not character then
		warn("ShieldAuraService: Персонаж не найден для", player.Name)
		return
	end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		warn("ShieldAuraService: HumanoidRootPart не найден для", player.Name)
		return
	end
	
	print("🛡️ ShieldAuraService: Создаем ауру щита для", player.Name, "на", duration, "сек")
	
	-- Создаем основную сферу щита
	local shield = self:_createShieldSphere(humanoidRootPart)
	
	-- Добавляем свечение
	self:_addShieldGlow(shield)
	
	-- Мгновенно позиционируем на игроке
	shield.CFrame = humanoidRootPart.CFrame
	shield.Parent = workspace
	
	-- Анимация появления
	local appearTween = self:_createAppearAnimation(shield)
	appearTween:Play()
	
	-- Запускаем обновление позиции (оптимизированное)
	local connection = self:_startPositionUpdate(shield, humanoidRootPart)
	
	-- Сохраняем состояние
	if not activeShields[player] then
		activeShields[player] = {}
	end
	
	activeShields[player][abilityId] = {
		shield = shield,
		connection = connection,
		tween = appearTween
	}
	
	-- Автоматическое удаление через заданное время
	spawn(function()
		wait(duration)
		self:removeShieldAura(player, abilityId)
	end)
	
	print("✅ ShieldAuraService: Аура щита создана и активна")
end

-- Удалить ауру щита с плавной анимацией
function ShieldAuraService:removeShieldAura(player: Player, abilityId: string)
	if not activeShields[player] or not activeShields[player][abilityId] then
		return
	end
	
	local shieldData = activeShields[player][abilityId]
	local shield = shieldData.shield
	
	print("🛡️ ShieldAuraService: Удаляем ауру щита для", player.Name)
	
	-- Останавливаем обновление позиции
	if shieldData.connection then
		shieldData.connection:Disconnect()
	end
	
	-- Останавливаем предыдущую анимацию если есть
	if shieldData.tween then
		shieldData.tween:Cancel()
	end
	
	-- Анимация исчезновения
	local disappearTween = TweenService:Create(shield, 
		TweenInfo.new(SHIELD_CONFIG.DISAPPEAR_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Transparency = 1,
			Size = Vector3.new(0.1, 0.1, 0.1)
		}
	)
	
	disappearTween.Completed:Connect(function()
		shield:Destroy()
	end)
	
	disappearTween:Play()
	
	-- Удаляем из состояния
	activeShields[player][abilityId] = nil
	
	print("✅ ShieldAuraService: Аура щита удалена")
end

-- Удалить все ауры щитов игрока
function ShieldAuraService:removeAllShieldAuras(player: Player)
	if not activeShields[player] then
		return
	end
	
	for abilityId, _ in pairs(activeShields[player]) do
		self:removeShieldAura(player, abilityId)
	end
	
	activeShields[player] = nil
end

-- Принудительно обновить позицию щитов (для случаев телепортации)
function ShieldAuraService:updateShieldPosition(player: Player)
	if not activeShields[player] then
		return
	end
	
	local character = player.Character
	if not character then return end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end
	
	for _, shieldData in pairs(activeShields[player]) do
		if shieldData.shield and shieldData.shield.Parent then
			shieldData.shield.CFrame = humanoidRootPart.CFrame
		end
	end
end

-- PRIVATE: Создать сферу щита
function ShieldAuraService:_createShieldSphere(humanoidRootPart: Part): Part
	local shield = Instance.new("Part")
	shield.Name = "ShieldAura_" .. tick() -- Уникальное имя
	   shield.Shape = Enum.PartType.Ball
	   shield.Material = Enum.Material.ForceField
	   shield.CanCollide = false
	   shield.Anchored = true
	   shield.Size = SHIELD_CONFIG.SIZE
	   shield.Color = SHIELD_CONFIG.SPHERE_COLOR -- Зеленая сфера
	   shield.Transparency = 1
	   shield.CFrame = humanoidRootPart.CFrame
	   shield.TopSurface = Enum.SurfaceType.Smooth
	   shield.BottomSurface = Enum.SurfaceType.Smooth
	
	-- Добавляем тег для идентификации
	local stringValue = Instance.new("StringValue")
	stringValue.Name = "ShieldTag"
	stringValue.Value = "PlayerShield"
	stringValue.Parent = shield
	
	return shield
end

-- PRIVATE: Добавить свечение к щиту
function ShieldAuraService:_addShieldGlow(shield: Part)
	   -- Основное мягкое свечение (цвет сферы)
	   local pointLight = Instance.new("PointLight")
	   pointLight.Color = SHIELD_CONFIG.SPHERE_COLOR
	   pointLight.Brightness = SHIELD_CONFIG.GLOW_BRIGHTNESS
	   pointLight.Range = SHIELD_CONFIG.GLOW_RANGE
	   pointLight.Parent = shield

	   --[[
	   -- Яркая голубая обводка (отключено временно)
	   local selectionBox = Instance.new("SelectionBox")
	   selectionBox.Adornee = shield
	   selectionBox.Color3 = SHIELD_CONFIG.OUTLINE_COLOR
	   selectionBox.Transparency = 0.85 -- Чуть более заметная
	   selectionBox.LineThickness = 0.12 -- Чуть толще
	   selectionBox.Parent = shield
	   --]]
end

-- PRIVATE: Создать анимацию появления
function ShieldAuraService:_createAppearAnimation(shield: Part): Tween
	local tween = TweenService:Create(shield, 
		TweenInfo.new(SHIELD_CONFIG.APPEAR_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{
			Transparency = SHIELD_CONFIG.BASE_TRANSPARENCY,
			Size = SHIELD_CONFIG.SIZE
		}
	)
	
	return tween
end

-- PRIVATE: Запустить обновление позиции с пульсацией
function ShieldAuraService:_startPositionUpdate(shield: Part, humanoidRootPart: Part): RBXScriptConnection
	local lastUpdate = 0
	local startTime = tick()
	
	local connection
	connection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		
		-- Ограничиваем обновления для производительности
		if currentTime - lastUpdate < SHIELD_CONFIG.UPDATE_INTERVAL then
			return
		end
		lastUpdate = currentTime
		
		-- Проверяем что объекты еще существуют
		if not shield.Parent or not humanoidRootPart.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end
		
		-- Обновляем позицию (следует за игроком)
	   shield.CFrame = humanoidRootPart.CFrame

	   -- Плавная пульсация прозрачности (очень деликатная)
	   local elapsed = currentTime - startTime
	   local pulse = math.sin(elapsed * SHIELD_CONFIG.PULSE_SPEED) * SHIELD_CONFIG.PULSE_AMPLITUDE

	   -- Узкий диапазон прозрачности
	   local targetTransparency = SHIELD_CONFIG.BASE_TRANSPARENCY + pulse
	   targetTransparency = math.max(0.82, math.min(0.93, targetTransparency))

	   shield.Transparency = targetTransparency

	   -- Медленное вращение
	   shield.CFrame = shield.CFrame * CFrame.Angles(0, elapsed * 0.15, 0)
	end)
	
	return connection
end

return ShieldAuraService
