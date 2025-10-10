local event = require("lib.core.event")

---@param player LuaPlayer
---@param target_thing things.ThingSummary
---@param player_state ribbon_cables.PlayerState
local function toggle_connection(player, target_thing, player_state)
	local _, source_thing =
		remote.call("things", "get", player_state.connection_source)
	if
		not source_thing
		or not source_thing.entity
		or not source_thing.entity.valid
	then
		player_state.connection_source = nil
		player.clear_cursor()
		return
	end

	local _, res = remote.call(
		"things",
		"modify_edge",
		"ribbon-cables",
		source_thing.id,
		target_thing.id,
		"toggle"
	)
	if res == true then
		-- Connection was added
		player_state.connection_source = target_thing.id
	else
		-- Connection was removed
		player_state.connection_source = nil
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
			player_state.connection_source = nil
			player.clear_cursor()
			return
		end
		return toggle_connection(player, thing, player_state)
	else
		player_state.connection_source = thing.id
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
		if not thing then
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
	if state then state.connection_source = nil end
end)
