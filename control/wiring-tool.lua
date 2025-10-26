local event = require("lib.core.event")
local strace = require("lib.core.strace")
local constants = require("lib.constants")
local pos_lib = require("lib.core.math.pos")

local MAX_DISTANCE = constants.ribbon_cable_max_distance
local MAX_DISTSQ = MAX_DISTANCE * MAX_DISTANCE

---@param player LuaPlayer
---@param target_thing things.ThingSummary
---@param player_state ribbon_cables.PlayerState
local function toggle_connection(player, target_thing, player_state)
	local _, source_thing =
		remote.call("things", "get", player_state.connection_source)
	if not source_thing or not source_thing.entity then
		strace.warn("Cannot find source thing", player_state.connection_source)
		player_state.connection_source = nil
		player.clear_cursor()
		return
	end

	local source_entity = source_thing.entity --[[@as LuaEntity]]
	local target_entity = target_thing.entity --[[@as LuaEntity]]
	local distsq =
		pos_lib.pos_distsq(source_entity.position, target_entity.position)
	if distsq > MAX_DISTSQ then
		player.print(
			{ "ribbon-cables.error-too-far" },
			{ skip = defines.print_skip.never, sound = defines.print_sound.always }
		)
		player_state:clear_connection()
		player.clear_cursor()
		return
	end

	strace.trace(
		"Toggling connection from thing",
		source_thing.id,
		"to thing",
		target_thing.id,
		"for player",
		player.index
	)
	local err, res = remote.call(
		"things",
		"modify_edge",
		"ribbon-cables",
		"toggle",
		source_thing.id,
		target_thing.id
	)
	if err then
		strace.error(
			"Error toggling connection from thing",
			source_thing.id,
			"to thing",
			target_thing.id,
			":",
			err
		)
	end
	if res == true then
		-- Connection was added
		player_state:set_connection_source(target_thing.id)
	else
		-- Connection was removed
		player_state:clear_connection()
	end
end

---@param player LuaPlayer
---@param thing things.ThingSummary
---@param player_state ribbon_cables.PlayerState
local function selected_with_wiring_tool(player, thing, player_state)
	local mux_state = get_multiplexer_state(thing.id)
	if not mux_state then
		player.print(
			{ "ribbon-cables.error-select-valid-entity" },
			{ skip = defines.print_skip.never, sound = defines.print_sound.always }
		)
		return
	end

	if player_state.connection_source then
		if player_state.connection_source == thing.id then
			player.print(
				{ "ribbon-cables.error-cannot-connect-to-self" },
				{ skip = defines.print_skip.never, sound = defines.print_sound.always }
			)
			player_state:clear_connection()
			player.clear_cursor()
			return
		end
		return toggle_connection(player, thing, player_state)
	else
		strace.trace(
			"Setting connection source to thing",
			thing.id,
			"for player",
			player.index
		)
		player_state:set_connection_source(thing.id)
	end
end

-- Broadphase select
event.bind(
	defines.events.on_player_selected_area,
	---@param ev EventData.on_player_selected_area
	function(ev)
		-- Sanity checks
		local player = game.get_player(ev.player_index)
		if not player then return end
		local cursor_stack = player.cursor_stack
		if
			not cursor_stack
			or not cursor_stack.valid
			or not cursor_stack.valid_for_read
		then
			return
		end
		if cursor_stack.name ~= "ribbon-cables-wiring-tool" then return end

		-- Find clicked Thing
		if not ev.entities or (#ev.entities == 0) or (#ev.entities > 1) then
			player.print(
				{ "ribbon-cables.error-select-only-one" },
				{ skip = defines.print_skip.never, sound = defines.print_sound.always }
			)
			return
		end

		local target = ev.entities[1]
		local _, thing = remote.call("things", "get", target)
		if not thing or thing.name ~= "ribbon-cables-mux" then
			player.print(
				{ "ribbon-cables.error-select-valid-entity" },
				{ skip = defines.print_skip.never, sound = defines.print_sound.always }
			)
			player.clear_cursor()
			return
		end

		local state = get_or_create_player_state(ev.player_index)
		selected_with_wiring_tool(player, thing, state)
	end
)

-- Cursor clear
event.bind("ribbon-cables-linked-clear-cursor", function(ev)
	local player = game.get_player(ev.player_index)
	if not player then return end
	local state = get_player_state(ev.player_index)
	if state then state:clear_connection() end
end)

-- Cursor select. Render a hypothetical edge.
event.bind(
	defines.events.on_selected_entity_changed,
	---@param ev EventData.on_selected_entity_changed
	function(ev)
		local player = game.get_player(ev.player_index)
		local player_state = get_player_state(ev.player_index)
		if not player or not player_state or not player_state.connection_source then
			return
		end
		local selected = player.selected
		player_state:clear_possible_connection_rendering()
		if not selected then return end
		local _, selected_thing = remote.call("things", "get", selected)
		if
			not selected_thing
			or selected_thing.name ~= "ribbon-cables-mux"
			or selected_thing.id == player_state.connection_source
		then
			return
		end
		local _, origin_thing =
			remote.call("things", "get", player_state.connection_source)
		if not origin_thing or not origin_thing.entity then return end
		local will_connect = true
		local _, edge = remote.call(
			"things",
			"get_edge",
			"ribbon-cables",
			player_state.connection_source,
			selected_thing.id
		)
		if edge then will_connect = false end
		if
			pos_lib.pos_distsq(
				origin_thing.entity.position,
				selected_thing.entity.position
			) > MAX_DISTSQ
		then
			will_connect = false
		end
		if will_connect then
			player_state:render_possible_connection(
				origin_thing.entity,
				selected_thing.entity
			)
		else
			player_state:render_possible_disconnection(
				origin_thing.entity,
				selected_thing.entity
			)
		end
	end
)
