--!strict
-- src/Shop/Wallet.luau
-- Модуль кошелька пользователя
-- Отвечает за хранение и изменение количества монет

-- Импортируем типы из централизованного модуля
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type WalletInterface = Types.WalletInterface

local Wallet = {}
Wallet.__index = Wallet

-- Конструктор кошелька
function Wallet.new(initialCoins: number?): WalletInterface
	local self = setmetatable({}, Wallet)
	self.coins = initialCoins or 0
	return self
end

-- Получить текущее количество монет
function Wallet:getCoins(): number
	return self.coins
end

-- Добавить монеты
function Wallet:addCoins(amount: number): ()
	if amount > 0 then
		self.coins = self.coins + amount
	end
end

-- Проверить, хватает ли монет
function Wallet:hasEnoughCoins(amount: number): boolean
	return self.coins >= amount
end

-- Списать монеты (если хватает)
function Wallet:spendCoins(amount: number): boolean
	if amount <= 0 then
		return false -- Нельзя тратить отрицательную сумму
	end
	
	if self.coins >= amount then
		self.coins = self.coins - amount
		return true
	else
		return false -- недостаточно монет
	end
end

return Wallet
