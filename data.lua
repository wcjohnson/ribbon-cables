require("data.pin")
require("data.mux")
require("data.tech")

data:extend({
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

data.raw["mod-data"]["things-names"].data["ribbon-cables-mux"] = {
	virtualize_orientation = true,
}
data.raw["mod-data"]["things-names"].data["ribbon-cables-pin"] = {}

data.raw["mod-data"]["things-graphs"].data["ribbon-cables"] = {
	directed = false,
}
