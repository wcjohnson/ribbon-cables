local oc_lib = require("lib.core.orientation.orientation-class")

require("data.pin")
require("data.mux")
require("data.tech")

data:extend({
	{ type = "custom-event", name = "ribbon-cables-on_initialized" },
	{ type = "custom-event", name = "ribbon-cables-on_status" },
	{ type = "custom-event", name = "ribbon-cables-on_edge_status" },
	{ type = "custom-event", name = "ribbon-cables-on_edge_changed" },
	{ type = "custom-event", name = "ribbon-cables-on_orientation_changed" },
	{ type = "custom-event", name = "ribbon-cables-on_children_normalized" },
	{
		type = "custom-input",
		name = "ribbon-cables-click",
		key_sequence = "mouse-button-3",
	},
	{
		type = "custom-input",
		name = "ribbon-cables-linked-clear-cursor",
		key_sequence = "",
		linked_game_control = "clear-cursor",
	},
	{
		type = "selection-tool",
		name = "ribbon-cables-wiring-tool",
		icon = "__ribbon-cables__/graphics/icon-jumper-cable.png",
		icon_size = 256,
		flags = { "only-in-cursor", "spawnable", "not-stackable" },
		hidden = true,
		stack_size = 1,
		draw_label_for_cursor_render = false,
		select = {
			border_color = { r = 0.0, g = 1.0, b = 0.0 },
			cursor_box_type = "entity",
			mode = { "any-entity", "same-force" },
			entity_filter_mode = "whitelist",
			entity_filters = { "ribbon-cables-mux" },
		},
		alt_select = {
			border_color = { r = 0.0, g = 1.0, b = 0.0 },
			cursor_box_type = "entity",
			mode = { "any-entity", "same-force" },
			entity_filter_mode = "whitelist",
			entity_filters = { "ribbon-cables-mux" },
		},
	},
	{
		type = "shortcut",
		name = "ribbon-cables-wiring-shortcut",
		icon = "__ribbon-cables__/graphics/icon-jumper-cable.png",
		icon_size = 256,
		small_icon = "__ribbon-cables__/graphics/icon-jumper-cable.png",
		small_icon_size = 256,
		action = "spawn-item",
		item_to_spawn = "ribbon-cables-wiring-tool",
		style = "default",
	},
})

local PIN_OFFSET = 0.4

---@type things.ThingRegistration
local mux_registration = {
	name = "ribbon-cables-mux",
	intercept_construction = true,
	virtualize_orientation = oc_lib.OrientationClass.OC_048CM_RF,
	custom_events = {
		on_initialized = "ribbon-cables-on_initialized",
		on_status = "ribbon-cables-on_status",
		on_edge_status = "ribbon-cables-on_edge_status",
		on_children_normalized = "ribbon-cables-on_children_normalized",
		on_orientation_changed = "ribbon-cables-on_orientation_changed",
	},
	children = {
		[1] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { 0, -PIN_OFFSET },
		},
		[2] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { PIN_OFFSET, -PIN_OFFSET },
		},
		[3] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { PIN_OFFSET, 0 },
		},
		[4] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { PIN_OFFSET, PIN_OFFSET },
		},
		[5] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { 0, PIN_OFFSET },
		},
		[6] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { -PIN_OFFSET, PIN_OFFSET },
		},
		[7] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { -PIN_OFFSET, 0 },
		},
		[8] = {
			create = { name = "ribbon-cables-pin", position = { 0, 0 } },
			offset = { -PIN_OFFSET, -PIN_OFFSET },
		},
	},
}
data.raw["mod-data"]["things-names"].data["ribbon-cables-mux"] =
	mux_registration

---@type things.ThingRegistration
local pin_registration = {
	name = "ribbon-cables-pin",
	intercept_construction = false,
	no_garbage_collection = true,
}
data.raw["mod-data"]["things-names"].data["ribbon-cables-pin"] =
	pin_registration

data.raw["mod-data"]["things-graphs"].data["ribbon-cables"] = {
	directed = false,
	custom_events = {
		on_edge_changed = "ribbon-cables-on_edge_changed",
	},
}
