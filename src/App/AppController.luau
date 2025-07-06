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
local AbilityConfig = ModuleLoader.require("shared/AbilityConfig")
local WalletComponent = ModuleLoader.require("App/WalletComponent")
local ShopComponent = ModuleLoader.require("App/ShopComponent")
local AbilityPanel = ModuleLoader.require("App/AbilityPanel")
local SimpleSoundService = ModuleLoader.require("services/SimpleSoundService")

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
	
	print("🔧 AppController: Сервисы инициализированы")
	
	-- Ref для магазина для анимации
	self.shopRef = Roact.createRef()
	
	-- Получаем начальное состояние валюты
	local initialCurrency = self.currencyService:getPlayerCurrency(player)
	
	print("💰 AppController: Начальное состояние валюты:", initialCurrency.coins)
	
	self:setState({ 
		coins = initialCurrency.coins,
		isLoaded = true,
		showShop = false, -- магазин скрыт по умолчанию
		shopAnimating = false, -- флаг анимации
		abilityUpdateTrigger = 0, -- триггер для обновления панели способностей
		shopUpdateTrigger = 0, -- триггер для обновления магазина
	})
	
	print("✅ AppController: Состояние установлено, isLoaded = true")
	
	-- Подписываемся на изменения валюты
	self.currencyService:onCurrencyChanged(function(changedPlayer: Player, newState: CurrencyState)
		if changedPlayer == player then
			self:setState({ coins = newState.coins })
		end
	end)
	
	print("✅ AppController:init() завершён!")
end

-- Функция для добавления монет (тестовая)
function AppController:addCoins()
	local success = self.currencyService:addCoins(player, 50)
	if not success then
		warn("Не удалось добавить монеты (возможно, кулдаун)")
	end
end

-- Переключить отображение магазина с анимацией
function AppController:toggleShop()
	-- Предотвращаем множественные нажатия во время анимации
	if self.state.shopAnimating then
		return
	end
	
	-- Звук переключения магазина
	self.soundService:playClickSound()
	
	local isOpening = not self.state.showShop
	
	if isOpening then
		-- ОТКРЫТИЕ МАГАЗИНА (СЛЕВА)
		self:setState({
			showShop = true,
			shopAnimating = true
		})
		
		-- Анимация появления слева
		spawn(function()
			wait(0.05) -- Небольшая задержка для рендера
			local shopFrame = self.shopRef:getValue()
			if shopFrame then
				-- Начальная позиция - за экраном слева (адаптивная)
				local startPosition = self.platformService:isMobile() and 
					UDim2.new(-0.9, 0, 0.1, 0) or -- Мобильная: -90% ширины, 10% отступ сверху
					UDim2.new(0, -480, 0, 80) -- Десктопная: -480px, 80px отступ сверху
				
				shopFrame.Position = startPosition
				
				-- Анимация скольжения к финальной позиции
				local finalPosition = self.platformService:isMobile() and 
					UDim2.new(0, 0, 0.1, 0) or -- Мобильная: левый край, 10% отступ сверху
					UDim2.new(0, 0, 0, 80) -- Десктопная: левый край, 80px отступ сверху
				
				local tween = TweenService:Create(shopFrame,
					TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{Position = finalPosition}
				)
				
				tween.Completed:Connect(function()
					self:setState({shopAnimating = false})
				end)
				
				tween:Play()
			else
				self:setState({shopAnimating = false})
			end
		end)
	else
		-- ЗАКРЫТИЕ МАГАЗИНА (ВЛЕВО)
		self:setState({
			shopAnimating = true
		})
		
		-- Анимация скрытия влево
		spawn(function()
			local shopFrame = self.shopRef:getValue()
			if shopFrame then
				-- Анимация скольжения за экран слева
				local hidePosition = self.platformService:isMobile() and 
					UDim2.new(-0.9, 0, 0.1, 0) or -- Мобильная: за экран слева, сохраняем отступ сверху
					UDim2.new(0, -480, 0, 80) -- Десктопная: за экран слева, сохраняем отступ сверху
				
				local tween = TweenService:Create(shopFrame,
					TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
					{Position = hidePosition}
				)
				
				tween.Completed:Connect(function()
					self:setState({
						showShop = false,
						shopAnimating = false
					})
				end)
				
				tween:Play()
			else
				self:setState({
					showShop = false,
					shopAnimating = false
				})
			end
		end)
	end
end

-- Функция вызывается после покупки товара
function AppController:onPurchase(product: Product)
	-- Покупаем товар через сервис
	local result = self.shopService:purchaseProduct(player, product.id)
	
	if result.success then
		print("✅ Успешная покупка:", result.message)
		
		-- Звук успешной покупки (убран для упрощения)
		-- self.soundService:playPurchaseSound()
		
		-- Обновляем панель способностей после покупки
		if product.category == "ability" then
			-- Принудительно обновляем состояние
			self:setState({
				coins = result.remainingCoins or self.state.coins,
				abilityUpdateTrigger = (self.state.abilityUpdateTrigger or 0) + 1, -- Триггер для обновления панели
				shopUpdateTrigger = (self.state.shopUpdateTrigger or 0) + 1, -- Триггер для обновления магазина
			})
		end
		
		-- Показываем уведомление об успехе
		game.StarterGui:SetCore("SendNotification", {
			Title = "Покупка успешна!",
			Text = "Куплен товар: " .. product.name,
			Duration = 3,
		})
	else
		warn("❌ Ошибка покупки:", result.message)
		
		-- Показываем уведомление об ошибке
		game.StarterGui:SetCore("SendNotification", {
			Title = "Ошибка покупки",
			Text = result.message,
			Duration = 4,
		})
	end
end

function AppController:render()
	-- Отладочная информация
	print("🎮 AppController:render() вызван! isLoaded =", self.state.isLoaded)
	
	-- 📱 ПРОСТАЯ АДАПТИВНАЯ КОНФИГУРАЦИЯ
	local config = self.platformService:getConfig()
	local isMobile = self.platformService:isMobile()
	local safeArea = self.platformService:getSafeAreaInsets()
	
	-- Показываем загрузку, пока модули не готовы
	if not self.state.isLoaded then
		print("⏳ AppController: Показываем экран загрузки...")
		return Roact.createElement("ScreenGui", {}, {
			LoadingFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			}, {
				LoadingText = Roact.createElement("TextLabel", {
					Text = "Загрузка магазина...",
					Size = UDim2.new(0, 300, 0, 100),
					Position = UDim2.new(0.5, -150, 0.5, -50),
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 24,
					Font = Enum.Font.Gotham,
				})
			})
		})
	end

	print("✅ AppController: Рендерим основной UI...")
	-- Основной UI
	return Roact.createElement("ScreenGui", {
		Name = "ShopApp",
		ResetOnSpawn = false,
	}, {
		MainFrame = Roact.createElement("Frame", {
			Size = UDim2.new(0, 420, 0, 500),
			Position = UDim2.new(0, 20, 0, 20),
			BackgroundTransparency = 1,
		}, {
			-- Компонент кошелька
			Wallet = Roact.createElement(WalletComponent, {
				coins = self.state.coins,
			}),
			
			-- Тестовая кнопка добавления монет
			AddButton = Roact.createElement("TextButton", {
				Text = "+50 монет",
				Size = UDim2.new(0, 140, 0, 44),
				Position = UDim2.new(0, 10, 0, 70),
				BackgroundColor3 = Color3.fromRGB(0, 200, 120),
				TextSize = 22,
				Font = Enum.Font.GothamBlack,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = true,
				BorderSizePixel = 0,
				[Roact.Event.MouseButton1Click] = function()
					self:addCoins()
				end,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 10),
				}),
			}),
		}),
		
		-- 🎮 ПРОФЕССИОНАЛЬНАЯ КНОПКА МАГАЗИНА
		ShopButton = Roact.createElement("TextButton", {
			Text = self.state.showShop and "ЗАКРЫТЬ" or "МАГАЗИН",
			Size = UDim2.new(0, 140, 0, 50), -- Немного уменьшили высоту для элегантности
			Position = self.platformService:isMobile() and 
				UDim2.new(0, 20, 0.5, -25) or -- Мобильная: левый край экрана
				UDim2.new(1, -160, 0.5, -25), -- Десктопная: правый край экрана
			-- УПРОЩЁННАЯ СХЕМА ЦВЕТОВ: только два состояния
			BackgroundColor3 = self.state.showShop and 
				Color3.fromRGB(239, 68, 68) or -- Красный для "закрыть" (более современный)
				Color3.fromRGB(59, 130, 246), -- Синий для "магазин" (более современный)
			BackgroundTransparency = 0,
			TextSize = 16, -- Чуть меньше для элегантности
			Font = Enum.Font.GothamBold, -- Менее агрессивный шрифт
			TextColor3 = Color3.fromRGB(255, 255, 255),
			AutoButtonColor = false,
			BorderSizePixel = 0,
			[Roact.Event.MouseButton1Down] = function()
				-- Убираем отдельное состояние нажатия
			end,
			[Roact.Event.MouseButton1Up] = function()
				self:toggleShop()
			end,
			-- СОВРЕМЕННЫЕ HOVER ЭФФЕКТЫ
			[Roact.Event.MouseEnter] = function(button)
				if self.state.showShop then
					-- Светлее красный при наведении
					button.BackgroundColor3 = Color3.fromRGB(248, 113, 113)
				else
					-- Светлее синий при наведении
					button.BackgroundColor3 = Color3.fromRGB(96, 165, 250)
				end
			end,
			[Roact.Event.MouseLeave] = function(button)
				-- Возврат к базовым цветам
				if self.state.showShop then
					button.BackgroundColor3 = Color3.fromRGB(239, 68, 68)
				else
					button.BackgroundColor3 = Color3.fromRGB(59, 130, 246)
				end
			end,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12), -- Современное скругление
			}),
		}),
		
		-- Панель способностей (отдельно от магазина)
		AbilityPanel = Roact.createElement(AbilityPanel, {
			updateTrigger = self.state.abilityUpdateTrigger,
		}),
		
		-- Магазин как отдельный ScreenGui для анимации (всегда рендерим для плавности)
		ShopGui = Roact.createElement("ScreenGui", {
			Name = "ShopGui",
			ResetOnSpawn = false,
			Enabled = self.state.showShop, -- Используем Enabled вместо условного рендера
		}, {		-- 🛒 АДАПТИВНЫЙ КОНТЕЙНЕР МАГАЗИНА С РОВНЫМИ ОТСТУПАМИ
		ShopFrame = Roact.createElement("Frame", {
			[Roact.Ref] = self.shopRef,
			Size = self.platformService:isMobile() and 
				UDim2.new(0.9, 0, 0.8, 0) or -- Мобильная: 90% ширины, 80% высоты экрана
				UDim2.new(0, 480, 0, 520), -- Десктопная: 480px ширина, 520px высота (уменьшили для отступа снизу)
			Position = self.platformService:isMobile() and 
				UDim2.new(-0.9, 0, 0.1, 0) or -- Мобильная: начальная позиция за экраном, 10% отступ сверху
				UDim2.new(0, -480, 0, 80), -- Десктопная: начальная позиция за экраном, 80px отступ сверху
			BackgroundTransparency = 1,
			}, {
				Shop = Roact.createElement(ShopComponent, {
					shopService = self.shopService,
					visible = true,
					updateTrigger = self.state.shopUpdateTrigger,
					onPurchase = function(product)
						self:onPurchase(product)
					end,
					onClose = function()
						self:toggleShop()
					end,
				}),
			}),
		}),
	})
end

return AppController
