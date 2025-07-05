# 📋 Руководство по добавлению новых способностей

## 🎯 Обзор системы

Система способностей теперь полностью централизована в конфигурационных файлах:

- **`src/shared/AbilityConfig.luau`** - основные способности (доступны всем)
- **`src/shared/SpecialAbilityConfig.luau`** - особые способности (премиум контент)

## ✅ Как добавить новую обычную способность

### 1. Откройте файл `src/shared/AbilityConfig.luau`

### 2. Добавьте новую способность в массив `ABILITY_CONFIG`:

```lua
{
	id = "my_new_ability", -- уникальный ID
	name = "🔥 Моя способность", -- отображаемое имя с эмодзи
	description = "Описание того, что делает способность",
	category = "Movement", -- Movement, Shield, Combat, Utility
	baseDuration = 15, -- длительность в секундах (0 для мгновенных)
	cooldown = 30, -- кулдаун в секундах
	price = 100, -- цена в монетах
	effects = {
		{
			type = "Set", -- Set, Add, Multiply
			value = 50, -- значение эффекта
			target = "WalkSpeed" -- WalkSpeed, JumpHeight, Shield, Health, Damage
		}
	},
	icon = "🔥", -- эмодзи иконка
	isStackable = false, -- можно ли накладывать несколько раз
	-- Дополнительные настройки
	hotkey = "T", -- горячая клавиша
	soundEffect = "fire_sound", -- звук активации
	visualEffect = "fire_particles", -- визуальный эффект
},
```

### 3. Типы эффектов:

- **`Set`** - устанавливает точное значение (например, скорость = 32)
- **`Add`** - добавляет к текущему значению (например, +50 щита)
- **`Multiply`** - умножает на значение (например, прыжок × 1.5)

### 4. Цели эффектов:

- **`WalkSpeed`** - скорость ходьбы
- **`JumpHeight`** - высота прыжка
- **`Shield`** - защита
- **`Health`** - здоровье
- **`Damage`** - урон

### 5. Категории:

- **`Movement`** - способности передвижения (зеленый цвет)
- **`Shield`** - защитные способности (синий цвет)
- **`Combat`** - боевые способности (красный цвет)
- **`Utility`** - вспомогательные способности (фиолетовый цвет)

## 🌟 Как добавить особую способность

### 1. Откройте файл `src/shared/SpecialAbilityConfig.luau`

### 2. Добавьте способность в массив `SPECIAL_ABILITIES`:

```lua
{
	id = "my_special_ability",
	name = "⭐ Особая способность",
	description = "Мощная премиум способность",
	category = "Combat",
	baseDuration = 20,
	cooldown = 120, -- больший кулдаун
	price = 500, -- дороже обычных
	effects = {
		{
			type = "Multiply",
			value = 3.0, -- мощнее обычных
			target = "Damage"
		}
	},
	icon = "⭐",
	isStackable = false,
	hotkey = "Y",
	soundEffect = "epic_sound",
	visualEffect = "epic_effect",
	-- Особые настройки
	isSpecial = true, -- обязательно для особых способностей
	requiresUnlock = true, -- требует разблокировки
	unlockLevel = 10, -- минимальный уровень
	unlockRequirements = {"strength_boost"}, -- требуемые способности
},
```

## 🔧 Глобальные настройки

В файле `AbilityConfig.luau` есть секция `GLOBAL_SETTINGS`:

```lua
local GLOBAL_SETTINGS = {
	-- Баланс
	DEFAULT_COOLDOWN = 30, -- базовый кулдаун
	DEFAULT_DURATION = 15, -- базовая длительность
	PREMIUM_MULTIPLIER = 1.5, -- множитель для премиум игроков
	
	-- Лимиты
	MAX_ACTIVE_ABILITIES = 3, -- максимум активных способностей
	MAX_STACK_COUNT = 5, -- максимум стаков
	
	-- UI настройки
	ABILITY_BUTTON_SIZE = 64,
	HOTKEY_DISPLAY = true,
	
	-- Эффекты
	ENABLE_VISUAL_EFFECTS = true,
	PARTICLE_QUALITY = "Medium", -- Low, Medium, High
}
```

## 📋 Настройки категорий

Можете изменить цвета и иконки категорий в секции `CATEGORY_CONFIG`:

```lua
Movement = {
	color = Color3.fromRGB(52, 199, 89), -- зеленый
	icon = "🏃",
	description = "Способности передвижения",
},
```

## 🧪 Примеры способностей

### Мгновенное исцеление:
```lua
{
	id = "instant_heal",
	name = "❤️ Мгновенное исцеление",
	description = "Восстанавливает 100 HP мгновенно",
	category = "Utility",
	baseDuration = 0, -- мгновенный эффект
	cooldown = 60,
	price = 75,
	effects = {
		{
			type = "Add",
			value = 100,
			target = "Health"
		}
	},
	icon = "❤️",
	isStackable = false,
}
```

### Временный щит:
```lua
{
	id = "temp_shield",
	name = "🛡️ Временный щит",
	description = "Дает 200 щита на 30 секунд",
	category = "Shield",
	baseDuration = 30,
	cooldown = 90,
	price = 150,
	effects = {
		{
			type = "Add",
			value = 200,
			target = "Shield"
		}
	},
	icon = "🛡️",
	isStackable = true, -- можно накладывать
}
```

### Боевая ярость:
```lua
{
	id = "battle_rage",
	name = "😡 Боевая ярость",
	description = "Удваивает урон и скорость на 15 секунд",
	category = "Combat",
	baseDuration = 15,
	cooldown = 45,
	price = 200,
	effects = {
		{
			type = "Multiply",
			value = 2.0,
			target = "Damage"
		},
		{
			type = "Multiply",
			value = 1.3,
			target = "WalkSpeed"
		}
	},
	icon = "😡",
	isStackable = false,
}
```

## ✅ После добавления способности

1. **Сохраните файл** - система автоматически загрузит новые способности
2. **Проверьте консоль** - должно появиться сообщение о загрузке способностей
3. **Откройте магазин** - новая способность должна появиться в соответствующей категории
4. **Протестируйте** - купите и активируйте способность

## 🚀 Расширенные возможности

### Добавление новых типов эффектов:
Если нужны новые типы эффектов, отредактируйте `src/shared/Types.luau`:

```lua
export type EffectTarget = "WalkSpeed" | "JumpHeight" | "Shield" | "Health" | "Damage" | "YourNewTarget"
```

### Добавление новых категорий:
Добавьте в `CATEGORY_CONFIG` и в `Types.luau`:

```lua
export type AbilityCategory = "Movement" | "Shield" | "Combat" | "Utility" | "YourNewCategory"
```

## 💡 Советы по балансу

- **Цена**: Обычно от 50 до 200 монет для базовых способностей
- **Кулдаун**: 30-60 секунд для большинства способностей
- **Длительность**: 10-20 секунд для временных эффектов
- **Особые способности**: В 2-3 раза дороже и мощнее обычных

## 🔍 Отладка

Если способность не работает:

1. Проверьте консоль на ошибки
2. Убедитесь, что ID уникален
3. Проверьте правильность типов эффектов
4. Убедитесь, что файл сохранен

---

**Система готова к расширению!** Просто добавляйте новые способности в конфигурационные файлы, и они автоматически появятся в игре.
