# БЭКАП КЛЮЧЕВЫХ НАСТРОЕК - FINAL_SHOP_v1.0

## Для быстрого восстановления критических параметров

### ShopComponent.luau - Ключевые значения:
```lua
-- Строка 99:
local currentY = 40 -- Поднятый заголовок СПОСОБНОСТИ

-- Строки 107-117: Заголовок СПОСОБНОСТИ
Size = UDim2.new(1, -24, 0, 45),
TextSize = 32,
Text = "СПОСОБНОСТИ",

-- Строки 230-231: Позиция баланса  
Position = UDim2.new(1, -200, 0, 14),

-- Строки 245-248: Рамка баланса
Color = ShopConfig.design.colors.accent.primary,
Thickness = 2,
Transparency = 0,
```

### ProductCard.luau - Что УБРАНО:
```lua
-- УБРАН весь блок CategoryIcon (строки ~152-176)
-- УБРАН UIGradient из кнопки покупки  
-- УБРАН ButtonShadow из кнопки покупки

-- ИСПРАВЛЕНА позиция ProductInfo:
Position = UDim2.new(0, ShopConfig.design.spacing.padding.large, 0, ShopConfig.design.spacing.gaps.medium),
```

### ShopData.luau - Названия БЕЗ эмодзи:
```lua
name = "Ускорение",        -- БЕЗ ⚡
name = "Щит",              -- БЕЗ 🛡  
name = "Супер прыжок",     -- БЕЗ 🚀
```

### ShopConfig.luau - Категория БЕЗ значка:
```lua
{
    id = "ability",
    name = "СПОСОБНОСТИ",     -- БЕЗ ⚡
    color = Color3.fromRGB(56, 189, 248),
    priority = 1,
}
-- УБРАНО: icon = "⚡",
```

### WalletComponent.luau - Синяя рамка:
```lua
UIStroke = {
    Color = ShopConfig.design.colors.accent.primary, -- Синий
    Thickness = 2,
    Transparency = 0,
}
```

---
## БЫСТРАЯ ПРОВЕРКА ВЕРСИИ:

1. currentY = 40? ✅
2. Баланс на -200? ✅  
3. Заголовок 32px? ✅
4. Кнопки без теней? ✅
5. Карточки без значков? ✅

**Если все ✅ - версия корректная!**
