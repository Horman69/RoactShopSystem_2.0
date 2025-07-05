# SHOP FILTERING FIX - ИСПРАВЛЕНИЕ ФИЛЬТРАЦИИ МАГАЗИНА

## Проблема
Купленные способности продолжали отображаться в магазине после покупки, что позволяло игрокам покупать одну и ту же способность многократно.

## Причина
В методе `ShopService:getAvailableProducts()` функция `_checkProductRequirements()` всегда возвращала `true`, не проверяя, владеет ли игрок уже купленной способностью.

При этом в методе `canPlayerBuyProduct()` такая проверка была реализована правильно:
```lua
if product.category == "ability" and product.abilityId then
    if self.abilityService:isAbilityOwned(player, product.abilityId) then
        return false -- Игрок уже владеет этой способностью
    end
end
```

## Решение
Исправление включало две части:

### 1. Серверная логика фильтрации
Добавил проверку владения способностями в метод `_checkProductRequirements()`:

**ДО:**
```lua
function ShopService:_checkProductRequirements(player: Player, product: Product): boolean
	-- Если нет требований, товар доступен всем
	if not product.requirements then
		return true
	end
	
	-- TODO: Реализовать проверку требований (уровень, другие товары и т.д.)
	-- Пока что возвращаем true для всех товаров
	return true
end
```

**ПОСЛЕ:**
```lua
function ShopService:_checkProductRequirements(player: Player, product: Product): boolean
	-- Проверяем, является ли товар способностью и владеет ли игрок уже ею
	if product.category == "ability" and product.abilityId then
		if self.abilityService:isAbilityOwned(player, product.abilityId) then
			return false -- Игрок уже владеет этой способностью - не показываем в магазине
		end
	end
	
	-- Если нет требований, товар доступен всем
	if not product.requirements then
		return true
	end
	
	-- TODO: Реализовать проверку требований (уровень, другие товары и т.д.)
	-- Пока что возвращаем true для всех товаров
	return true
end
```

### 2. Клиентская синхронизация UI
Добавил автоматическое обновление списка товаров в `ShopComponent` после покупки:

**Изменения в ShopComponent.luau:**
- Добавлен метод `updateProducts()` для обновления списка товаров
- Добавлен метод `didUpdate()` для реакции на изменение пропсов
- Список товаров теперь обновляется при изменении `updateTrigger`

**Изменения в AppController.luau:**
- Добавлен `shopUpdateTrigger` в состояние
- Триггер обновляется после каждой успешной покупки способности
- Триггер передается в `ShopComponent` как проп

## Результат
Теперь купленные способности автоматически исчезают из списка товаров магазина, предотвращая повторные покупки и улучшая пользовательский опыт.

## Тестирование
Создан тестовый скрипт `TestShopFiltering.client.luau` для проверки корректности работы фильтрации.

## Файлы изменены
- `src/services/ShopService.luau` - исправлена серверная логика фильтрации
- `src/App/ShopComponent.luau` - добавлено автоматическое обновление списка товаров
- `src/App/AppController.luau` - добавлен триггер обновления магазина
- `src/client/TestShopFiltering.client.luau` - улучшен тест (можно удалить после проверки)

## Итоговый результат
Теперь система работает полностью корректно:
1. **Серверная фильтрация** - купленные способности не возвращаются в `getAvailableProducts()`
2. **Клиентская синхронизация** - UI магазина автоматически обновляется после покупки
3. **Предотвращение дублирования** - невозможно купить одну способность дважды
4. **Визуальная обратная связь** - купленные товары мгновенно исчезают из магазина
