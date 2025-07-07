# ИСПРАВЛЕНИЕ ОШИБКИ NIL INDEX v2.1.2
**Дата:** 07.07.2025  
**Статус:** КРИТИЧЕСКАЯ ОШИБКА ИСПРАВЛЕНА

## 🔧 ПРОБЛЕМА
```
attempt to index nil with 'movement'
ShopConfig.design.colors.abilities.movement.primary
```

## 🕵️ ПРИЧИНА
- Раздел `abilities` не был правильно добавлен в структуру `ShopConfig.design.colors`
- Были дублирующие определения цветовых схем
- Структура конфигурации была нарушена

## ✅ ИСПРАВЛЕНИЕ

### 1. Добавили `abilities` в правильное место
```lua
ShopConfig.design = {
    colors = {
        -- ...existing colors...
        status = {
            success = Color3.fromRGB(34, 197, 94),
            error = Color3.fromRGB(248, 113, 113),
            warning = Color3.fromRGB(245, 158, 11),
        },
        
        -- 🎨 Цветовые схемы для типов способностей
        abilities = {
            movement = {
                primary = Color3.fromRGB(59, 130, 246),
                active = Color3.fromRGB(79, 150, 255),
                icon = "⚡"
            },
            defense = {
                primary = Color3.fromRGB(34, 197, 94),
                active = Color3.fromRGB(54, 217, 114),
                icon = "🛡️"
            },
            // ... остальные типы
        },
    }
}
```

### 2. Удалили дублирующий раздел
- Удалили отдельное определение `ShopConfig.abilityColors`
- Оставили только один источник истины в `ShopConfig.design.colors.abilities`

## 🎯 РЕЗУЛЬТАТ

Теперь код `ShopConfig.design.colors.abilities.movement.primary` должен работать корректно:
- ✅ `ShopConfig.design.colors.abilities` существует
- ✅ `movement`, `defense`, `attack`, `utility`, `elemental` доступны
- ✅ У каждого типа есть `primary` и `active` цвета
- ✅ Нет дублирующих определений

## 🧪 ТЕСТИРОВАНИЕ

После исправления:
1. Панель способностей должна открываться без ошибок
2. Кнопки должны иметь правильные цвета:
   - **Скорость/Прыжок**: Синий (movement)
   - **Щит**: Зеленый (defense)
3. Прогресс-бары должны отображаться под кнопками

**Ошибка исправлена!** 🚀
