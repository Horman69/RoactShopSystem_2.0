--!strict
-- src/shared/ModuleLoader.luau
-- Центральная система загрузки модулей
-- Решает проблему с WaitForChild в каждом модуле

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Кэш для загруженных модулей
local ModuleCache = {}

local ModuleLoader = {}

-- Безопасная загрузка модуля с кэшированием
function ModuleLoader.require(modulePath: string): any
	-- Проверяем кэш
	if ModuleCache[modulePath] then
		return ModuleCache[modulePath]
	end
	
	-- Загружаем модуль
	local success, moduleResult = pcall(function()
		local pathParts = string.split(modulePath, "/")
		local currentLocation = ReplicatedStorage
		
		-- Проходим по частям пути
		for _, part in ipairs(pathParts) do
			currentLocation = currentLocation:WaitForChild(part)
		end
		
		return require(currentLocation)
	end)
	
	if success then
		-- Кэшируем успешно загруженный модуль
		ModuleCache[modulePath] = moduleResult
		return moduleResult
	else
		error("Не удалось загрузить модуль: " .. modulePath .. " - " .. tostring(moduleResult))
	end
end

-- Предзагрузка критически важных модулей
function ModuleLoader.preloadCriticalModules(): ()
	local criticalModules = {
		"Packages/roact",
		"shared/Types",
		"Shop/ShopData",
		"services/CurrencyService",
		"services/ShopService",
		-- SoundService удалён - больше не используется
		-- Wallet удалён - заменён на CurrencyService
	}
	
	for _, modulePath in ipairs(criticalModules) do
		pcall(function()
			ModuleLoader.require(modulePath)
		end)
	end
end

-- Очистка кэша (для тестирования)
function ModuleLoader.clearCache(): ()
	ModuleCache = {}
end

return ModuleLoader
