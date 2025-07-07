--!strict
-- src/shared/ShopConfig.luau
-- Центральная конфигурация магазина
-- Современный подход к настройке UI/UX и поведения

local ShopConfig = {}

-- 🎨 КОНФИГУРАЦИЯ ДИЗАЙНА
ShopConfig.design = {
	-- Основные цвета темы - УЛУЧШЕННАЯ ТЕМНАЯ СХЕМА
	colors = {
		-- Основные фоны - современные темные тона
		background = {
			primary = Color3.fromRGB(15, 20, 35),       -- Темно-синий фон
			secondary = Color3.fromRGB(20, 25, 40),     -- Вторичный фон
			card = Color3.fromRGB(25, 35, 55),          -- Синевато-серые карточки
			cardHover = Color3.fromRGB(30, 40, 65),     -- Светлее при наведении
		},
		
		-- Границы и разделители
		border = {
			primary = Color3.fromRGB(60, 70, 90),       -- Синевато-серые границы
			secondary = Color3.fromRGB(40, 50, 70),     -- Темные разделители
		},
		
		-- Акценты
		accent = {
			primary = Color3.fromRGB(79, 172, 254),     -- Яркие синие акценты
			secondary = Color3.fromRGB(99, 102, 241),   -- Фиолетовый акцент
		},
		

		
		-- Текст
		text = {
			primary = Color3.fromRGB(240, 245, 255),    -- Почти белый основной текст
			secondary = Color3.fromRGB(160, 170, 190),  -- Светло-серый вторичный текст  
			accent = Color3.fromRGB(79, 172, 254),      -- Яркий синий акцент
			disabled = Color3.fromRGB(120, 130, 150),   -- Приглушенный текст
			button = Color3.fromRGB(255, 255, 255),     -- Белый текст кнопок
			-- Шрифты
			fonts = {
				regular = Enum.Font.Gotham,
				bold = Enum.Font.GothamBold,
				semibold = Enum.Font.GothamSemibold,
				black = Enum.Font.GothamBlack,
			}
		},
		
		-- Кнопки с яркими современными цветами
		button = {
			primary = Color3.fromRGB(79, 172, 254),     -- Основной синий
			buy = Color3.fromRGB(16, 185, 129),         -- Яркий зеленый
			buyHover = Color3.fromRGB(20, 200, 140),    -- Светлее зеленый при наведении
			success = Color3.fromRGB(34, 197, 94),      -- Успех/активно
			owned = Color3.fromRGB(107, 114, 128),      -- Серый "куплено"
			disabled = Color3.fromRGB(60, 60, 70),      -- Отключенная кнопка
			cantAfford = Color3.fromRGB(248, 113, 113), -- Яркий красный
			close = Color3.fromRGB(248, 113, 113),      -- Яркий красный
			closeHover = Color3.fromRGB(255, 130, 130), -- Светлее красный при наведении
		},
		
		-- Статусы
		status = {
			success = Color3.fromRGB(34, 197, 94),      -- Зеленый успех
			error = Color3.fromRGB(248, 113, 113),      -- Красная ошибка
			warning = Color3.fromRGB(245, 158, 11),     -- Желтое предупреждение
		},
		
		-- 🎨 Цветовые схемы для типов способностей
		abilities = {
			movement = {
				primary = Color3.fromRGB(59, 130, 246),    -- Синий для движения
				active = Color3.fromRGB(79, 150, 255),     -- Яркий синий когда активно
				icon = "⚡"
			},
			defense = {
				primary = Color3.fromRGB(34, 197, 94),     -- Зеленый для защиты
				active = Color3.fromRGB(54, 217, 114),     -- Яркий зеленый когда активно  
				icon = "🛡️"
			},
			attack = {
				primary = Color3.fromRGB(239, 68, 68),     -- Красный для атаки
				active = Color3.fromRGB(255, 88, 88),      -- Яркий красный когда активно
				icon = "💥"
			},
			utility = {
				primary = Color3.fromRGB(168, 85, 247),    -- Фиолетовый для утилит
				active = Color3.fromRGB(188, 105, 255),    -- Яркий фиолетовый когда активно
				icon = "✨"
			},
			elemental = {
				primary = Color3.fromRGB(251, 146, 60),    -- Оранжевый для стихий
				active = Color3.fromRGB(255, 166, 80),     -- Яркий оранжевый когда активно
				icon = "🔥"
			}
		},
		
		-- 🌈 Цвета для эффектов и частиц
		effects = {
			glow = Color3.fromRGB(56, 189, 248), -- Основной glow
			particles = {
				Color3.fromRGB(56, 189, 248),   -- Синий
				Color3.fromRGB(168, 85, 247),   -- Фиолетовый  
				Color3.fromRGB(34, 197, 94),    -- Зеленый
				Color3.fromRGB(236, 72, 153),   -- Розовый
			},
			rainbow = {
				Color3.fromRGB(56, 189, 248),   -- Синий
				Color3.fromRGB(99, 102, 241),   -- Индиго
				Color3.fromRGB(168, 85, 247),   -- Фиолетовый
				Color3.fromRGB(236, 72, 153),   -- Розовый
			}
		}
	},
	
	-- Тени и глубина
	shadow = {
		color = Color3.fromRGB(0, 0, 0),            -- Черный для теней
		transparency = 0.9,                         -- Прозрачность теней
		offset = {
			x = 2,
			y = 3,
		}
	},
	
	-- Обводки
	stroke = {
		thickness = 2,                              -- Толщина обводки
	},
	
	-- Размеры и отступы
	spacing = {
		-- Внутренние отступы
		padding = {
			small = 8,
			medium = 12,
			large = 20,
			xlarge = 24,
		},
		-- Отступы между элементами
		gaps = {
			tiny = 4,
			small = 8,
			medium = 12,
			large = 16,
			xlarge = 20,
		},
		-- Высоты элементов
		heights = {
			header = 35,
			cardMobile = 75,
			cardDesktop = 85,
			buttonMobile = 28,
			buttonDesktop = 32,
		}
	},
	
	-- Скругления
	borderRadius = {
		button = 8,      -- Для кнопок
		card = 12,       -- Для карточек
		container = 16,  -- Для контейнеров
		small = 6,
		medium = 8,
		large = 12,
		xlarge = 24,
		round = 1000,    -- Для круглых элементов
	},
	
	-- Анимации
	animations = {
		duration = 0.3,  -- Основная длительность анимаций
		fast = 0.1,
		normal = 0.2,
		slow = 0.3,
		easing = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	
	-- 🌟 ЭЛЕМЕНТЫ СОВРЕМЕННОГО ДИЗАЙНА
	-- Тени для глубины (дублируем для обратной совместимости)
	shadows = {
		card = {
			size = UDim2.new(0, 2, 0, 4),
			transparency = 0.9,
			color = Color3.fromRGB(0, 0, 0),
		},
		button = {
			size = UDim2.new(0, 1, 0, 2),
			transparency = 0.85,
			color = Color3.fromRGB(0, 0, 0),
		},
		container = {
			size = UDim2.new(0, 4, 0, 8),
			transparency = 0.92,
			color = Color3.fromRGB(0, 0, 0),
		}
	}
}

-- 📱 КОНФИГУРАЦИЯ АДАПТИВНОСТИ
ShopConfig.responsive = {
	-- Брейкпоинты
	breakpoints = {
		mobile = 768,
		tablet = 1024,
		desktop = 1440,
	},
	
	-- Размеры контейнера
	container = {
		mobile = {
			widthPercent = 0.9,
			heightPercent = 0.8,
			maxWidth = 350,
		},
		desktop = {
			width = 480,
			height = 520,
		}
	},
	
	-- Размеры текста
	typography = {
		mobile = {
			header = 28,  -- Еще больше увеличили размер заголовка
			title = 16,
			price = 14,
			description = 12,
			button = 12,
		},
		desktop = {
			header = 32,  -- Еще больше увеличили размер заголовка
			title = 18,
			price = 16,
			description = 13,
			button = 13,
		}
	}
}

-- 🛍️ КОНФИГУРАЦИЯ КАТЕГОРИЙ
ShopConfig.categories = {
	{
		id = "ability",
		name = "СПОСОБНОСТИ",
		color = Color3.fromRGB(56, 189, 248),
		priority = 1,
	},
	{
		id = "weapon",
		name = "⚔️ ОРУЖИЕ",
		icon = "⚔️",
		color = Color3.fromRGB(239, 68, 68),
		priority = 2,
	},
	{
		id = "armor",
		name = "🛡️ БРОНЯ",
		icon = "🛡️",
		color = Color3.fromRGB(34, 197, 94),
		priority = 3,
	},
	{
		id = "consumable",
		name = "🧪 РАСХОДНИКИ",
		icon = "🧪",
		color = Color3.fromRGB(168, 85, 247),
		priority = 4,
	},
	{
		id = "cosmetic",
		name = "✨ КОСМЕТИКА",
		icon = "✨",
		color = Color3.fromRGB(236, 72, 153),
		priority = 5,
	},
	{
		id = "currency",
		name = "💰 ВАЛЮТА",
		icon = "💰",
		color = Color3.fromRGB(251, 191, 36),
		priority = 6,
	}
}

-- ⚙️ КОНФИГУРАЦИЯ ПОВЕДЕНИЯ
ShopConfig.behavior = {
	-- Автоматическое закрытие
	autoClose = {
		enabled = false,
		timeoutSeconds = 30,
	},
	

	
	-- Анимации
	animations = {
		enableCardAppear = false, -- Отключили по просьбе пользователя
		enableHoverEffects = true,
		enableButtonAnimations = true,
	},
	
	-- Производительность
	performance = {
		virtualization = false, -- Пока отключено
		maxVisibleItems = 50,
		lazyLoading = false,
	}
}

-- 🏪 КОНФИГУРАЦИЯ МАГАЗИНА
ShopConfig.shop = {
	-- Заголовок - простой и стильный
	title = "МАГАЗИН",
	
	-- Кнопки
	buttons = {
		close = "X",
		buy = "КУПИТЬ",
		owned = "КУПЛЕНО",
		cantAfford = "НЕ ХВАТАЕТ",
	},
	
	-- Сортировка по умолчанию
	defaultSort = "category", -- category, price, name, popularity
	
	-- Группировка
	groupByCategory = true,
	showCategoryHeaders = true,
}

-- 🛠️ МЕТОДЫ КОНФИГУРАЦИИ
function ShopConfig.getCategoryConfig(categoryId: string)
	for _, category in ipairs(ShopConfig.categories) do
		if category.id == categoryId then
			return category
		end
	end
	
	-- Возвращаем дефолтную конфигурацию
	return {
		id = "other",
		name = "📦 ДРУГОЕ",
		icon = "📦",
		color = Color3.fromRGB(107, 114, 128),
		priority = 999,
	}
end

function ShopConfig.getResponsiveConfig(isMobile: boolean)
	if isMobile then
		return {
			container = ShopConfig.responsive.container.mobile,
			typography = ShopConfig.responsive.typography.mobile,
			spacing = ShopConfig.design.spacing,
		}
	else
		return {
			container = ShopConfig.responsive.container.desktop,
			typography = ShopConfig.responsive.typography.desktop,
			spacing = ShopConfig.design.spacing,
		}
	end
end

function ShopConfig.getCardDimensions(isMobile: boolean)
	return {
		height = isMobile and ShopConfig.design.spacing.heights.cardMobile or ShopConfig.design.spacing.heights.cardDesktop,
		buttonHeight = isMobile and ShopConfig.design.spacing.heights.buttonMobile or ShopConfig.design.spacing.heights.buttonDesktop,
		spacing = ShopConfig.design.spacing.gaps.medium,
	}
end

-- Проверка темной темы
function ShopConfig.isDarkTheme(): boolean
	return true -- Темная современная тема активна
end

-- Конфигурация валютных блоков
function ShopConfig.getCurrencyDisplayConfig()
	return {
		-- Размеры блока валюты
		blockSize = {
			width = 100,
			height = 35,
		},
		-- Отступы между блоками
		spacing = 10,
		-- Шрифты
		fontSize = 14,
		-- Позиционирование (отступ от правого края, увеличен для кнопки закрытия)
		rightOffset = 55, -- Было 15, увеличили до 55 чтобы не пересекался с кнопкой закрытия
	}
end

return ShopConfig
