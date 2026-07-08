---Circuit connector pins.

local constants = require("lib.constants")

---@type data.Sprite
local pin_sprite = {
	filename = "__ribbon-cables__/graphics/circle.png",
	size = 32,
	scale = 0.125,
	tint = { 1, 1, 1, 1 },
}

---@type data.ContainerPrototype
local pin = {
	-- PrototypeBase
	type = "container",
	name = "ribbon-cables-pin-legacy",
	hidden_in_factoriopedia = true,

	-- ContainerPrototype
	inventory_size = 0,
	picture = pin_sprite,
	circuit_wire_max_distance = constants.circuit_wire_max_distance,
	draw_copper_wires = false,
	draw_circuit_wires = true,

	-- EntityWithHealthPrototype
	max_health = 1,

	-- EntityPrototype
	icon = "__ribbon-cables__/graphics/icon-jumper-wire.png",
	icon_size = 256,
	-- XXX: TYPES: FMTK vector bug
	---@diagnostic disable-next-line: missing-fields
	collision_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
	collision_mask = { layers = {} },
	-- XXX: TYPES: FMTK vector bug
	---@diagnostic disable-next-line: missing-fields
	selection_box = { { -0.1, -0.1 }, { 0.1, 0.1 } },
	flags = {
		"placeable-off-grid",
		"not-on-map",
		"not-deconstructable",
		"hide-alt-info",
		"not-selectable-in-game",
		"not-upgradable",
		"no-automated-item-removal",
		"no-automated-item-insertion",
		"not-in-kill-statistics",
		"placeable-neutral",
		"player-creation",
	},
	minable = nil,
	selection_priority = 70,
	allow_copy_paste = false,
}

---@type data.ItemPrototype
local pin_item = {
	-- PrototypeBase
	type = "item",
	name = "ribbon-cables-pin-legacy",
	order = "f[iber-optics]",
	subgroup = "circuit-network",
	hidden_in_factoriopedia = true,

	-- ItemPrototype
	stack_size = 50,
	icon = "__ribbon-cables__/graphics/icon-jumper-wire.png",
	icon_size = 256,
	place_result = "ribbon-cables-pin-legacy",
	flags = { "hide-from-bonus-gui", "only-in-cursor" },
	weight = 0,
}

data:extend({ pin, pin_item })
