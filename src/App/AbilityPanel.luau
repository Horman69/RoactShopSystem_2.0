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
local SoundService = ModuleLoader.require("services/SoundService")

local AbilityPanel = Roact.Component:extend("AbilityPanel")

function AbilityPanel:init()
	self.abilityService = AbilityService.new()
	self.soundService = SoundService.new()
	
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
		wait(0.1) -- Минимальная задержка для стабильности
		self:loadAbilities()
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

function AbilityPanel:loadAbilities()
	local player = Players.LocalPlayer
	if not player then return end
	
	local abilities = self.abilityService:getPlayerAbilities(player)
	self:setState({ abilities = abilities })
end

function AbilityPanel:updateState()
	local player = Players.LocalPlayer
	if not player then return end
	
	local cooldowns = {}
	local cooldownTimes = {}
	local activeEffects = self.abilityService:getActiveEffects(player)
	
	-- Проверяем кулдауны для всех базовых способностей (даже не купленных)
	local baseAbilities = {"speed_boost", "shield_aura", "jump_boost"}
	
	for _, abilityId in ipairs(baseAbilities) do
		local isOnCooldown = self.abilityService:isAbilityOnCooldown(player, abilityId)
		local wasOnCooldown = self.previousCooldowns[abilityId] or false
		
		cooldowns[abilityId] = isOnCooldown
		
		-- Проверяем, закончился ли кулдаун (был на кулдауне, теперь нет)
		if wasOnCooldown and not isOnCooldown then
			-- Кулдаун закончился - воспроизводим звук
			if self.soundService then
				self.soundService:playCooldownFinishedSound()
			end
			print("AbilityPanel: Кулдаун способности", abilityId, "закончился!")
		end
		
		if isOnCooldown then
			cooldownTimes[abilityId] = self.abilityService:getCooldownTimeLeft(player, abilityId)
		end
	end
	
	-- Также проверяем купленные способности (для особых способностей в будущем)
	for _, ability in ipairs(self.state.abilities) do
		local isOnCooldown = self.abilityService:isAbilityOnCooldown(player, ability.id)
		local wasOnCooldown = self.previousCooldowns[ability.id] or false
		
		cooldowns[ability.id] = isOnCooldown
		
		-- Проверяем окончание кулдауна
		if wasOnCooldown and not isOnCooldown then
			if self.soundService then
				self.soundService:playCooldownFinishedSound()
			end
			print("AbilityPanel: Кулдаун способности", ability.id, "закончился!")
		end
		
		if isOnCooldown then
			cooldownTimes[ability.id] = self.abilityService:getCooldownTimeLeft(player, ability.id)
		end
	end
	
	-- Сохраняем текущие состояния для следующего обновления
	self.previousCooldowns = cooldowns
	
	self:setState({
		cooldowns = cooldowns,
		activeEffects = activeEffects,
		cooldownTimes = cooldownTimes,
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
		
		-- Неудачная активация - воспроизводим звук ошибки и показываем уведомление
		if self.soundService then
			self.soundService:playAbilityCooldownSound()
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
	
	-- ОБЫЧНАЯ КНОПКА С ПРОСТЫМИ АНИМАЦИЯМИ (БЕЗ ЛИШНЕГО FRAME)
	return Roact.createElement("TextButton", {
		[Roact.Ref] = self.buttonRefs[ability.id],
		BackgroundColor3 = buttonColor,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 64, 0, 64),
		Position = UDim2.new(0, (index - 1) * 72, 0, 0),
		Text = "",
		AutoButtonColor = false,
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
		
		-- ИКОНКА СПОСОБНОСТИ (ЦЕНТР) - цвет зависит от состояния
		Icon = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.6, 0, 0.6, 0),
			Position = UDim2.new(0.2, 0, 0.1, 0),
			Text = config.icon,
			TextColor3 = isOnCooldown and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255),
			TextTransparency = isOnCooldown and 0.5 or 0,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
		}),
		
		-- ГОРЯЧАЯ КЛАВИША (ПРАВЫЙ ВЕРХНИЙ УГОЛ)
		Hotkey = Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.3, 0, 0.25, 0),
			Position = UDim2.new(0.7, 0, 0.05, 0),
			Text = hotkey,
			TextColor3 = isOnCooldown and Color3.fromRGB(150, 150, 150) or Color3.fromRGB(255, 255, 255),
			TextTransparency = isOnCooldown and 0.5 or 0,
			TextSize = 12,
			Font = Enum.Font.GothamBold,
		}),
		
		-- ТАЙМЕР КУЛДАУНА (ЦЕНТР, ПОВЕРХ ИКОНКИ)
		Timer = isOnCooldown and Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.8, 0, 0.4, 0),
			Position = UDim2.new(0.1, 0, 0.4, 0),
			Text = tostring(math.ceil(cooldownTime)),
			TextColor3 = Color3.fromRGB(255, 100, 100), -- Красный цвет для кулдауна
			TextSize = 16,
			Font = Enum.Font.GothamBold,
			TextStrokeTransparency = 0,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = 5,
		}) or nil,
		
		-- ИНДИКАТОР АКТИВНОСТИ (если способность активна)
		ActiveIndicator = isActive and Roact.createElement("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(0.4, 0, 0.3, 0),
			Position = UDim2.new(0.3, 0, 0.65, 0),
			Text = "ON",
			TextColor3 = Color3.fromRGB(0, 255, 100), -- Зеленый цвет для активности
			TextSize = 10,
			Font = Enum.Font.GothamBold,
			TextStrokeTransparency = 0,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = 5,
		}) or nil,
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
	
	return Roact.createElement("TextButton", {
		[Roact.Ref] = self.buttonRefs[slot.abilityId],
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = 0.2, -- Немного прозрачные для индикации
		BorderSizePixel = 0,
		Size = UDim2.new(0, 64, 0, 64),
		Position = UDim2.new(0, (index - 1) * 72, 0, 0),
		Text = "", -- Убираем текст кнопки
		AutoButtonColor = false,
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
		
		-- Иконка способности (центр)
		Icon = Roact.createElement("TextLabel", {
			Text = slot.icon,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.6, 0, 0.6, 0),
			Position = UDim2.new(0.2, 0, 0.1, 0),
			TextScaled = true,
		}),
		
		-- Горячая клавиша (правый верхний угол)
		Hotkey = Roact.createElement("TextLabel", {
			Text = hotkey,
			TextColor3 = Color3.fromRGB(150, 150, 150),
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.3, 0, 0.25, 0),
			Position = UDim2.new(0.7, 0, 0.05, 0),
			TextSize = 12,
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
		
		-- Таймер кулдауна (центр)
		Timer = isOnCooldown and Roact.createElement("TextLabel", {
			Text = tostring(math.ceil(cooldownTime)),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.8, 0, 0.4, 0),
			Position = UDim2.new(0.1, 0, 0.4, 0),
			TextSize = 16,
			TextStrokeTransparency = 0,
			TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
			ZIndex = 5,
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
	
	local buttonSize = 64
	local spacing = 72  -- Общий spacing (64 размер кнопки + 8 отступ)
	local totalWidth = (#baseAbilitySlots - 1) * spacing + buttonSize  -- Последняя кнопка без spacing
	local totalHeight = buttonSize
	
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
			Position = UDim2.new(0.5, -(totalWidth + 16) / 2, 1, -totalHeight - 32),
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
			
			-- ТОНКАЯ РАМКА (ПРОФЕССИОНАЛЬНО)
			Border = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(60, 60, 60),
				Thickness = 1,
				Transparency = 0.5,
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

return AbilityPanel
