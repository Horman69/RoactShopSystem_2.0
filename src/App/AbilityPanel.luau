--!strict
-- src/App/AbilityPanel.luau
-- Главная панель способностей

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local AbilityService = ModuleLoader.require("services/AbilityService")
local SimpleSoundService = ModuleLoader.require("services/SimpleSoundService")
local PlatformService = ModuleLoader.require("services/SimplePlatformService")
local AbilityConfig = ModuleLoader.require("shared/AbilityConfig") -- Добавляем импорт конфигурации
local ShopConfig = ModuleLoader.require("shared/ShopConfig") -- Импорт для унифицированных стилей

local AbilityPanel = Roact.Component:extend("AbilityPanel")

function AbilityPanel:init()
	-- Безопасная инициализация сервисов
	local success, error = pcall(function()
		self.abilityService = AbilityService.new()
		self.soundService = SimpleSoundService.new()
		self.platformService = PlatformService.new()
	end)
	
	if not success then
		warn("AbilityPanel: Ошибка инициализации сервисов:", error)
		-- Создаем заглушки для сервисов
		self.abilityService = { 
			getActiveEffects = function() return {} end,
			isAbilityUnavailableForUI = function() return false end,
			getUITimeLeft = function() return 0 end,
			activateAbility = function() return {success = false, message = "Сервис недоступен"} end
		}
		self.soundService = { playSound = function() end }
		self.platformService = { isMobile = function() return false end }
	end
	
	-- Рефы для анимации кнопок
	self.buttonRefs = {}
	
	-- Рефы для плавной анимации прогресс-баров
	self.progressRefs = {}
	
	-- Отслеживание предыдущих состояний кулдаунов для звука окончания
	self.previousCooldowns = {}
	
	-- Для плавной анимации прогресс-баров
	self.isUpdating = false
	self.lastUpdateTime = 0
	
	self.state = {
		abilities = {},
		cooldowns = {},
		activeEffects = {},
		cooldownTimes = {},
		effectTimes = {}, -- Добавляем отслеживание времени эффектов
		hoveredAbility = nil,
	}
	
	-- Оптимизированное обновление состояния (не каждый кадр!)
	self.updateConnection = nil
	self:startOptimizedUpdates()
	
	-- Загружаем способности мгновенно и делаем первое обновление
	spawn(function()
		wait(0.1) -- Минимальная задержка для стабильности
		self:loadAbilities()
		
		-- ВАЖНО: Инициализируем previousCooldowns правильно
		self:initializePreviousCooldowns()
		
		-- ВАЖНО: Принудительно обновляем состояние в начале для корректной инициализации
		wait(0.1) -- Дополнительная задержка для загрузки способностей
		self:updateState()
		print("🔄 AbilityPanel: Принудительное первое обновление состояния выполнено")
	end)
	
	-- Горячие клавиши
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		-- Базовые способности - привязаны к конкретным ID
		if input.KeyCode == Enum.KeyCode.Q then
			self:onAbilityActivate("speed_boost")
		elseif input.KeyCode == Enum.KeyCode.E then
			self:onAbilityActivate("shield_aura")
		elseif input.KeyCode == Enum.KeyCode.R then
			self:onAbilityActivate("jump_boost")
		-- Особые способности (пока отключены)
		-- elseif input.KeyCode == Enum.KeyCode.T then
		-- 	self:onAbilityActivate("strength_boost")
		-- elseif input.KeyCode == Enum.KeyCode.F then
		-- 	self:onAbilityActivate("invisibility")
		-- elseif input.KeyCode == Enum.KeyCode.G then
		-- 	self:onAbilityActivate("fire_aura")
		end
	end)
end

function AbilityPanel:initializePreviousCooldowns()
	local player = Players.LocalPlayer
	if not player then return end
	
	local initialCooldowns = {}
	
	-- Инициализируем состояния для базовых способностей
	local baseAbilities = {"speed_boost", "shield_aura", "jump_boost"}
	for _, abilityId in ipairs(baseAbilities) do
		initialCooldowns[abilityId] = self.abilityService:isAbilityUnavailableForUI(player, abilityId)
	end
	
	-- Инициализируем состояния для купленных способностей
	for _, ability in ipairs(self.state.abilities) do
		initialCooldowns[ability.id] = self.abilityService:isAbilityUnavailableForUI(player, ability.id)
	end
	
	self.previousCooldowns = initialCooldowns
	print("🔄 AbilityPanel: Инициализированы предыдущие состояния кулдаунов:", initialCooldowns)
end

function AbilityPanel:loadAbilities()
	local player = Players.LocalPlayer
	if not player then return end
	
	local abilities = self.abilityService:getPlayerAbilities(player)
	self:setState({ abilities = abilities })
end

-- Умная система обновлений (замена Heartbeat)
function AbilityPanel:startOptimizedUpdates()
	-- Запускаем цикл обновлений только при необходимости
	spawn(function()
		local idleCounter = 0 -- Счетчик циклов без активности
		
		while self.updateConnection ~= false do -- Флаг для остановки
			wait(0.1) -- Обновляем максимум 10 раз в секунду
			
			if self.updateConnection == false then break end
			
			local player = Players.LocalPlayer
			if not player then continue end
			
			-- Проверяем, нужно ли обновление
			local needsUpdate = self:checkIfUpdateNeeded(player)
			
			if needsUpdate then
				self:updateState()
				idleCounter = 0 -- Сбрасываем счетчик при активности
			else
				idleCounter = idleCounter + 1
				
				-- Увеличиваем паузу только после длительного простоя (5+ секунд)
				if idleCounter > 50 then -- 50 * 0.1 = 5 секунд
					wait(0.3) -- Дополнительная пауза только после долгого простоя
				end
			end
		end
	end)
	
	self.updateConnection = true
end

-- Проверка необходимости обновления
function AbilityPanel:checkIfUpdateNeeded(player)
	-- Быстрая проверка активных эффектов
	local activeEffects = self.abilityService:getActiveEffects(player)
	for abilityId, _ in pairs(activeEffects) do
		return true -- Есть активные эффекты
	end
	
	-- Проверка кулдаунов базовых способностей
	local baseAbilities = {"speed_boost", "shield_aura", "jump_boost"}
	for _, abilityId in ipairs(baseAbilities) do
		local isOnCooldown = self.abilityService:isAbilityUnavailableForUI(player, abilityId)
		local wasOnCooldown = self.previousCooldowns[abilityId]
		
		-- ВАЖНО: Первый запуск или изменение состояния
		if wasOnCooldown == nil or wasOnCooldown ~= isOnCooldown then
			if wasOnCooldown ~= nil then -- Не первый запуск
				print("🔄 checkIfUpdateNeeded: Состояние", abilityId, "изменилось:", wasOnCooldown, "→", isOnCooldown)
			end
			return true -- Состояние кулдауна изменилось
		end
		
		if isOnCooldown then
			return true -- Есть активные кулдауны
		end
	end
	
	-- Проверка купленных способностей
	for _, ability in ipairs(self.state.abilities) do
		local isOnCooldown = self.abilityService:isAbilityUnavailableForUI(player, ability.id)
		local wasOnCooldown = self.previousCooldowns[ability.id]
		
		-- ВАЖНО: Первый запуск или изменение состояния
		if wasOnCooldown == nil or wasOnCooldown ~= isOnCooldown then
			if wasOnCooldown ~= nil then -- Не первый запуск
				print("🔄 checkIfUpdateNeeded: Состояние", ability.id, "изменилось:", wasOnCooldown, "→", isOnCooldown)
			end
			return true -- Состояние кулдауна изменилось
		end
		
		if isOnCooldown then
			return true -- Есть активные кулдауны
		end
	end
	
	return false -- Нет активности, обновления не нужны
end

function AbilityPanel:updateState()
	local player = Players.LocalPlayer
	if not player then return end
	
	local cooldowns = {}
	local cooldownTimes = {}
	local effectTimes = {}
	local activeEffects = self.abilityService:getActiveEffects(player)
	
	-- Проверяем кулдауны для всех базовых способностей (даже не купленных)
	local baseAbilities = {"speed_boost", "shield_aura", "jump_boost"}
	
	for _, abilityId in ipairs(baseAbilities) do
		local isOnCooldown = self.abilityService:isAbilityUnavailableForUI(player, abilityId)
		local wasOnCooldown = self.previousCooldowns[abilityId]
		
		cooldowns[abilityId] = isOnCooldown
		
		-- Получаем время эффекта напрямую из AbilityService
		if activeEffects[abilityId] then
			local config = self:getAbilityConfig(abilityId)
			if config then
				local effect = activeEffects[abilityId]
				local elapsed = tick() - effect.startTime
				local remaining = math.max(0, config.baseDuration - elapsed)
				effectTimes[abilityId] = remaining
			end
		end
		
		-- Проверяем, закончился ли кулдаун (был на кулдауне, теперь нет)
		if wasOnCooldown == true and isOnCooldown == false then
			-- Кулдаун закончился
			print("✅ AbilityPanel: Кулдаун способности", abilityId, "закончился! Обновляем UI")
			print("📊 AbilityPanel: Детали -", abilityId, "wasOnCooldown:", wasOnCooldown, "isOnCooldown:", isOnCooldown)
		end
		
		if isOnCooldown then
			cooldownTimes[abilityId] = self.abilityService:getUITimeLeft(player, abilityId)
		end
	end
	
	-- Также проверяем купленные способности (для особых способностей в будущем)
	for _, ability in ipairs(self.state.abilities) do
		local isOnCooldown = self.abilityService:isAbilityUnavailableForUI(player, ability.id)
		local wasOnCooldown = self.previousCooldowns[ability.id]
		
		cooldowns[ability.id] = isOnCooldown
		
		-- Получаем время эффекта
		if activeEffects[ability.id] then
			local config = self:getAbilityConfig(ability.id)
			if config then
				local effect = activeEffects[ability.id]
				local elapsed = tick() - effect.startTime
				local remaining = math.max(0, config.baseDuration - elapsed)
				effectTimes[ability.id] = remaining
			end
		end
		
		-- Проверяем окончание кулдауна
		if wasOnCooldown == true and isOnCooldown == false then
			print("✅ AbilityPanel: Кулдаун способности", ability.id, "закончился! Обновляем UI")
			print("📊 AbilityPanel: Детали -", ability.id, "wasOnCooldown:", wasOnCooldown, "isOnCooldown:", isOnCooldown)
		end
		
		if isOnCooldown then
			cooldownTimes[ability.id] = self.abilityService:getUITimeLeft(player, ability.id)
		end
	end
	
	-- Сохраняем текущие состояния для следующего обновления
	self.previousCooldowns = cooldowns
	
	-- ОТЛАДКА: Логируем изменения состояния
	local changedAbilities = {}
	for abilityId, newState in pairs(cooldowns) do
		local oldState = self.state.cooldowns[abilityId]
		if oldState ~= newState then
			table.insert(changedAbilities, string.format("%s: %s→%s", abilityId, tostring(oldState), tostring(newState)))
		end
	end
	
	if #changedAbilities > 0 then
		print("🔄 AbilityPanel updateState: Изменения состояний:", table.concat(changedAbilities, ", "))
	end
	
	self:setState({
		cooldowns = cooldowns,
		activeEffects = activeEffects,
		cooldownTimes = cooldownTimes,
		effectTimes = effectTimes,
	})
end

function AbilityPanel:activateAbilityByIndex(index: number)
	local abilities = self.state.abilities
	if abilities[index] then
		self:onAbilityActivate(abilities[index].id)
	end
end

function AbilityPanel:onAbilityActivate(abilityId: string)
	local player = Players.LocalPlayer
	if not player then return end
	
	local result = self.abilityService:activateAbility(player, abilityId)
	
	-- Находим кнопку для анимации
	local buttonRef = self.buttonRefs[abilityId]
	local button = buttonRef and buttonRef:getValue()
	
	if result.success then
		-- Успешная активация - простая анимация успеха
		if button then
			self:animateSuccess(button)
		end
		
		-- Успешная активация - обновляем состояние
		spawn(function()
			wait(0.1)
			self:updateState()
		end)
	else
		-- Неудачная активация - без анимации, только звук
		if button then
			-- Можно добавить простую анимацию ошибки, но пока без неё
		end
		
		-- Неудачная активация - воспроизводим звук кулдауна
		if self.soundService then
			self.soundService:playAbilityCooldown()
		end
		
		-- Краткие уведомления
		if result.message:find("нет этой способности") then
			game.StarterGui:SetCore("SendNotification", {
				Title = "Способность не куплена!",
				Text = "Откройте магазин для покупки",
				Duration = 3,
			})
		elseif result.message:find("кулдауне") then
			local timeLeft = math.ceil(self.abilityService:getCooldownTimeLeft(player, abilityId))
			game.StarterGui:SetCore("SendNotification", {
				Title = "Способность на кулдауне!",
				Text = "Подождите " .. timeLeft .. " сек",
				Duration = 2,
			})
		end
	end
	
	-- Обновляем состояние
	self:updateState()
end

-- Простая анимация hover для кнопок
function AbilityPanel:animateHover(button: GuiObject)
	if not button then return end
	
	local tween = TweenService:Create(button, 
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 68, 0, 68)} -- Увеличиваем с 64 до 68
	)
	tween:Play()
end

-- Простая анимация отпускания кнопки
function AbilityPanel:animateRelease(button: GuiObject)
	if not button then return end
	
	local tween = TweenService:Create(button, 
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 64, 0, 64)} -- Возвращаем к 64
	)
	tween:Play()
end

-- Простая анимация успешной активации
function AbilityPanel:animateSuccess(button: GuiObject)
	if not button then return end
	
	local originalColor = button.BackgroundColor3
	
	-- Зеленое мигание
	local tween1 = TweenService:Create(button, 
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = Color3.fromRGB(0, 255, 100)}
	)
	
	tween1.Completed:Connect(function()
		local tween2 = TweenService:Create(button, 
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{BackgroundColor3 = originalColor}
		)
		tween2:Play()
	end)
	
	tween1:Play()
end

-- Создает прогресс-бар для отображения времени эффекта или кулдауна
function AbilityPanel:createProgressBar(abilityId: string, isEffectBar: boolean)
	local isActive = self.state.activeEffects[abilityId] ~= nil
	local isOnCooldown = self.state.cooldowns[abilityId] or false
	local effectTime = self.state.effectTimes[abilityId] or 0
	local cooldownTime = self.state.cooldownTimes[abilityId] or 0
	
	-- Определяем, показывать ли прогресс-бар
	local shouldShow = false
	local progress = 0
	local barColor = Color3.fromRGB(76, 175, 80) -- Зеленый по умолчанию
	
	if isEffectBar and isActive and effectTime > 0 then
		-- Прогресс-бар эффекта (зеленый) - показываем когда способность активна
		local config = self:getAbilityConfig(abilityId)
		if config then
			progress = math.max(0, math.min(1, effectTime / config.baseDuration))
			barColor = Color3.fromRGB(76, 175, 80) -- Зеленый
			shouldShow = true
		end
	elseif not isEffectBar and not isActive and isOnCooldown and cooldownTime > 0 then
		-- Прогресс-бар кулдауна (оранжевый) - показываем когда способность НЕ активна, но на кулдауне
		local config = self:getAbilityConfig(abilityId)
		if config then
			progress = math.max(0, math.min(1, cooldownTime / config.cooldown))
			barColor = Color3.fromRGB(255, 152, 0) -- Оранжевый
			shouldShow = true
		end
	end
	
	if not shouldShow then
		return nil
	end
	
	-- Создаем уникальный ref для этого прогресс-бара
	local refKey = abilityId .. (isEffectBar and "_effect" or "_cooldown")
	if not self.progressRefs[refKey] then
		self.progressRefs[refKey] = Roact.createRef()
	end
	
	return Roact.createElement("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(0.9, 0, 0.12, 0),
		Position = UDim2.new(0.05, 0, 0.82, 0),
		ZIndex = 6,
	}, {
		-- Фон прогресс-бара
		Background = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
		}),
		
		-- Заливка прогресса с плавной анимацией
		Fill = Roact.createElement("Frame", {
			[Roact.Ref] = self.progressRefs[refKey],
			BackgroundColor3 = barColor,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Size = UDim2.new(progress, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			ZIndex = 7,
			[Roact.Event.Changed] = function(property)
				-- Плавная анимация изменения размера
				if property == "Size" then
					local fillFrame = self.progressRefs[refKey]:getValue()
					if fillFrame then
						local tween = TweenService:Create(fillFrame,
							TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Size = UDim2.new(progress, 0, 1, 0)}
						)
						tween:Play()
					end
				end
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
		}),
	})
end

-- Упрощенная версия createProButton
function AbilityPanel:createSimpleButton(ability, index: number)
	local isOnCooldown = self.state.cooldowns[ability.id]
	local isActive = self.state.activeEffects[ability.id] ~= nil
	local cooldownTime = self.state.cooldownTimes[ability.id] or 0
	
	-- КОНФИГУРАЦИЯ СПОСОБНОСТЕЙ
	local abilityConfig = {
		speed_boost = { icon = "⚡", color = Color3.fromRGB(0, 174, 255) },
		shield_aura = { icon = "🛡", color = Color3.fromRGB(255, 149, 0) },
		jump_boost = { icon = "🚀", color = Color3.fromRGB(52, 199, 89) },
	}
	
	local config = abilityConfig[ability.id] or {
		icon = "?", color = Color3.fromRGB(100, 100, 255)
	}
	
	-- УЛУЧШЕННАЯ ЛОГИКА ЦВЕТОВ И СОСТОЯНИЙ
	local buttonColor, transparency, strokeColor, strokeThickness
	
	if isActive then
		-- Способность АКТИВНА (работает прямо сейчас) - яркий светящийся цвет
		buttonColor = Color3.new(
			math.min(1, config.color.R * 1.5), 
			math.min(1, config.color.G * 1.5), 
			math.min(1, config.color.B * 1.5)
		)
		transparency = 0 -- Полностью непрозрачная
		strokeColor = Color3.fromRGB(255, 255, 255) -- Белая обводка
		strokeThickness = 2
	elseif isOnCooldown then
		-- Способность на КУЛДАУНЕ - темная, заблокированная
		buttonColor = Color3.fromRGB(60, 30, 30) -- Темно-красная
		transparency = 0.3 -- Слегка прозрачная
		strokeColor = Color3.fromRGB(120, 60, 60) -- Красноватая обводка
		strokeThickness = 1
	else
		-- Способность ГОТОВА К ИСПОЛЬЗОВАНИЮ - обычный яркий цвет
		buttonColor = config.color
		transparency = 0 -- Непрозрачная
		strokeColor = Color3.fromRGB(80, 80, 80) -- Серая обводка
		strokeThickness = 1
	end
	
	-- ГОРЯЧИЕ КЛАВИШИ
	local hotkey = ""
	if ability.id == "speed_boost" then hotkey = "Q"
	elseif ability.id == "shield_aura" then hotkey = "E" 
	elseif ability.id == "jump_boost" then hotkey = "R" end
	
	-- Создаем ref для анимации этой кнопки
	if not self.buttonRefs[ability.id] then
		self.buttonRefs[ability.id] = Roact.createRef()
	end
	
	-- 📱 АДАПТИВНОЕ ПОЗИЦИОНИРОВАНИЕ
	local isMobile = self.platformService:isMobile()
	local position
	if isMobile then
		-- Мобильная версия: вертикальное размещение (Y координата меняется)
		position = UDim2.new(0, 0, 0, (index - 1) * 72)
	else
		-- Десктопная версия: горизонтальное размещение (X координата меняется)
		position = UDim2.new(0, (index - 1) * 72, 0, 0)
	end
	
	-- ОБЫЧНАЯ КНОПКА С ПРОСТЫМИ АНИМАЦИЯМИ (БЕЗ ЛИШНЕГО FRAME)
	return Roact.createElement("TextButton", {
		[Roact.Ref] = self.buttonRefs[ability.id],
		BackgroundColor3 = buttonColor,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 64, 0, 64),
		Position = position,
		Text = "",
		AutoButtonColor = false,
		Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
		[Roact.Event.Activated] = function()
			-- Всегда вызываем onAbilityActivate - звук и уведомления обработаются внутри
			self:onAbilityActivate(ability.id)
		end,
		[Roact.Event.MouseEnter] = function()
			-- Простая анимация hover
			local button = self.buttonRefs[ability.id]:getValue()
			if button then
				self:animateHover(button)
			end
		end,
		[Roact.Event.MouseLeave] = function()
			-- Возвращение к нормальному размеру
			local button = self.buttonRefs[ability.id]:getValue()
			if button then
				self:animateRelease(button)
			end
		end,
	}, {
		-- СКРУГЛЕНИЕ
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		
		-- ОБВОДКА ДЛЯ ИНДИКАЦИИ СОСТОЯНИЯ
		Stroke = Roact.createElement("UIStroke", {
			Color = strokeColor,
			Thickness = strokeThickness,
			Transparency = 0.3,
		}),
		
		-- ИКОНКА СПОСОБНОСТИ (ИДЕАЛЬНОЕ ЦЕНТРИРОВАНИЕ)
		Icon = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.7, 0, 0.7, 0), -- Увеличиваем размер для лучшей видимости
			Position = UDim2.new(0.15, 0, 0.08, 0), -- Корректируем позицию для центрирования
			AnchorPoint = Vector2.new(0, 0), -- Якорь в левом верхнем углу
			Text = config.icon,
			TextColor3 = isOnCooldown and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255),
			TextTransparency = isOnCooldown and 0.5 or 0,
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center, -- Горизонтальное центрирование
			TextYAlignment = Enum.TextYAlignment.Center, -- Вертикальное центрирование
			Font = Enum.Font.GothamBold,
		}),
		
		-- ГОРЯЧАЯ КЛАВИША (ПРАВЫЙ ВЕРХНИЙ УГОЛ)
		Hotkey = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.25, 0, 0.22, 0), -- Слегка уменьшаем размер
			Position = UDim2.new(0.72, 0, 0.03, 0), -- Сдвигаем чуть правее и выше
			Text = hotkey,
			TextColor3 = isOnCooldown and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255),
			TextTransparency = isOnCooldown and 0.5 or 0,
			TextSize = 11, -- Слегка уменьшаем размер шрифта
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Font = Enum.Font.GothamBold,
		}),
		
		-- ПРОГРЕСС-БАР ЭФФЕКТА (показывается когда способность активна)
		EffectProgress = self:createProgressBar(ability.id, true),
		
		-- ПРОГРЕСС-БАР КУЛДАУНА (показывается когда способность на кулдауне)
		CooldownProgress = self:createProgressBar(ability.id, false),
	})
end

-- Создает пустой слот для неактивной способности
function AbilityPanel:createEmptySlot(slot, index: number)
	local hotkey = slot.hotkey or "?"
	
	-- Проверяем кулдаун (даже для не купленных способностей)
	local isOnCooldown = self.state.cooldowns[slot.abilityId] or false
	local cooldownTime = self.state.cooldownTimes[slot.abilityId] or 0
	
	-- Улучшенная логика цветов для пустых слотов
	local backgroundColor, strokeColor, strokeThickness
	
	if isOnCooldown then
		-- Не куплена, но попытались использовать (на кулдауне)
		backgroundColor = Color3.fromRGB(80, 40, 40)
		strokeColor = Color3.fromRGB(120, 60, 60)
		strokeThickness = 2
	else
		-- Обычный пустой слот (не куплена)
		backgroundColor = Color3.fromRGB(40, 40, 40)
		strokeColor = Color3.fromRGB(80, 80, 80)
		strokeThickness = 1
	end
	
	-- Создаем ref для анимации пустого слота
	if not self.buttonRefs[slot.abilityId] then
		self.buttonRefs[slot.abilityId] = Roact.createRef()
	end
	
	-- 📱 АДАПТИВНОЕ ПОЗИЦИОНИРОВАНИЕ
	local isMobile = self.platformService:isMobile()
	local position
	if isMobile then
		-- Мобильная версия: вертикальное размещение (Y координата меняется)
		position = UDim2.new(0, 0, 0, (index - 1) * 72)
	else
		-- Десктопная версия: горизонтальное размещение (X координата меняется)
		position = UDim2.new(0, (index - 1) * 72, 0, 0)
	end
	
	return Roact.createElement("TextButton", {
		[Roact.Ref] = self.buttonRefs[slot.abilityId],
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = 0.2, -- Немного прозрачные для индикации
		BorderSizePixel = 0,
		Size = UDim2.new(0, 64, 0, 64),
		Position = position,
		Text = "", -- Убираем текст кнопки
		AutoButtonColor = false,
		Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
		[Roact.Event.Activated] = function()
			-- Вызываем активацию - звук ошибки и уведомление обработаются внутри
			self:onAbilityActivate(slot.abilityId)
		end,
		[Roact.Event.MouseEnter] = function()
			-- Простая анимация hover для пустого слота
			local button = self.buttonRefs[slot.abilityId]:getValue()
			if button then
				self:animateHover(button)
			end
		end,
		[Roact.Event.MouseLeave] = function()
			local button = self.buttonRefs[slot.abilityId]:getValue()
			if button then
				self:animateRelease(button)
			end
		end,
	}, {
		-- Скругления
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		
		-- Обводка для пустых слотов
		Stroke = Roact.createElement("UIStroke", {
			Color = strokeColor,
			Thickness = strokeThickness,
			Transparency = 0.5,
		}),
		
		-- ИКОНКА СПОСОБНОСТИ (ИДЕАЛЬНОЕ ЦЕНТРИРОВАНИЕ)
		Icon = Roact.createElement("TextLabel", {
			Text = slot.icon,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.7, 0, 0.7, 0), -- Увеличиваем размер для лучшей видимости
			Position = UDim2.new(0.15, 0, 0.08, 0), -- Корректируем позицию для центрирования
			AnchorPoint = Vector2.new(0, 0), -- Якорь в левом верхнем углу
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Center, -- Горизонтальное центрирование
			TextYAlignment = Enum.TextYAlignment.Center, -- Вертикальное центрирование
		}),
		
		-- ГОРЯЧАЯ КЛАВИША (ПРАВЫЙ ВЕРХНИЙ УГОЛ)
		Hotkey = Roact.createElement("TextLabel", {
			Text = hotkey,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.25, 0, 0.22, 0), -- Слегка уменьшаем размер
			Position = UDim2.new(0.72, 0, 0.03, 0), -- Сдвигаем чуть правее и выше
			TextSize = 11, -- Слегка уменьшаем размер шрифта
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
		
		-- Замок (если не на кулдауне)
		LockIcon = not isOnCooldown and Roact.createElement("TextLabel", {
			Text = "🔒",
			TextColor3 = Color3.fromRGB(120, 120, 120),
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.3, 0, 0.3, 0),
			Position = UDim2.new(0.35, 0, 0.6, 0),
			TextScaled = true,
		}) or nil,
	})
end

-- Реагируем на изменения пропов (например, после покупки способности)
function AbilityPanel:didUpdate(prevProps)
	if self.props.updateTrigger and prevProps.updateTrigger ~= self.props.updateTrigger then
		-- Обновляем список способностей после покупки
		spawn(function()
			wait(0.1) -- Небольшая задержка для синхронизации
			self:loadAbilities()
			print("AbilityPanel: Обновили список способностей после покупки")
		end)
	end
end

function AbilityPanel:render()
	local abilities = self.state.abilities
	
	-- Всегда показываем 3 слота для базовых способностей (Q, E, R)
	local baseAbilitySlots = {
		{hotkey = "Q", abilityId = "speed_boost", icon = "⚡", name = "Ускорение"},
		{hotkey = "E", abilityId = "shield_aura", icon = "🛡", name = "Щит"},
		{hotkey = "R", abilityId = "jump_boost", icon = "🚀", name = "Прыжок"},
	}
	
	-- 📱 АДАПТИВНАЯ ЛОГИКА РАЗМЕЩЕНИЯ
	local isMobile = self.platformService:isMobile()
	
	local buttonSize = 64
	local spacing = 72  -- Общий spacing (64 размер кнопки + 8 отступ)
	
	-- Для мобильных - вертикальное размещение, для десктопа - горизонтальное
	local totalWidth, totalHeight
	if isMobile then
		-- Мобильная версия: вертикальный столбец
		totalWidth = buttonSize
		totalHeight = (#baseAbilitySlots - 1) * spacing + buttonSize
	else
		-- Десктопная версия: горизонтальная полоса
		totalWidth = (#baseAbilitySlots - 1) * spacing + buttonSize
		totalHeight = buttonSize
	end
	
	local abilityButtons = {}
	for i, slot in ipairs(baseAbilitySlots) do
		-- Ищем способность в списке купленных
		local ownedAbility = nil
		for _, ability in ipairs(abilities) do
			if ability.id == slot.abilityId then
				ownedAbility = ability
				break
			end
		end
		
		if ownedAbility then
			-- Способность куплена - показываем активную кнопку
			abilityButtons["Ability" .. i] = self:createSimpleButton(ownedAbility, i)
		else
			-- Способность не куплена - показываем пустой слот
			abilityButtons["Ability" .. i] = self:createEmptySlot(slot, i)
		end
	end
	
	return Roact.createElement("ScreenGui", {
		Name = "AbilityPanel",
		ResetOnSpawn = false,
	}, {
		-- ОБЫЧНАЯ ПАНЕЛЬ (БЕЗ АНИМАЦИИ)
		MainBar = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(28, 28, 30), -- Темно-серый Apple style
			BackgroundTransparency = 0.05, -- Почти непрозрачный
			BorderSizePixel = 0,
			Size = UDim2.new(0, totalWidth + 16, 0, totalHeight + 16),
			Position = isMobile and 
				UDim2.new(1, -(totalWidth + 16 + 20), 0.3, -(totalHeight + 16) / 2) or -- Мобильная: правый край, выше центра
				UDim2.new(0.5, -(totalWidth + 16) / 2, 1, -totalHeight - 32), -- Десктопная: снизу по центру
		}, {
			-- СОВРЕМЕННОЕ СКРУГЛЕНИЕ
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 16),
			}),
			
			-- ПРОФЕССИОНАЛЬНАЯ ТЕНЬ ПАНЕЛИ
			Shadow = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.8,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 6, 1, 6),
				Position = UDim2.new(0, -3, 0, 3),
				ZIndex = -1,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 19),
				}),
			}),
			
			-- СТИЛЬНАЯ РАМКА КАК У МАГАЗИНА (ИЗ SHOPCONFIG)
			Border = Roact.createElement("UIStroke", {
				Color = ShopConfig.design.colors.accent.primary, -- Синий акцент из ShopConfig
				Thickness = ShopConfig.design.stroke.thickness, -- Унифицированная толщина
				Transparency = 0.3, -- Менее прозрачная для лучшей видимости
			}),
			
			-- КОНТЕЙНЕР КНОПОК
			ButtonContainer = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -16, 1, -16),
				Position = UDim2.new(0, 8, 0, 8),
			}, abilityButtons),
		}),
	})
end

-- Получает конфигурацию способности из AbilityConfig
function AbilityPanel:getAbilityConfig(abilityId: string)
	local allAbilities = AbilityConfig.getAllAbilities()
	for _, config in ipairs(allAbilities) do
		if config.id == abilityId then
			return config
		end
	end
	return nil
end

function AbilityPanel:willUnmount()
	-- Останавливаем оптимизированные обновления
	self.updateConnection = false
	
	-- Отключаем старое соединение Heartbeat (если оно есть)
	if self.heartbeatConnection then
		self.heartbeatConnection:Disconnect()
		self.heartbeatConnection = nil
	end
end

return AbilityPanel
