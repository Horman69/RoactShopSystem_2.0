--!strict
-- src/App/EffectDisplay.luau
-- Компонент для отображения активных эффектов способностей
-- Показывает иконки и оставшееся время

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local AbilityConfig = ModuleLoader.require("shared/AbilityConfig")

-- Импортируем типы
local Types = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("Types"))
type ActiveEffect = Types.ActiveEffect

-- Пропсы компонента
type EffectDisplayProps = {
	activeEffects: {[string]: ActiveEffect},
	position: UDim2?,
	size: UDim2?,
}

-- Стиль отображения эффектов
local EFFECT_STYLE = {
	BACKGROUND_COLOR = Color3.fromRGB(30, 30, 30),
	BORDER_COLOR = Color3.fromRGB(0, 170, 255),
	TEXT_COLOR = Color3.fromRGB(255, 255, 255),
	TIME_COLOR = Color3.fromRGB(255, 215, 0),
	ICON_SIZE = 32,
	PADDING = 8,
}

local EffectDisplay = Roact.Component:extend("EffectDisplay")

function EffectDisplay:init()
	self:setState({
		currentTime = tick(),
	})
	
	-- Обновляем время каждую секунду
	self.timeConnection = RunService.Heartbeat:Connect(function()
		if tick() % 0.1 < 0.05 then -- Обновляем каждые 0.1 секунды для плавности
			self:setState({
				currentTime = tick(),
			})
		end
	end)
end

function EffectDisplay:willUnmount()
	if self.timeConnection then
		self.timeConnection:Disconnect()
	end
end

function EffectDisplay:render()
	local props = self.props
	local state = self.state
	local activeEffects = props.activeEffects
	
	-- Создаем список эффектов для отображения
	local effectElements = {}
	local effectCount = 0
	
	for abilityId, effect in pairs(activeEffects) do
		local ability = AbilityConfig.getAbilityById(abilityId)
		if ability then
			local timeLeft = effect.startTime + effect.duration - state.currentTime
			
			if timeLeft > 0 then
				effectCount = effectCount + 1
				
				-- Создаем элемент эффекта
				effectElements["Effect_" .. abilityId] = Roact.createElement("Frame", {
					Size = UDim2.new(0, 120, 0, 40),
					Position = UDim2.new(0, (effectCount - 1) * 130, 0, 0),
					BackgroundColor3 = EFFECT_STYLE.BACKGROUND_COLOR,
					BorderSizePixel = 1,
					BorderColor3 = EFFECT_STYLE.BORDER_COLOR,
				}, {
					UICorner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 8),
					}),
					
					-- Иконка способности
					Icon = Roact.createElement("TextLabel", {
						Size = UDim2.new(0, EFFECT_STYLE.ICON_SIZE, 0, EFFECT_STYLE.ICON_SIZE),
						Position = UDim2.new(0, 4, 0, 4),
						BackgroundTransparency = 1,
						Text = ability.icon or "✨",
						TextColor3 = EFFECT_STYLE.TEXT_COLOR,
						TextSize = 20,
						Font = Enum.Font.GothamBold,
						TextXAlignment = Enum.TextXAlignment.Center,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
					
					-- Название способности
					Name = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, -45, 0, 16),
						Position = UDim2.new(0, 40, 0, 2),
						BackgroundTransparency = 1,
						Text = ability.name:gsub("🏃 ", ""):gsub("🛡️ ", ""):gsub("⬆️ ", ""), -- Убираем эмодзи из названия
						TextColor3 = EFFECT_STYLE.TEXT_COLOR,
						TextSize = 12,
						Font = Enum.Font.GothamSemibold,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
						TextTruncate = Enum.TextTruncate.AtEnd,
					}),
					
					-- Оставшееся время
					Time = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, -45, 0, 16),
						Position = UDim2.new(0, 40, 0, 18),
						BackgroundTransparency = 1,
						Text = string.format("%.1f сек", timeLeft),
						TextColor3 = EFFECT_STYLE.TIME_COLOR,
						TextSize = 10,
						Font = Enum.Font.Gotham,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
					
					-- Прогресс-бар времени
					ProgressBar = Roact.createElement("Frame", {
						Size = UDim2.new(1, -8, 0, 2),
						Position = UDim2.new(0, 4, 1, -6),
						BackgroundColor3 = Color3.fromRGB(60, 60, 60),
						BorderSizePixel = 0,
					}, {
						UICorner = Roact.createElement("UICorner", {
							CornerRadius = UDim.new(0, 1),
						}),
						
						Progress = Roact.createElement("Frame", {
							Size = UDim2.new(math.max(0, timeLeft / effect.duration), 0, 1, 0),
							Position = UDim2.new(0, 0, 0, 0),
							BackgroundColor3 = EFFECT_STYLE.BORDER_COLOR,
							BorderSizePixel = 0,
						}, {
							UICorner = Roact.createElement("UICorner", {
								CornerRadius = UDim.new(0, 1),
							}),
						}),
					}),
				})
			end
		end
	end
	
	-- Если нет активных эффектов, не отображаем панель
	if effectCount == 0 then
		return Roact.createElement("Frame", {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
		})
	end
	
	-- Заголовок панели
	effectElements.Header = Roact.createElement("TextLabel", {
		Size = UDim2.new(0, effectCount * 130, 0, 20),
		Position = UDim2.new(0, 0, 0, -25),
		BackgroundTransparency = 1,
		Text = "✨ Активные эффекты:",
		TextColor3 = EFFECT_STYLE.TEXT_COLOR,
		TextSize = 14,
		Font = Enum.Font.GothamSemibold,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	
	return Roact.createElement("Frame", {
		Size = props.size or UDim2.new(0, effectCount * 130, 0, 40),
		Position = props.position or UDim2.new(0, 20, 0, 220),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, effectElements)
end

return EffectDisplay
