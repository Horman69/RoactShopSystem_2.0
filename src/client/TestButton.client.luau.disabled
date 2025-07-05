-- src/client/TestButton.client.luau
-- Тестовый скрипт для проверки появления одной кнопки в интерфейсе игрока

-- Удаляем старый TestScreenGui, если он есть, чтобы не было дублирования
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("TestScreenGui")
if old then
	old:Destroy()
end

-- Отключаем тестовую кнопку, чтобы не мешала основному UI
--[[]
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TestScreenGui"
screenGui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0, 200, 0, 50)
button.Position = UDim2.new(0, 100, 0, 100)
button.Text = "Тестовая кнопка"
button.Parent = screenGui

button.MouseButton1Click:Connect(function()
	button.Text = "Нажато!"
end)
]]
