--!strict
-- src/services/AnimationService.luau
-- Центральный сервис анимаций для всего приложения
-- Обеспечивает единообразные, плавные анимации с профессиональным подходом

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Предустановленные конфигурации анимаций
local ANIMATION_PRESETS = {
	-- БЫСТРЫЕ АНИМАЦИИ (UI отклик)
	QUICK = {
		duration = 0.15,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	
	-- СТАНДАРТНЫЕ АНИМАЦИИ (основные переходы)
	STANDARD = {
		duration = 0.3,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	
	-- ПЛАВНЫЕ АНИМАЦИИ (входы/выходы)
	SMOOTH = {
		duration = 0.4,
		easing = Enum.EasingStyle.Sine,
		direction = Enum.EasingDirection.Out,
	},
	
	-- УПРУГИЕ АНИМАЦИИ (кнопки, интерактивные элементы)
	BOUNCY = {
		duration = 0.5,
		easing = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	},
	
	-- ЭЛАСТИЧНЫЕ АНИМАЦИИ (эффектные появления)
	ELASTIC = {
		duration = 0.8,
		easing = Enum.EasingStyle.Elastic,
		direction = Enum.EasingDirection.Out,
	},
}

-- Специальные анимации для конкретных элементов
local ELEMENT_ANIMATIONS = {
	-- МАГАЗИН
	SHOP_OPEN = {
		duration = 0.4,
		easing = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
		scale = {from = Vector3.new(0.8, 0.8, 1), to = Vector3.new(1, 1, 1)},
		transparency = {from = 1, to = 0},
		position = {offset = UDim2.new(0, 0, 0, 20)}, -- сдвиг снизу
	},
	
	SHOP_CLOSE = {
		duration = 0.25,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.In,
		scale = {from = Vector3.new(1, 1, 1), to = Vector3.new(0.9, 0.9, 1)},
		transparency = {from = 0, to = 1},
	},
	
	-- КНОПКИ
	BUTTON_HOVER = {
		duration = 0.15,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
		scale = {from = Vector3.new(1, 1, 1), to = Vector3.new(1.05, 1.05, 1)},
	},
	
	BUTTON_PRESS = {
		duration = 0.1,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
		scale = {from = Vector3.new(1.05, 1.05, 1), to = Vector3.new(0.95, 0.95, 1)},
	},
	
	BUTTON_RELEASE = {
		duration = 0.2,
		easing = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
		scale = {from = Vector3.new(0.95, 0.95, 1), to = Vector3.new(1, 1, 1)},
	},
	
	-- ПАНЕЛЬ СПОСОБНОСТЕЙ
	ABILITY_ACTIVATE = {
		duration = 0.3,
		easing = Enum.EasingStyle.Elastic,
		direction = Enum.EasingDirection.Out,
		scale = {from = Vector3.new(1, 1, 1), to = Vector3.new(1.2, 1.2, 1), back_to = Vector3.new(1, 1, 1)},
	},
	
	-- ПОЯВЛЕНИЕ ЭЛЕМЕНТОВ
	FADE_IN = {
		duration = 0.3,
		easing = Enum.EasingStyle.Sine,
		direction = Enum.EasingDirection.Out,
		transparency = {from = 1, to = 0},
		position = {offset = UDim2.new(0, 0, 0, 15)},
	},
	
	SLIDE_IN_LEFT = {
		duration = 0.4,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
		position = {offset = UDim2.new(0, -50, 0, 0)},
		transparency = {from = 1, to = 0},
	},
	
	SLIDE_IN_BOTTOM = {
		duration = 0.5,
		easing = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
		position = {offset = UDim2.new(0, 0, 0, 50)}, -- сдвиг снизу
		transparency = {from = 1, to = 0},
		scale = {from = Vector3.new(0.9, 0.9, 1), to = Vector3.new(1, 1, 1)},
	},
}

-- Интерфейс сервиса анимаций
type AnimationServiceInterface = {
	-- Основные методы
	tweenElement: (self: AnimationServiceInterface, element: GuiObject, animationType: string, onComplete: (() -> ())?) -> Tween?,
	tweenCustom: (self: AnimationServiceInterface, element: GuiObject, properties: {[string]: any}, preset: string?, onComplete: (() -> ())?) -> Tween?,
	
	-- Специализированные анимации
	animateShopOpen: (self: AnimationServiceInterface, shopFrame: GuiObject, onComplete: (() -> ())?) -> (),
	animateShopClose: (self: AnimationServiceInterface, shopFrame: GuiObject, onComplete: (() -> ())?) -> (),
	animateButtonHover: (self: AnimationServiceInterface, button: GuiObject) -> (),
	animateButtonPress: (self: AnimationServiceInterface, button: GuiObject) -> (),
	animateButtonRelease: (self: AnimationServiceInterface, button: GuiObject) -> (),
	animateAbilityActivation: (self: AnimationServiceInterface, abilityButton: GuiObject) -> (),
	
	-- Групповые анимации
	animateSequence: (self: AnimationServiceInterface, animations: {{element: GuiObject, animationType: string, delay: number?}}, onComplete: (() -> ())?) -> (),
	animateStagger: (self: AnimationServiceInterface, elements: {GuiObject}, animationType: string, staggerDelay: number?, onComplete: (() -> ())?) -> (),
	
	-- Утилиты
	stopAllTweens: (self: AnimationServiceInterface, element: GuiObject) -> (),
	createPreset: (self: AnimationServiceInterface, name: string, config: any) -> (),
}

local AnimationService = {} :: AnimationServiceInterface
AnimationService.__index = AnimationService

-- Активные твины для каждого элемента
local activeTweens: {[GuiObject]: {Tween}} = {}

-- Инициализация сервиса
function AnimationService.new(): AnimationServiceInterface
	local self = setmetatable({}, AnimationService)
	print("AnimationService: Сервис анимаций инициализирован")
	return self
end

-- Основной метод анимации элемента
function AnimationService:tweenElement(element: GuiObject, animationType: string, onComplete: (() -> ())?): Tween?
	local animation = ELEMENT_ANIMATIONS[animationType]
	if not animation then
		warn("AnimationService: Неизвестный тип анимации:", animationType)
		return nil
	end
	
	-- Останавливаем существующие твины
	self:stopAllTweens(element)
	
	local tweenInfo = TweenInfo.new(
		animation.duration,
		animation.easing,
		animation.direction,
		0, -- повторений
		false, -- реверс
		0 -- задержка
	)
	
	-- Сохраняем исходные значения
	local originalPosition = element.Position
	local originalSize = element.Size
	
	-- Подготавливаем свойства для анимации
	local properties = {}
	local setupCallbacks = {}
	
	-- Масштабирование
	if animation.scale then
		if animation.scale.from then
			element.Size = UDim2.new(
				originalSize.X.Scale * animation.scale.from.X,
				originalSize.X.Offset * animation.scale.from.X,
				originalSize.Y.Scale * animation.scale.from.Y,
				originalSize.Y.Offset * animation.scale.from.Y
			)
		end
		
		if animation.scale.to then
			properties.Size = UDim2.new(
				originalSize.X.Scale * animation.scale.to.X,
				originalSize.X.Offset * animation.scale.to.X,
				originalSize.Y.Scale * animation.scale.to.Y,
				originalSize.Y.Offset * animation.scale.to.Y
			)
		end
	end
	
	-- Прозрачность
	if animation.transparency then
		if animation.transparency.from then
			element.BackgroundTransparency = animation.transparency.from
		end
		if animation.transparency.to then
			properties.BackgroundTransparency = animation.transparency.to
		end
	end
	
	-- Позиция
	if animation.position and animation.position.offset then
		properties.Position = UDim2.new(
			originalPosition.X.Scale,
			originalPosition.X.Offset + animation.position.offset.X.Offset,
			originalPosition.Y.Scale,
			originalPosition.Y.Offset + animation.position.offset.Y.Offset
		)
	end
	
	-- Создаём и запускаем твин
	local tween = TweenService:Create(element, tweenInfo, properties)
	
	-- Сохраняем твин
	if not activeTweens[element] then
		activeTweens[element] = {}
	end
	table.insert(activeTweens[element], tween)
	
	-- Обработчик завершения
	tween.Completed:Connect(function()
		-- Удаляем твин из активных
		if activeTweens[element] then
			for i, t in ipairs(activeTweens[element]) do
				if t == tween then
					table.remove(activeTweens[element], i)
					break
				end
			end
		end
		
		-- Обратная анимация (если указана)
		if animation.scale and animation.scale.back_to then
			local backTween = TweenService:Create(element, 
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					Size = UDim2.new(
						originalSize.X.Scale * animation.scale.back_to.X,
						originalSize.X.Offset * animation.scale.back_to.X,
						originalSize.Y.Scale * animation.scale.back_to.Y,
						originalSize.Y.Offset * animation.scale.back_to.Y
					)
				}
			)
			backTween:Play()
		end
		
		-- Колбэк завершения
		if onComplete then
			onComplete()
		end
	end)
	
	tween:Play()
	return tween
end

-- Кастомная анимация с пресетами
function AnimationService:tweenCustom(element: GuiObject, properties: {[string]: any}, preset: string?, onComplete: (() -> ())?): Tween?
	preset = preset or "STANDARD"
	local config = ANIMATION_PRESETS[preset]
	
	if not config then
		warn("AnimationService: Неизвестный пресет:", preset)
		config = ANIMATION_PRESETS.STANDARD
	end
	
	self:stopAllTweens(element)
	
	local tweenInfo = TweenInfo.new(config.duration, config.easing, config.direction)
	local tween = TweenService:Create(element, tweenInfo, properties)
	
	-- Сохраняем твин
	if not activeTweens[element] then
		activeTweens[element] = {}
	end
	table.insert(activeTweens[element], tween)
	
	tween.Completed:Connect(function()
		-- Удаляем твин из активных
		if activeTweens[element] then
			for i, t in ipairs(activeTweens[element]) do
				if t == tween then
					table.remove(activeTweens[element], i)
					break
				end
			end
		end
		
		if onComplete then
			onComplete()
		end
	end)
	
	tween:Play()
	return tween
end

-- Специализированные анимации

function AnimationService:animateShopOpen(shopFrame: GuiObject, onComplete: (() -> ())?): ()
	self:tweenElement(shopFrame, "SHOP_OPEN", onComplete)
end

function AnimationService:animateShopClose(shopFrame: GuiObject, onComplete: (() -> ())?): ()
	self:tweenElement(shopFrame, "SHOP_CLOSE", onComplete)
end

function AnimationService:animateButtonHover(button: GuiObject): ()
	self:tweenElement(button, "BUTTON_HOVER")
end

function AnimationService:animateButtonPress(button: GuiObject): ()
	self:tweenElement(button, "BUTTON_PRESS")
end

function AnimationService:animateButtonRelease(button: GuiObject): ()
	self:tweenElement(button, "BUTTON_RELEASE")
end

function AnimationService:animateAbilityActivation(abilityButton: GuiObject): ()
	self:tweenElement(abilityButton, "ABILITY_ACTIVATE")
end

-- НОВЫЕ СПЕЦИАЛИЗИРОВАННЫЕ АНИМАЦИИ ДЛЯ СПОСОБНОСТЕЙ
function AnimationService:animateAbilitySuccess(abilityButton: GuiObject): ()
	-- Эффект успешной активации - зеленое свечение
	local originalColor = abilityButton.BackgroundColor3
	
	self:tweenCustom(abilityButton, {
		BackgroundColor3 = Color3.fromRGB(0, 255, 100),
		Size = UDim2.new(1.1, 0, 1.1, 0),
	}, "QUICK", function()
		self:tweenCustom(abilityButton, {
			BackgroundColor3 = originalColor,
			Size = UDim2.new(1, 0, 1, 0),
		}, "STANDARD")
	end)
end

function AnimationService:animateAbilityCooldown(abilityButton: GuiObject): ()
	-- Эффект кулдауна - красное мигание
	local originalColor = abilityButton.BackgroundColor3
	
	self:tweenCustom(abilityButton, {
		BackgroundColor3 = Color3.fromRGB(255, 100, 100),
	}, "QUICK", function()
		self:tweenCustom(abilityButton, {
			BackgroundColor3 = originalColor,
		}, "QUICK")
	end)
end

function AnimationService:animateAbilityPulse(abilityButton: GuiObject): ()
	-- Постоянная пульсация для активных эффектов
	local pulseTween = self:tweenCustom(abilityButton, {
		Size = UDim2.new(1.05, 0, 1.05, 0),
		BackgroundTransparency = 0.3,
	}, "SMOOTH", function()
		self:tweenCustom(abilityButton, {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0,
		}, "SMOOTH")
	end)
	
	return pulseTween
end

function AnimationService:animatePanelSlideUp(panel: GuiObject, onComplete: (() -> ())?): ()
	self:tweenElement(panel, "SLIDE_IN_BOTTOM", onComplete)
end

-- Последовательная анимация
function AnimationService:animateSequence(animations: {{element: GuiObject, animationType: string, delay: number?}}, onComplete: (() -> ())?): ()
	local totalAnimations = #animations
	local completedAnimations = 0
	
	for i, animData in ipairs(animations) do
		local delay = animData.delay or 0
		
		spawn(function()
			if delay > 0 then
				wait(delay)
			end
			
			self:tweenElement(animData.element, animData.animationType, function()
				completedAnimations += 1
				if completedAnimations >= totalAnimations and onComplete then
					onComplete()
				end
			end)
		end)
	end
end

-- Ступенчатая анимация (stagger)
function AnimationService:animateStagger(elements: {GuiObject}, animationType: string, staggerDelay: number?, onComplete: (() -> ())?): ()
	staggerDelay = staggerDelay or 0.1
	local totalElements = #elements
	local completedElements = 0
	
	for i, element in ipairs(elements) do
		spawn(function()
			wait((i - 1) * staggerDelay)
			
			self:tweenElement(element, animationType, function()
				completedElements += 1
				if completedElements >= totalElements and onComplete then
					onComplete()
				end
			end)
		end)
	end
end

-- Останавливает все твины для элемента
function AnimationService:stopAllTweens(element: GuiObject): ()
	if activeTweens[element] then
		for _, tween in ipairs(activeTweens[element]) do
			tween:Cancel()
		end
		activeTweens[element] = {}
	end
end

-- Создаёт новый пресет анимации
function AnimationService:createPreset(name: string, config: any): ()
	ANIMATION_PRESETS[name] = config
	print("AnimationService: Создан новый пресет анимации:", name)
end

-- Очистка при выходе игрока
game.Players.PlayerRemoving:Connect(function(player)
	-- Очищаем все активные твины
	for element, tweens in pairs(activeTweens) do
		for _, tween in ipairs(tweens) do
			tween:Cancel()
		end
	end
	activeTweens = {}
end)

return AnimationService
