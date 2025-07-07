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

-- Типы и конфигурация
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
local ShopConfig = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ShopConfig"))
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

-- Современная информация о твинах
local TWEEN_INFO = {
	HOVER = TweenInfo.new(ShopConfig.design.animations.duration, ShopConfig.design.animations.easing),
	PRESS = TweenInfo.new(0.1, ShopConfig.design.animations.easing),
	COOLDOWN = TweenInfo.new(0.3, ShopConfig.design.animations.easing),
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
	
	-- Выбираем современные цвета в зависимости от состояния
	local backgroundColor = ShopConfig.design.colors.button.primary
	local textColor = ShopConfig.design.colors.text.button
	
	if not props.isOwned then
		backgroundColor = ShopConfig.design.colors.button.disabled
		textColor = ShopConfig.design.colors.text.secondary
	elseif props.isOnCooldown then
		backgroundColor = ShopConfig.design.colors.button.disabled
		textColor = ShopConfig.design.colors.text.disabled
	elseif isActive then
		backgroundColor = ShopConfig.design.colors.button.success
		textColor = ShopConfig.design.colors.text.button
	elseif state.isHovering and props.isOwned and not props.isOnCooldown then
		backgroundColor = Color3.new(
			math.min(1, ShopConfig.design.colors.button.primary.R * 1.1),
			math.min(1, ShopConfig.design.colors.button.primary.G * 1.1),
			math.min(1, ShopConfig.design.colors.button.primary.B * 1.1)
		)
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
		Modal = true, -- ДОБАВЛЕНО: отключаем стандартные звуки Roblox
		
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
		-- Современное скругление
		UICorner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.button),
		}),
		
		-- Современный градиент (для активных способностей)
		UIGradient = isActive and Roact.createElement("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ShopConfig.design.colors.button.success),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(
					math.max(0, ShopConfig.design.colors.button.success.R * 255 - 30) / 255,
					math.max(0, ShopConfig.design.colors.button.success.G * 255 - 30) / 255,
					math.max(0, ShopConfig.design.colors.button.success.B * 255 - 30) / 255
				)),
			}),
			Rotation = 45,
		}) or nil,
		
		-- Современный основной текст способности
		NameLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, isMobile and 36 or 32),
			Position = UDim2.new(0, 10, 0, isMobile and 10 or 8),
			BackgroundTransparency = 1,
			Text = buttonText,
			TextColor3 = textColor,
			TextSize = isMobile and 20 or 18,
			Font = ShopConfig.design.colors.text.fonts.bold,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
		}),
		
		-- Современное описание способности
		DescriptionLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, isMobile and 24 or 20),
			Position = UDim2.new(0, 10, 0, isMobile and 42 or 35),
			BackgroundTransparency = 1,
			Text = ability.description,
			TextColor3 = ShopConfig.design.colors.text.secondary,
			TextSize = isMobile and 14 or 12,
			Font = ShopConfig.design.colors.text.fonts.regular,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
		}),
		
		-- Современный статус (цена, кулдаун, активность)
		StatusLabel = statusText ~= "" and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -20, 0, isMobile and 20 or 16),
			Position = UDim2.new(0, 10, 1, isMobile and -28 or -24),
			BackgroundTransparency = 1,
			Text = statusText,
			TextColor3 = not props.isOwned and ShopConfig.design.colors.text.accent or 
						 props.isOnCooldown and ShopConfig.design.colors.text.disabled or
						 isActive and ShopConfig.design.colors.status.success or
						 textColor,
			TextSize = isMobile and 16 or 14,
			Font = ShopConfig.design.colors.text.fonts.bold,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
		}) or nil,
		
		-- Современный прогресс-бар кулдауна
		CooldownBar = props.isOnCooldown and props.cooldownTimeLeft and Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			Position = UDim2.new(0, 0, 1, -3),
			BackgroundColor3 = ShopConfig.design.colors.status.error,
			BorderSizePixel = 0,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}),
			
			-- Современный прогресс кулдауна
			Progress = Roact.createElement("Frame", {
				Size = UDim2.new(math.max(0, props.cooldownTimeLeft / 8), 0, 1, 0), -- Примерный максимальный кулдаун 8 сек
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = ShopConfig.design.colors.accent.primary,
				BorderSizePixel = 0,
			}, {
				UICorner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}),
			}),
		}) or nil,
		
		-- Современный эффект свечения для активных способностей
		GlowEffect = isActive and Roact.createElement("Frame", {
			Size = UDim2.new(1, 4, 1, 4),
			Position = UDim2.new(0, -2, 0, -2),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = -1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, ShopConfig.design.borderRadius.button + 2),
			}),
			
			UIStroke = Roact.createElement("UIStroke", {
				Color = ShopConfig.design.colors.accent.primary,
				Thickness = ShopConfig.design.stroke.thickness,
				Transparency = 0.3,
			}),
		}) or nil,
	})
end

return AbilityButton

