--!strict
-- src/shared/SpecialAbilityConfig.luau
-- Конфигурация особых способностей - премиум контент для будущего
-- Эти способности можно будет докупать отдельно

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))

type Ability = Types.Ability
type AbilityList = Types.AbilityList

-- ===== ОСОБЫЕ СПОСОБНОСТИ =====

local SPECIAL_ABILITIES: AbilityList = {
	-- 💪 СПОСОБНОСТЬ СИЛЫ - премиум
	{
		id = "strength_boost",
		name = "💪 Сила",
		description = "Увеличивает урон в 2 раза на 10 секунд",
		category = "Combat",
		baseDuration = 10,
		cooldown = 45,
		price = 200, -- дороже обычных
		effects = {
			{
				type = "Multiply",
				value = 2.0,
				target = "Damage"
			}
		},
		icon = "💪",
		isStackable = false,
		hotkey = "T",
		visualEffect = "strength_aura",
		-- Особые настройки
		isSpecial = true, -- флаг особой способности
		requiresUnlock = true, -- требует разблокировки
		unlockLevel = 10, -- минимальный уровень
	},
	
	-- 💨 СПОСОБНОСТЬ НЕВИДИМОСТИ - премиум
	{
		id = "invisibility",
		name = "💨 Невидимость",
		description = "Делает игрока невидимым на 8 секунд",
		category = "Utility",
		baseDuration = 8,
		cooldown = 60,
		price = 300, -- очень дорого
		effects = {
			{
				type = "Set",
				value = 0.1, -- почти невидим
				target = "Transparency"
			}
		},
		icon = "💨",
		isStackable = false,
		hotkey = "F",
		visualEffect = "fade_out",
		-- Особые настройки
		isSpecial = true,
		requiresUnlock = true,
		unlockLevel = 15,
		unlockRequirements = {"strength_boost"}, -- нужна сила
	},
	
	-- 🔥 ОГНЕННАЯ АУРА - премиум
	{
		id = "fire_aura",
		name = "🔥 Огненная аура",
		description = "Наносит урон всем врагам рядом на 12 секунд",
		category = "Combat",
		baseDuration = 12,
		cooldown = 50,
		price = 250,
		effects = {
			{
				type = "Add",
				value = 20,
				target = "AreaDamage"
			}
		},
		icon = "🔥",
		isStackable = false,
		hotkey = "G",
		visualEffect = "fire_aura",
		-- Особые настройки
		isSpecial = true,
		requiresUnlock = true,
		unlockLevel = 12,
	},
}

-- ===== ФУНКЦИИ ДОСТУПА =====

local SpecialAbilityConfig = {}

-- Получить все особые способности
function SpecialAbilityConfig.getAllSpecialAbilities(): AbilityList
	return SPECIAL_ABILITIES
end

-- Получить особую способность по ID
function SpecialAbilityConfig.getSpecialAbilityById(abilityId: string): Ability?
	for _, ability in ipairs(SPECIAL_ABILITIES) do
		if ability.id == abilityId then
			return ability
		end
	end
	return nil
end

-- Проверить, является ли способность особой
function SpecialAbilityConfig.isSpecialAbility(abilityId: string): boolean
	return SpecialAbilityConfig.getSpecialAbilityById(abilityId) ~= nil
end

-- Проверить требования для разблокировки
function SpecialAbilityConfig.checkUnlockRequirements(ability: Ability, playerLevel: number, ownedAbilities: {[string]: boolean}): boolean
	if not ability.isSpecial then
		return true
	end
	
	-- Проверяем уровень
	if ability.unlockLevel and playerLevel < ability.unlockLevel then
		return false
	end
	
	-- Проверяем требуемые способности
	if ability.unlockRequirements then
		for _, requiredId in ipairs(ability.unlockRequirements) do
			if not ownedAbilities[requiredId] then
				return false
			end
		end
	end
	
	return true
end

print("✅ SpecialAbilityConfig: Загружено", #SPECIAL_ABILITIES, "особых способностей")

return SpecialAbilityConfig
