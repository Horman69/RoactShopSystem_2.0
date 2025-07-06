--!strict
-- src/services/CurrencyService.luau
-- Сервис управления валютой игрока
-- Отвечает за все операции с монетами, событиями и сохранением

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Импортируем типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type CurrencyState = Types.CurrencyState
type WalletInterface = Types.WalletInterface

-- Внутренний тип для сервиса
type CurrencyServiceInterface = {
	getPlayerCurrency: (self: CurrencyServiceInterface, player: Player) -> CurrencyState,
	addCoins: (self: CurrencyServiceInterface, player: Player, amount: number) -> boolean,
	spendCoins: (self: CurrencyServiceInterface, player: Player, amount: number) -> boolean,
	hasEnoughCoins: (self: CurrencyServiceInterface, player: Player, amount: number) -> boolean,
	onCurrencyChanged: (self: CurrencyServiceInterface, callback: (player: Player, newState: CurrencyState) -> ()) -> (),
	savePlayerData: (self: CurrencyServiceInterface, player: Player) -> (),
	loadPlayerData: (self: CurrencyServiceInterface, player: Player) -> CurrencyState,
}

local CurrencyService = {} :: CurrencyServiceInterface
CurrencyService.__index = CurrencyService

-- Кэш валютных состояний игроков
local playerCurrencyCache: {[Player]: CurrencyState} = {}

-- Колбэки для событий изменения валюты
local currencyChangeCallbacks: {(player: Player, newState: CurrencyState) -> ()} = {}

-- Конфигурация сервиса
local CONFIG = {
	DEFAULT_COINS = 200, -- Достаточно для покупки всех базовых способностей
	MAX_COINS = 999999,
	AUTO_SAVE_INTERVAL = 30, -- секунд
	COIN_GAIN_COOLDOWN = 1, -- секунд между получением монет
}

-- Кулдауны для предотвращения спама
local playerCooldowns: {[Player]: number} = {}

-- Инициализация сервиса
function CurrencyService.new(): CurrencyServiceInterface
	local self = setmetatable({}, CurrencyService)
	
	-- Запускаем автосохранение
	if RunService:IsServer() then
		self:_startAutoSave()
	end
	
	return self
end

-- Получить валютное состояние игрока
function CurrencyService:getPlayerCurrency(player: Player): CurrencyState
	if not playerCurrencyCache[player] then
		playerCurrencyCache[player] = self:loadPlayerData(player)
	end
	
	return playerCurrencyCache[player]
end

-- Добавить монеты игроку
function CurrencyService:addCoins(player: Player, amount: number): boolean
	-- Валидация
	if amount <= 0 then
		warn("CurrencyService: Нельзя добавить отрицательное количество монет")
		return false
	end
	
	-- Проверка кулдауна
	local currentTime = tick()
	if playerCooldowns[player] and currentTime - playerCooldowns[player] < CONFIG.COIN_GAIN_COOLDOWN then
		return false
	end
	
	local currentState = self:getPlayerCurrency(player)
	local newCoins = math.min(currentState.coins + amount, CONFIG.MAX_COINS)
	
	-- Обновляем состояние
	playerCurrencyCache[player] = {
		coins = newCoins,
		gems = currentState.gems,
		tokens = currentState.tokens,
	}
	
	-- Обновляем кулдаун
	playerCooldowns[player] = currentTime
	
	-- Уведомляем подписчиков
	self:_notifyCurrencyChanged(player, playerCurrencyCache[player])
	
	return true
end

-- Потратить монеты
function CurrencyService:spendCoins(player: Player, amount: number): boolean
	-- Валидация
	if amount <= 0 then
		warn("CurrencyService: Нельзя потратить отрицательное количество монет")
		return false
	end
	
	local currentState = self:getPlayerCurrency(player)
	
	-- Проверяем, хватает ли монет
	if currentState.coins < amount then
		return false
	end
	
	-- Списываем монеты
	playerCurrencyCache[player] = {
		coins = currentState.coins - amount,
		gems = currentState.gems,
		tokens = currentState.tokens,
	}
	
	-- Уведомляем подписчиков
	self:_notifyCurrencyChanged(player, playerCurrencyCache[player])
	
	return true
end

-- Проверить, хватает ли монет
function CurrencyService:hasEnoughCoins(player: Player, amount: number): boolean
	local currentState = self:getPlayerCurrency(player)
	return currentState.coins >= amount
end

-- Подписаться на изменения валюты
function CurrencyService:onCurrencyChanged(callback: (player: Player, newState: CurrencyState) -> ())
	table.insert(currencyChangeCallbacks, callback)
end

-- Загрузить данные игрока (заглушка - позже добавим DataStore)
function CurrencyService:loadPlayerData(player: Player): CurrencyState
	-- TODO: Интеграция с DataStoreService
	print("CurrencyService: Загружаем данные для", player.Name)
	
	return {
		coins = CONFIG.DEFAULT_COINS,
		gems = 0,
		tokens = 0,
	}
end

-- Сохранить данные игрока (заглушка)
function CurrencyService:savePlayerData(player: Player)
	local playerData = playerCurrencyCache[player]
	if not playerData then return end
	
	-- TODO: Интеграция с DataStoreService
	print("CurrencyService: Сохраняем данные для", player.Name, "Монеты:", playerData.coins)
end

-- Приватные методы

-- Уведомить подписчиков об изменении валюты
function CurrencyService:_notifyCurrencyChanged(player: Player, newState: CurrencyState)
	for _, callback in ipairs(currencyChangeCallbacks) do
		pcall(callback, player, newState)
	end
end

-- Запустить автосохранение (только на сервере)
function CurrencyService:_startAutoSave()
	spawn(function()
		while true do
			wait(CONFIG.AUTO_SAVE_INTERVAL)
			
			-- Сохраняем данные всех игроков
			for player, _ in pairs(playerCurrencyCache) do
				if player.Parent then -- Игрок всё ещё в игре
					self:savePlayerData(player)
				else
					-- Убираем из кэша отключившихся игроков
					playerCurrencyCache[player] = nil
					playerCooldowns[player] = nil
				end
			end
		end
	end)
end

-- Очистка при выходе игрока
Players.PlayerRemoving:Connect(function(player)
	local service = CurrencyService :: any
	if service.savePlayerData then
		service:savePlayerData(player)
	end
	
	-- Очищаем кэш
	playerCurrencyCache[player] = nil
	playerCooldowns[player] = nil
end)

return CurrencyService
