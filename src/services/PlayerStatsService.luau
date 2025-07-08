--!strict
-- src/services/PlayerStatsService.luau
-- Сервис управления характеристиками игрока
-- Отвечает за применение эффектов способностей к WalkSpeed, JumpHeight и визуальным эффектам

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Импортируем типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type AbilityEffect = Types.AbilityEffect
type ActiveEffect = Types.ActiveEffect
type EffectType = Types.EffectType
type EffectTarget = Types.EffectTarget

-- Импортируем новый сервис ауры щита
local ShieldAuraService

-- Интерфейс сервиса
type PlayerStatsServiceInterface = {
	-- Основные методы
	applyEffect: (self: PlayerStatsServiceInterface, player: Player, effect: AbilityEffect, abilityId: string) -> (),
	removeEffect: (self: PlayerStatsServiceInterface, player: Player, abilityId: string) -> (),
	removeAllEffects: (self: PlayerStatsServiceInterface, player: Player) -> (),
	
	-- Получение состояния
	getOriginalStats: (self: PlayerStatsServiceInterface, player: Player) -> PlayerStats,
	getCurrentStats: (self: PlayerStatsServiceInterface, player: Player) -> PlayerStats,
	getActiveEffectsByTarget: (self: PlayerStatsServiceInterface, player: Player, target: EffectTarget) -> {AbilityEffect},
	
	-- Обновление
	updatePlayerStats: (self: PlayerStatsServiceInterface, player: Player) -> (),
	recalculateAllStats: (self: PlayerStatsServiceInterface, player: Player) -> (),
}

-- Типы для характеристик игрока
type PlayerStats = {
	walkSpeed: number,
	jumpHeight: number,
	health: number,
	maxHealth: number,
}

-- Эффект на игроке
type AppliedEffect = {
	abilityId: string,
	effect: AbilityEffect,
	appliedAt: number, -- Время применения
}

local PlayerStatsService = {} :: PlayerStatsServiceInterface
PlayerStatsService.__index = PlayerStatsService

-- Состояние игроков
local playerOriginalStats: {[Player]: PlayerStats} = {}
local playerAppliedEffects: {[Player]: {AppliedEffect}} = {}
local playerShieldEffects: {[Player]: {Part}} = {} -- Визуальные эффекты щитов

-- Конфигурация
local CONFIG = {
	DEFAULT_WALK_SPEED = 16,
	DEFAULT_JUMP_HEIGHT = 7.2, -- Стандартная высота прыжка в Roblox
	DEFAULT_HEALTH = 100,
	MAX_WALK_SPEED = 100, -- Лимит скорости
	MAX_JUMP_HEIGHT = 50, -- Лимит высоты прыжка
	SHIELD_TRANSPARENCY = 0.7,
	SHIELD_COLOR = Color3.fromRGB(0, 255, 100), -- Зеленый цвет щита
}

-- Инициализация сервиса
function PlayerStatsService.new(): PlayerStatsServiceInterface
	local self = setmetatable({}, PlayerStatsService)
	
	-- Инициализируем новый сервис ауры щита
	local success, result = pcall(function()
		local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
		return ModuleLoader.require("services/ShieldAuraService").new()
	end)
	
	if success then
		ShieldAuraService = result
		print("PlayerStatsService: ShieldAuraService успешно инициализирован")
	else
		warn("PlayerStatsService: Ошибка загрузки ShieldAuraService:", result)
		warn("PlayerStatsService: Будет использоваться старая система щитов")
		ShieldAuraService = nil
	end
	
	-- Подписываемся на события игроков
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			wait(1) -- Ждем полной загрузки персонажа
			self:_initializePlayerStats(player, character)
		end)
		
		-- Если персонаж уже есть
		if player.Character then
			wait(1) -- Ждем полной загрузки персонажа
			self:_initializePlayerStats(player, player.Character)
		end
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_cleanupPlayerStats(player)
	end)
	
	-- Инициализируем уже подключенных игроков
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			wait(1) -- Ждем полной загрузки персонажа
			self:_initializePlayerStats(player, player.Character)
		end
	end
	
	print("PlayerStatsService: Сервис инициализирован")
	return self
end

-- Применить эффект к игроку
function PlayerStatsService:applyEffect(player: Player, effect: AbilityEffect, abilityId: string): ()
	if not player.Character then
		warn("PlayerStatsService: У игрока", player.Name, "нет персонажа")
		return
	end
	
	-- Добавляем эффект в список примененных
	if not playerAppliedEffects[player] then
		playerAppliedEffects[player] = {}
	end
	
	local appliedEffect: AppliedEffect = {
		abilityId = abilityId,
		effect = effect,
		appliedAt = tick(),
	}
	
	table.insert(playerAppliedEffects[player], appliedEffect)
	
	-- Применяем эффект в зависимости от цели
	if effect.target == "WalkSpeed" or effect.target == "JumpHeight" then
		self:updatePlayerStats(player)
		
		-- Логируем новую скорость для отладки
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			print("PlayerStatsService: Новая скорость игрока", player.Name, ":", player.Character.Humanoid.WalkSpeed)
		end
	elseif effect.target == "Shield" then
		-- Используем новый улучшенный сервис ауры щита
		if ShieldAuraService then
			-- Получаем длительность эффекта из AbilityConfig
			local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
			local AbilityConfig = ModuleLoader.require("shared/AbilityConfig")
			
			-- Находим конфигурацию способности для получения длительности
			local duration = 15 -- Дефолтная длительность
			local ability = AbilityConfig.getAbilityById(abilityId)
			if ability then
				duration = ability.baseDuration
			end
			
			ShieldAuraService:createShieldAura(player, abilityId, duration)
			print("PlayerStatsService: Создана улучшенная аура щита для", player.Name, "на", duration, "сек")
		else
			-- Fallback на старый метод если новый сервис недоступен
			self:_createShieldEffect(player, effect.value, abilityId)
		end
	elseif effect.target == "Health" then
		self:_applyHealthEffect(player, effect)
	end
	
	print("PlayerStatsService: Применен эффект", effect.target, "для игрока", player.Name, "от способности", abilityId)
end

-- Удалить эффект с игрока
function PlayerStatsService:removeEffect(player: Player, abilityId: string): ()
	if not playerAppliedEffects[player] then
		return
	end
	
	-- Удаляем все эффекты от этой способности
	local effectsToRemove = {}
	for i, appliedEffect in ipairs(playerAppliedEffects[player]) do
		if appliedEffect.abilityId == abilityId then
			table.insert(effectsToRemove, i)
			
			-- Удаляем визуальные эффекты щита
			if appliedEffect.effect.target == "Shield" then
				-- Используем новый сервис для удаления ауры щита
				if ShieldAuraService then
					ShieldAuraService:removeShieldAura(player, abilityId)
					print("PlayerStatsService: Удалена улучшенная аура щита для", player.Name)
				else
					-- Fallback на старый метод
					self:_removeShieldEffect(player, abilityId)
				end
			end
		end
	end
	
	if #effectsToRemove > 0 then
		-- Удаляем эффекты в обратном порядке, чтобы не нарушить индексы
		for i = #effectsToRemove, 1, -1 do
			table.remove(playerAppliedEffects[player], effectsToRemove[i])
		end
		
		-- Пересчитываем статистики
		self:recalculateAllStats(player)
		
		print("PlayerStatsService: Удален эффект способности", abilityId, "с игрока", player.Name)
		
		-- Логируем новую скорость для отладки
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			print("PlayerStatsService: Новая скорость игрока", player.Name, ":", player.Character.Humanoid.WalkSpeed)
		end
	end
end

-- Удалить все эффекты с игрока
function PlayerStatsService:removeAllEffects(player: Player): ()
	if not playerAppliedEffects[player] then
		return
	end
	
	-- Удаляем все визуальные эффекты щитов
	-- Удаляем все визуальные эффекты щитов
	if ShieldAuraService then
		ShieldAuraService:removeAllShieldAuras(player)
	else
		self:_removeAllShieldEffects(player)
	end
	
	-- Очищаем список эффектов
	playerAppliedEffects[player] = {}
	
	-- Восстанавливаем оригинальные статистики
	self:_restoreOriginalStats(player)
	
	print("PlayerStatsService: Удалены все эффекты с игрока", player.Name)
end

-- Получить оригинальные характеристики игрока
function PlayerStatsService:getOriginalStats(player: Player): PlayerStats
	return playerOriginalStats[player] or {
		walkSpeed = CONFIG.DEFAULT_WALK_SPEED,
		jumpHeight = CONFIG.DEFAULT_JUMP_HEIGHT,
		health = CONFIG.DEFAULT_HEALTH,
		maxHealth = CONFIG.DEFAULT_HEALTH,
	}
end

-- Получить текущие характеристики игрока
function PlayerStatsService:getCurrentStats(player: Player): PlayerStats
	if not player.Character then
		return self:getOriginalStats(player)
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return self:getOriginalStats(player)
	end
	
	return {
		walkSpeed = humanoid.WalkSpeed,
		jumpHeight = humanoid.JumpHeight,
		health = humanoid.Health,
		maxHealth = humanoid.MaxHealth,
	}
end

-- Получить активные эффекты по цели
function PlayerStatsService:getActiveEffectsByTarget(player: Player, target: EffectTarget): {AbilityEffect}
	if not playerAppliedEffects[player] then
		return {}
	end
	
	local effects = {}
	for _, appliedEffect in ipairs(playerAppliedEffects[player]) do
		if appliedEffect.effect.target == target then
			table.insert(effects, appliedEffect.effect)
		end
	end
	
	return effects
end

-- Обновить характеристики игрока
function PlayerStatsService:updatePlayerStats(player: Player): ()
	if not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local originalStats = self:getOriginalStats(player)
	
	-- Рассчитываем новые значения
	local newWalkSpeed = self:_calculateEffectiveValue(player, "WalkSpeed", originalStats.walkSpeed)
	local newJumpHeight = self:_calculateEffectiveValue(player, "JumpHeight", originalStats.jumpHeight)
	
	-- Применяем лимиты
	newWalkSpeed = math.min(newWalkSpeed, CONFIG.MAX_WALK_SPEED)
	newJumpHeight = math.min(newJumpHeight, CONFIG.MAX_JUMP_HEIGHT)
	
	-- Устанавливаем новые значения
	humanoid.WalkSpeed = newWalkSpeed
	humanoid.JumpHeight = newJumpHeight
end

-- Пересчитать все характеристики игрока
function PlayerStatsService:recalculateAllStats(player: Player): ()
	self:updatePlayerStats(player)
	-- TODO: Пересчитать здоровье и другие характеристики
end

-- Приватные методы

-- Инициализация характеристик игрока
function PlayerStatsService:_initializePlayerStats(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid")
	
	-- Устанавливаем базовые значения по умолчанию
	humanoid.WalkSpeed = CONFIG.DEFAULT_WALK_SPEED
	humanoid.JumpHeight = CONFIG.DEFAULT_JUMP_HEIGHT
	humanoid.MaxHealth = CONFIG.DEFAULT_HEALTH
	humanoid.Health = CONFIG.DEFAULT_HEALTH
	
	-- Сохраняем оригинальные характеристики (всегда стандартные)
	playerOriginalStats[player] = {
		walkSpeed = CONFIG.DEFAULT_WALK_SPEED,
		jumpHeight = CONFIG.DEFAULT_JUMP_HEIGHT,
		health = CONFIG.DEFAULT_HEALTH,
		maxHealth = CONFIG.DEFAULT_HEALTH,
	}
	
	-- Инициализируем списки эффектов
	playerAppliedEffects[player] = {}
	playerShieldEffects[player] = {}
	
	print("PlayerStatsService: Инициализированы стандартные характеристики для игрока", player.Name, 
		"(Скорость:", CONFIG.DEFAULT_WALK_SPEED, ")")
end

-- Очистка данных игрока
function PlayerStatsService:_cleanupPlayerStats(player: Player)
	self:removeAllEffects(player)
	playerOriginalStats[player] = nil
	playerAppliedEffects[player] = nil
	playerShieldEffects[player] = nil
	
	print("PlayerStatsService: Очищены данные игрока", player.Name)
end

-- Рассчитать эффективное значение с учетом всех эффектов
function PlayerStatsService:_calculateEffectiveValue(player: Player, target: EffectTarget, baseValue: number): number
	local effects = self:getActiveEffectsByTarget(player, target)
	local result = baseValue
	
	-- Применяем эффекты в порядке: Add -> Multiply -> Set
	
	-- Сначала аддитивные эффекты
	for _, effect in ipairs(effects) do
		if effect.type == "Add" then
			result = result + effect.value
		end
	end
	
	-- Затем мультипликативные эффекты
	for _, effect in ipairs(effects) do
		if effect.type == "Multiply" then
			result = result * effect.value
		end
	end
	
	-- В конце эффекты установки значения (последний побеждает)
	for _, effect in ipairs(effects) do
		if effect.type == "Set" then
			result = effect.value
		end
	end
	
	return math.max(0, result) -- Не позволяем отрицательным значениям
end

-- Создать визуальный эффект щита
function PlayerStatsService:_createShieldEffect(player: Player, shieldValue: number, abilityId: string)
	if not player.Character then
		return
	end
	
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end
	
	-- Создаем сферу щита
	local shield = Instance.new("Part")
	shield.Name = "Shield_" .. abilityId
	shield.Shape = Enum.PartType.Ball
	shield.Material = Enum.Material.ForceField
	shield.CanCollide = false
	shield.Anchored = true
	shield.Size = Vector3.new(8, 8, 8)
	shield.CFrame = humanoidRootPart.CFrame
	shield.Color = CONFIG.SHIELD_COLOR
	shield.Transparency = CONFIG.SHIELD_TRANSPARENCY
	
	-- Добавляем свечение
	local pointLight = Instance.new("PointLight")
	pointLight.Color = CONFIG.SHIELD_COLOR
	pointLight.Brightness = 1
	pointLight.Range = 10
	pointLight.Parent = shield
	
	-- Оптимизированная анимация пульсации (10 FPS вместо 60+)
	local connection
	local lastUpdate = 0
	connection = RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		
		-- Ограничиваем частоту обновления до 10 FPS для экономии ресурсов
		if currentTime - lastUpdate < 0.1 then
			return
		end
		lastUpdate = currentTime
		
		if shield.Parent then
			shield.Transparency = CONFIG.SHIELD_TRANSPARENCY + math.sin(currentTime * 3) * 0.2
			if humanoidRootPart.Parent then
				shield.CFrame = humanoidRootPart.CFrame
			else
				connection:Disconnect()
				shield:Destroy()
			end
		else
			connection:Disconnect()
		end
	end)
	
	shield.Parent = workspace
	
	-- Сохраняем ссылку на эффект
	if not playerShieldEffects[player] then
		playerShieldEffects[player] = {}
	end
	table.insert(playerShieldEffects[player], shield)
	
	print("PlayerStatsService: Создан эффект щита для игрока", player.Name, "силой", shieldValue)
end

-- Удалить эффект щита
function PlayerStatsService:_removeShieldEffect(player: Player, abilityId: string)
	if not playerShieldEffects[player] then
		return
	end
	
	for i = #playerShieldEffects[player], 1, -1 do
		local shield = playerShieldEffects[player][i]
		if shield.Name == "Shield_" .. abilityId then
			shield:Destroy()
			table.remove(playerShieldEffects[player], i)
			break
		end
	end
end

-- Удалить все эффекты щитов
function PlayerStatsService:_removeAllShieldEffects(player: Player)
	if not playerShieldEffects[player] then
		return
	end
	
	for _, shield in ipairs(playerShieldEffects[player]) do
		shield:Destroy()
	end
	playerShieldEffects[player] = {}
end

-- Применить эффект здоровья
function PlayerStatsService:_applyHealthEffect(player: Player, effect: AbilityEffect)
	if not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	if effect.type == "Add" then
		humanoid.Health = math.min(humanoid.Health + effect.value, humanoid.MaxHealth)
	elseif effect.type == "Multiply" then
		humanoid.Health = math.min(humanoid.Health * effect.value, humanoid.MaxHealth)
	elseif effect.type == "Set" then
		humanoid.Health = math.min(effect.value, humanoid.MaxHealth)
	end
end

-- Восстановить оригинальные характеристики
function PlayerStatsService:_restoreOriginalStats(player: Player)
	if not player.Character then
		return
	end
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end
	
	local originalStats = self:getOriginalStats(player)
	humanoid.WalkSpeed = originalStats.walkSpeed
	humanoid.JumpHeight = originalStats.jumpHeight
end

return PlayerStatsService
