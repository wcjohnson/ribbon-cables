--------------------------------------------------------------------------------
-- PIN CONNECTION UNDO
-- When a pin is voided, pickle its circuit connections by world key.
-- When it is devoided, restore them.
--------------------------------------------------------------------------------

local events = require("lib.core.event")
local strace = require("lib.core.strace")
local ws_lib = require("lib.core.world-state")

local get_world_key = ws_lib.get_world_key
local get_world_state = ws_lib.get_world_state
local find_matching = ws_lib.find_matching

---Full representation of a wire connection from a Pin to something else.
---[1] The Thing ID of the Pin.
---[2] The wire connector ID on the Pin.
---[3] The World State of the target entity.
---[4] The wire connector ID on the target entity.
---@alias ribbon_cables.WireConnection [int64, defines.wire_connector_id, Core.WorldState, defines.wire_connector_id]

---Make a unique key for a wire connection record.
---@param connection ribbon_cables.WireConnection
local function make_connection_key(connection)
	return string.format(
		"%d-%d-%d-%s",
		connection[1],
		connection[2],
		connection[4],
		connection[3].key
	)
end

---@alias ribbon_cables.WireConnectionMap table<string, ribbon_cables.WireConnection>

---Save all non-scripted wire connections from a pin.
---@param map ribbon_cables.WireConnectionMap
---@param pin things.ThingSummary
local function save_connections(map, pin)
	local pin_entity = pin.entity
	if not pin_entity then return end
	for pin_connector_id, pin_connector in
		pairs(pin_entity.get_wire_connectors(false))
	do
		local connections = pin_connector.connections
		for _, connection in pairs(connections) do
			-- Save only player wires.
			if
				connection.origin == nil
				or connection.origin == defines.wire_origin.player
			then
				local ws = get_world_state(connection.target.owner)
				local record = {
					pin.id,
					pin_connector_id,
					ws,
					connection.target.wire_connector_id,
				}
				local key = make_connection_key(record)
				map[key] = record
			end
		end
	end
end

---Restore all mapped wire connections to a pin.
---@param map ribbon_cables.WireConnectionMap
---@param pin things.ThingSummary
local function restore_connections_to(map, pin)
	local pin_entity = pin.entity
	if not pin_entity then return end
	for _, connection in pairs(map) do
		if connection[1] == pin.id then
			local target_entity = find_matching(connection[3])[1]
			if target_entity then
				local pin_connector = pin_entity.get_wire_connector(connection[2], true)
				local target_connector =
					target_entity.get_wire_connector(connection[4], true)
				if pin_connector and target_connector then
					pin_connector.connect_to(target_connector, true)
				end
			end
		end
	end
end

-- When Mux is MFD, save all child wires
events.bind(
	defines.events.on_marked_for_deconstruction,
	---@param ev EventData.on_marked_for_deconstruction
	function(ev)
		local _, thing = remote.call("things", "get", ev.entity)
		if not thing or thing.name ~= "ribbon-cables-mux" then return end
		local _, children = remote.call("things", "get_children", thing.id)
		if not children then return end
		for _, pin in pairs(children) do
			local connection_map = {}
			save_connections(connection_map, pin)
			remote.call(
				"things",
				"set_transient_data",
				pin.id,
				"connections",
				connection_map
			)
		end
	end
)

-- When Mux is unMFD, clear all child wire storage
events.bind(
	defines.events.on_cancelled_deconstruction,
	---@param ev EventData.on_cancelled_deconstruction
	function(ev)
		local _, thing = remote.call("things", "get", ev.entity)
		if not thing or thing.name ~= "ribbon-cables-mux" then return end
		local _, children = remote.call("things", "get_children", thing.id)
		if not children then return end
		for _, pin in pairs(children) do
			remote.call("things", "set_transient_data", pin.id, "connections", nil)
		end
	end
)

-- At top of Frame, mark active = true and clear saved state

-- While active, if a wire to/from a pin is disconnected, save "disconnected(pin, wire)"

-- At bottom of Frame, mark active = false

-- When pin voided, if no wires were marked from MFD, combine current wires with all associated `disconnected(pin, wire)` records and save that as the pin's redo state.
events.bind(
	"ribbon-cables-on_pin_immediate_voided",
	---@param ev things.EventData.on_immediate_voided
	function(ev)
		local pin_entity = ev.entity
		if not pin_entity then return end
		local _, transient = remote.call("things", "get_transient_data", ev.id)
		if transient and transient.connections then return end
		local connections = {}
		save_connections(connections, ev)
		remote.call(
			"things",
			"set_transient_data",
			ev.id,
			"connections",
			connections
		)
	end
)

-- When pin restored from void, restore all saved wires.
events.bind(
	"ribbon-cables-on_pin_status",
	---@param ev things.EventData.on_status
	function(ev)
		if ev.new_status == "destroyed" then return end
		if ev.old_status ~= "void" then return end
		local pin_entity = ev.thing.entity
		if not pin_entity then return end
		local _, transient_data =
			remote.call("things", "get_transient_data", ev.thing.id)
		if not transient_data or not transient_data.connections then return end
		remote.call("things", "set_transient_data", ev.thing.id, "connections", nil)
		restore_connections_to(
			transient_data.connections --[[@as ribbon_cables.WireConnectionMap]],
			ev.thing
		)
	end
)
