--!strict
-- src/services/SimpleSoundService.luau
-- Простая система звуков без переусложнения

local SoundService = game:GetService("SoundService")

local SimpleSoundService = {}
SimpleSoundService.__index = SimpleSoundService

-- Конструктор
function SimpleSoundService.new()
	local self = setmetatable({}, SimpleSoundService)
	return self
end

-- Простые звуковые эффекты
function SimpleSoundService:playClickSound()
	-- Стандартный клик UI
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/electronicpingshort.wav" -- Встроенный звук Roblox
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	
	-- Удаляем после проигрывания
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SimpleSoundService:playPurchaseSound()
	-- Звук покупки
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/impact_water.mp3" -- Встроенный звук Roblox
	sound.Volume = 0.7
	sound.Parent = SoundService
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SimpleSoundService:playAbilitySound()
	-- Звук способности
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/beep.mp3" -- Встроенный звук Roblox
	sound.Volume = 0.6
	sound.Parent = SoundService
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function SimpleSoundService:playErrorSound()
	-- Звук ошибки
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxasset://sounds/navigation_bump.wav" -- Встроенный звук Roblox
	sound.Volume = 0.4
	sound.Parent = SoundService
	sound:Play()
	
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

return SimpleSoundService
