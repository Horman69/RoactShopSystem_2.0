--!strict
-- src/services/SimpleSoundService.luau
-- Продвинутая система звуков для магазина и способностей
-- Версия 2.1 с диагностикой производительности и оптимизацией

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local SimpleSoundService = {}
SimpleSoundService.__index = SimpleSoundService

-- Конфигурация звуков
local SOUND_CONFIG = {
	-- Звуки магазина
	shop = {
		open = "rbxassetid://242135745",     -- Открытие магазина
		close = "rbxassetid://242135745",    -- Закрытие магазина
		purchase = "rbxassetid://14621507602", -- Покупка (НОВЫЙ ЗВУК)
	},
	
	-- Звуки способностей
	abilities = {
		activate = "rbxassetid://119289373229825", -- Активация способности
		active = "rbxassetid://107261392908541",   -- Способность снова активна (всегда через 30 сек) - НОВЫЙ ЗВУК
		deactivate = "rbxassetid://17628141786",   -- Способность останавливается (через 15 сек)
		cooldown = "rbxassetid://104184340183231", -- Попытка активации во время кулдауна
	},
	
	-- Настройки
	volume = 0.5,
	enabled = true,
	debug = true, -- Включить детальное логирование
}

-- Конструктор
function SimpleSoundService.new()
	local self = setmetatable({}, SimpleSoundService)
	
	-- Кэш для звуков и метрики производительности
	self.preloadedSounds = {}
	self.soundPoolSize = {}
	self.performanceMetrics = {
		totalCalls = 0,
		averageLatency = 0,
		maxLatency = 0,
		cacheHits = 0,
		cacheMisses = 0,
	}
	
	-- Предзагружаем все звуки для устранения задержек
	self:preloadAllSounds()
	
	-- Создаем пул звуков для каждого типа (для полного устранения задержек)
	self:createSoundPools()
	
	return self
end

-- Предзагрузка всех звуков через ContentProvider (максимальная скорость)
function SimpleSoundService:preloadAllSounds()
	local startTime = tick()
	local allSounds = {}
	local soundIds = {}
	
	-- Собираем все ID звуков
	for category, sounds in pairs(SOUND_CONFIG) do
		if type(sounds) == "table" and category ~= "volume" and category ~= "enabled" and category ~= "debug" then
			for soundType, soundId in pairs(sounds) do
				if type(soundId) == "string" and soundId ~= "" then
					table.insert(allSounds, soundId)
					table.insert(soundIds, soundId)
				end
			end
		end
	end
	
	-- КРИТИЧЕСКИ ВАЖНО: Используем ContentProvider для предзагрузки
	spawn(function()
		local success, err = pcall(function()
			ContentProvider:PreloadAsync(soundIds)
		end)
		
		if success then
			if SOUND_CONFIG.debug then
				print("🔊 SimpleSoundService: ContentProvider предзагрузил", #soundIds, "звуков за", math.round((tick() - startTime) * 1000), "мс")
			end
		else
			warn("⚠️ SimpleSoundService: Ошибка предзагрузки ContentProvider:", err)
		end
	end)
	
	-- Создаем объекты Sound для кэширования
	for _, soundId in ipairs(allSounds) do
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = 0 -- Беззвучно создаем
		sound.Parent = SoundService
		
		-- Сохраняем для переиспользования
		self.preloadedSounds[soundId] = sound
		self.soundPoolSize[soundId] = 1
	end
	
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Создано", #allSounds, "объектов Sound за", math.round((tick() - startTime) * 1000), "мс")
	end
end

-- Создание пула звуков для критических событий (покупка, активация способностей)
function SimpleSoundService:createSoundPools()
	local criticalSounds = {
		SOUND_CONFIG.shop.purchase,
		SOUND_CONFIG.abilities.activate,
		SOUND_CONFIG.abilities.cooldown
	}
	
	-- Создаем по 3 копии каждого критического звука
	for _, soundId in ipairs(criticalSounds) do
		if soundId and soundId ~= "" then
			for i = 2, 3 do -- Уже есть 1 копия, создаем еще 2
				local sound = Instance.new("Sound")
				sound.SoundId = soundId
				sound.Volume = 0
				sound.Parent = SoundService
				
				-- Добавляем в пул
				local poolKey = soundId .. "_" .. i
				self.preloadedSounds[poolKey] = sound
				self.soundPoolSize[soundId] = (self.soundPoolSize[soundId] or 1) + 1
			end
		end
	end
	
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Создан пул для критических звуков")
	end
end

-- МАКСИМАЛЬНО БЫСТРЫЙ метод воспроизведения звука с диагностикой
function SimpleSoundService:playSound(soundId: string, volume: number?)
	if not SOUND_CONFIG.enabled or not soundId or soundId == "" then
		return
	end
	
	local startTime = tick()
	self.performanceMetrics.totalCalls += 1
	
	-- Ищем доступный звук в пуле
	local sound = nil
	local poolSize = self.soundPoolSize[soundId] or 1
	
	-- Сначала ищем основной звук
	local mainSound = self.preloadedSounds[soundId]
	if mainSound and not mainSound.IsPlaying then
		sound = mainSound
		self.performanceMetrics.cacheHits += 1
	else
		-- Ищем в пуле копий
		for i = 2, poolSize do
			local poolSound = self.preloadedSounds[soundId .. "_" .. i]
			if poolSound and not poolSound.IsPlaying then
				sound = poolSound
				self.performanceMetrics.cacheHits += 1
				break
			end
		end
		
		-- Если все звуки заняты, создаем новый (редкий случай)
		if not sound then
			sound = Instance.new("Sound")
			sound.SoundId = soundId
			sound.Parent = SoundService
			self.performanceMetrics.cacheMisses += 1
			
			if SOUND_CONFIG.debug then
				warn("⚠️ SimpleSoundService: Создан новый звук для", soundId, "- все копии заняты")
			end
		end
	end
	
	-- Мгновенно воспроизводим
	sound.Volume = volume or SOUND_CONFIG.volume
	sound:Play()
	
	-- Статистика производительности
	local latency = (tick() - startTime) * 1000
	self.performanceMetrics.maxLatency = math.max(self.performanceMetrics.maxLatency, latency)
	self.performanceMetrics.averageLatency = (self.performanceMetrics.averageLatency + latency) / 2
	
	if SOUND_CONFIG.debug and latency > 1 then -- Логируем только задержки > 1мс
		print("🔊 Звук воспроизведен за", math.round(latency * 100) / 100, "мс | ID:", soundId)
	end
end

-- Получить статистику производительности
function SimpleSoundService:getPerformanceStats()
	return {
		totalCalls = self.performanceMetrics.totalCalls,
		averageLatency = math.round(self.performanceMetrics.averageLatency * 100) / 100,
		maxLatency = math.round(self.performanceMetrics.maxLatency * 100) / 100,
		cacheHitRate = math.round((self.performanceMetrics.cacheHits / math.max(self.performanceMetrics.totalCalls, 1)) * 100),
		cacheMisses = self.performanceMetrics.cacheMisses,
	}
end

-- Логирование статистики (можно вызвать для отладки)
function SimpleSoundService:printStats()
	local stats = self:getPerformanceStats()
	print("📊 SimpleSoundService Статистика:")
	print("   Всего вызовов:", stats.totalCalls)
	print("   Средняя задержка:", stats.averageLatency, "мс")
	print("   Макс. задержка:", stats.maxLatency, "мс")
	print("   Попадания в кэш:", stats.cacheHitRate, "%")
	print("   Промахи кэша:", stats.cacheMisses)
end

-- === ЗВУКИ МАГАЗИНА ===
function SimpleSoundService:playShopOpen()
	self:playSound(SOUND_CONFIG.shop.open)
end

function SimpleSoundService:playShopClose()
	self:playSound(SOUND_CONFIG.shop.close)
end

function SimpleSoundService:playPurchaseSound()
	self:playSound(SOUND_CONFIG.shop.purchase)
end

-- === ЗВУКИ СПОСОБНОСТЕЙ ===
function SimpleSoundService:playAbilityActivate()
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Воспроизводится звук 'активация способности' ID:", SOUND_CONFIG.abilities.activate)
	end
	self:playSound(SOUND_CONFIG.abilities.activate)
end

function SimpleSoundService:playAbilityActive()
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Воспроизводится звук 'способность снова активна' ID:", SOUND_CONFIG.abilities.active)
	end
	self:playSound(SOUND_CONFIG.abilities.active)
end

function SimpleSoundService:playAbilityDeactivate()
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Воспроизводится звук 'деактивация способности' ID:", SOUND_CONFIG.abilities.deactivate)
	end
	self:playSound(SOUND_CONFIG.abilities.deactivate)
end

function SimpleSoundService:playAbilityCooldown()
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Воспроизводится звук 'кулдаун способности' ID:", SOUND_CONFIG.abilities.cooldown)
	end
	self:playSound(SOUND_CONFIG.abilities.cooldown)
end

-- Управление
function SimpleSoundService:setEnabled(enabled: boolean)
	SOUND_CONFIG.enabled = enabled
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Звуки", enabled and "включены" or "выключены")
	end
end

function SimpleSoundService:setVolume(volume: number)
	SOUND_CONFIG.volume = math.clamp(volume, 0, 1)
	if SOUND_CONFIG.debug then
		print("🔊 SimpleSoundService: Громкость установлена на", SOUND_CONFIG.volume)
	end
end

function SimpleSoundService:setDebug(enabled: boolean)
	SOUND_CONFIG.debug = enabled
	print("🔊 SimpleSoundService: Отладка", enabled and "включена" or "выключена")
end

-- Тестирование всех звуков (для отладки)
function SimpleSoundService:testAllSounds()
	print("🔊 Тестирование всех звуков...")
	
	local testSequence = {
		{sound = "shop.open", delay = 0.5, description = "Открытие магазина"},
		{sound = "shop.purchase", delay = 0.5, description = "Покупка товара"},
		{sound = "abilities.activate", delay = 0.5, description = "Активация способности"},
		{sound = "abilities.active", delay = 0.5, description = "Способность снова активна (30 сек)"},
		{sound = "abilities.deactivate", delay = 0.5, description = "Деактивация способности"},
		{sound = "abilities.cooldown", delay = 0.5, description = "Кулдаун способности"},
		{sound = "shop.close", delay = 0, description = "Закрытие магазина"},
	}
	
	spawn(function()
		for i, test in ipairs(testSequence) do
			local parts = test.sound:split(".")
			local category, soundType = parts[1], parts[2]
			local soundId = SOUND_CONFIG[category] and SOUND_CONFIG[category][soundType]
			
			if soundId then
				print("   Тест", i, "- Звук:", test.description, "(ID:", soundId, ")")
				self:playSound(soundId, 0.3)
			else
				warn("   Тест", i, "- Звук не найден:", test.sound)
			end
			
			if test.delay > 0 then
				wait(test.delay)
			end
		end
		
		wait(1)
		self:printStats()
	end)
end

return SimpleSoundService