---Recipe and technology

local constants = require("lib.constants")

---@type data.RecipePrototype
local mux_recipe = {
	type = "recipe",
	name = constants.mux_name,
	hidden = false,
	enabled = false,
	energy_required = 30,
	ingredients = {
		{ type = "item", name = "electronic-circuit", amount = 8 },
		{ type = "item", name = "copper-cable", amount = 16 },
	},
	results = {
		{ type = "item", name = constants.mux_name, amount = 1 },
	},
}

---@type data.TechnologyPrototype
local mux_technology = {
	type = "technology",
	name = constants.tech_name,
	icon_size = 128,
	icon = "__ribbon-cables__/graphics/mux-icon-128.png",
	effects = {
		{ type = "unlock-recipe", recipe = constants.mux_name },
	},
	prerequisites = { "circuit-network" },
	unit = {
		count = 100,
		ingredients = {
			{ "automation-science-pack", 1 },
			{ "logistic-science-pack", 1 },
		},
		time = 30,
	},
	order = "a-d-d-z",
}

data:extend({ mux_recipe, mux_technology })
