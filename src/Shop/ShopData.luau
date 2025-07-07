--!strict
-- src/Shop/ShopData.luau
-- Массив товаров магазина. Только особые способности для покупки!

-- Импортируем типы из централизованного модуля
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type Product = Types.Product

local Products: {Product} = {
	-- БАЗОВЫЕ СПОСОБНОСТИ (нужно покупать)
	{
		id = 100,
		name = "Ускорение",
		price = 50,
		description = "Увеличивает скорость на 15 секунд (Q)",
		category = "ability",
		abilityId = "speed_boost",
	},
	{
		id = 101,
		name = "Щит",
		price = 75,
		description = "Защитная аура на 15 секунд (E)",
		category = "ability",
		abilityId = "shield_aura",
	},
	{
		id = 102,
		name = "Супер прыжок",
		price = 60,
		description = "Увеличивает прыжок в 1.5 раза на 15 секунд (R)",
		category = "ability",
		abilityId = "jump_boost",
	},
}

return Products
