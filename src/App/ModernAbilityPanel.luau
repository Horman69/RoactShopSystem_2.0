--!strict
-- src/App/ModernAbilityPanel.luau
-- Современная нижняя панель способностей

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Импортируем зависимости
local ModuleLoader = require(ReplicatedStorage:WaitForChild("shared"):WaitForChild("ModuleLoader"))
local Roact = ModuleLoader.require("Packages/roact")
local ModernAbilityButton = ModuleLoader.require("App/ModernAbilityButton")
local AbilityService = ModuleLoader.require("services/AbilityService")

local ModernAbilityPanel = Roact.Component:extend("ModernAbilityPanel")

function ModernAbilityPanel:init()
	-- Создаем сервис способностей
	self.abilityService = AbilityService.new()
	
	self.state = {
		abilities = {},
		cooldowns = {},
		activeEffects = {},
		cooldownTimes = {}, -- Оставшееся время кулдауна
		isVisible = true,
	}
	
	-- Обновляем состояние каждые 0.1 секунды для плавного прогресса
	spawn(function()
		while true do
			wait(0.1)
			self:updateState()
		end
	end)
	
	-- Загружаем способности
	spawn(function()
		wait(2) -- Ждем инициализации сервиса
		self:loadAbilities()
	end)
end

function ModernAbilityPanel:loadAbilities()
	local player = Players.LocalPlayer
	if not player then return end
	
	-- Получаем список способностей игрока
	local abilities = self.abilityService:getPlayerAbilities(player)
	
	self:setState({
		abilities = abilities
	})
end

function ModernAbilityPanel:updateState()
	local player = Players.LocalPlayer
	if not player then return end
	
	-- Получаем текущие кулдауны и активные эффекты
	local cooldowns = {}
	local cooldownTimes = {}
	local activeEffects = self.abilityService:getActiveEffects(player)
	
	for _, ability in ipairs(self.state.abilities) do
		local isOnCooldown = self.abilityService:isAbilityOnCooldown(player, ability.id)
		local timeLeft = self.abilityService:getCooldownTimeLeft(player, ability.id)
		
		cooldowns[ability.id] = isOnCooldown
		cooldownTimes[ability.id] = timeLeft
	end
	
	self:setState({
		cooldowns = cooldowns,
		cooldownTimes = cooldownTimes,
		activeEffects = activeEffects,
	})
end

function ModernAbilityPanel:onAbilityActivate(abilityId: string)
	local player = Players.LocalPlayer
	if not player then return end
	
	-- Активируем способность
	local result = self.abilityService:activateAbility(player, abilityId)
	
	if result.success then
		print("✅", result.message)
		-- Можно добавить звуковой эффект или анимацию
	else
		warn("❌", result.message)
	end
	
	-- Обновляем состояние
	self:updateState()
end

function ModernAbilityPanel:togglePanel()
	self:setState({
		isVisible = not self.state.isVisible
	})
end

function ModernAbilityPanel:render()
	local abilities = self.state.abilities
	
	if not self.state.isVisible then
		-- Минималистичная кнопка для открытия панели
		return Roact.createElement("ScreenGui", {
			Name = "ModernAbilityUI",
			ResetOnSpawn = false,
		}, {
			ToggleButton = Roact.createElement("TextButton", {
				BackgroundColor3 = Color3.fromRGB(33, 37, 41),
				BorderSizePixel = 0,
				Size = UDim2.new(0, 50, 0, 50),
				Position = UDim2.new(1, -70, 1, -70),
				Text = "⚡",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 24,
				Font = Enum.Font.SourceSansBold,
				
				[Roact.Event.MouseButton1Click] = function()
					self:togglePanel()
				end,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 25),
				}),
				Border = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(64, 224, 255),
					Thickness = 2,
				}),
			})
		})
	end
	
	-- Создаем кнопки для способностей
	local abilityButtons = {}
	local buttonSpacing = 90 -- Расстояние между кнопками
	local startX = (#abilities * buttonSpacing) / -2 + 45 -- Центрируем кнопки
	
	for i, ability in ipairs(abilities) do
		local isOnCooldown = self.state.cooldowns[ability.id] or false
		local isActive = self.state.activeEffects[ability.id] ~= nil
		local cooldownTime = self.state.cooldownTimes[ability.id] or 0
		local cooldownProgress = 1 - (cooldownTime / 30) -- 30 секунд общий кулдаун
		
		abilityButtons["Ability" .. i] = Roact.createElement(ModernAbilityButton, {
			ability = ability,
			isOnCooldown = isOnCooldown,
			isActive = isActive,
			cooldownProgress = cooldownProgress,
			onActivate = function(abilityId)
				self:onAbilityActivate(abilityId)
			end,
			position = UDim2.new(0.5, startX + (i - 1) * buttonSpacing, 0, 10),
			size = UDim2.new(0, 80, 0, 80),
		})
	end
	
	-- Добавляем кнопку сворачивания
	abilityButtons.ToggleButton = Roact.createElement("TextButton", {
		BackgroundColor3 = Color3.fromRGB(52, 58, 64),
		BorderSizePixel = 0,
		Size = UDim2.new(0, 30, 0, 30),
		Position = UDim2.new(1, -40, 0, 10),
		Text = "−",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		Font = Enum.Font.SourceSansBold,
		
		[Roact.Event.MouseButton1Click] = function()
			self:togglePanel()
		end,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 15),
		}),
	})
	
	return Roact.createElement("ScreenGui", {
		Name = "ModernAbilityUI",
		ResetOnSpawn = false,
	}, {
		-- Нижняя панель
		BottomPanel = Roact.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(23, 27, 31),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 100),
			Position = UDim2.new(0, 0, 1, -100),
		}, {
			-- Скругленные верхние углы
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 20),
			}),
			
			-- Верхняя рамка
			TopBorder = Roact.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(64, 224, 255),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 3),
				Position = UDim2.new(0, 0, 0, 0),
			}),
			
			-- Полупрозрачный градиент
			Gradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(33, 37, 41)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(23, 27, 31)),
				}),
				Rotation = 90,
			}),
			
			-- Контейнер для кнопок
			ButtonContainer = Roact.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
			}, abilityButtons),
		})
	})
end

return ModernAbilityPanel
