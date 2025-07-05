--!strict
-- src/client/TestShopFiltering.client.luau
-- Улучшенный тест фильтрации товаров в магазине

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local ShopService = ModuleLoader.require("services/ShopService")
local AbilityService = ModuleLoader.require("services/AbilityService")

local player = Players.LocalPlayer

wait(2) -- Ждём инициализацию сервисов

-- Создаём экземпляры сервисов
local shopService = ShopService.new()
local abilityService = AbilityService.new()

print("=== УЛУЧШЕННЫЙ ТЕСТ ФИЛЬТРАЦИИ МАГАЗИНА ===")

-- Функция для отображения списка товаров
local function showProducts(title, products)
	print("\n" .. title .. ":")
	if #products == 0 then
		print("  (товаров нет)")
	else
		for i, product in ipairs(products) do
			print("  ", i, product.name, "(ID:", product.id .. ", цена:", product.price .. ")")
		end
	end
end

-- Функция для проверки владения способностями
local function checkAbilities()
	print("\nВладение способностями:")
	print("  speed_boost:", abilityService:isAbilityOwned(player, "speed_boost"))
	print("  shield_aura:", abilityService:isAbilityOwned(player, "shield_aura"))
	print("  jump_boost:", abilityService:isAbilityOwned(player, "jump_boost"))
end

-- 1. Проверяем товары до покупки
local productsBeforePurchase = shopService:getAvailableProducts(player)
showProducts("1. Товары в магазине ДО покупки", productsBeforePurchase)
checkAbilities()

-- 2. Покупаем способность speed_boost
print("\n2. Покупаем speed_boost...")
local purchaseResult1 = shopService:purchaseProduct(player, 1)
if purchaseResult1.success then
	print("✓ Покупка успешна:", purchaseResult1.message)
else
	print("✗ Ошибка покупки:", purchaseResult1.message)
end

-- 3. Проверяем товары после первой покупки
local productsAfterPurchase1 = shopService:getAvailableProducts(player)
showProducts("3. Товары в магазине ПОСЛЕ покупки speed_boost", productsAfterPurchase1)
checkAbilities()

-- 4. Покупаем способность shield_aura
print("\n4. Покупаем shield_aura...")
local purchaseResult2 = shopService:purchaseProduct(player, 2)
if purchaseResult2.success then
	print("✓ Покупка успешна:", purchaseResult2.message)
else
	print("✗ Ошибка покупки:", purchaseResult2.message)
end

-- 5. Проверяем товары после второй покупки
local productsAfterPurchase2 = shopService:getAvailableProducts(player)
showProducts("5. Товары в магазине ПОСЛЕ покупки shield_aura", productsAfterPurchase2)
checkAbilities()

-- 6. Пытаемся купить уже купленную способность
print("\n6. Пытаемся повторно купить speed_boost...")
local purchaseResult3 = shopService:purchaseProduct(player, 1)
if purchaseResult3.success then
	print("✗ ОШИБКА: Удалось купить уже купленную способность!")
else
	print("✓ Правильно: Повторная покупка заблокирована:", purchaseResult3.message)
end

-- 7. Финальная проверка
local finalProducts = shopService:getAvailableProducts(player)
showProducts("7. ИТОГОВЫЙ список товаров в магазине", finalProducts)
checkAbilities()

print("\n=== ТЕСТ ЗАВЕРШЁН ===")
print("Ожидаемый результат: в магазине должен остаться только jump_boost")
print("Купленные способности (speed_boost, shield_aura) должны исчезнуть из магазина")
