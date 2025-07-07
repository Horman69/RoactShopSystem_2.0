# 🛒 RoactShopSystem 2.0

**Профессиональная система магазина для Roblox с использованием Roact, продвинутой звуковой системой v2.1 и строгой типизацией**

![Roblox](https://img.shields.io/badge/Platform-Roblox-00A2FF?style=for-the-badge&logo=roblox)
![Luau](https://img.shields.io/badge/Language-Luau-0066CC?style=for-the-badge)
![Roact](https://img.shields.io/badge/UI-Roact-61DAFB?style=for-the-badge)
![TypeScript](https://img.shields.io/badge/Types-Strict-3178C6?style=for-the-badge)
![Sounds](https://img.shields.io/badge/Sounds-v2.1-FF6B6B?style=for-the-badge)

---

## 🔊 Новинка: Звуковая система v2.1

- **⚡ Максимальная производительность**: <1мс задержка благодаря ContentProvider предзагрузке
- **🎵 6 уникальных звуков**: для всех событий магазина и способностей  
- **🛠️ Команды отладки**: `/testsounds`, `/soundstats`, `/sounddebug`
- **✨ Новый звук**: "способность снова активна" через 30 секунд (`107261392908541`)
- **🏊 Пул объектов Sound**: 3 копии критических звуков для устранения задержек

## ✨ Особенности

- 🎯 **Строгая типизация** с `--!strict` во всех файлах
- 🏛️ **SOLID принципы** и чистая архитектура
- 🔄 **Сервисная архитектура** для легкого тестирования и расширения
- 💰 **Продвинутая система валюты** с кулдаунами и валидацией
- 🛒 **Умный магазин** с проверкой требований и инвентарём
- 📱 **Современный UI** на Roact с красивым дизайном
- 🚀 **ModuleLoader** для быстрой загрузки без WaitForChild проблем
- 📊 **Готов к DataStore** для сохранения прогресса игроков

---

## 🚀 Быстрый старт

### Требования
- [Rojo](https://github.com/rojo-rbx/rojo) 7.0+
- [Wally](https://github.com/UpliftGames/wally) 0.3+
- Roblox Studio

### Установка

1. **Клонируйте репозиторий:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/RoactShopSystem.git
   cd RoactShopSystem
   ```

2. **Установите зависимости:**
   ```bash
   wally install
   ```

3. **Запустите Rojo сервер:**
   ```bash
   rojo serve
   ```

4. **В Roblox Studio:**
   - Подключитесь к серверу Rojo (`localhost:34872`)
   - Запустите игру и наслаждайтесь магазином!

---

## 🏗️ Архитектура

### Структура проекта
```
src/
├── App/                    # UI компоненты Roact
│   ├── AppController.luau  # Главный контроллер приложения
│   ├── ShopComponent.luau  # Компонент магазина
│   └── WalletComponent.luau # Компонент кошелька
├── services/               # Бизнес-логика
│   ├── CurrencyService.luau # Управление валютой
│   └── ShopService.luau    # Логика магазина
├── shared/                 # Общие модули
│   ├── Types.luau          # Система типов
│   └── ModuleLoader.luau   # Безопасная загрузка модулей
├── Shop/                   # Данные магазина
│   ├── ShopData.luau       # Товары магазина
│   └── Wallet.luau         # Модель кошелька (legacy)
└── client/                 # Клиентские скрипты
    └── ShopApp.client.luau # Запуск приложения
```

### Принципы архитектуры

#### 🎯 **Single Responsibility Principle**
- `CurrencyService` - только валюта
- `ShopService` - только логика магазина  
- UI компоненты - только отображение

#### 🔒 **Interface Segregation**
- Строгие типы для всех интерфейсов
- Минимальные зависимости между модулями

#### 🔄 **Dependency Inversion**
- Сервисы не зависят от UI
- ModuleLoader изолирует импорты

---

## 🛠️ Использование

### Добавление нового товара

1. **Откройте `src/Shop/ShopData.luau`:**
```lua
{
    id = 4,
    name = "Волшебный посох",
    price = 300,
    description = "Мощный посох для магов",
    category = "magic",
    maxQuantity = 1,
}
```

2. **Товар автоматически появится в магазине!**

### Кастомизация валюты

```lua
-- В CurrencyService.luau
local CONFIG = {
    DEFAULT_COINS = 100,        -- Стартовые монеты
    MAX_COINS = 999999,         -- Максимум монет
    AUTO_SAVE_INTERVAL = 30,    -- Автосохранение
    COIN_GAIN_COOLDOWN = 1,     -- Кулдаун получения
}
```

### Подписка на события

```lua
-- Слушаем изменения валюты
currencyService:onCurrencyChanged(function(player, newState)
    print(player.Name, "теперь имеет", newState.coins, "монет")
end)
```

---

## 🎨 Кастомизация UI

### Цвета темы
```lua
-- В компонентах можно легко изменить цвета:
local THEME = {
    DARK_BACKGROUND = Color3.fromRGB(40, 44, 52),
    ACCENT_BLUE = Color3.fromRGB(0, 170, 255),
    GOLD_TEXT = Color3.fromRGB(255, 215, 0),
    SUCCESS_GREEN = Color3.fromRGB(0, 200, 120),
}
```

### Добавление новых компонентов
```lua
-- Создайте новый файл в src/App/
local MyComponent = Roact.Component:extend("MyComponent")

function MyComponent:render()
    -- Ваш UI код
end

return MyComponent
```

---

## 🔧 Продвинутые возможности

### Требования для товаров
```lua
{
    id = 5,
    name = "Легендарный меч",
    price = 1000,
    requirements = {
        level = 10,
        hasItem = {2, 3}, -- Нужны щит и лук
    }
}
```

### Система достижений (готова к расширению)
```lua
-- В ShopService можно добавить:
function ShopService:onPurchaseComplete(player, product)
    AchievementService:checkPurchaseAchievements(player, product)
end
```

---

## 📈 Производительность

- ⚡ **Кэширование модулей** - быстрая повторная загрузка
- 🎯 **Ленивая загрузка** - модули загружаются по требованию  
- 📊 **Оптимизированный UI** - ScrollingFrame для больших списков
- 🔒 **Валидация данных** - предотвращение ошибок

---

## 🧪 Тестирование

### Запуск в режиме разработки
```bash
# Запуск с горячей перезагрузкой
rojo serve --watch
```

### Отладка
```lua
-- Включите логирование в ModuleLoader:
ModuleLoader._DEBUG = true
```

---

## 🚀 Планы развития

- [ ] 💾 **DataStore интеграция** для сохранения прогресса
- [ ] 🎁 **Система промокодов** и скидок
- [ ] 🏆 **Достижения** и награды
- [ ] 📊 **Аналитика** покупок и поведения игроков
- [ ] 🎨 **Темы оформления** и кастомизация
- [ ] 🌐 **Мультиязычность** интерфейса
- [ ] 🔔 **Push-уведомления** о новых товарах
- [ ] 📱 **Мобильная оптимизация** UI

---

## 🤝 Вклад в проект

Мы приветствуем любые улучшения! 

1. Форкните репозиторий
2. Создайте ветку для фичи (`git checkout -b feature/amazing-feature`)
3. Зафиксируйте изменения (`git commit -m 'Add amazing feature'`)
4. Отправьте в ветку (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

### Стиль кода
- ✅ Используйте `--!strict` во всех файлах
- ✅ Комментарии на русском языке
- ✅ Следуйте принципам SOLID
- ✅ Добавляйте типы для всех функций

---

## 📄 Лицензия

Распространяется под лицензией MIT. См. файл `LICENSE` для подробностей.

---

## 🙏 Благодарности

- **Roblox Team** за Luau и отличную платформу
- **Rojo Team** за превосходный инструмент синхронизации
- **Roact Community** за мощную UI библиотеку
- **Wally Team** за удобный пакетный менеджер

---

## 📞 Поддержка

Есть вопросы или нужна помощь?

- 🐛 [Сообщить об ошибке](https://github.com/YOUR_USERNAME/RoactShopSystem/issues)
- 💡 [Предложить улучшение](https://github.com/YOUR_USERNAME/RoactShopSystem/discussions)
- 📖 [Документация](https://github.com/YOUR_USERNAME/RoactShopSystem/wiki)

---

<div align="center">

**Сделано с ❤️ для сообщества Roblox разработчиков**

⭐ **Поставьте звезду, если проект помог вам!** ⭐

</div>
