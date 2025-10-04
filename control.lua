local entities_lib = require("lib.core.entities")
local pos_lib = require("lib.core.math.pos")
local constants = require("lib.constants")

require("lib.core.debug-log")
set_print_debug_log(true)

require("control.multiplexer")
require("control.storage")

-- Enable support for the Global Variable Viewer debugging mod, if it is
-- installed.
if script.active_mods["gvv"] then require("__gvv__.gvv")() end

script.on_event("things-on_initialized", function(event)
	debug_log("RIBBON-CABLES: things-on_initialized: ", event)
	local entity = event.entity --[[@as LuaEntity?]]
	if
		entity
		and entity.valid
		and entities_lib.true_prototype_name(entity) == constants.mux_name
	then
		get_or_create_multiplexer_state(event.thing_id)
		debug_log(
			"RIBBON-CABLES: created state ",
			event.thing_id,
			", now creating pins..."
		)
		local pin_pos =
			pos_lib.pos_add(pos_lib.pos_new(entity.position), 1, { 0, -1 })
		local pin1 = entity.surface.create_entity({
			name = constants.pin_name,
			position = pin_pos,
			force = entity.force,
			create_build_effect_smoke = false,
			raise_built = true,
		})
		remote.call("things", "add_child", event, 1, pin1)
	end
end)

script.on_event("things-on_status_changed", function(event)
	if event.new_status == "destroyed" then
		local st = get_multiplexer_state(event.thing_id)
		if st then st:destroy() end
	end
end)

script.on_event("things-on_edges_changed", function(event)
	if event.graph_name ~= "ribbon-cables" then return end
	debug_log("RIBBON-CABLES: things-on_edges_changed: ", event.nodes)
	for thing_id in pairs(event.nodes) do
		local st = get_multiplexer_state(thing_id)
		if st then st:update_connection_render_objects() end
	end
end)

script.on_event(
	"ribbon-cables-click",
	---@param event EventData.on_lua_shortcut
	function(event)
		local player = game.get_player(event.player_index)
		if not player then return end
		if not player.is_cursor_empty() then return end
		local selected = player.selected
		if not selected then return end
		local _, prototype_name = entities_lib.resolve_possible_ghost(selected)
		if prototype_name ~= "ribbon-cables-mux" then return end
		local _, thing_id = remote.call("things", "get_status", selected)
		if not thing_id then
			debug_log("ribbon-cables-click: not a thing?")
			return
		end
		local cursor_stack = player.cursor_stack
		if not cursor_stack then return end
		if not cursor_stack.can_set_stack("ribbon-cables-wiring-tool") then
			return
		end
		local state = get_or_create_player_state(event.player_index)
		-- TODO: use Thing ID here in case ghost state changes
		state.connection_source = selected
		cursor_stack.set_stack("ribbon-cables-wiring-tool")
		-- XXX: debugging
		local _, tags = remote.call("things", "get_tags", selected)
		if not tags then tags = { clicker = 0 } end
		tags.clicker = (tags.clicker or 0) + 1
		remote.call("things", "set_tags", selected, tags)
	end
)

---@param player LuaPlayer
---@param event EventData.on_player_selected_area
local function try_complete_connection(player, event)
	if not event.entities or (#event.entities == 0) or (#event.entities > 1) then
		player.print({ "ribbon-cables.error-select-only-one" })
		return false
	end
	local connection_target = event.entities[1]

	local state = get_or_create_player_state(event.player_index)
	local connection_source = state.connection_source
	if not connection_source or not connection_source.valid then
		-- TODO: error msg?
		return false
	end
	if connection_source == connection_target then
		player.print({ "ribbon-cables.error-cannot-connect-to-self" })
		return false
	end

	debug_log("Connecting ", connection_source, " to ", connection_target)
	remote.call(
		"things",
		"modify_edge",
		"ribbon-cables",
		connection_source,
		connection_target,
		"toggle"
	)
end

script.on_event(defines.events.on_player_selected_area, function(event)
	local player = game.get_player(event.player_index)
	if not player then return end
	debug_log("on_player_selected_area: ", event)
	local cursor_stack = player.cursor_stack
	if
		not cursor_stack
		or not cursor_stack.valid
		or not cursor_stack.valid_for_read
	then
		return
	end
	if cursor_stack.name ~= "ribbon-cables-wiring-tool" then return end
	try_complete_connection(player, event)
	player.clear_cursor()
end)
