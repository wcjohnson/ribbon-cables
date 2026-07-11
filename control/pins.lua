--------------------------------------------------------------------------------
-- Child pin entities
--------------------------------------------------------------------------------

local event = require("lib.core.event")
local strace = require("lib.core.strace")
local olib = require("lib.core.orientation.orientation")
---@diagnostic disable-next-line: unresolved-require
local things_client = require("__0-things__.client.client") --[[@as things.client]]

local get_children = things_client.parent_child_v1.get_children

local transform_offset = olib.transform_offset

--------------------------------------------------------------------------------
-- Pin wiring
--------------------------------------------------------------------------------

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
---@param pins table<string, things.ThingChildInfo>?
local function disconnect_all_pins_entirely(pins)
	if not pins then return end
	for index, child_summary in pairs(pins) do
		disconnect_one_pin_entirely(child_summary.entity)
	end
end

---@param from_pins table<string, things.ThingChildInfo>?
---@param to_pins table<string, things.ThingChildInfo>?
local function connect_each_pin(from_pins, to_pins)
	if not from_pins or not to_pins then return end
	for from_index, from_pin_summary in pairs(from_pins) do
		local to_pin_summary = to_pins[from_index]
		if to_pin_summary then
			connect_one_pin(from_pin_summary.entity, to_pin_summary.entity)
		end
	end
end

---@param from_pins table<string, things.ThingChildInfo>?
---@param to_pins table<string, things.ThingChildInfo>?
local function disconnect_each_pin(from_pins, to_pins)
	if not from_pins or not to_pins then return end
	for from_index, from_pin_summary in pairs(from_pins) do
		local to_pin_summary = to_pins[from_index]
		if to_pin_summary then
			disconnect_one_pin(from_pin_summary.entity, to_pin_summary.entity)
		end
	end
end

---@param my_pins table<string, things.ThingChildInfo>?
---@param neighbor_id uint64?
local function connect_one_neighbor(my_pins, neighbor_id)
	if not my_pins or not neighbor_id then return end
	local _, neighbor = remote.call("things", "get", neighbor_id)
	if not neighbor or neighbor.status ~= "real" then return end
	local neighbor_pins = get_children(neighbor_id)
	connect_each_pin(my_pins, neighbor_pins)
end

---@param my_pins table<string, things.ThingChildInfo>?
---@param neighbor_id uint64?
local function disconnect_one_neighbor(my_pins, neighbor_id)
	if not my_pins or not neighbor_id then return end
	local neighbor_pins = get_children(neighbor_id)
	disconnect_each_pin(my_pins, neighbor_pins)
end

---@param me things.ThingSummary?
---@param my_pins table<string, things.ThingChildInfo>?
---@param out_edges {[int64]: things.GraphEdge}?
---@param in_edges {[int64]: things.GraphEdge}?
local function connect_all_neighbors(me, my_pins, out_edges, in_edges)
	if not me then return end
	if not my_pins then my_pins = get_children(me.id) end
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
---@param my_pins table<string, things.ThingChildInfo>?
local function disconnect_all_neighbors(me, my_pins)
	if not me then return end
	if not my_pins then my_pins = get_children(me.id) end
	disconnect_all_pins_entirely(my_pins)
end

--------------------------------------------------------------------------------
-- Dynamic pins
--------------------------------------------------------------------------------

local PIN_OFFSET = 0.4
local INNER_PIN_OFFSET = 0.2

local pin_layouts = {
	[0] = {},
	[2] = { { -PIN_OFFSET, 0 }, { PIN_OFFSET, 0 } },
	[4] = {
		{ 0, -PIN_OFFSET },
		{ PIN_OFFSET, 0 },
		{ 0, PIN_OFFSET },
		{ -PIN_OFFSET, 0 },
	},
	[8] = {
		{ 0, -PIN_OFFSET },
		{ PIN_OFFSET, -PIN_OFFSET },
		{ PIN_OFFSET, 0 },
		{ PIN_OFFSET, PIN_OFFSET },
		{ 0, PIN_OFFSET },
		{ -PIN_OFFSET, PIN_OFFSET },
		{ -PIN_OFFSET, 0 },
		{ -PIN_OFFSET, -PIN_OFFSET },
	},
	[16] = {
		{ 0, -PIN_OFFSET },
		{ PIN_OFFSET, -PIN_OFFSET },
		{ PIN_OFFSET, 0 },
		{ PIN_OFFSET, PIN_OFFSET },
		{ 0, PIN_OFFSET },
		{ -PIN_OFFSET, PIN_OFFSET },
		{ -PIN_OFFSET, 0 },
		{ -PIN_OFFSET, -PIN_OFFSET },
		{ 0, -INNER_PIN_OFFSET },
		{ INNER_PIN_OFFSET, -INNER_PIN_OFFSET },
		{ INNER_PIN_OFFSET, 0 },
		{ INNER_PIN_OFFSET, INNER_PIN_OFFSET },
		{ 0, INNER_PIN_OFFSET },
		{ -INNER_PIN_OFFSET, INNER_PIN_OFFSET },
		{ -INNER_PIN_OFFSET, 0 },
		{ -INNER_PIN_OFFSET, -INNER_PIN_OFFSET },
	},
}

---@param parent_entity LuaEntity
---@param pos MapPosition
local function create_pin_entity(parent_entity, pos)
	return parent_entity.surface.create_entity({
		name = "ribbon-cables-pin",
		position = pos,
		force = parent_entity.force,
		raise_built = false,
		create_build_effect_smoke = false,
	})
end

local function create_pin_thing(parent, child_entity, index, num, offset)
	remote.call("things", "create_thing", {
		entity = child_entity,
		parent = parent.id,
		child_index = index,
		relative_pos = offset,
		tags = {
			n = num,
		},
	})
end

local function devoid_pin_thing(child_id, child_entity)
	remote.call("things", "create_thing", {
		devoid = child_id,
		entity = child_entity,
	})
end

---Check a mux for correct number and placement of pins, creating or destroying pin entities as needed.
---@param parent things.ThingShortSummary
---@param n_pins 0|2|4|8|16
function _G.check_pins(parent, n_pins)
	local pin_layout = pin_layouts[n_pins]
	if not pin_layout then
		error("LOGIC ERROR: invalid number of pins: " .. n_pins)
		return
	end
	local parent_entity = parent.entity
	if not parent_entity then
		error("LOGIC ERROR: parent entity is nil for mux " .. parent.id)
		return
	end

	local did_work = false
	local parent_pos = parent_entity.position
	local parent_status = parent.status
	local child_should_live = parent_status == "real" or parent_status == "ghost"

	local children = get_children(parent.id)
	for i = 1, n_pins do
		local pin_index = tostring(i)
		local pin_offset = pin_layout[i] --[[@as MapPosition]]
		local child_info = children and children[pin_index]
		local child = child_info and child_info.thing

		if (not child) and child_should_live then
			-- Must create entity and thing
			local child_pos =
				transform_offset(parent_pos, parent.virtual_orientation, pin_offset)
			local child_entity = create_pin_entity(parent_entity, child_pos)
			if child_entity then
				create_pin_thing(parent, child_entity, pin_index, i, pin_offset)
				strace.trace("created pin", pin_index, "of mux", parent.id)
				did_work = true
			else
				strace.error("Failed to create pin entity for thing", parent.id)
			end
		elseif child and (child.status == "void") and child_should_live then
			-- Must create entity and devoid thing
			local child_pos =
				transform_offset(parent_pos, parent.virtual_orientation, pin_offset)
			local child_entity = create_pin_entity(parent_entity, child_pos)
			if child_entity then
				devoid_pin_thing(child.id, child_entity)
				strace.trace("devoided pin", pin_index, "of mux", parent.id)
				did_work = true
			else
				strace.error("Failed to create pin entity for thing", parent.id)
			end
		elseif child and (child.status ~= "void") and not child_should_live then
			remote.call("things", "void", child.id)
			did_work = true
		end
	end

	if did_work then
		event.raise("ribbon-cables.mux_children_normalized", parent)
	end
end

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

---@param mux_thing_summary things.ThingShortSummary
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
			error(
				"LOGIC ERROR: invalid mux in things-on_initialized, shouldnt happen."
			)
			return
		end
		local n_pins_tag = (ev.tags and ev.tags.n_pins) --[[@as uint?]]
		if n_pins_tag then
			mux.n_pins = n_pins_tag
		else
			---@type any, uint
			local _, n_children = remote.call("things", "get_num_children", ev.id)
			n_children = n_children or 0
			if n_children > 8 then
				n_children = 16
			elseif n_children > 4 then
				n_children = 8
			elseif n_children > 2 then
				n_children = 4
			elseif n_children > 0 then
				n_children = 2
			else
				n_children = 0
			end
			mux.n_pins = n_children
		end
		strace.trace("Initialized mux", mux.thing_id, "with", mux.n_pins, "pins")
		-- Create pins
		check_pins(ev, mux.n_pins)
		if mux then mux:update_connection_render_objects() end
		-- NOTE: on_children_normalized handles neighbor connection on creation
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
		-- Check pins in all non-void states
		if mux and (ev.new_status == "ghost" or ev.new_status == "real") then
			check_pins(ev.thing, mux.n_pins)
		end
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
		local pins = get_children(ev.from.id)
		local entity, mux = get_mux_info(ev.from, false)
		if mux then mux:update_connection_render_objects() end
		entity, mux = get_mux_info(ev.to, false)
		if mux then mux:update_connection_render_objects() end
		if
			ev.change == "create"
			and ev.from.status == "real"
			and ev.to.status == "real"
		then
			-- Connection between nonghost = connect pins
			connect_one_neighbor(pins, ev.to.id)
		elseif ev.change == "delete" then
			disconnect_one_neighbor(pins, ev.to.id)
		end
	end
)

event.bind(
	"ribbon-cables.mux_children_normalized",
	---@param mux_thing_summary things.ThingSummary
	function(mux_thing_summary)
		-- Reconnect to all neighbors if not ghost
		if mux_thing_summary.status == "real" then
			strace.trace(
				"ribbon-cables.mux_children_normalized",
				mux_thing_summary,
				"reconnecting to neighbors"
			)
			local pins = get_children(mux_thing_summary.id)
			disconnect_all_neighbors(mux_thing_summary, pins)
			connect_all_neighbors(mux_thing_summary, pins, nil, nil)
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

event.bind("ribbon-cables.mux_pins_changed", function(ev)
	local _, thing = remote.call("things", "get", ev.thing_id)
	if not thing then return end
	local n_pins = ev:get_n_pins()
	remote.call("things", "set_tag", thing.id, "n_pins", n_pins)
	check_pins(thing, n_pins)
end)

--------------------------------------------------------------------------------
-- PIN LABELS
--------------------------------------------------------------------------------

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
				or selected_thing.name == "ribbon-cables-pin-legacy"
				or selected_thing.name == "ribbon-cables-mux"
			)
		then
			return
		end
		if
			selected_thing.name == "ribbon-cables-pin"
			or selected_thing.name == "ribbon-cables-pin-legacy"
		then
			if selected_thing.parent then
				_, selected_thing =
					remote.call("things", "get", selected_thing.parent[1])
			else
				return
			end
		end
		if not selected_thing then return end
		player_state:render_pin_labels(selected_thing, nil)
	end
)

-- When mux orientation changes, pin labels need to be redrawn for all players
-- that have them shown.
event.bind(
	"ribbon-cables-on_orientation_changed",
	---@param ev things.EventData.on_orientation_changed
	function(ev)
		strace.trace("ribbon-cables-on_orientation_changed", ev)
		local entity = ev.thing.entity
		if not entity then return end
		for _, player in pairs(game.connected_players) do
			if player.selected == entity then
				local player_state = get_or_create_player_state(player.index)
				if player_state then player_state:render_pin_labels(ev.thing, nil) end
			end
		end
	end
)

--------------------------------------------------------------------------------
-- SUPPRESS CONTAINER GUI
-- If a pin is clicked, close the resulting container GUI.
--------------------------------------------------------------------------------

event.bind(
	defines.events.on_gui_opened,
	---@param ev EventData.on_gui_opened
	function(ev)
		if ev.gui_type ~= defines.gui_type.entity then return end
		local entity = ev.entity
		if not entity then return end
		local player = game.get_player(ev.player_index)
		if not player then return end
		local name = entity.type == "entity-ghost" and entity.ghost_name
			or entity.name
		if
			(name ~= "ribbon-cables-pin-legacy") and (name ~= "ribbon-cables-pin")
		then
			return
		end
		player.opened = nil
	end
)
