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
	
	-- === КОМАНДЫ ОТЛАДКИ ЗВУКОВ (ТОЛЬКО ДЛЯ РАЗРАБОТКИ) ===
	-- Добавляем консольные команды для тестирования звуков
	if game:GetService("RunService"):IsStudio() then
		spawn(function()
			wait(2) -- Ждем полной инициализации
			
			-- Команда для тестирования всех звуков
			game.Players.LocalPlayer.Chatted:Connect(function(message)
				if message:lower() == "/testsounds" then
					print("🔊 Запуск тестирования всех звуков...")
					self.soundService:testAllSounds()
				elseif message:lower() == "/soundstats" then
					print("📊 Статистика звуковой системы:")
					self.soundService:printStats()
				elseif message:lower() == "/sounddebug" then
					self.soundService:setDebug(true)
					print("🔊 Отладка звуков включена")
				elseif message:lower() == "/sounddebugoff" then
					self.soundService:setDebug(false)
					print("🔊 Отладка звуков выключена")
				end
			end)
			
			print("🔊 Команды отладки звуков доступны:")
			print("   /testsounds - тест всех звуков")
			print("   /soundstats - статистика производительности")
			print("   /sounddebug - включить детальное логирование")
			print("   /sounddebugoff - выключить детальное логирование")
		end)
	end
	
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
	
	local isOpening = not self.state.showShop
	
	-- Воспроизводим звук
	if isOpening then
		self.soundService:playShopOpen()
	else
		self.soundService:playShopClose()
	end
	
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
	-- Воспроизводим звук покупки СРАЗУ для мгновенного отклика
	self.soundService:playPurchaseSound()
	
	-- Покупаем товар через сервис
	local result = self.shopService:purchaseProduct(player, product.id)
	
	if result.success then
		print("✅ Успешная покупка:", result.message)
		
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
				AutoButtonColor = false, -- ИСПРАВЛЕНО: отключаем автоматические эффекты
				Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
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
		
		-- 🎮 ПРОФЕССИОНАЛЬНАЯ КНОПКА МАГАЗИНА (В СТИЛЕ ПРОЕКТА)
		ShopButton = Roact.createElement("TextButton", {
			Text = self.state.showShop and "ЗАКРЫТЬ" or "МАГАЗИН",
			Size = UDim2.new(0, 150, 0, 54), -- Стандартная высота как у магазина
			Position = self.platformService:isMobile() and 
				UDim2.new(0, 20, 0.5, -27) or -- Мобильная: левый край экрана
				UDim2.new(1, -170, 0.5, -27), -- Десктопная: правый край экрана
			
			-- ЦВЕТА ИЗ SHOPCONFIG
			BackgroundColor3 = self.state.showShop and 
				ShopConfig.design.colors.button.close or -- Красный для "закрыть"
				ShopConfig.design.colors.button.buy, -- Зеленый для "магазин"
			BackgroundTransparency = 0,
			
			-- ТИПОГРАФИКА ИЗ SHOPCONFIG (КАСТОМНЫЙ РАЗМЕР ШРИФТА)
			TextSize = self.platformService:isMobile() and 26 or 30, -- На 2px меньше чем header (было 28/32)
			Font = Enum.Font.GothamBold,
			TextColor3 = ShopConfig.design.colors.text.primary,
			
			AutoButtonColor = false,
			Modal = true,
			BorderSizePixel = 0,
			
			[Roact.Event.MouseButton1Up] = function()
				self:toggleShop()
			end,
			
			-- АНИМАЦИЯ НАЖАТИЯ
			[Roact.Event.MouseButton1Down] = function(button)
				-- Быстрая анимация "вжатия"
				local pressTween = TweenService:Create(button,
					TweenInfo.new(0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{
						Size = UDim2.new(0, 145, 0, 52) -- Слегка уменьшаем
					}
				)
				pressTween:Play()
			end,
			
			-- АНИМИРОВАННЫЕ HOVER ЭФФЕКТЫ
			[Roact.Event.MouseEnter] = function(button)
				local hoverColor = self.state.showShop and 
					ShopConfig.design.colors.button.closeHover or 
					ShopConfig.design.colors.button.buyHover
				
				-- Плавная анимация цвета и размера
				local colorTween = TweenService:Create(button,
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{
						BackgroundColor3 = hoverColor,
						Size = UDim2.new(0, 155, 0, 56) -- Небольшое увеличение
					}
				)
				colorTween:Play()
			end,
			
			[Roact.Event.MouseLeave] = function(button)
				local baseColor = self.state.showShop and 
					ShopConfig.design.colors.button.close or 
					ShopConfig.design.colors.button.buy
				
				-- Плавная анимация обратно к исходному состоянию
				local colorTween = TweenService:Create(button,
					TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
					{
						BackgroundColor3 = baseColor,
						Size = UDim2.new(0, 150, 0, 54) -- Возврат к исходному размеру
					}
				)
				colorTween:Play()
			end,
		}, {
			-- СКРУГЛЕНИЕ ИЗ SHOPCONFIG
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.medium),
			}),
			
			-- ТОНКАЯ ЧЕРНАЯ ОБВОДКА ДЛЯ КОНТРАСТА
			UIStroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(0, 0, 0), -- Черная обводка
				Thickness = 1, -- Тонкая обводка
				Transparency = 0.3, -- Слегка прозрачная для мягкости
			}),
			
			-- ТЕНЬ КАК У ДРУГИХ ЭЛЕМЕНТОВ МАГАЗИНА
			ButtonShadow = Roact.createElement("Frame", {
				Size = UDim2.new(1, 4, 1, 6),
				Position = UDim2.new(0, 2, 0, 3),
				BackgroundColor3 = ShopConfig.design.shadow.color,
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				ZIndex = -1,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.medium),
				}),
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
		}, {
			-- 🛒 АДАПТИВНЫЙ КОНТЕЙНЕР МАГАЗИНА С РОВНЫМИ ОТСТУПАМИ
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
					soundService = self.soundService,
					visible = true,
					updateTrigger = self.state.shopUpdateTrigger,
					currentCoins = self.state.coins, -- Передаем актуальное количество монет
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

