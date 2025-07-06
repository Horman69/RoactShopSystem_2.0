--!strict
-- src/services/SimplePlatformService.luau
-- Простой стандартный сервис адаптации под мобильные устройства
-- Использует проверенные подходы без переусложнения

local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Простые типы
export type AdaptiveConfig = {
	-- Фиксированные размеры для разных платформ
	abilityButtonSize: UDim2,
	shopButtonSize: UDim2,
	walletSize: UDim2,
	
	-- Размеры текста
	headerTextSize: number,
	bodyTextSize: number,
	buttonTextSize: number,
	
	-- Отступы
	padding: number,
	spacing: number,
	
	-- Прочее
	cornerRadius: number,
	strokeThickness: number,
}

local SimplePlatformService = {}
SimplePlatformService.__index = SimplePlatformService

-- Конструктор
function SimplePlatformService.new()
	local self = setmetatable({}, SimplePlatformService)
	return self
end

-- ПРОСТОЕ определение мобильного устройства
function SimplePlatformService:isMobile(): boolean
	-- Стандартная проверка: есть touch, нет мыши
	return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
end

-- Определение планшета
function SimplePlatformService:isTablet(): boolean
	if not UserInputService.TouchEnabled then
		return false
	end
	
	-- Простая проверка: если разрешение больше чем у телефона
	local viewportSize = workspace.CurrentCamera.ViewportSize
	local minDimension = math.min(viewportSize.X, viewportSize.Y)
	
	-- Планшет если минимальная сторона больше 600px
	return minDimension > 600 and UserInputService.TouchEnabled
end

-- Определение десктопа
function SimplePlatformService:isDesktop(): boolean
	return not self:isMobile() and not self:isTablet()
end

-- ПРОСТАЯ конфигурация размеров - как в нормальных приложениях
function SimplePlatformService:getConfig(): AdaptiveConfig
	if self:isMobile() then
		-- 📱 МОБИЛЬНЫЕ ТЕЛЕФОНЫ - очень компактные размеры
		return {
			-- Размеры кнопок (очень компактные для мобильных)
			abilityButtonSize = UDim2.new(0, 50, 0, 50),    -- Компактные 50x50 для мобильных
			shopButtonSize = UDim2.new(0, 100, 0, 36),      -- Меньший магазин 100x36
			walletSize = UDim2.new(0, 160, 0, 32),          -- Очень компактный кошелёк
			
			-- Размеры текста (компактные для мобильных)
			headerTextSize = 18,        -- Меньше заголовки
			bodyTextSize = 14,          -- Компактный основной текст
			buttonTextSize = 14,        -- Компактный текст на кнопках
			
			-- Отступы (минимальные)
			padding = 8,                -- Меньше внутренние отступы
			spacing = 6,                -- Меньше между элементами
			
			-- Стиль
			cornerRadius = 6,           -- Меньше скругление
			strokeThickness = 1,        -- Тоньше обводка
		}
		
	elseif self:isTablet() then
		-- 📱 ПЛАНШЕТЫ - немного больше
		return {
			abilityButtonSize = UDim2.new(0, 80, 0, 80),    -- Чуть больше для планшетов
			shopButtonSize = UDim2.new(0, 140, 0, 55),
			walletSize = UDim2.new(0, 240, 0, 45),
			
			headerTextSize = 26,
			bodyTextSize = 18,
			buttonTextSize = 20,
			
			padding = 16,
			spacing = 10,
			
			cornerRadius = 10,
			strokeThickness = 2,
		}
		
	else
		-- 🖥️ ДЕСКТОП - оригинальные размеры
		return {
			abilityButtonSize = UDim2.new(0, 64, 0, 64),    -- Оригинальные размеры
			shopButtonSize = UDim2.new(0, 140, 0, 54),
			walletSize = UDim2.new(0, 220, 0, 50),
			
			headerTextSize = 24,
			bodyTextSize = 18,
			buttonTextSize = 18,
			
			padding = 10,
			spacing = 8,
			
			cornerRadius = 12,
			strokeThickness = 3,
		}
	end
end

-- Получить размер экрана
function SimplePlatformService:getScreenSize(): Vector2
	return workspace.CurrentCamera.ViewportSize
end

-- Получить безопасные отступы (для notch и т.д.)
function SimplePlatformService:getSafeAreaInsets()
	local guiInset = GuiService:GetGuiInset()
	return {
		Top = guiInset.Y,
		Bottom = 0,
		Left = guiInset.X,
		Right = 0,
	}
end

-- Совместимость со старым API
function SimplePlatformService:getMobileUIConfig()
	local config = self:getConfig()
	
	-- Конвертируем в старый формат для совместимости
	return {
		buttonSize = config.shopButtonSize,
		abilityButtonSize = config.abilityButtonSize,
		shopCardHeight = 80,
		textSize = config.buttonTextSize,
		iconSize = 32,
		padding = config.padding,
		margin = config.spacing,
		bottomSafeArea = 20,
		topSafeArea = 20,
		touchPadding = 8,
		minimumTouchSize = 44,
	}
end

function SimplePlatformService:getAdaptiveSizes()
	local config = self:getConfig()
	return {
		abilityButton = {
			X = config.abilityButtonSize.X.Offset,
			Y = config.abilityButtonSize.Y.Offset
		},
		shopButton = {
			X = config.shopButtonSize.X.Offset,
			Y = config.shopButtonSize.Y.Offset
		},
		fontSize = config.buttonTextSize,
		padding = config.padding,
	}
end

function SimplePlatformService:getScaleFactor(): number
	-- Простой фиксированный масштаб - никаких сложных расчетов
	if self:isMobile() then
		return 1.0  -- Фиксированный масштаб для мобильных
	elseif self:isTablet() then
		return 1.1  -- Чуть больше для планшетов
	else
		return 1.0  -- Обычный для десктопа
	end
end

function SimplePlatformService:isTouchEnabled(): boolean
	return UserInputService.TouchEnabled
end

return SimplePlatformService
