local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.roact)

local SimpleButton = Roact.Component:extend("SimpleButton")

function SimpleButton:render()
	return Roact.createElement("ScreenGui", {}, {
		Button = Roact.createElement("TextButton", {
			Size = UDim2.new(0, 200, 0, 50),
			Position = UDim2.new(0.5, -100, 0.5, -25),
			Text = "Hello, Roact!",
			[Roact.Event.Activated] = function()
				print("Button clicked!")
			end,
		}),
	})
end

return SimpleButton