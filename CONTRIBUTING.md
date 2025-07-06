# Руководство по вкладу в RoactShopSystem

Спасибо за интерес к улучшению проекта! 🎉

## 🚀 Быстрый старт для разработчиков

### Настройка окружения

1. **Форкните репозиторий** на GitHub
2. **Клонируйте ваш форк:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/RoactShopSystem.git
   cd RoactShopSystem
   ```
3. **Установите зависимости:**
   ```bash
   wally install
   ```
4. **Создайте ветку для вашей фичи:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

### Запуск в режиме разработки

```bash
# Запуск Rojo с горячей перезагрузкой
rojo serve --watch

# В другом терминале можно запустить тесты (когда они будут)
# luau-test src/
```

## 📋 Стандарты кода

### Обязательные требования

- ✅ **`--!strict`** в начале каждого файла
- ✅ **Типизация** всех функций и переменных
- ✅ **Комментарии на русском языке**
- ✅ **Следование принципам SOLID**

### Пример хорошего кода

```lua
--!strict
-- src/services/ExampleService.luau
-- Пример правильно оформленного сервиса

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))

-- Типы для этого модуля
type ExampleData = {
    id: number,
    name: string,
    isActive: boolean,
}

type ExampleServiceInterface = {
    processData: (self: ExampleServiceInterface, data: ExampleData) -> boolean,
    validateInput: (self: ExampleServiceInterface, input: any) -> boolean,
}

local ExampleService = {} :: ExampleServiceInterface
ExampleService.__index = ExampleService

-- Создание нового экземпляра сервиса
function ExampleService.new(): ExampleServiceInterface
    local self = setmetatable({}, ExampleService)
    return self
end

-- Обработка данных с валидацией
function ExampleService:processData(data: ExampleData): boolean
    -- Валидация входных данных
    if not self:validateInput(data) then
        warn("ExampleService: Некорректные данные переданы в processData")
        return false
    end
    
    -- Основная логика
    print("ExampleService: Обрабатываем данные для", data.name)
    return true
end

-- Валидация входных данных
function ExampleService:validateInput(input: any): boolean
    return type(input) == "table" and 
           type(input.id) == "number" and
           type(input.name) == "string"
end

return ExampleService
```

### Структура коммитов

Используйте [Conventional Commits](https://www.conventionalcommits.org/ru/v1.0.0/):

```bash
# Примеры хороших коммитов:
git commit -m "feat: добавить систему достижений"
git commit -m "fix: исправить ошибку загрузки товаров"
git commit -m "docs: обновить README с новыми примерами"
git commit -m "refactor: улучшить архитектуру CurrencyService"
git commit -m "test: добавить тесты для ShopService"
```

## 🐛 Сообщение об ошибках

### Перед созданием Issue проверьте:

1. **Поиск** - возможно, ошибка уже была сообщена
2. **Воспроизведение** - убедитесь, что ошибка повторяется
3. **Версии** - укажите версии Rojo, Wally, Roblox Studio

### Шаблон для Bug Report

```markdown
## 🐛 Описание ошибки
Краткое описание того, что происходит не так.

## 🔄 Шаги для воспроизведения
1. Откройте...
2. Нажмите на...
3. Произойдёт ошибка...

## ✅ Ожидаемое поведение
Что должно было произойти.

## 📱 Окружение
- Rojo версия: 
- Wally версия:
- Roblox Studio версия:
- ОС: Windows/macOS/Linux

## 📋 Дополнительная информация
Логи, скриншоты, любая полезная информация.
```

## 💡 Предложение улучшений

### Шаблон для Feature Request

```markdown
## 🚀 Описание фичи
Что вы хотите добавить в проект?

## 🎯 Мотивация
Зачем это нужно? Какую проблему это решает?

## 📝 Подробное описание
Как это должно работать?

## 🎨 Возможная реализация
Есть ли идеи о том, как это можно реализовать?
```

## 🔄 Процесс Pull Request

### Перед отправкой PR:

1. **Тестирование** - убедитесь, что код работает в Roblox Studio
2. **Линтинг** - проверьте код на соответствие стандартам
3. **Документация** - обновите README если нужно
4. **Коммиты** - убедитесь в чистоте истории коммитов

### Шаблон описания PR:

```markdown
## 📋 Что изменено
- Добавлено X
- Исправлено Y  
- Улучшено Z

## 🎯 Тип изменений
- [ ] Bug fix (исправление ошибки)
- [ ] New feature (новая функция)
- [ ] Breaking change (ломающее изменение)
- [ ] Documentation update (обновление документации)

## ✅ Чеклист
- [ ] Код соответствует стандартам проекта
- [ ] Добавлены типы для новых функций
- [ ] Обновлена документация при необходимости
- [ ] Тестировано в Roblox Studio
```

## 🏗️ Архитектурные решения

### При добавлении новых модулей:

1. **Сервисы** - в `src/services/` для бизнес-логики
2. **Компоненты** - в `src/App/` для UI
3. **Типы** - в `src/shared/Types.luau`
4. **Утилиты** - в `src/shared/` для общих функций

### Принципы проектирования:

- **Single Responsibility** - один модуль = одна ответственность
- **Dependency Injection** - используйте параметры вместо прямых импортов
- **Interface Segregation** - маленькие, специфичные интерфейсы
- **Don't Repeat Yourself** - выносите общую логику в утилиты

## 🎨 UI/UX Гайдлайны

### Цветовая схема:
```lua
local THEME = {
    -- Основные цвета
    BACKGROUND_DARK = Color3.fromRGB(40, 44, 52),
    SURFACE = Color3.fromRGB(50, 55, 65),
    
    -- Акцентные цвета
    PRIMARY_BLUE = Color3.fromRGB(0, 170, 255),
    SUCCESS_GREEN = Color3.fromRGB(0, 200, 120),
    WARNING_ORANGE = Color3.fromRGB(255, 165, 0),
    ERROR_RED = Color3.fromRGB(255, 69, 58),
    
    -- Текст
    TEXT_PRIMARY = Color3.fromRGB(255, 255, 255),
    TEXT_SECONDARY = Color3.fromRGB(180, 180, 180),
    TEXT_GOLD = Color3.fromRGB(255, 215, 0),
}
```

### Размеры и отступы:
```lua
local LAYOUT = {
    PADDING_SMALL = 8,
    PADDING_MEDIUM = 16,
    PADDING_LARGE = 24,
    
    BORDER_RADIUS = 12,
    BORDER_RADIUS_SMALL = 8,
    
    BUTTON_HEIGHT = 44,
    INPUT_HEIGHT = 36,
}
```

## 🤝 Сообщество

### Где получить помощь:

- 💬 [GitHub Discussions](https://github.com/YOUR_USERNAME/RoactShopSystem/discussions) - общие вопросы
- 🐛 [GitHub Issues](https://github.com/YOUR_USERNAME/RoactShopSystem/issues) - баги и фичи
- 📖 [Wiki](https://github.com/YOUR_USERNAME/RoactShopSystem/wiki) - документация

### Кодекс поведения:

- 🤝 Будьте уважительны к другим участникам
- 💡 Конструктивная критика приветствуется
- 🚫 Никакого спама, троллинга или оскорблений
- 📚 Помогайте новичкам освоиться в проекте

---

## 🎉 Спасибо за вклад!

Каждая строчка кода, каждый баг-репорт и каждое предложение делают проект лучше для всего сообщества Roblox разработчиков!

**Вместе мы создаём лучшие инструменты для разработки игр! 🚀**
