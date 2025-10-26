--- Multiplexer entity that can be placed into the world.
--- Connects to circuit network via 8 pins, connects to other muxes via
--- ribbon cables.

local constants = require("lib.constants")

local entity_sprite = {}
for idx, direction in pairs({ "north", "east", "south", "west" }) do
	---@type data.Sprite
	entity_sprite[direction] = {
		filename = "__ribbon-cables__/graphics/mux-entity.png",
		width = 128,
		height = 128,
		scale = 0.25,
		x = (idx - 1) * 128,
		shift = util.by_pixel(0, 0),
	}
end

---@type data.SimpleEntityWithOwnerPrototype
local mux = {
	-- PrototypeBase
	type = "simple-entity-with-owner",
	name = constants.mux_name,

	-- SimpleEntityWithOwnerPrototype
	render_layer = "floor-mechanics",
	picture = entity_sprite,

	-- EntityWithHealthPrototype
	max_health = 250,
	dying_explosion = "medium-explosion",
	corpse = "medium-remnants",

	-- EntityPrototype
	icon = "__ribbon-cables__/graphics/mux-icon-128.png",
	icon_size = 128,
	collision_box = { { -0.45, -0.45 }, { 0.45, 0.45 } },
	collision_mask = {
		layers = {
			item = true,
			object = true,
			player = true,
			water_tile = true,
		},
	},
	selection_box = { { -0.5, -0.5 }, { 0.5, 0.5 } },
	flags = {
		"player-creation",
		"placeable-neutral",
		"not-upgradable",
	},
	minable = { mining_time = 1, result = constants.mux_name },
	selection_priority = 20,
}

---@type data.ItemPrototype
local item = {
	-- Prototype Base
	type = "item",
	name = constants.mux_name,
	place_result = constants.mux_name,

	-- ItemPrototype
	stack_size = 50,
	icon = "__ribbon-cables__/graphics/mux-icon-128.png",
	icon_size = 128,
	order = "m",
	subgroup = "circuit-network",
}

data:extend({ mux, item })
