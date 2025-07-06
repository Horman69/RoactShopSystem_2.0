--!strict
-- src/shared/AbilityData.luau
-- Данные способностей для магазина
-- Содержит базовые способности: Бег, Щит, Прыжок

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))

type Ability = Types.Ability
type AbilityList = Types.AbilityList

-- Данные способностей
local ABILITIES: AbilityList = {
	{
		id = "speed_boost",
		name = "🏃 Ускорение",
		description = "Увеличивает скорость бега до 32 на 15 секунд",
		category = "Movement",
		baseDuration = 15, -- 15 секунд базово
		cooldown = 30, -- 30 секунд кулдаун
		price = 50, -- 50 монет
		effects = {
			{
				type = "Set",
				value = 32, -- Устанавливаем скорость 32 (16 * 2)
				target = "WalkSpeed"
			}
		},
		icon = "🏃",
		isStackable = false, -- Нельзя стакать ускорение
	},
	
	{
		id = "shield_aura",
		name = "🛡️ Щит",
		description = "Создает защитную ауру вокруг игрока на 15 секунд", 
		category = "Shield",
		baseDuration = 15,
		cooldown = 30, -- 30 секунд кулдаун
		price = 75, -- Дороже чем бег
		effects = {
			{
				type = "Add",
				value = 50, -- +50 к защите
				target = "Shield"
			}
		},
		icon = "🛡️",
		isStackable = true, -- Можно стакать щиты
	},
	
	{
		id = "jump_boost",
		name = "⬆️ Супер прыжок",
		description = "Увеличивает высоту прыжка в 1.5 раза на 15 секунд",
		category = "Movement", 
		baseDuration = 15,
		cooldown = 30, -- 30 секунд кулдаун
		price = 40, -- Дешевле остальных
		effects = {
			{
				type = "Multiply",
				value = 1.5, -- x1.5 к прыжку
				target = "JumpHeight"
			}
		},
		icon = "⬆️",
		isStackable = false, -- Нельзя стакать прыжки
	}
}

-- Функция для получения способности по ID
local function getAbilityById(abilityId: string): Ability?
	for _, ability in ipairs(ABILITIES) do
		if ability.id == abilityId then
			return ability
		end
	end
	return nil
end

-- Функция для получения способностей по категории
local function getAbilitiesByCategory(category: string): AbilityList
	local result: AbilityList = {}
	for _, ability in ipairs(ABILITIES) do
		if ability.category == category then
			table.insert(result, ability)
		end
	end
	return result
end

-- Функция для валидации способности
local function validateAbility(ability: Ability): boolean
	-- Проверяем обязательные поля
	if not ability.id or not ability.name or not ability.description then
		return false
	end
	
	-- Проверяем корректность значений
	if ability.baseDuration <= 0 or ability.cooldown < 0 or ability.price < 0 then
		return false
	end
	
	-- Проверяем наличие эффектов
	if not ability.effects or #ability.effects == 0 then
		return false
	end
	
	return true
end

-- Валидируем все способности при загрузке модуля
for _, ability in ipairs(ABILITIES) do
	if not validateAbility(ability) then
		error("AbilityData: Некорректная способность: " .. tostring(ability.id))
	end
end

print("AbilityData: Загружено", #ABILITIES, "способностей")

return {
	ABILITIES = ABILITIES,
	getAbilityById = getAbilityById,
	getAbilitiesByCategory = getAbilitiesByCategory,
	validateAbility = validateAbility,
}
