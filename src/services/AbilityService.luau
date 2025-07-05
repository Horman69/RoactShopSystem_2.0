--!strict
-- src/services/AbilityService.luau
-- Сервис управления способностями игроков
-- Отвечает за активацию, кулдауны, временные эффекты и премиум бусты

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Импортируем зависимости через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local AbilityConfig = ModuleLoader.require("shared/AbilityConfig")
local SpecialAbilityConfig = ModuleLoader.require("shared/SpecialAbilityConfig")

-- Импортируем типы напрямую
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type Ability = Types.Ability
type AbilityList = Types.AbilityList
type PlayerAbilityState = Types.PlayerAbilityState
type ActiveEffect = Types.ActiveEffect
type AbilityActivationResult = Types.AbilityActivationResult

-- Импортируем PlayerStatsService (будет создан при инициализации)
local PlayerStatsService

-- Интерфейс сервиса способностей
type AbilityServiceInterface = {
	-- Основные методы
	activateAbility: (self: AbilityServiceInterface, player: Player, abilityId: string) -> AbilityActivationResult,
	getPlayerAbilities: (self: AbilityServiceInterface, player: Player) -> AbilityList,
	getPlayerState: (self: AbilityServiceInterface, player: Player) -> PlayerAbilityState,
	
	-- Проверки состояния
	isAbilityOwned: (self: AbilityServiceInterface, player: Player, abilityId: string) -> boolean,
	isAbilityOnCooldown: (self: AbilityServiceInterface, player: Player, abilityId: string) -> boolean,
	getCooldownTimeLeft: (self: AbilityServiceInterface, player: Player, abilityId: string) -> number,
	
	-- Управление способностями
	grantAbility: (self: AbilityServiceInterface, player: Player, abilityId: string) -> boolean,
	removeAbility: (self: AbilityServiceInterface, player: Player, abilityId: string) -> boolean,
	
	-- Эффекты
	getActiveEffects: (self: AbilityServiceInterface, player: Player) -> {[string]: ActiveEffect},
	clearExpiredEffects: (self: AbilityServiceInterface, player: Player) -> (),
	removeAllEffects: (self: AbilityServiceInterface, player: Player) -> (),
	
	-- События
	onAbilityActivated: (self: AbilityServiceInterface, callback: (player: Player, ability: Ability) -> ()) -> (),
	onEffectExpired: (self: AbilityServiceInterface, callback: (player: Player, abilityId: string) -> ()) -> (),
	
	-- Утилиты
	getEffectiveDuration: (self: AbilityServiceInterface, player: Player, abilityId: string) -> number,
	isPremiumPlayer: (self: AbilityServiceInterface, player: Player) -> boolean,
}

local AbilityService = {} :: AbilityServiceInterface
AbilityService.__index = AbilityService

-- Состояние игроков
local playerStates: {[Player]: PlayerAbilityState} = {}

-- Колбэки для событий
local abilityActivatedCallbacks: {(player: Player, ability: Ability) -> ()} = {}
local effectExpiredCallbacks: {(player: Player, abilityId: string) -> ()} = {}

-- Конфигурация
local CONFIG = {
	PREMIUM_DURATION_MULTIPLIER = 2, -- Премиум игроки получают x2 к длительности
	MAX_ACTIVE_EFFECTS = 10, -- Максимум активных эффектов на игрока
	EFFECT_UPDATE_INTERVAL = 0.1, -- Интервал обновления эффектов в секундах (более частые проверки)
}

-- Инициализация сервиса
function AbilityService.new(): AbilityServiceInterface
	local self = setmetatable({}, AbilityService)
	
	-- Инициализируем PlayerStatsService
	PlayerStatsService = ModuleLoader.require("services/PlayerStatsService").new()
	
	-- Инициализируем SoundService для звуков способностей
	local SoundService = ModuleLoader.require("services/SoundService").new()
	self.soundService = SoundService
	
	-- Запускаем цикл обновления эффектов
	self:_startEffectUpdateLoop()
	
	-- Подписываемся на события игроков
	Players.PlayerAdded:Connect(function(player)
		self:_initializePlayerState(player)
	end)
	
	Players.PlayerRemoving:Connect(function(player)
		self:_cleanupPlayerState(player)
	end)
	
	-- Инициализируем уже подключенных игроков
	for _, player in ipairs(Players:GetPlayers()) do
		self:_initializePlayerState(player)
	end
	
	print("AbilityService: Сервис инициализирован")
	return self
end

-- Активировать способность
function AbilityService:activateAbility(player: Player, abilityId: string): AbilityActivationResult
	print("AbilityService: Попытка активации способности", abilityId, "игроком", player.Name)
	
	-- Получаем способность (ищем в базовых и особых)
	local ability = AbilityConfig.getAbilityById(abilityId)
	if not ability then
		ability = SpecialAbilityConfig.getSpecialAbilityById(abilityId)
	end
	
	if not ability then
		print("AbilityService: Способность", abilityId, "не найдена")
		return {
			success = false,
			message = "Способность не найдена",
			ability = nil,
			cooldownEnd = nil,
		}
	end
	
	print("AbilityService: Способность найдена:", ability.name)
	
	-- Проверяем, что игрок владеет способностью
	if not self:isAbilityOwned(player, abilityId) then
		print("AbilityService: Игрок", player.Name, "не владеет способностью", abilityId)
		
		-- Воспроизводим звук ошибки (нет способности)
		if self.soundService then
			self.soundService:playAbilityCooldownSound()
		end
		
		return {
			success = false,
			message = "У вас нет этой способности",
			ability = ability,
			cooldownEnd = nil,
		}
	end
	
	print("AbilityService: Игрок владеет способностью")
	
	-- Проверяем кулдаун
	if self:isAbilityOnCooldown(player, abilityId) then
		local timeLeft = self:getCooldownTimeLeft(player, abilityId)
		print("AbilityService: Способность на кулдауне, осталось", timeLeft, "сек")
		
		-- Воспроизводим звук ошибки кулдауна
		if self.soundService then
			self.soundService:playAbilityCooldownSound()
		end
		
		return {
			success = false,
			message = string.format("Способность на кулдауне (%.1f сек)", timeLeft),
			ability = ability,
			cooldownEnd = tick() + timeLeft,
		}
	end
	
	print("AbilityService: Кулдаун не активен")
	
	-- Проверяем лимит активных эффектов
	local activeEffects = self:getActiveEffects(player)
	if #activeEffects >= CONFIG.MAX_ACTIVE_EFFECTS then
		print("AbilityService: Превышен лимит активных эффектов:", #activeEffects)
		return {
			success = false,
			message = "Слишком много активных эффектов",
			ability = ability,
			cooldownEnd = nil,
		}
	end
	
	print("AbilityService: Лимит эффектов в норме")
	
	-- Активируем способность
	local duration = self:getEffectiveDuration(player, abilityId)
	local currentTime = tick()
	
	print("AbilityService: Активируем способность с длительностью", duration, "сек")
	
	-- Создаем активный эффект
	local activeEffect: ActiveEffect = {
		abilityId = abilityId,
		startTime = currentTime,
		duration = duration,
		effects = ability.effects,
	}
	
	-- Добавляем эффект к игроку
	local playerState = self:getPlayerState(player)
	playerState.activeEffects[abilityId] = activeEffect
	
	-- Устанавливаем кулдаун ПОСЛЕ окончания действия способности
	-- Кулдаун = время окончания эффекта + время кулдауна
	playerState.cooldowns[abilityId] = currentTime + duration + ability.cooldown
	
	print("AbilityService: Эффект добавлен, применяем через PlayerStatsService")
	
	-- Применяем эффекты способности через PlayerStatsService
	for i, effect in ipairs(ability.effects) do
		print("AbilityService: Применяем эффект", i, ":", effect.type, effect.value, effect.target)
		PlayerStatsService:applyEffect(player, effect, abilityId)
	end
	
	-- Воспроизводим звук использования способности
	if self.soundService then
		self.soundService:playAbilityUseSound()
	end
	
	-- Уведомляем подписчиков
	self:_notifyAbilityActivated(player, ability)
	
	print("AbilityService: Игрок", player.Name, "активировал способность", ability.name)
	
	return {
		success = true,
		message = string.format("Способность '%s' активирована на %.1f сек", ability.name, duration),
		ability = ability,
		cooldownEnd = currentTime + duration + ability.cooldown, -- Исправляем время окончания кулдауна
	}
end

-- Получить список способностей игрока
function AbilityService:getPlayerAbilities(player: Player): AbilityList
	local playerState = self:getPlayerState(player)
	local abilities: AbilityList = {}
	
	for abilityId, isOwned in pairs(playerState.ownedAbilities) do
		if isOwned then
			-- Ищем способность сначала в базовых, потом в особых
			local ability = AbilityConfig.getAbilityById(abilityId)
			if not ability then
				ability = SpecialAbilityConfig.getSpecialAbilityById(abilityId)
			end
			
			if ability then
				table.insert(abilities, ability)
			end
		end
	end
	
	return abilities
end

-- Получить состояние игрока
function AbilityService:getPlayerState(player: Player): PlayerAbilityState
	if not playerStates[player] then
		self:_initializePlayerState(player)
	end
	return playerStates[player]
end

-- Проверить, владеет ли игрок способностью
function AbilityService:isAbilityOwned(player: Player, abilityId: string): boolean
	local playerState = self:getPlayerState(player)
	return playerState.ownedAbilities[abilityId] == true
end

-- Проверить, на кулдауне ли способность
function AbilityService:isAbilityOnCooldown(player: Player, abilityId: string): boolean
	return self:getCooldownTimeLeft(player, abilityId) > 0
end

-- Получить время до окончания кулдауна
function AbilityService:getCooldownTimeLeft(player: Player, abilityId: string): number
	local playerState = self:getPlayerState(player)
	local cooldownEnd = playerState.cooldowns[abilityId]
	
	if not cooldownEnd then
		return 0
	end
	
	local timeLeft = cooldownEnd - tick()
	return math.max(0, timeLeft)
end

-- Выдать способность игроку
function AbilityService:grantAbility(player: Player, abilityId: string): boolean
	local ability = AbilityConfig.getAbilityById(abilityId)
	if not ability then
		return false
	end
	
	local playerState = self:getPlayerState(player)
	playerState.ownedAbilities[abilityId] = true
	
	print("AbilityService: Игрок", player.Name, "получил способность", ability.name)
	return true
end

-- Забрать способность у игрока
function AbilityService:removeAbility(player: Player, abilityId: string): boolean
	local playerState = self:getPlayerState(player)
	
	if not playerState.ownedAbilities[abilityId] then
		return false
	end
	
	-- Удаляем способность
	playerState.ownedAbilities[abilityId] = false
	
	-- Удаляем активный эффект, если есть
	playerState.activeEffects[abilityId] = nil
	
	print("AbilityService: У игрока", player.Name, "забрана способность", abilityId)
	return true
end

-- Получить активные эффекты игрока
function AbilityService:getActiveEffects(player: Player): {[string]: ActiveEffect}
	local playerState = self:getPlayerState(player)
	self:clearExpiredEffects(player) -- Очищаем истекшие эффекты
	return playerState.activeEffects
end

-- Очистить истекшие эффекты
function AbilityService:clearExpiredEffects(player: Player): ()
	local playerState = self:getPlayerState(player)
	local currentTime = tick()
	
	for abilityId, effect in pairs(playerState.activeEffects) do
		if currentTime >= effect.startTime + effect.duration then
			-- Эффект истек
			playerState.activeEffects[abilityId] = nil
			
			-- Удаляем эффекты через PlayerStatsService
			if PlayerStatsService then
				PlayerStatsService:removeEffect(player, abilityId)
			end
			
			self:_notifyEffectExpired(player, abilityId)
			print("AbilityService: Эффект", abilityId, "истек у игрока", player.Name)
		end
	end
end

-- Удалить все эффекты игрока
function AbilityService:removeAllEffects(player: Player): ()
	local playerState = self:getPlayerState(player)
	
	-- Удаляем все активные эффекты через PlayerStatsService
	for abilityId, _ in pairs(playerState.activeEffects) do
		if PlayerStatsService then
			PlayerStatsService:removeEffect(player, abilityId)
		end
	end
	
	-- Очищаем список активных эффектов
	playerState.activeEffects = {}
	
	print("AbilityService: Удалены все эффекты игрока", player.Name)
end

-- Подписаться на активацию способностей
function AbilityService:onAbilityActivated(callback: (player: Player, ability: Ability) -> ())
	table.insert(abilityActivatedCallbacks, callback)
end

-- Подписаться на истечение эффектов
function AbilityService:onEffectExpired(callback: (player: Player, abilityId: string) -> ())
	table.insert(effectExpiredCallbacks, callback)
end

-- Получить эффективную длительность с учетом бустов
function AbilityService:getEffectiveDuration(player: Player, abilityId: string): number
	local ability = AbilityConfig.getAbilityById(abilityId)
	if not ability then
		return 0
	end
	
	local baseDuration = ability.baseDuration
	
	-- Применяем премиум буст
	if self:isPremiumPlayer(player) then
		baseDuration = baseDuration * CONFIG.PREMIUM_DURATION_MULTIPLIER
	end
	
	-- TODO: Добавить бусты от траекторий движения
	
	return baseDuration
end

-- Проверить, является ли игрок премиум (заглушка)
function AbilityService:isPremiumPlayer(player: Player): boolean
	-- TODO: Интегрировать с настоящей системой премиума
	-- Пока что проверяем по имени для тестирования
	return string.find(player.Name, "Premium") ~= nil
end

-- Приватные методы

-- Инициализация состояния игрока
function AbilityService:_initializePlayerState(player: Player)
	playerStates[player] = {
		ownedAbilities = {},
		activeEffects = {},
		cooldowns = {},
	}
	
	-- TODO: Загрузить данные из DataStore
	-- Игрок начинает БЕЗ способностей - все нужно покупать в магазине
	-- Это обеспечивает правильную интеграцию с системой магазина
	
	print("AbilityService: Инициализировано состояние для игрока", player.Name, "- без способностей (нужно покупать)")
end

-- Очистка состояния игрока
function AbilityService:_cleanupPlayerState(player: Player)
	-- TODO: Сохранить данные в DataStore
	playerStates[player] = nil
	print("AbilityService: Очищено состояние для игрока", player.Name)
end

-- Запуск цикла обновления эффектов
function AbilityService:_startEffectUpdateLoop()
	local lastUpdate = 0
	
	RunService.Heartbeat:Connect(function()
		local currentTime = tick()
		
		-- Обновляем эффекты каждые 0.1 секунды
		if currentTime - lastUpdate >= CONFIG.EFFECT_UPDATE_INTERVAL then
			lastUpdate = currentTime
			
			for player, _ in pairs(playerStates) do
				if player.Parent then -- Игрок все еще в игре
					self:clearExpiredEffects(player)
				end
			end
		end
	end)
end

-- Уведомить об активации способности
function AbilityService:_notifyAbilityActivated(player: Player, ability: Ability)
	for _, callback in ipairs(abilityActivatedCallbacks) do
		callback(player, ability)
	end
end

-- Уведомить об истечении эффекта
function AbilityService:_notifyEffectExpired(player: Player, abilityId: string)
	for _, callback in ipairs(effectExpiredCallbacks) do
		callback(player, abilityId)
	end
end

return AbilityService
