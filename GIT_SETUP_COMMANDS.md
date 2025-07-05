# 🚀 КОМАНДЫ ДЛЯ НАСТРОЙКИ GITHUB РЕПОЗИТОРИЯ

## 📋 ПОШАГОВЫЕ ИНСТРУКЦИИ

### 1. Подготовка локального репозитория

```bash
# Проверяем текущее состояние
git status

# Добавляем все файлы
git add .

# Создаем основной коммит
git commit -m "feat: Initial release of RoactShopSystem v2.0

🎮 Complete modular architecture with service layer
🎨 Modern Roact UI components with professional animations  
🛒 Production-ready shop and ability management system
📚 Comprehensive documentation and architectural guides
🔧 Enterprise-level codebase with strict Luau typing
✨ Professional animations and sound effects
🏗️ SOLID principles and clean architecture
📊 Full performance audit and optimization

This release represents a complete rewrite of the shop system
with modern practices, scalable architecture, and production
readiness for commercial Roblox games."

# Создаем основную ветку (если нужно)
git branch -M main
```

### 2. Подключение к GitHub репозиторию

```bash
# Добавляем удаленный репозиторий
git remote add origin https://github.com/Horman69/RoactShopSystem_2.0.git

# Проверяем подключение
git remote -v

# Первый пуш с установкой upstream
git push -u origin main
```

### 3. Создание ветки разработки

```bash
# Создаем и переключаемся на ветку разработки
git checkout -b development

# Пушим ветку разработки
git push -u origin development

# Возвращаемся на main
git checkout main
```

### 4. Создание тегов для релиза

```bash
# Создаем тег для первого релиза
git tag -a v2.0.0 -m "RoactShopSystem v2.0.0 - Initial Release

🎯 Features:
- Complete modular shop system
- Professional UI animations  
- Ability management with cooldowns
- Sound effects system
- Modern Roact architecture
- Comprehensive documentation

🏗️ Architecture:
- Service-oriented design
- SOLID principles
- Strict Luau typing
- Clean separation of concerns

📊 Quality:
- Production-ready codebase
- Full documentation coverage
- Performance optimized
- Enterprise standards"

# Пушим теги
git push origin --tags
```

## 🔧 КОМАНДЫ ДЛЯ БУДУЩИХ ОБНОВЛЕНИЙ

### Рабочий процесс для новых функций:

```bash
# 1. Создание feature ветки
git checkout development
git pull origin development
git checkout -b feature/new-feature-name

# 2. Работа над функцией
# ... делаем изменения ...
git add .
git commit -m "feat: add new feature description"

# 3. Пуш feature ветки
git push -u origin feature/new-feature-name

# 4. Создание Pull Request через GitHub UI
# ... создаем PR из feature/new-feature-name в development ...

# 5. После merge - очистка
git checkout development
git pull origin development
git branch -d feature/new-feature-name
git push origin --delete feature/new-feature-name
```

### Релиз процесс:

```bash
# 1. Подготовка релиза
git checkout development
git pull origin development
git checkout -b release/v2.1.0

# 2. Финальные изменения (version bump, CHANGELOG)
# ... обновляем версии и документацию ...
git add .
git commit -m "chore: prepare release v2.1.0"

# 3. Merge в main
git checkout main
git pull origin main
git merge release/v2.1.0

# 4. Создание тега
git tag -a v2.1.0 -m "Release v2.1.0 - Description"

# 5. Пуш всего
git push origin main
git push origin --tags

# 6. Merge обратно в development
git checkout development
git merge main
git push origin development

# 7. Очистка
git branch -d release/v2.1.0
```

### Hotfix процесс:

```bash
# 1. Создание hotfix от main
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix

# 2. Исправление
# ... делаем критичные изменения ...
git add .
git commit -m "fix: critical issue description"

# 3. Merge в main
git checkout main
git merge hotfix/critical-fix

# 4. Тег для patch версии
git tag -a v2.0.1 -m "Hotfix v2.0.1 - Critical bug fix"

# 5. Пуш
git push origin main
git push origin --tags

# 6. Merge в development
git checkout development
git merge main
git push origin development

# 7. Очистка
git branch -d hotfix/critical-fix
```

## 🏷️ СОГЛАШЕНИЯ О КОММИТАХ

### Формат:
```
<type>(<scope>): <description>

<body>

<footer>
```

### Типы коммитов:
- `feat`: новая функциональность
- `fix`: исправление бага
- `docs`: изменения в документации
- `style`: форматирование кода
- `refactor`: рефакторинг без изменения функциональности
- `perf`: улучшение производительности
- `test`: добавление или изменение тестов
- `chore`: изменения в build процессе или вспомогательных инструментах

### Примеры:
```bash
git commit -m "feat(shop): add currency validation system"
git commit -m "fix(abilities): resolve cooldown timer bug"
git commit -m "docs(api): update service interface documentation"
git commit -m "perf(ui): optimize animation rendering"
```

## 📊 ПОЛЕЗНЫЕ КОМАНДЫ

### Проверка состояния:
```bash
# Статус репозитория
git status

# История коммитов
git log --oneline -10

# Различия
git diff

# Ветки
git branch -a

# Удаленные репозитории
git remote -v
```

### Синхронизация:
```bash
# Получить изменения без merge
git fetch origin

# Получить и применить изменения
git pull origin main

# Синхронизация всех веток
git fetch --all
```

### Откат изменений:
```bash
# Отменить изменения в рабочей директории
git checkout -- <file>

# Отменить последний коммит (сохранить изменения)
git reset --soft HEAD~1

# Отменить последний коммит (удалить изменения)
git reset --hard HEAD~1
```

## 🎯 НАСТРОЙКА GITHUB РЕПОЗИТОРИЯ

### Настройки репозитория:
1. **General Settings**:
   - Description: "🛒 Production-ready Roblox shop system with Roact UI and modern architecture"
   - Website: ссылка на документацию
   - Topics: `roblox`, `roact`, `luau`, `shop-system`, `ui-components`

2. **Branch Protection**:
   - Protect `main` branch
   - Require PR reviews (1 approval)
   - Require status checks
   - Restrict pushes to main

3. **Pages Setup**:
   - Enable GitHub Pages
   - Source: Deploy from a branch
   - Branch: `main` / docs folder

4. **Issues & PR Templates**:
   - ✅ Уже созданы в `.github/`

### Начальные Issues для проекта:
```bash
# Создать через GitHub UI или gh CLI:
gh issue create --title "🚀 Setup CI/CD Pipeline" --body "Configure automated testing and deployment"
gh issue create --title "📊 Add DataStore Integration" --body "Implement persistent data storage"
gh issue create --title "🧪 Add Unit Tests" --body "Create comprehensive test suite"
gh issue create --title "📚 Setup GitHub Pages Documentation" --body "Deploy documentation site"
```

## ✅ CHECKLIST ПЕРЕД ПУБЛИКАЦИЕЙ

- [ ] Проверить, что все файлы добавлены в git
- [ ] Убедиться, что .gitignore настроен корректно  
- [ ] Проверить README.md на актуальность
- [ ] Убедиться, что нет конфиденциальной информации
- [ ] Проверить, что все ссылки в документации работают
- [ ] Протестировать код в чистом окружении
- [ ] Подготовить release notes
- [ ] Настроить branch protection rules
- [ ] Создать initial issues для roadmap

---
*Инструкции подготовлены для RoactShopSystem v2.0*
