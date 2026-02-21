local createSource = require("./createSource")
local derive = require("./derive")
local effect = require("./effect")
local untrack = require("./untrack")
local switch = require("./switch")

type Array<T> = { T }
type Getter<T> = () -> T

local function show<T, Obj>(
	input: Getter<T?>,
	component: (Getter<T>, Getter<boolean>) -> (Obj, ...number),
	fallback: ((Getter<boolean>) -> (Obj, ...number))?
): Getter<nil | Obj | Array<Obj>>
	local filtered_input, set_filtered_input = createSource()

	effect(function()
		local v = input()
		if v then
			set_filtered_input(v)
		end
	end)

	local input_is_truthy = derive(function()
		return not not input()
	end)

	return switch(input_is_truthy)({
		[true] = function(present)
			return component(filtered_input, present)
		end,
		[false] = fallback,
	})
end

return show
