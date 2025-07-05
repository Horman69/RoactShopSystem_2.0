--!strict
-- src/services/ShopService.luau
-- Сервис управления магазином
-- Отвечает за логику покупок, валидацию товаров и инвентарь

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Импортируем зависимости
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))

-- Импортируем данные и сервисы
local ShopData = ModuleLoader.require("Shop/ShopData")
local CurrencyService = ModuleLoader.require("services/CurrencyService")
local AbilityService = ModuleLoader.require("services/AbilityService")

-- Типы
type Product = Types.Product
type PurchaseResult = Types.PurchaseResult
type ProductList = Types.ProductList

-- Интерфейс сервиса магазина
type ShopServiceInterface = {
	getAvailableProducts: (self: ShopServiceInterface, player: Player?) -> ProductList,
	purchaseProduct: (self: ShopServiceInterface, player: Player, productId: number) -> PurchaseResult,
	getProductById: (self: ShopServiceInterface, productId: number) -> Product?,
	validateProduct: (self: ShopServiceInterface, product: Product) -> boolean,
	canPlayerBuyProduct: (self: ShopServiceInterface, player: Player, product: Product) -> boolean,
	addProductToInventory: (self: ShopServiceInterface, player: Player, product: Product) -> boolean,
}

local ShopService = {} :: ShopServiceInterface
ShopService.__index = ShopService

-- Кэш инвентарей игроков
local playerInventories: {[Player]: {[number]: number}} = {}

-- Статистика продаж
local salesStats: {[number]: number} = {}

-- Инициализация сервиса
function ShopService.new(): ShopServiceInterface
	local self = setmetatable({}, ShopService)
	
	-- Инициализируем CurrencyService
	self.currencyService = CurrencyService.new()
	
	-- Инициализируем AbilityService
	self.abilityService = AbilityService.new()
	
	-- Валидируем все товары при запуске
	self:_validateAllProducts()
	
	return self
end

-- Получить доступные товары для игрока
function ShopService:getAvailableProducts(player: Player?): ProductList
	local availableProducts: ProductList = {}
	
	for _, product in ipairs(ShopData) do
		-- Базовая валидация товара
		if self:validateProduct(product) then
			-- Если игрок указан, проверяем требования
			if not player or self:_checkProductRequirements(player, product) then
				table.insert(availableProducts, product)
			end
		end
	end
	
	return availableProducts
end

-- Купить товар
function ShopService:purchaseProduct(player: Player, productId: number): PurchaseResult
	local product = self:getProductById(productId)
	
	-- Проверка существования товара
	if not product then
		return {
			success = false,
			message = "Товар не найден",
			product = nil,
			remainingCoins = nil,
		}
	end
	
	-- Валидация товара
	if not self:validateProduct(product) then
		return {
			success = false,
			message = "Товар недоступен для покупки",
			product = product,
			remainingCoins = nil,
		}
	end
	
	-- Проверка возможности покупки
	if not self:canPlayerBuyProduct(player, product) then
		local playerCurrency = self.currencyService:getPlayerCurrency(player)
		return {
			success = false,
			message = "Недостаточно монет для покупки",
			product = product,
			remainingCoins = playerCurrency.coins,
		}
	end
	
	-- Попытка списания монет
	local spendSuccess = self.currencyService:spendCoins(player, product.price)
	if not spendSuccess then
		local playerCurrency = self.currencyService:getPlayerCurrency(player)
		return {
			success = false,
			message = "Ошибка при списании монет",
			product = product,
			remainingCoins = playerCurrency.coins,
		}
	end
	
	-- Добавление товара в инвентарь
	local inventorySuccess = self:addProductToInventory(player, product)
	if not inventorySuccess then
		-- Возвращаем монеты при ошибке инвентаря
		self.currencyService:addCoins(player, product.price)
		local playerCurrency = self.currencyService:getPlayerCurrency(player)
		
		return {
			success = false,
			message = "Ошибка при добавлении товара в инвентарь",
			product = product,
			remainingCoins = playerCurrency.coins,
		}
	end
	
	-- Обновляем статистику
	self:_updateSalesStats(productId)
	
	-- Успешная покупка
	local playerCurrency = self.currencyService:getPlayerCurrency(player)
	print("ShopService: Игрок", player.Name, "купил", product.name, "за", product.price, "монет")
	
	return {
		success = true,
		message = "Товар успешно куплен!",
		product = product,
		remainingCoins = playerCurrency.coins,
	}
end

-- Найти товар по ID
function ShopService:getProductById(productId: number): Product?
	for _, product in ipairs(ShopData) do
		if product.id == productId then
			return product
		end
	end
	return nil
end

-- Валидация товара
function ShopService:validateProduct(product: Product): boolean
	-- Проверка обязательных полей
	if not product.id or not product.name or not product.price or not product.description then
		warn("ShopService: Товар имеет пустые обязательные поля:", product.name or "Неизвестный")
		return false
	end
	
	-- Проверка корректности цены
	if product.price <= 0 then
		warn("ShopService: Товар имеет некорректную цену:", product.name, product.price)
		return false
	end
	
	-- Проверка максимального количества
	if product.maxQuantity and product.maxQuantity <= 0 then
		warn("ShopService: Товар имеет некорректное максимальное количество:", product.name)
		return false
	end
	
	return true
end

-- Проверить, может ли игрок купить товар
function ShopService:canPlayerBuyProduct(player: Player, product: Product): boolean
	-- Проверка наличия монет
	if not self.currencyService:hasEnoughCoins(player, product.price) then
		return false
	end
	
	-- Проверка требований товара
	if not self:_checkProductRequirements(player, product) then
		return false
	end
	
	-- Проверка для способностей - если игрок уже владеет способностью
	if product.category == "ability" and product.abilityId then
		if self.abilityService:isAbilityOwned(player, product.abilityId) then
			return false -- Игрок уже владеет этой способностью
		end
	end
	
	-- Проверка максимального количества в инвентаре
	if product.maxQuantity then
		local playerInventory = self:_getPlayerInventory(player)
		local currentQuantity = playerInventory[product.id] or 0
		
		if currentQuantity >= product.maxQuantity then
			return false
		end
	end
	
	return true
end

-- Добавить товар в инвентарь
function ShopService:addProductToInventory(player: Player, product: Product): boolean
	-- Проверяем, является ли товар способностью
	if product.category == "ability" and product.abilityId then
		-- Для способностей выдаем их через AbilityService
		local success = self.abilityService:grantAbility(player, product.abilityId)
		if success then
			print("ShopService: Игрок", player.Name, "получил способность", product.name)
			return true
		else
			warn("ShopService: Ошибка при выдаче способности", product.abilityId, "игроку", player.Name)
			return false
		end
	else
		-- Для обычных товаров добавляем в инвентарь
		local playerInventory = self:_getPlayerInventory(player)
		playerInventory[product.id] = (playerInventory[product.id] or 0) + 1
		print("ShopService: Добавлен товар в инвентарь:", player.Name, product.name)
		return true
	end
end

-- Приватные методы

-- Получить инвентарь игрока
function ShopService:_getPlayerInventory(player: Player): {[number]: number}
	if not playerInventories[player] then
		playerInventories[player] = {}
	end
	return playerInventories[player]
end

-- Проверить требования товара
function ShopService:_checkProductRequirements(player: Player, product: Product): boolean
	-- Проверяем, является ли товар способностью и владеет ли игрок уже ею
	if product.category == "ability" and product.abilityId then
		if self.abilityService:isAbilityOwned(player, product.abilityId) then
			return false -- Игрок уже владеет этой способностью - не показываем в магазине
		end
	end
	
	-- Если нет требований, товар доступен всем
	if not product.requirements then
		return true
	end
	
	-- TODO: Реализовать проверку требований (уровень, другие товары и т.д.)
	-- Пока что возвращаем true для всех товаров
	return true
end

-- Валидировать все товары при инициализации
function ShopService:_validateAllProducts()
	local validProducts = 0
	local invalidProducts = 0
	
	for _, product in ipairs(ShopData) do
		if self:validateProduct(product) then
			validProducts += 1
		else
			invalidProducts += 1
		end
	end
	
	print("ShopService: Валидация завершена. Валидных товаров:", validProducts, "Невалидных:", invalidProducts)
end

-- Обновить статистику продаж
function ShopService:_updateSalesStats(productId: number)
	salesStats[productId] = (salesStats[productId] or 0) + 1
end

-- Очистка инвентаря при выходе игрока
game.Players.PlayerRemoving:Connect(function(player)
	-- TODO: Сохранить инвентарь в DataStore
	playerInventories[player] = nil
end)

return ShopService
