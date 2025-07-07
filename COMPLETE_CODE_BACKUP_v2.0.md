# ПОЛНОЕ СОХРАНЕНИЕ КОДА СИСТЕМЫ v2.0
**Дата:** 07.07.2025
**Статус:** ФИНАЛЬНАЯ РАБОЧАЯ ВЕРСИЯ

## AppController.luau - ПОЛНЫЙ КОД
```lua
--!strict
-- src/App/AppController.luau
-- Главный контроллер приложения - правильная архитектура
-- Использует сервисы для бизнес-логики

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости через ModuleLoader
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))

-- Предзагружаем критически важные модули
ModuleLoader.preloadCriticalModules()

-- Загружаем модули
local Roact = ModuleLoader.require("Packages/roact")
local CurrencyService = ModuleLoader.require("services/CurrencyService")
local ShopService = ModuleLoader.require("services/ShopService")
local AbilityService = ModuleLoader.require("services/AbilityService")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")
local SimpleSoundService = ModuleLoader.require("services/SimpleSoundService")
local AbilityConfig = ModuleLoader.require("shared/AbilityConfig")
local WalletComponent = ModuleLoader.require("App/WalletComponent")
local ShopComponent = ModuleLoader.require("App/ShopComponent")
local AbilityPanel = ModuleLoader.require("App/AbilityPanel")

-- Импортируем ShopConfig для глобальных стилей
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))

-- Типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type CurrencyState = Types.CurrencyState
type Product = Types.Product
type Ability = Types.Ability

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Контроллер приложения
local AppController = Roact.Component:extend("AppController")

function AppController:init()
	print("🎮 AppController:init() начат!")
	
	-- Инициализируем сервисы
	self.currencyService = CurrencyService.new()
	self.shopService = ShopService.new()
	self.platformService = PlatformService.new()
	self.soundService = SimpleSoundService.new()
	
	-- Начальное состояние
	self:setState({
		isShopVisible = false,
		isAbilityPanelVisible = false,
		balance = 0,
		shopProducts = {},
		abilities = {},
		player = player,
		isControlsEnabled = true
	})
	
	-- Привязываем события
	self:bindEvents()
	
	-- Загружаем данные
	self:loadInitialData()
	
	print("✅ AppController:init() завершён!")
end

function AppController:bindEvents()
	-- Обновление баланса
	self.currencyService.onBalanceChanged:Connect(function(newBalance: number)
		print("💰 Баланс изменён:", newBalance)
		self:setState({
			balance = newBalance
		})
	end)
	
	-- Обновление товаров магазина  
	self.shopService.onProductsChanged:Connect(function(products: {Product})
		print("🛒 Товары магазина обновлены:", #products)
		self:setState({
			shopProducts = products
		})
	end)
end

function AppController:loadInitialData()
	-- Загружаем баланс
	local balance = self.currencyService:getBalance()
	print("💰 Начальный баланс:", balance)
	
	-- Загружаем товары
	local products = self.shopService:getProducts()
	print("🛒 Загружено товаров:", #products)
	
	-- Загружаем способности
	local abilities = AbilityConfig:getAbilities()
	print("⚡ Загружено способностей:", #abilities)
	
	-- Обновляем состояние
	self:setState({
		balance = balance,
		shopProducts = products,
		abilities = abilities
	})
end

-- Переключение видимости магазина
function AppController:toggleShop()
	local newVisibility = not self.state.isShopVisible
	print("🛒 Переключение магазина:", newVisibility)
	
	-- Закрываем панель способностей при открытии магазина
	if newVisibility then
		self:setState({
			isShopVisible = true,
			isAbilityPanelVisible = false
		})
	else
		self:setState({
			isShopVisible = false
		})
	end
end

-- Переключение панели способностей
function AppController:toggleAbilityPanel()
	local newVisibility = not self.state.isAbilityPanelVisible
	print("⚡ Переключение панели способностей:", newVisibility)
	
	-- Закрываем магазин при открытии панели способностей
	if newVisibility then
		self:setState({
			isAbilityPanelVisible = true,
			isShopVisible = false
		})
	else
		self:setState({
			isAbilityPanelVisible = false
		})
	end
end

-- Закрытие всех панелей
function AppController:closeAllPanels()
	print("❌ Закрытие всех панелей")
	self:setState({
		isShopVisible = false,
		isAbilityPanelVisible = false
	})
end

-- Покупка товара
function AppController:purchaseProduct(product: Product)
	print("🛍️ Попытка покупки:", product.name, "за", product.price)
	
	if self.currencyService:canAfford(product.price) then
		-- Списываем деньги
		if self.currencyService:spendCurrency(product.price) then
			print("✅ Покупка успешна!")
			self.soundService:playPurchaseSound()
			
			-- Добавляем товар в инвентарь (если нужно)
			if product.type == "ability" then
				-- Активируем способность через AbilityService
				AbilityService:activateAbility(product.abilityId, self.state.player)
			end
		else
			print("❌ Ошибка при списании средств")
			self.soundService:playErrorSound()
		end
	else
		print("💸 Недостаточно средств для покупки")
		self.soundService:playErrorSound()
	end
end

-- Активация способности
function AppController:activateAbility(ability: Ability)
	print("⚡ Активация способности:", ability.name)
	AbilityService:activateAbility(ability.id, self.state.player)
end

-- Обработка нажатий клавиш
function AppController:didMount()
	local UserInputService = game:GetService("UserInputService")
	
	-- Подключаем обработчик клавиш
	self.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self.state.isControlsEnabled then return end
		
		-- Обработка клавиш только когда контролы включены
		if input.KeyCode == Enum.KeyCode.E then
			print("🔑 Нажата клавиша E - переключение магазина")
			self:toggleShop()
		elseif input.KeyCode == Enum.KeyCode.Q then
			print("🔑 Нажата клавиша Q - переключение панели способностей")
			self:toggleAbilityPanel()
		elseif input.KeyCode == Enum.KeyCode.Escape then
			print("🔑 Нажата клавиша Escape - закрытие всех панелей")
			self:closeAllPanels()
		end
		
		-- Горячие клавиши для способностей (1-6)
		local hotkeys = {
			[Enum.KeyCode.One] = 1,
			[Enum.KeyCode.Two] = 2,
			[Enum.KeyCode.Three] = 3,
			[Enum.KeyCode.Four] = 4,
			[Enum.KeyCode.Five] = 5,
			[Enum.KeyCode.Six] = 6
		}
		
		local abilityIndex = hotkeys[input.KeyCode]
		if abilityIndex and self.state.abilities[abilityIndex] then
			print("🔥 Горячая клавиша", abilityIndex, "- активация способности")
			self:activateAbility(self.state.abilities[abilityIndex])
		end
	end)
end

function AppController:willUnmount()
	-- Отключаем обработчик при размонтировании
	if self.inputConnection then
		self.inputConnection:Disconnect()
	end
end

function AppController:render()
	local state = self.state
	
	return Roact.createElement("ScreenGui", {
		Name = "RoactShopSystem",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	}, {
		-- Кошелёк (всегда видимый)
		Wallet = Roact.createElement(WalletComponent, {
			balance = state.balance,
			visible = true
		}),
		
		-- Магазин
		Shop = state.isShopVisible and Roact.createElement(ShopComponent, {
			products = state.shopProducts,
			balance = state.balance,
			onPurchase = function(product)
				self:purchaseProduct(product)
			end,
			onClose = function()
				self:toggleShop()
			end
		}),
		
		-- Панель способностей
		AbilityPanel = state.isAbilityPanelVisible and Roact.createElement(AbilityPanel, {
			abilities = state.abilities,
			onActivateAbility = function(ability)
				self:activateAbility(ability)
			end,
			onClose = function()
				self:toggleAbilityPanel()
			end
		}),
		
		-- Подсказки управления (если ничего не открыто)
		ControlsHint = (not state.isShopVisible and not state.isAbilityPanelVisible) and Roact.createElement("Frame", {
			Size = UDim2.new(0, 400, 0, 100),
			Position = UDim2.new(0, 50, 1, -150),
			BackgroundTransparency = 1,
			ZIndex = 1
		}, {
			HintText = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "E - Магазин | Q - Способности | 1-6 - Быстрые способности",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.SourceSansBold,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left
			})
		})
	})
end

return AppController
````
## ShopComponent.luau - ПОЛНЫЙ КОД
```lua
--!strict
-- src/App/ShopComponent.luau
-- Компонент магазина в минималистичном стиле панели способностей

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local ShopService = ModuleLoader.require("services/ShopService")
local SimpleSoundService = ModuleLoader.require("services/SimpleSoundService")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")
local ProductCard = ModuleLoader.require("App/ProductCard")

-- Типы и конфигурация
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type Product = Types.Product

local ShopComponent = Roact.Component:extend("ShopComponent")

function ShopComponent:init()
	self.shopService = self.props.shopService or ShopService
	self.soundService = self.props.soundService or SimpleSoundService
	self.platformService = PlatformService
	
	self:setState({
		products = {}
	})
	
	self:updateProducts()
end

-- Обновляем список товаров
function ShopComponent:updateProducts()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	
	local availableProducts = self.shopService:getAvailableProducts(player)
	self:setState({
		products = availableProducts
	})
end

-- Обновляем товары при изменении пропсов
function ShopComponent:didUpdate(previousProps)
	if self.props.updateTrigger ~= previousProps.updateTrigger then
		self:updateProducts()
	end
end

-- Покупка товара
function ShopComponent:purchaseProduct(product: Product)
	print("🛍️ Покупка товара:", product.name)
	
	if self.props.onPurchase then
		self.props.onPurchase(product)
	end
	
	-- Обновляем список товаров после покупки
	self:updateProducts()
end

-- Рендер магазина
function ShopComponent:render()
	local props = self.props
	local state = self.state
	
	-- Проверяем мобильность
	local isMobile = self.platformService:isMobile()
	local isTablet = self.platformService:isTablet()
	
	-- Адаптивные размеры
	local panelWidth = isMobile and 0.9 or 0.7
	local panelHeight = isMobile and 0.85 or 0.8
	
	-- Разделяем товары по категориям
	local categorizedProducts = {}
	for _, product in ipairs(state.products or {}) do
		local category = product.category or "abilities"
		if not categorizedProducts[category] then
			categorizedProducts[category] = {}
		end
		table.insert(categorizedProducts[category], product)
	end
	
	-- Создаём элементы товаров
	local productElements = {}
	local currentY = 0.12  -- Уменьшен отступ для поднятия заголовка
	
	-- Заголовок "СПОСОБНОСТИ" над товарами
	productElements["AbilitiesTitle"] = Roact.createElement("TextLabel", {
		Size = UDim2.new(1, -40, 0, 30),
		Position = UDim2.new(0, 20, 0, currentY * 500),
		BackgroundTransparency = 1,
		Text = "СПОСОБНОСТИ",
		TextColor3 = ShopConfig.colors.text,
		Font = ShopConfig.fonts.header,
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 2
	})
	
	currentY = currentY + 0.08  -- Отступ после заголовка
	
	for categoryName, categoryProducts in pairs(categorizedProducts) do
		-- Создаём карточки товаров для каждой категории
		for i, product in ipairs(categoryProducts) do
			local elementName = categoryName .. "_" .. tostring(i)
			
			-- Позиционирование для сетки
			local col = (i - 1) % 2
			local row = math.floor((i - 1) / 2)
			
			productElements[elementName] = Roact.createElement(ProductCard, {
				product = product,
				position = UDim2.new(0.05 + col * 0.475, 0, currentY + row * 0.12, 0),
				size = UDim2.new(0.45, 0, 0.1, 0),
				balance = props.balance or 0,
				onPurchase = function(prod)
					self:purchaseProduct(prod)
				end
			})
		end
		
		-- Обновляем currentY для следующей категории
		local numRows = math.ceil(#categoryProducts / 2)
		currentY = currentY + numRows * 0.12 + 0.05
	end
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(panelWidth, 0, panelHeight, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = ShopConfig.colors.background,
		BorderSizePixel = 3,
		BorderColor3 = ShopConfig.colors.border,
		ZIndex = 1
	}, {
		-- Градиент фона (опционально)
		BackgroundGradient = Roact.createElement("UIGradient", {
			Color = ShopConfig.gradients.panelBackground,
			Rotation = 45
		}),
		
		-- Заголовок панели
		Header = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = ShopConfig.colors.headerBackground,
			BorderSizePixel = 0,
			ZIndex = 2
		}, {
			-- Градиент заголовка
			HeaderGradient = Roact.createElement("UIGradient", {
				Color = ShopConfig.gradients.header,
				Rotation = 90
			}),
			
			-- Текст заголовка
			HeaderText = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, -80, 1, 0),
				Position = UDim2.new(0, 20, 0, 0),
				BackgroundTransparency = 1,
				Text = "МАГАЗИН",
				TextColor3 = ShopConfig.colors.headerText,
				Font = ShopConfig.fonts.header,
				TextSize = isMobile and 20 or 24,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3
			}),
			
			-- Кнопка закрытия
			CloseButton = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 40, 0, 40),
				Position = UDim2.new(1, -50, 0, 10),
				BackgroundColor3 = ShopConfig.colors.danger,
				BorderSizePixel = 2,
				BorderColor3 = ShopConfig.colors.border,
				Text = "✕",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.SourceSansBold,
				TextSize = 18,
				ZIndex = 3,
				[Roact.Event.Activated] = function()
					self.soundService:playClickSound()
					if props.onClose then
						props.onClose()
					end
				end
			})
		}),
		
		-- Контейнер для баланса
		BalanceContainer = Roact.createElement("Frame", {
			Size = UDim2.new(0, 150, 0, 35),
			Position = UDim2.new(0, 15, 0, 70),  -- Сдвинуто левее
			BackgroundColor3 = ShopConfig.colors.background,
			BorderSizePixel = 3,
			BorderColor3 = ShopConfig.colors.border,  -- Синяя рамка
			ZIndex = 2
		}, {
			BalanceText = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, -10, 1, 0),
				Position = UDim2.new(0, 5, 0, 0),
				BackgroundTransparency = 1,
				Text = "💰 " .. (props.balance or 0),
				TextColor3 = ShopConfig.colors.text,
				Font = ShopConfig.fonts.button,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 3
			})
		}),
		
		-- Контейнер для товаров
		ProductContainer = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -20, 1, -130),
			Position = UDim2.new(0, 10, 0, 120),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 8,
			ScrollBarImageColor3 = ShopConfig.colors.border,
			CanvasSize = UDim2.new(0, 0, 0, math.max(400, currentY * 500 + 50)),
			ZIndex = 1
		}, productElements)
	})
end

return ShopComponent
````
## AbilityPanel.luau - ПОЛНЫЙ КОД (ЧАСТЬ 1)
```lua
--!strict
-- src/App/AbilityPanel.luau
-- Главная панель способностей

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local AbilityService = ModuleLoader.require("services/AbilityService")
local SimpleSoundService = ModuleLoader.require("services/SimpleSoundService")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")

-- Типы и конфигурация
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))

local AbilityPanel = Roact.Component:extend("AbilityPanel")

function AbilityPanel:init()
	self.abilityService = AbilityService.new()
	self.soundService = SimpleSoundService.new()
	self.platformService = PlatformService.new()
	
	-- Рефы для анимации кнопок
	self.buttonRefs = {}
	
	-- Отслеживание предыдущих состояний кулдаунов для звука окончания
	self.previousCooldowns = {}
	
	self.state = {
		abilities = {},
		cooldowns = {},
		activeEffects = {},
		cooldownTimes = {},
		hoveredAbility = nil,
	}
	
	-- Обновляем состояние каждые 0.1 секунды для плавности
	spawn(function()
		while true do
			wait(0.1)
			self:updateState()
		end
	end)
	
	-- Загружаем способности мгновенно
	spawn(function()
		self:loadAbilities()
	end)
end

-- Загрузка способностей
function AbilityPanel:loadAbilities()
	local abilitiesData = self.abilityService:getAvailableAbilities()
	
	-- Преобразуем в нужный формат
	local abilities = {}
	for i = 1, 6 do
		local abilityData = abilitiesData[i]
		if abilityData then
			table.insert(abilities, {
				id = abilityData.id,
				name = abilityData.name,
				description = abilityData.description,
				hotkey = i,
				icon = abilityData.icon or "⚡",
				color = abilityData.color or Color3.fromRGB(100, 255, 100)
			})
		end
	end
	
	self:setState({
		abilities = abilities
	})
end

-- Обновление состояния кулдаунов
function AbilityPanel:updateState()
	local newCooldowns = {}
	local newActiveEffects = {}
	local newCooldownTimes = {}
	
	for _, ability in ipairs(self.state.abilities) do
		local cooldownInfo = self.abilityService:getCooldownInfo(ability.id)
		newCooldowns[ability.id] = cooldownInfo.isOnCooldown
		newCooldownTimes[ability.id] = cooldownInfo.remainingTime
		
		-- Проверяем, закончился ли кулдаун для проигрывания звука
		if self.previousCooldowns[ability.id] == true and not cooldownInfo.isOnCooldown then
			self.soundService:playCooldownEndSound()
		end
		
		-- Активные эффекты
		newActiveEffects[ability.id] = self.abilityService:isAbilityActive(ability.id)
	end
	
	-- Сохраняем предыдущие состояния
	self.previousCooldowns = newCooldowns
	
	self:setState({
		cooldowns = newCooldowns,
		activeEffects = newActiveEffects,
		cooldownTimes = newCooldownTimes
	})
end

-- Активация способности
function AbilityPanel:activateAbility(ability)
	print("⚡ Активация способности:", ability.name)
	
	local player = Players.LocalPlayer
	local success = self.abilityService:activateAbility(ability.id, player)
	
	if success then
		self.soundService:playAbilitySound()
		
		-- Анимация нажатия кнопки
		local buttonRef = self.buttonRefs[ability.id]
		if buttonRef and buttonRef.current then
			local button = buttonRef.current
			local originalSize = button.Size
			
			-- Анимация сжатия и расширения
			local shrinkTween = TweenService:Create(button, 
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = originalSize * 0.9}
			)
			
			local expandTween = TweenService:Create(button,
				TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = originalSize}
			)
			
			shrinkTween:Play()
			shrinkTween.Completed:Connect(function()
				expandTween:Play()
			end)
		end
	else
		self.soundService:playErrorSound()
	end
end

-- Обработка наведения на способность
function AbilityPanel:onAbilityHover(ability, isHovering)
	if isHovering then
		self:setState({
			hoveredAbility = ability
		})
	else
		self:setState({
			hoveredAbility = self.state.hoveredAbility == ability and Roact.None or self.state.hoveredAbility
		})
	end
end

-- Рендер одной кнопки способности
function AbilityPanel:renderAbilityButton(ability, index)
	local cooldownProgress = 0
	local isOnCooldown = self.state.cooldowns[ability.id] or false
	local isActive = self.state.activeEffects[ability.id] or false
	local cooldownTime = self.state.cooldownTimes[ability.id] or 0
	
	if isOnCooldown and cooldownTime > 0 then
		-- Предполагаем максимальное время кулдауна 10 секунд для расчёта прогресса
		cooldownProgress = math.max(0, 1 - (cooldownTime / 10))
	end
	
	-- Цвета для разных состояний
	local backgroundColor = Color3.fromRGB(100, 255, 100)  -- Зелёный
	local textColor = Color3.fromRGB(255, 255, 255)
	
	if isOnCooldown then
		backgroundColor = Color3.fromRGB(128, 128, 128)  -- Серый
	elseif isActive then
		backgroundColor = Color3.fromRGB(255, 215, 0)  -- Золотой
	end
	
	-- Адаптивные размеры
	local isMobile = self.platformService:isMobile()
	local iconSize = isMobile and 24 or 32
	local fontSize = isMobile and 14 or 16
	
	-- Создаём ref для анимации
	if not self.buttonRefs[ability.id] then
		self.buttonRefs[ability.id] = Roact.createRef()
	end
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, isMobile and 140 or 160, 0, isMobile and 120 or 140),
		Position = UDim2.new(0.1 + ((index - 1) % 3) * 0.3, 0, 0.15 + math.floor((index - 1) / 3) * 0.4, 0),
		BackgroundTransparency = 1,
		ZIndex = 2
	}, {
		-- Основная кнопка способности
		AbilityButton = Roact.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0.7, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = backgroundColor,
			BorderSizePixel = 3,
			BorderColor3 = ShopConfig.colors.border,
			Text = "",
			ZIndex = 3,
			[Roact.Ref] = self.buttonRefs[ability.id],
			[Roact.Event.Activated] = function()
				if not isOnCooldown then
					self:activateAbility(ability)
				end
			end,
			[Roact.Event.MouseEnter] = function()
				self:onAbilityHover(ability, true)
			end,
			[Roact.Event.MouseLeave] = function()
				self:onAbilityHover(ability, false)
			end
		}, {
			-- Иконка способности
			AbilityIcon = Roact.createElement("TextLabel", {
				Size = UDim2.new(0, iconSize, 0, iconSize),
				Position = UDim2.new(0.5, -iconSize/2, 0, 10),
				BackgroundTransparency = 1,
				Text = ability.icon,
				TextColor3 = textColor,
				TextSize = iconSize,
				Font = Enum.Font.SourceSansBold,
				ZIndex = 4
			}),
			
			-- Название способности
			AbilityName = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, -10, 0, 20),
				Position = UDim2.new(0, 5, 1, -25),
				BackgroundTransparency = 1,
				Text = ability.name,
				TextColor3 = textColor,
				TextSize = fontSize,
				Font = Enum.Font.SourceSansBold,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 4
			}),
			
			-- Прогресс кулдауна
			CooldownOverlay = isOnCooldown and Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1 - cooldownProgress, 0),
				Position = UDim2.new(0, 0, cooldownProgress, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
				ZIndex = 5
			}),
			
			-- Текст времени кулдауна
			CooldownText = isOnCooldown and cooldownTime > 0 and Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = string.format("%.1f", cooldownTime),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = isMobile and 18 or 24,
				Font = Enum.Font.SourceSansBold,
				ZIndex = 6
			})
		}),
		
		-- Горячая клавиша
		HotkeyLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(0, 25, 0, 25),
			Position = UDim2.new(0, -5, 0, -5),
			BackgroundColor3 = ShopConfig.colors.border,
			BorderSizePixel = 2,
			BorderColor3 = Color3.fromRGB(255, 255, 255),
			Text = tostring(ability.hotkey),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 14,
			Font = Enum.Font.SourceSansBold,
			ZIndex = 4
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4)
			})
		})
	})
end

-- Основной рендер панели
function AbilityPanel:render()
	local isMobile = self.platformService:isMobile()
	local panelWidth = isMobile and 0.9 or 0.8
	local panelHeight = isMobile and 0.85 or 0.8
	
	-- Создаём кнопки способностей
	local abilityButtons = {}
	for i, ability in ipairs(self.state.abilities) do
		abilityButtons["Ability" .. i] = self:renderAbilityButton(ability, i)
	end
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(panelWidth, 0, panelHeight, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = ShopConfig.colors.background,
		BorderSizePixel = 3,
		BorderColor3 = ShopConfig.colors.border,
		ZIndex = 1
	}, {
		-- Заголовок панели
		Header = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = ShopConfig.colors.headerBackground,
			BorderSizePixel = 0,
			ZIndex = 2
		}, {
			-- Градиент заголовка
			HeaderGradient = Roact.createElement("UIGradient", {
				Color = ShopConfig.gradients.header,
				Rotation = 90
			}),
			
			-- Текст заголовка
			HeaderText = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, -80, 1, 0),
				Position = UDim2.new(0, 20, 0, 0),
				BackgroundTransparency = 1,
				Text = "ПАНЕЛЬ СПОСОБНОСТЕЙ",
				TextColor3 = ShopConfig.colors.headerText,
				Font = ShopConfig.fonts.header,
				TextSize = isMobile and 18 or 22,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 3
			}),
			
			-- Кнопка закрытия
			CloseButton = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 40, 0, 40),
				Position = UDim2.new(1, -50, 0, 10),
				BackgroundColor3 = ShopConfig.colors.danger,
				BorderSizePixel = 2,
				BorderColor3 = ShopConfig.colors.border,
				Text = "✕",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.SourceSansBold,
				TextSize = 18,
				ZIndex = 3,
				[Roact.Event.Activated] = function()
					self.soundService:playClickSound()
					if self.props.onClose then
						self.props.onClose()
					end
				end
			})
		}),
		
		-- Контейнер для кнопок способностей
		AbilitiesContainer = Roact.createElement("Frame", {
			Size = UDim2.new(1, -20, 1, -80),
			Position = UDim2.new(0, 10, 0, 70),
			BackgroundTransparency = 1,
			ZIndex = 1
		}, abilityButtons),
		
		-- Подсказка внизу
		HintText = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, 30),
			Position = UDim2.new(0, 10, 1, -40),
			BackgroundTransparency = 1,
			Text = "Используйте клавиши 1-6 для быстрой активации",
			TextColor3 = Color3.fromRGB(200, 200, 200),
			Font = Enum.Font.SourceSans,
			TextSize = isMobile and 12 or 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			ZIndex = 2
		}),
		
		-- Всплывающая подсказка (если есть наведённая способность)
		Tooltip = self.state.hoveredAbility and Roact.createElement("Frame", {
			Size = UDim2.new(0, 250, 0, 80),
			Position = UDim2.new(1, 10, 0, 100),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 2,
			BorderColor3 = ShopConfig.colors.border,
			ZIndex = 10
		}, {
			ToolTipText = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, -10, 1, -10),
				Position = UDim2.new(0, 5, 0, 5),
				BackgroundTransparency = 1,
				Text = self.state.hoveredAbility.description or "Описание недоступно",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.SourceSans,
				TextSize = 14,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 11
			})
		})
	})
end

return AbilityPanel
````
