-- src/client/RoactStarter.client.luau
-- ОТКЛЮЧЕН - используем новый ShopApp.client.luau
-- Этот скрипт автоматически запускает Roact UI для игрока и предотвращает дублирование UI

--[[ ОТКЛЮЧЕНО
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("roact"))
local Main = require(ReplicatedStorage:WaitForChild("App"):WaitForChild("Main"))

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Удаляем старый UI, если он есть, чтобы не было дублирования
local old = playerGui:FindFirstChild("MainApp")
if old then
	old:Destroy()
end

Roact.mount(Roact.createElement(Main), playerGui, "MainApp")
--]]
