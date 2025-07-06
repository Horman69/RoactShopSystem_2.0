--!strict
-- src/App/AbilityButton.luau
-- Переиспользуемая кнопка способности с кулдауном и анимациями
-- Соответствует стилю проекта

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local PlatformService = ModuleLoader.require("services/PlatformService")

-- Импортируем типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type Ability = Types.Ability

-- Пропсы компонента
type AbilityButtonProps = {
	ability: Ability,
	isOwned: boolean,
	isOnCooldown: boolean,
	cooldownTimeLeft: number?,
	isActive: boolean?, -- Есть ли активный эффект
	onActivate: (abilityId: string) -> (),
	onPurchase: ((ability: Ability) -> ())?,
	position: UDim2?,
	size: UDim2?,
}

-- Стиль кнопки (в едином стиле проекта)
local BUTTON_STYLE = {
	-- Основные цвета
	BACKGROUND_DEFAULT = Color3.fromRGB(40, 44, 52),
	BACKGROUND_HOVER = Color3.fromRGB(50, 54, 62),
	BACKGROUND_ACTIVE = Color3.fromRGB(0, 170, 255),
	BACKGROUND_COOLDOWN = Color3.fromRGB(25, 25, 25),
	BACKGROUND_NOT_OWNED = Color3.fromRGB(60, 60, 60),
	
	-- Цвета текста
	TEXT_DEFAULT = Color3.fromRGB(255, 255, 255),
	TEXT_COOLDOWN = Color3.fromRGB(150, 150, 150),
	TEXT_NOT_OWNED = Color3.fromRGB(200, 200, 200),
	TEXT_ACTIVE = Color3.fromRGB(255, 255, 255),
	
	-- Акцентные цвета
	ACCENT_BLUE = Color3.fromRGB(0, 170, 255),
	ACCENT_GREEN = Color3.fromRGB(0, 200, 120),
	ACCENT_RED = Color3.fromRGB(255, 100, 100),
	ACCENT_GOLD = Color3.fromRGB(255, 215, 0),
}

-- Информация о твинах
local TWEEN_INFO = {
	HOVER = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	PRESS = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	COOLDOWN = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
}

local AbilityButton = Roact.Component:extend("AbilityButton")

function AbilityButton:init()
	self:setState({
		isHovering = false,
		isPressing = false,
	})
	
	-- Инициализируем PlatformService
	self.platformService = PlatformService.new()
end

function AbilityButton:render()
	local props = self.props
	local state = self.state
	local ability = props.ability
	
	-- Получаем адаптивные размеры
	local isMobile = self.platformService:isMobile()
	local scaleFactor = self.platformService:getScaleFactor()
	
	-- Определяем состояние кнопки
	local isDisabled = props.isOnCooldown or not props.isOwned
	local isActive = props.isActive or false
	
	-- Выбираем цвета в зависимости от состояния
	local backgroundColor = BUTTON_STYLE.BACKGROUND_DEFAULT
	local textColor = BUTTON_STYLE.TEXT_DEFAULT
	
	if not props.isOwned then
		backgroundColor = BUTTON_STYLE.BACKGROUND_NOT_OWNED
		textColor = BUTTON_STYLE.TEXT_NOT_OWNED
	elseif props.isOnCooldown then
		backgroundColor = BUTTON_STYLE.BACKGROUND_COOLDOWN
		textColor = BUTTON_STYLE.TEXT_COOLDOWN
	elseif isActive then
		backgroundColor = BUTTON_STYLE.BACKGROUND_ACTIVE
		textColor = BUTTON_STYLE.TEXT_ACTIVE
	elseif state.isHovering and props.isOwned and not props.isOnCooldown then
		backgroundColor = BUTTON_STYLE.BACKGROUND_HOVER
	end
	
	-- Формируем текст кнопки
	local buttonText = ability.icon and (ability.icon .. " " .. ability.name) or ability.name
	local statusText = ""
	
	if not props.isOwned then
		statusText = string.format("💰 %d монет", ability.price)
	elseif props.isOnCooldown and props.cooldownTimeLeft then
		statusText = string.format("⏰ %.1f сек", props.cooldownTimeLeft)
	elseif isActive then
		statusText = "✨ Активно"
	end
	
	return Roact.createElement("TextButton", {
		Size = props.size or UDim2.new(0, isMobile and 280 or 200, 0, isMobile and 100 or 80),
		Position = props.position or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = backgroundColor,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		
		-- События мыши
		[Roact.Event.MouseEnter] = function()
			self:setState({ isHovering = true })
		end,
		
		[Roact.Event.MouseLeave] = function()
			self:setState({ isHovering = false, isPressing = false })
		end,
		
		[Roact.Event.MouseButton1Down] = function()
			if not isDisabled then
				self:setState({ isPressing = true })
			end
		end,
		
		[Roact.Event.MouseButton1Up] = function()
			self:setState({ isPressing = false })
		end,
		
		[Roact.Event.MouseButton1Click] = function()
			if not isDisabled then
				if props.isOwned then
					props.onActivate(ability.id)
				elseif props.onPurchase then
					props.onPurchase(ability)
				end
			end
		end,
		
		-- Touch events для мобильных устройств
		[Roact.Event.TouchTap] = function()
			if not isDisabled then
				if props.isOwned then
					props.onActivate(ability.id)
				elseif props.onPurchase then
					props.onPurchase(ability)
				end
			end
		end,
	}, {
		-- Скругленные углы
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 12),
		}),
		
		-- Градиент (опционально для активных способностей)
		UIGradient = isActive and Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 140, 200)),
			}),
			Rotation = 45,
		}) or nil,
		
		-- Основной текст способности
		NameLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, isMobile and 36 or 32),
			Position = UDim2.new(0, 10, 0, isMobile and 10 or 8),
			BackgroundTransparency = 1,
			Text = buttonText,
			TextColor3 = textColor,
			TextSize = isMobile and 20 or 18,
			Font = Enum.Font.GothamSemibold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
		
		-- Описание способности
		DescriptionLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, isMobile and 24 or 20),
			Position = UDim2.new(0, 10, 0, isMobile and 42 or 35),
			BackgroundTransparency = 1,
			Text = ability.description,
			TextColor3 = Color3.fromRGB(180, 180, 180),
			TextSize = isMobile and 14 or 12,
			Font = Enum.Font.Gotham,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		}),
		
		-- Статус (цена, кулдаун, активность)
		StatusLabel = statusText ~= "" and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, isMobile and 20 or 16),
			Position = UDim2.new(0, 10, 1, isMobile and -28 or -24),
			BackgroundTransparency = 1,
			Text = statusText,
			TextColor3 = not props.isOwned and BUTTON_STYLE.ACCENT_GOLD or 
						 props.isOnCooldown and BUTTON_STYLE.TEXT_COOLDOWN or
						 isActive and BUTTON_STYLE.ACCENT_GREEN or
						 textColor,
			TextSize = isMobile and 16 or 14,
			Font = Enum.Font.GothamBold,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
		}) or nil,
		
		-- Прогресс-бар кулдауна
		CooldownBar = props.isOnCooldown and props.cooldownTimeLeft and Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, -3),
			BackgroundColor3 = BUTTON_STYLE.ACCENT_RED,
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
			
			-- Прогресс кулдауна
			Progress = Roact.createElement("Frame", {
				Size = UDim2.new(math.max(0, props.cooldownTimeLeft / 8), 0, 1, 0), -- Примерный максимальный кулдаун 8 сек
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = BUTTON_STYLE.ACCENT_BLUE,
				BorderSizePixel = 0,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
		}) or nil,
		
		-- Эффект свечения для активных способностей
		GlowEffect = isActive and Roact.createElement("Frame", {
			Size = UDim2.new(1, 4, 1, 4),
			Position = UDim2.new(0, -2, 0, -2),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 14),
			}),
			
			UIStroke = Roact.createElement("UIStroke", {
				Color = BUTTON_STYLE.ACCENT_BLUE,
				Thickness = 2,
				Transparency = 0.3,
			}),
		}) or nil,
	})
end

return AbilityButton
