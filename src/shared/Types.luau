--!strict
-- src/shared/Types.luau
-- Система типов для магазина и валюты
-- Все интерфейсы и типы данных в одном месте

-- Тип товара в магазине
export type Product = {
	id: number,
	name: string,
	price: number,
	description: string,
	category: string?, -- Опциональная категория (ability, weapon, armor, и т.д.)
	icon: string?, -- Опциональная иконка товара
	maxQuantity: number?, -- Максимальное количество для покупки
	requirements: {[string]: any}?, -- Требования для покупки (уровень, другие товары)
	abilityId: string?, -- ID способности (если товар - способность)
}

-- Массив товаров
export type ProductList = {Product}

-- Интерфейс кошелька
export type WalletInterface = {
	getCoins: (self: WalletInterface) -> number,
	addCoins: (self: WalletInterface, amount: number) -> (),
	spendCoins: (self: WalletInterface, amount: number) -> boolean,
	hasEnoughCoins: (self: WalletInterface, amount: number) -> boolean,
}

-- Результат операции покупки
export type PurchaseResult = {
	success: boolean,
	message: string,
	product: Product?,
	remainingCoins: number?,
}

-- Состояние валюты игрока
export type CurrencyState = {
	coins: number,
	gems: number?, -- Для будущего расширения
	tokens: number?, -- Для будущего расширения
}

-- Пропсы для компонента кошелька
export type WalletComponentProps = {
	coins: number,
	onCoinChange: ((newAmount: number) -> ())?,
}

-- Пропсы для компонента магазина
export type ShopComponentProps = {
	wallet: WalletInterface,
	onPurchase: ((product: Product) -> ())?,
	products: ProductList?,
}

-- Пропсы для компонента товара
export type ProductItemProps = {
	product: Product,
	wallet: WalletInterface,
	onPurchase: (product: Product) -> (),
}

-- События для системы магазина
export type ShopEvents = {
	ProductPurchased: "ProductPurchased",
	InsufficientFunds: "InsufficientFunds",
	CurrencyChanged: "CurrencyChanged",
}

-- Конфигурация магазина
export type ShopConfig = {
	defaultCurrency: number,
	maxCoinsPerSession: number?,
	enableNotifications: boolean,
	notificationDuration: number,
}

-- ===== СИСТЕМА СПОСОБНОСТЕЙ =====

-- Категории способностей
export type AbilityCategory = "Movement" | "Shield" | "Combat" | "Utility"

-- Типы эффектов способностей
export type EffectType = "Multiply" | "Add" | "Set"

-- Цели эффектов (на что влияет способность)
export type EffectTarget = "WalkSpeed" | "JumpHeight" | "Shield" | "Health" | "Damage"

-- Эффект способности
export type AbilityEffect = {
	type: EffectType,
	value: number, -- Множитель или значение
	target: EffectTarget, -- На что влияет
}

-- Способность
export type Ability = {
	id: string,
	name: string,
	description: string,
	category: AbilityCategory,
	baseDuration: number, -- Базовая длительность в секундах
	cooldown: number, -- Кулдаун между использованиями в секундах
	price: number, -- Цена в магазине
	effects: {AbilityEffect}, -- Список эффектов способности
	icon: string?, -- Иконка для UI
	isStackable: boolean?, -- Можно ли стакать эффект
}

-- Список способностей
export type AbilityList = {Ability}

-- Активный эффект на игроке
export type ActiveEffect = {
	abilityId: string,
	startTime: number, -- Время начала (tick())
	duration: number, -- Длительность с учетом бустов
	effects: {AbilityEffect}, -- Эффекты способности
}

-- Состояние способностей игрока
export type PlayerAbilityState = {
	ownedAbilities: {[string]: boolean}, -- Купленные способности
	activeEffects: {[string]: ActiveEffect}, -- Активные эффекты
	cooldowns: {[string]: number}, -- Кулдауны способностей (время окончания)
}

-- Результат активации способности
export type AbilityActivationResult = {
	success: boolean,
	message: string,
	ability: Ability?,
	cooldownEnd: number?, -- Время окончания кулдауна
}

-- Пропсы для компонента способности
export type AbilityButtonProps = {
	ability: Ability,
	isOwned: boolean,
	isOnCooldown: boolean,
	cooldownTimeLeft: number?,
	onActivate: (abilityId: string) -> (),
	onPurchase: (ability: Ability) -> ()?,
}

-- Пропсы для панели способностей
export type AbilityBarProps = {
	abilities: AbilityList,
	playerState: PlayerAbilityState,
	onActivateAbility: (abilityId: string) -> (),
}

-- Пропсы для отображения активных эффектов
export type EffectDisplayProps = {
	activeEffects: {[string]: ActiveEffect},
}

-- ===== КОНЕЦ СИСТЕМЫ СПОСОБНОСТЕЙ =====

return {
	-- Экспортируем типы через module для совместимости
	Product = {} :: Product,
	WalletInterface = {} :: WalletInterface,
	PurchaseResult = {} :: PurchaseResult,
	CurrencyState = {} :: CurrencyState,
	-- Добавляем новые типы способностей
	Ability = {} :: Ability,
	AbilityList = {} :: AbilityList,
	PlayerAbilityState = {} :: PlayerAbilityState,
	AbilityActivationResult = {} :: AbilityActivationResult,
	ActiveEffect = {} :: ActiveEffect,
	AbilityEffect = {} :: AbilityEffect,
	AbilityCategory = {} :: AbilityCategory,
	EffectType = {} :: EffectType,
	EffectTarget = {} :: EffectTarget,
}
