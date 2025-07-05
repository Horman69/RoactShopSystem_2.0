# ГЛОБАЛЬНАЯ СИСТЕМА АНИМАЦИЙ - ПОЛНОЕ РУКОВОДСТВО

## 🎬 ОБЗОР СИСТЕМЫ

Мы создали профессиональную, модульную систему анимаций для Roact, которая обеспечивает:

- **Единообразные анимации** по всему приложению
- **Простое добавление новых анимаций** через пресеты
- **HOC (Higher-Order Components)** для легкой интеграции
- **Специализированные анимации** для разных типов элементов
- **Производительность** через TweenService Roblox

## 🏗️ АРХИТЕКТУРА

### 1. AnimationService (`src/services/AnimationService.luau`)

**Центральный сервис управления анимациями:**

```lua
-- Базовые методы
animationService:tweenElement(element, "SHOP_OPEN", callback)
animationService:tweenCustom(element, {Size = UDim2.new(1.2, 0, 1.2, 0)}, "BOUNCY")

-- Специализированные методы
animationService:animateButtonHover(button)
animationService:animateAbilitySuccess(abilityButton)
animationService:animateShopOpen(shopFrame)
```

**Пресеты анимаций:**
- `QUICK` (0.15s) - быстрый отклик UI
- `STANDARD` (0.3s) - основные переходы  
- `SMOOTH` (0.4s) - плавные входы/выходы
- `BOUNCY` (0.5s) - упругие интерактивные элементы
- `ELASTIC` (0.8s) - эффектные появления

### 2. AnimatedComponents (`src/App/AnimatedComponents.luau`)

**HOC компоненты для Roact:**

#### AnimatedButton
```lua
Roact.createElement(AnimatedComponents.Button, {
    Text = "Кнопка",
    BackgroundColor3 = Color3.fromRGB(70, 120, 200),
    clickColor = Color3.fromRGB(100, 150, 255),
    animateOnMount = true,
    onClick = function() end,
})
```

**Автоматические анимации:**
- Hover эффект при наведении
- Press/Release при клике
- Цветовая вспышка при активации
- Появление при монтировании

#### AnimatedPanel
```lua
Roact.createElement(AnimatedComponents.Panel, {
    Size = UDim2.new(0, 400, 0, 300),
    visible = showPanel,
    enterAnimation = "SHOP_OPEN",
    exitAnimation = "SHOP_CLOSE",
    onEnterComplete = function() print("Открыто!") end,
})
```

**Особенности:**
- Управление видимостью через `visible` проп
- Настраиваемые анимации входа/выхода
- Колбэки завершения анимаций

#### AnimatedList
```lua
Roact.createElement(AnimatedComponents.List, {
    items = listData,
    itemAnimation = "SLIDE_IN_LEFT", 
    staggerDelay = 0.1,
    renderItem = function(item, index) 
        return Roact.createElement("TextLabel", {Text = item.text})
    end,
})
```

**Stagger эффекты:**
- Последовательная анимация элементов списка
- Настраиваемая задержка между элементами
- Кастомные анимации для каждого элемента

## 🎯 СПЕЦИАЛИЗИРОВАННЫЕ АНИМАЦИИ

### Кнопки
- `BUTTON_HOVER` - масштабирование при наведении
- `BUTTON_PRESS` - сжатие при нажатии  
- `BUTTON_RELEASE` - упругое возвращение

### Магазин
- `SHOP_OPEN` - появление с масштабированием + сдвиг
- `SHOP_CLOSE` - исчезновение с сжатием

### Способности  
- `ABILITY_ACTIVATE` - эластичная пульсация
- `animateAbilitySuccess()` - зеленое свечение
- `animateAbilityCooldown()` - красное мигание
- `animateAbilityPulse()` - постоянная пульсация

### Панели
- `SLIDE_IN_BOTTOM` - появление снизу с масштабированием
- `SLIDE_IN_LEFT` - появление слева
- `FADE_IN` - плавное появление с сдвигом

## 🔧 ИНТЕГРАЦИЯ В КОМПОНЕНТЫ

### В AbilityPanel

```lua
-- 1. Импорт
local AnimatedComponents = ModuleLoader.require("App/AnimatedComponents")
local AnimationService = ModuleLoader.require("services/AnimationService")

-- 2. Инициализация
function AbilityPanel:init()
    self.animationService = AnimationService.new()
    self.buttonRefs = {} -- Рефы для анимации
end

-- 3. Использование
Button = Roact.createElement(AnimatedComponents.Button, {
    [Roact.Ref] = self.buttonRefs[ability.id],
    BackgroundColor3 = buttonColor,
    clickColor = Color3.fromRGB(255, 255, 255),
    onClick = function() self:onAbilityActivate(ability.id) end,
})

-- 4. Анимация при событиях
if result.success then
    self.animationService:animateAbilitySuccess(button)
else
    self.animationService:animateAbilityCooldown(button)
end
```

### В ShopComponent

```lua
-- Анимированная панель магазина
return Roact.createElement(AnimatedComponents.Panel, {
    visible = self.props.visible,
    enterAnimation = "SHOP_OPEN",
    exitAnimation = "SHOP_CLOSE", 
    onEnterComplete = function() print("Магазин открыт") end,
})

-- Анимированные кнопки покупки
BuyButton = Roact.createElement(AnimatedComponents.Button, {
    Text = "Купить",
    clickColor = Color3.fromRGB(0, 200, 255),
    onClick = function() self.props.onPurchase(product) end,
})
```

## 🎨 ДОБАВЛЕНИЕ НОВЫХ АНИМАЦИЙ

### 1. Создание пресета
```lua
-- В AnimationService.luau, ANIMATION_PRESETS
PULSE = {
    duration = 1.0,
    easing = Enum.EasingStyle.Sine,
    direction = Enum.EasingDirection.InOut,
},
```

### 2. Создание специальной анимации
```lua
-- В ELEMENT_ANIMATIONS
NOTIFICATION_POPUP = {
    duration = 0.6,
    easing = Enum.EasingStyle.Back,
    direction = Enum.EasingDirection.Out,
    scale = {from = Vector3.new(0.5, 0.5, 1), to = Vector3.new(1, 1, 1)},
    transparency = {from = 1, to = 0},
    position = {offset = UDim2.new(0, 0, 0, 30)},
},
```

### 3. Добавление метода
```lua
function AnimationService:animateNotificationPopup(notification: GuiObject): ()
    self:tweenElement(notification, "NOTIFICATION_POPUP")
end
```

## 🧩 HOC withAnimation

Для оборачивания существующих компонентов:

```lua
local AnimatedMyComponent = AnimatedComponents.withAnimation(MyComponent, {
    enterAnimation = "FADE_IN",
    exitAnimation = "FADE_OUT",
})

-- Использование
Roact.createElement(AnimatedMyComponent, {
    -- обычные пропсы компонента
    someProperty = "value",
    -- анимационные пропсы
    enterAnimation = "SHOP_OPEN",
})
```

## 🎯 ЛУЧШИЕ ПРАКТИКИ

### 1. Производительность
- Используйте рефы для прямого доступа к элементам
- Останавливайте старые твины перед новыми
- Группируйте анимации через `animateSequence()`

### 2. UX
- Быстрые анимации (0.1-0.2s) для кнопок
- Средние анимации (0.3-0.5s) для панелей
- Медленные анимации (0.5-1s) для эффектных появлений

### 3. Согласованность
- Используйте единые пресеты по всему приложению
- Группируйте похожие анимации (все кнопки, все панели)
- Тестируйте на разных устройствах

## 📊 ТЕСТИРОВАНИЕ

Созданы специальные тестовые файлы:

- `TestAnimations.client.luau` - общие тесты системы
- `TestAbilityAnimations.client.luau` - тесты способностей

Горячие клавиши:
- F1 - перезапуск общих тестов
- F2 - перезапуск тестов способностей
- Q/E/R/T - быстрое тестирование анимаций

## 🚀 РЕЗУЛЬТАТЫ

✅ **Полностью анимированная панель способностей** - кнопки, слоты, анимации успеха/ошибки
✅ **Анимированный магазин** - плавное появление/исчезновение, анимированные кнопки
✅ **Масштабируемая архитектура** - легко добавлять новые анимации и компоненты
✅ **Производительность** - использование TweenService, управление активными твинами
✅ **Профессиональный UX** - согласованные, плавные переходы

Система готова к дальнейшему расширению и может легко поддерживать новые типы анимаций для любых будущих UI элементов!
