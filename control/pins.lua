-- Manage child pin entities.

local event = require("lib.core.event")
local strace = require("lib.core.strace")

---@param pin LuaEntity?
local function disconnect_one_pin_entirely(pin)
	if not pin then return end
	local reds =
		pin.get_wire_connector(defines.wire_connector_id.circuit_red, false)
	local greens =
		pin.get_wire_connector(defines.wire_connector_id.circuit_green, false)
	if reds then reds.disconnect_all(defines.wire_origin.script) end
	if greens then greens.disconnect_all(defines.wire_origin.script) end
end

---@param from_pin LuaEntity?
---@param to_pin LuaEntity?
local function connect_one_pin(from_pin, to_pin)
	if not from_pin or not to_pin then return end
	local reds_from =
		from_pin.get_wire_connector(defines.wire_connector_id.circuit_red, true)
	local greens_from =
		from_pin.get_wire_connector(defines.wire_connector_id.circuit_green, true)
	local reds_to =
		to_pin.get_wire_connector(defines.wire_connector_id.circuit_red, true)
	local greens_to =
		to_pin.get_wire_connector(defines.wire_connector_id.circuit_green, true)
	if reds_from and reds_to then
		reds_from.connect_to(reds_to, false, defines.wire_origin.script)
	end
	if greens_from and greens_to then
		greens_from.connect_to(greens_to, false, defines.wire_origin.script)
	end
end

---@param from_pin LuaEntity?
---@param to_pin LuaEntity?
local function disconnect_one_pin(from_pin, to_pin)
	if not from_pin or not to_pin then return end
	local reds_from =
		from_pin.get_wire_connector(defines.wire_connector_id.circuit_red, true)
	local greens_from =
		from_pin.get_wire_connector(defines.wire_connector_id.circuit_green, true)
	local reds_to =
		to_pin.get_wire_connector(defines.wire_connector_id.circuit_red, true)
	local greens_to =
		to_pin.get_wire_connector(defines.wire_connector_id.circuit_green, true)
	if reds_from and reds_to then
		reds_from.disconnect_from(reds_to, defines.wire_origin.script)
	end
	if greens_from and greens_to then
		greens_from.disconnect_from(greens_to, defines.wire_origin.script)
	end
end

---Remove all script wires connecting pins to other pins.
---@param pins {[string|int]: things.ThingSummary}?
local function disconnect_all_pins_entirely(pins)
	if not pins then return end
	for index, child_summary in pairs(pins) do
		disconnect_one_pin_entirely(child_summary.entity)
	end
end

---@param from_pins {[string|int]: things.ThingSummary}?
---@param to_pins {[string|int]: things.ThingSummary}?
local function connect_each_pin(from_pins, to_pins)
	if not from_pins or not to_pins then return end
	for from_index, from_pin_summary in pairs(from_pins) do
		local to_pin_summary = to_pins[from_index]
		if to_pin_summary then
			connect_one_pin(from_pin_summary.entity, to_pin_summary.entity)
		end
	end
end

---@param from_pins {[string|int]: things.ThingSummary}?
---@param to_pins {[string|int]: things.ThingSummary}?
local function disconnect_each_pin(from_pins, to_pins)
	if not from_pins or not to_pins then return end
	for from_index, from_pin_summary in pairs(from_pins) do
		local to_pin_summary = to_pins[from_index]
		if to_pin_summary then
			disconnect_one_pin(from_pin_summary.entity, to_pin_summary.entity)
		end
	end
end

---@param my_pins {[string|int]: things.ThingSummary}?
---@param neighbor_id uint64?
local function connect_one_neighbor(my_pins, neighbor_id)
	if not my_pins or not neighbor_id then return end
	local _, neighbor_pins = remote.call("things", "get_children", neighbor_id)
	connect_each_pin(my_pins, neighbor_pins)
end

---@param my_pins {[string|int]: things.ThingSummary}?
---@param neighbor_id uint64?
local function disconnect_one_neighbor(my_pins, neighbor_id)
	if not my_pins or not neighbor_id then return end
	local _, neighbor_pins = remote.call("things", "get_children", neighbor_id)
	disconnect_each_pin(my_pins, neighbor_pins)
end

---@param me things.ThingSummary?
---@param my_pins {[string|int]: things.ThingSummary}?
---@param out_edges {[int64]: things.GraphEdge}?
---@param in_edges {[int64]: things.GraphEdge}?
local function connect_all_neighbors(me, my_pins, out_edges, in_edges)
	if not me then return end
	if not my_pins then
		_, my_pins = remote.call("things", "get_children", me.id)
	end
	if not out_edges or not in_edges then
		_, out_edges, in_edges =
			remote.call("things", "get_edges", "ribbon-cables", me.id)
	end
	if not out_edges or not in_edges then return end
	for neighbor_id in pairs(out_edges) do
		connect_one_neighbor(my_pins, neighbor_id)
	end
	for neighbor_id in pairs(in_edges) do
		connect_one_neighbor(my_pins, neighbor_id)
	end
end

---@param me things.ThingSummary?
---@param my_pins {[string|int]: things.ThingSummary}?
local function disconnect_all_neighbors(me, my_pins)
	if not me then return end
	if not my_pins then
		_, my_pins = remote.call("things", "get_children", me.id)
	end
	disconnect_all_pins_entirely(my_pins)
end

---@param mux_thing_summary things.ThingSummary
---@param create_if_missing boolean?
---@return LuaEntity? entity
---@return ribbon_cables.Multiplexer? state
local function get_mux_info(mux_thing_summary, create_if_missing)
	local entity = mux_thing_summary.entity
	local state = nil
	if create_if_missing then
		state = get_or_create_multiplexer_state(mux_thing_summary.id)
	else
		state = get_multiplexer_state(mux_thing_summary.id)
	end
	return entity, state
end

event.bind(
	"ribbon-cables-on_initialized",
	---@param ev things.EventData.on_initialized
	function(ev)
		local entity, mux = get_mux_info(ev, true)
		if not entity or not mux then
			return debug_crash(
				"RIBBON-CABLES: invalid mux in things-on_initialized, shouldnt happen."
			)
		end
		if mux then mux:update_connection_render_objects() end
	end
)

event.bind(
	"ribbon-cables-on_status",
	---@param ev things.EventData.on_status
	function(ev)
		strace.trace("ribbon-cables-on_status", ev)
		if ev.new_status == "destroyed" then
			local mux = get_multiplexer_state(ev.thing.id)
			if mux then mux:destroy() end
			return
		end
		local entity, mux = get_mux_info(ev.thing, false)
		if mux then mux:update_connection_render_objects() end
		if ev.old_status == "ghost" and ev.new_status == "real" then
			-- Connect to all neighbors on revival.
			connect_all_neighbors(ev.thing)
		end
	end
)

event.bind(
	"ribbon-cables-on_edge_changed",
	---@param ev things.EventData.on_edge_changed
	function(ev)
		strace.trace("ribbon-cables-on_edge_changed", ev)
		local _, pins = remote.call("things", "get_children", ev.from.id)
		local entity, mux = get_mux_info(ev.from, false)
		if mux then mux:update_connection_render_objects() end
		entity, mux = get_mux_info(ev.to, false)
		if mux then mux:update_connection_render_objects() end
		if ev.change == "create" then
			connect_one_neighbor(pins, ev.to.id)
		elseif ev.change == "delete" then
			disconnect_one_neighbor(pins, ev.to.id)
		end
	end
)

event.bind(
	"ribbon-cables-on_children_normalized",
	---@param ev things.EventData.on_children_normalized
	function(ev)
		strace.trace("ribbon-cables-on_children_normalized", ev)
		-- Reconnect to all neighbors if not ghost
		if ev.status == "real" then
			local _, pins = remote.call("things", "get_children", ev.id)
			disconnect_all_neighbors(ev, pins)
			connect_all_neighbors(ev, pins, nil, nil)
		end
	end
)

event.bind(
	"ribbon-cables-on_edge_status",
	---@param ev things.EventData.on_edge_status
	function(ev)
		strace.trace("ribbon-cables-on_edge_status", ev)
		local entity, mux = get_mux_info(ev.thing, false)
		if mux then mux:update_connection_render_objects() end
		entity, mux = get_mux_info(ev.changed_thing, false)
		if mux then mux:update_connection_render_objects() end
	end
)

-- Render pin labels when selecting a pin or mux entity.
event.bind(
	defines.events.on_selected_entity_changed,
	---@param ev EventData.on_selected_entity_changed
	function(ev)
		local player = game.get_player(ev.player_index)
		local player_state = get_or_create_player_state(ev.player_index)
		if not player or not player_state then return end
		local selected = player.selected
		player_state:clear_pin_labels()
		if not selected then return end
		local _, selected_thing = remote.call("things", "get", selected)
		if
			not selected_thing
			or not (
				selected_thing.name == "ribbon-cables-pin"
				or selected_thing.name == "ribbon-cables-mux"
			)
		then
			return
		end
		if selected_thing.name == "ribbon-cables-pin" then
			_, selected_thing = remote.call("things", "get", selected_thing.parent[1])
		end
		if not selected_thing then return end
		player_state:render_pin_labels(selected_thing, nil)
	end
)
