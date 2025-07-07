--!strict
-- src/shared/AbilityConfig.luau
-- Конфигурация всех способностей - легко добавлять новые и настраивать существующие

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))

type Ability = Types.Ability
type AbilityList = Types.AbilityList

-- ===== КОНФИГУРАЦИЯ СПОСОБНОСТЕЙ =====

local ABILITY_CONFIG: AbilityList = {
	-- ⚡ СПОСОБНОСТЬ УСКОРЕНИЯ
	{
		id = "speed_boost",
		name = "⚡ Ускорение",
		description = "Увеличивает скорость бега до 32 на 15 секунд",
		category = "Movement",
		baseDuration = 15, -- секунд
		cooldown = 15, -- секунд (быстрее для лучшего UX)
		price = 50, -- монет
		effects = {
			{
				type = "Set",
				value = 32, -- скорость
				target = "WalkSpeed"
			}
		},
		icon = "⚡",
		isStackable = false,
		-- Дополнительные настройки
		hotkey = "Q", -- горячая клавиша
		visualEffect = "speed_trail", -- визуальный эффект
	},
	
	-- 🛡️ СПОСОБНОСТЬ ЩИТА
	{
		id = "shield_aura",
		name = "🛡️ Щит",
		description = "Создает защитную ауру вокруг игрока на 15 секунд", 
		category = "Shield",
		baseDuration = 15,
		cooldown = 15, -- секунд (быстрее для лучшего UX)
		price = 75,
		effects = {
			{
				type = "Add",
				value = 50, -- +50 к защите
				target = "Shield"
			}
		},
		icon = "🛡️",
		isStackable = true, -- можно накладывать несколько щитов
		-- Дополнительные настройки
		hotkey = "E",
		visualEffect = "shield_glow",
		shieldColor = Color3.fromRGB(0, 170, 255), -- цвет щита
		shieldTransparency = 0.7,
	},
	
	-- 🚀 СПОСОБНОСТЬ ПРЫЖКА
	{
		id = "jump_boost",
		name = "🚀 Супер прыжок",
		description = "Увеличивает высоту прыжка в 1.5 раза на 15 секунд",
		category = "Movement", 
		baseDuration = 15,
		cooldown = 15, -- секунд (быстрее для лучшего UX)
		price = 40,
		effects = {
			{
				type = "Multiply",
				value = 1.5, -- x1.5 к прыжку
				target = "JumpHeight"
			}
		},
		icon = "🚀",
		isStackable = false,
		-- Дополнительные настройки
		hotkey = "R",
		visualEffect = "jump_particles",
	},
}

-- ===== НАСТРОЙКИ КАТЕГОРИЙ =====

local CATEGORY_CONFIG = {
	Movement = {
		color = Color3.fromRGB(52, 199, 89), -- зеленый
		icon = "🏃",
		description = "Способности передвижения",
	},
	Shield = {
		color = Color3.fromRGB(0, 122, 255), -- синий
		icon = "🛡️",
		description = "Защитные способности",
	},
	Combat = {
		color = Color3.fromRGB(255, 59, 48), -- красный
		icon = "⚔️",
		description = "Боевые способности",
	},
	Utility = {
		color = Color3.fromRGB(88, 86, 214), -- фиолетовый
		icon = "🔧",
		description = "Вспомогательные способности",
	},
}

-- ===== ГЛОБАЛЬНЫЕ НАСТРОЙКИ =====

local GLOBAL_SETTINGS = {
	-- Баланс
	DEFAULT_COOLDOWN = 15, -- базовый кулдаун (быстрее для лучшего UX)
	DEFAULT_DURATION = 15, -- базовая длительность
	PREMIUM_MULTIPLIER = 1.5, -- множитель для премиум игроков
	
	-- Лимиты
	MAX_ACTIVE_ABILITIES = 3, -- максимум активных способностей одновременно
	MAX_STACK_COUNT = 5, -- максимум стаков для stackable способностей
	
	-- UI
	ABILITY_BUTTON_SIZE = 64,
	ABILITY_BUTTON_SPACING = 8,
	HOTKEY_DISPLAY = true, -- показывать горячие клавиши
	
	-- Звуки
	-- Эффекты
	ENABLE_VISUAL_EFFECTS = true,
	PARTICLE_QUALITY = "Medium", -- Low, Medium, High
}

-- ===== ФУНКЦИИ ДОСТУПА =====

local AbilityConfig = {}

-- Получить все способности
function AbilityConfig.getAllAbilities(): AbilityList
	return ABILITY_CONFIG
end

-- Получить только базовые способности (доступные с самого начала)
function AbilityConfig.getBasicAbilities(): AbilityList
	-- Базовые способности - это все способности из этого конфига
	-- Особые способности находятся в SpecialAbilityConfig
	return ABILITY_CONFIG
end

-- Получить способность по ID
function AbilityConfig.getAbilityById(abilityId: string): Ability?
	for _, ability in ipairs(ABILITY_CONFIG) do
		if ability.id == abilityId then
			return ability
		end
	end
	return nil
end

-- Получить способности по категории
function AbilityConfig.getAbilitiesByCategory(category: string): AbilityList
	local result: AbilityList = {}
	for _, ability in ipairs(ABILITY_CONFIG) do
		if ability.category == category then
			table.insert(result, ability)
		end
	end
	return result
end

-- Получить конфигурацию категории
function AbilityConfig.getCategoryConfig(category: string)
	return CATEGORY_CONFIG[category] or {
		color = Color3.fromRGB(128, 128, 128),
		icon = "❓",
		description = "Неизвестная категория",
	}
end

-- Получить глобальные настройки
function AbilityConfig.getGlobalSettings()
	return GLOBAL_SETTINGS
end

-- Валидация способности
function AbilityConfig.validateAbility(ability: Ability): boolean
	-- Проверяем обязательные поля
	if not ability.id or not ability.name or not ability.description then
		warn("AbilityConfig: Отсутствуют обязательные поля у способности", ability.id or "unknown")
		return false
	end
	
	-- Проверяем корректность значений
	if ability.baseDuration < 0 or ability.cooldown < 0 or ability.price < 0 then
		warn("AbilityConfig: Некорректные значения у способности", ability.id)
		return false
	end
	
	-- Проверяем наличие эффектов
	if not ability.effects or #ability.effects == 0 then
		warn("AbilityConfig: Отсутствуют эффекты у способности", ability.id)
		return false
	end
	
	-- Проверяем корректность эффектов
	for _, effect in ipairs(ability.effects) do
		if not effect.type or not effect.target or effect.value == nil then
			warn("AbilityConfig: Некорректный эффект у способности", ability.id)
			return false
		end
	end
	
	return true
end

-- Валидируем все способности при загрузке
for _, ability in ipairs(ABILITY_CONFIG) do
	if not AbilityConfig.validateAbility(ability) then
		error("AbilityConfig: Некорректная способность: " .. tostring(ability.id))
	end
end

print("✅ AbilityConfig: Загружено", #ABILITY_CONFIG, "способностей в", table.getn(CATEGORY_CONFIG), "категориях")

return AbilityConfig
