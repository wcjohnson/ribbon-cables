local oc_lib = require("lib.core.orientation.orientation-class")

-- Bootstrap Relm data phase
_G.__RELM_GRAPHICS_PATH__ = "__ribbon-cables__/lib/core/relm/graphics/"
require("lib.core.relm.relm_data")

require("data.pin")
require("data.legacy-pin")
require("data.mux")
require("data.tech")

data:extend({
	{ type = "custom-event", name = "ribbon-cables-on_initialized" },
	{ type = "custom-event", name = "ribbon-cables-on_status" },
	{ type = "custom-event", name = "ribbon-cables-on_edge_status" },
	{ type = "custom-event", name = "ribbon-cables-on_edge_changed" },
	{ type = "custom-event", name = "ribbon-cables-on_orientation_changed" },
	{ type = "custom-event", name = "ribbon-cables-on_pin_status" },
	{ type = "custom-event", name = "ribbon-cables-on_pin_immediate_voided" },
	{
		type = "custom-input",
		name = "ribbon-cables-click",
		key_sequence = "mouse-button-1",
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
	virtualize_orientation = oc_lib.OrientationClass.D8_0_RF,
	custom_events = {
		on_initialized = "ribbon-cables-on_initialized",
		on_status = "ribbon-cables-on_status",
		on_edge_status = "ribbon-cables-on_edge_status",
		on_orientation_changed = "ribbon-cables-on_orientation_changed",
	},
}
data.raw["mod-data"]["things-names"].data["ribbon-cables-mux"] =
	mux_registration

---@type things.ThingRegistration
local pin_registration = {
	name = "ribbon-cables-pin",
	intercept_construction = false,
	no_garbage_collection = true,
	allow_in_cursor = "never",
	custom_events = {
		on_status = "ribbon-cables-on_pin_status",
		on_immediate_voided = "ribbon-cables-on_pin_immediate_voided",
	},
}
data.raw["mod-data"]["things-names"].data["ribbon-cables-pin"] =
	pin_registration

---@type things.ThingRegistration
local legacy_pin_registration = {
	name = "ribbon-cables-pin-legacy",
	intercept_construction = false,
	no_garbage_collection = true,
	allow_in_cursor = "never",
	custom_events = {
		on_status = "ribbon-cables-on_pin_status",
		on_immediate_voided = "ribbon-cables-on_pin_immediate_voided",
	},
}
data.raw["mod-data"]["things-names"].data["ribbon-cables-pin-legacy"] =
	legacy_pin_registration

data.raw["mod-data"]["things-graphs"].data["ribbon-cables"] = {
	directed = false,
	custom_events = {
		on_edge_changed = "ribbon-cables-on_edge_changed",
	},
}
