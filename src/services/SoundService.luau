--!strict
-- src/services/SoundService.luau
-- Сервис управления звуковыми эффектами
-- Отвечает за воспроизведение звуков при различных игровых событиях

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Конфигурация звуков
local SOUND_CONFIG = {
	-- Звук покупки (сделан тише)
	PURCHASE = {
		id = 18444216941,
		volume = 0.3, -- Уменьшено с 0.5 до 0.3
		pitch = 1.0,
		fadeIn = false,
	},
	
	-- Звук открытия/закрытия магазина
	SHOP_TOGGLE = {
		id = 452267918,
		volume = 0.3,
		pitch = 1.0,
		fadeIn = true,
	},
	
	-- Звук использования способности
	ABILITY_USE = {
		id = 18747232612,
		volume = 0.4,
		pitch = 1.0,
		fadeIn = false,
	},
	
	-- Звук ошибки (способность на кулдауне)
	ABILITY_COOLDOWN = {
		id = 17628141786,
		volume = 0.3,
		pitch = 1.0,
		fadeIn = false,
	},
	
	-- Звук окончания кулдауна
	COOLDOWN_FINISHED = {
		id = 5728423829,
		volume = 0.4,
		pitch = 1.0,
		fadeIn = false,
	},
}

-- Интерфейс сервиса звуков
type SoundServiceInterface = {
	playPurchaseSound: (self: SoundServiceInterface) -> (),
	playShopToggleSound: (self: SoundServiceInterface) -> (),
	playAbilityUseSound: (self: SoundServiceInterface) -> (),
	playAbilityCooldownSound: (self: SoundServiceInterface) -> (),
	playCooldownFinishedSound: (self: SoundServiceInterface) -> (),
	playSound: (self: SoundServiceInterface, soundConfig: any) -> (),
	setMasterVolume: (self: SoundServiceInterface, volume: number) -> (),
	getMasterVolume: (self: SoundServiceInterface) -> number,
}

local GameSoundService = {} :: SoundServiceInterface
GameSoundService.__index = GameSoundService

-- Мастер-громкость
local masterVolume = 1.0

-- Кэш звуковых объектов
local soundCache: {[number]: Sound} = {}

-- Инициализация сервиса
function GameSoundService.new(): SoundServiceInterface
	local self = setmetatable({}, GameSoundService)
	
	-- Предзагружаем критически важные звуки
	self:_preloadSounds()
	
	print("SoundService: Сервис звуков инициализирован")
	return self
end

-- Воспроизвести звук покупки
function GameSoundService:playPurchaseSound()
	print("SoundService: Воспроизводим звук покупки")
	self:playSound(SOUND_CONFIG.PURCHASE)
end

-- Воспроизвести звук открытия/закрытия магазина
function GameSoundService:playShopToggleSound()
	print("SoundService: Воспроизводим звук переключения магазина")
	self:playSound(SOUND_CONFIG.SHOP_TOGGLE)
end

-- Воспроизвести звук использования способности
function GameSoundService:playAbilityUseSound()
	print("SoundService: Воспроизводим звук использования способности")
	self:playSound(SOUND_CONFIG.ABILITY_USE)
end

-- Воспроизвести звук ошибки (способность на кулдауне)
function GameSoundService:playAbilityCooldownSound()
	print("SoundService: Воспроизводим звук ошибки кулдауна")
	self:playSound(SOUND_CONFIG.ABILITY_COOLDOWN)
end

-- Воспроизвести звук окончания кулдауна
function GameSoundService:playCooldownFinishedSound()
	print("SoundService: Воспроизводим звук окончания кулдауна")
	self:playSound(SOUND_CONFIG.COOLDOWN_FINISHED)
end

-- Универсальный метод воспроизведения звука
function GameSoundService:playSound(soundConfig: any)
	local sound = self:_getOrCreateSound(soundConfig.id)
	
	if not sound then
		warn("SoundService: Не удалось загрузить звук с ID", soundConfig.id)
		return
	end
	
	-- Настраиваем параметры звука
	sound.Volume = soundConfig.volume * masterVolume
	sound.Pitch = soundConfig.pitch or 1.0
	sound.EmitterSize = 0 -- Глобальный звук
	
	-- Воспроизводим с анимацией громкости если нужно
	if soundConfig.fadeIn then
		sound.Volume = 0
		sound:Play()
		
		local tween = TweenService:Create(sound, 
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Volume = soundConfig.volume * masterVolume}
		)
		tween:Play()
	else
		sound:Play()
	end
end

-- Установить мастер-громкость
function GameSoundService:setMasterVolume(volume: number)
	masterVolume = math.clamp(volume, 0, 1)
	print("SoundService: Мастер-громкость установлена на", masterVolume)
end

-- Получить мастер-громкость
function GameSoundService:getMasterVolume(): number
	return masterVolume
end

-- Приватные методы

-- Получить или создать звуковой объект
function GameSoundService:_getOrCreateSound(soundId: number): Sound?
	-- Проверяем кэш
	if soundCache[soundId] then
		return soundCache[soundId]
	end
	
	-- Создаем новый звук
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://" .. soundId
	sound.Parent = workspace -- Глобальные звуки
	
	-- Ждем загрузки звука
	if not sound.IsLoaded then
		local startTime = tick()
		while not sound.IsLoaded and tick() - startTime < 5 do
			wait(0.1)
		end
		
		if not sound.IsLoaded then
			warn("SoundService: Таймаут загрузки звука", soundId)
			sound:Destroy()
			return nil
		end
	end
	
	-- Добавляем в кэш
	soundCache[soundId] = sound
	print("SoundService: Звук загружен и кэширован:", soundId)
	
	return sound
end

-- Предзагружаем важные звуки
function GameSoundService:_preloadSounds()
	print("SoundService: Предзагрузка звуков...")
	
	-- Предзагружаем все звуки в фоне
	spawn(function()
		for soundName, config in pairs(SOUND_CONFIG) do
			self:_getOrCreateSound(config.id)
			wait(0.1) -- Небольшая задержка между загрузками
		end
		print("SoundService: Предзагрузка завершена")
	end)
end

-- Очистка при выходе игрока
game.Players.PlayerRemoving:Connect(function(player)
	-- Очищаем кэш если нужно (пока оставляем звуки для других игроков)
end)

return GameSoundService
