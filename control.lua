local strace = require("lib.core.strace")

local stringify = strace.stringify
local format_tick_relative =
	require("lib.core.math.numeric").format_tick_relative
local select = select

strace.set_handler(function(level, ...)
	local frame = game.ticks_played
	local cat_tbl = {
		"[",
		frame,
		format_tick_relative(frame, 0),
		strace.level_to_string[level],
		"]",
	}
	strace.foreach(function(key, value, ...)
		if key == "level" then
		-- skip
		elseif key == "message" then
			cat_tbl[#cat_tbl + 1] = stringify(value)
			for i = 1, select("#", ...) do
				cat_tbl[#cat_tbl + 1] = stringify(select(i, ...))
			end
		else
			cat_tbl[#cat_tbl + 1] = " "
			cat_tbl[#cat_tbl + 1] = tostring(key)
			cat_tbl[#cat_tbl + 1] = "="
			cat_tbl[#cat_tbl + 1] = stringify(value)
		end
	end, level, ...)
	log(table.concat(cat_tbl, " "))
end)

local entities_lib = require("lib.core.entities")
local pos_lib = require("lib.core.math.pos")
local constants = require("lib.constants")
local orientation_lib = require("lib.core.orientation.orientation")
local events = require("lib.core.event")

require("control.multiplexer")
require("control.storage")

-- Enable support for the Global Variable Viewer debugging mod, if it is
-- installed.
if script.active_mods["gvv"] then require("__gvv__.gvv")() end

-- script.on_event(
-- 	"things-on_initialized",
-- 	---@param event things.EventData.on_initialized
-- 	function(event)
-- 		debug_log("RIBBON-CABLES: things-on_initialized: ", event)
-- 		local entity = event.entity --[[@as LuaEntity?]]
-- 		if
-- 			entity
-- 			and entity.valid
-- 			and entities_lib.true_prototype_name(entity) == constants.mux_name
-- 		then
-- 			get_or_create_multiplexer_state(event.id)
-- 			debug_log("RIBBON-CABLES: created state ", event.id)
-- 			local O = orientation_lib.from_data(event.virtual_orientation)
-- 			if not O then
-- 				debug_crash("RIBBON-CABLES: failed to decode orientation")
-- 				return
-- 			end
-- 			local _, children = remote.call("things", "get_children", event.id)
-- 			if not children then
-- 				debug_crash("RIBBON-CABLES: get_children failed")
-- 				return
-- 			end
-- 			for i = 1, 2 do
-- 				if not children[i] then
-- 					local pin_pos = pos_lib.pos_add(
-- 						pos_lib.pos_new(entity.position),
-- 						pin_distance,
-- 						O:local_to_world_offset(pin_offsets[i])
-- 					)
-- 					local pin = entity.surface.create_entity({
-- 						name = constants.pin_name,
-- 						position = pin_pos,
-- 						force = entity.force,
-- 						create_build_effect_smoke = false,
-- 						raise_built = true,
-- 					})
-- 					if not pin then
-- 						debug_crash("RIBBON-CABLES: failed to create pin")
-- 						return
-- 					end
-- 					local res = remote.call("things", "add_child", entity, i, pin)
-- 					if res then debug_log("RIBBON-CABLES: add_child failed", res) end
-- 				else
-- 					debug_log("RIBBON-CABLES: pin already exists at index ", i)
-- 				end
-- 			end
-- 		end
-- 	end
-- )

-- script.on_event(
-- 	"things-on_orientation_changed",
-- 	---@param event things.EventData.on_orientation_changed
-- 	function(event)
-- 		debug_log("RIBBON-CABLES: things-on_orientation_changed: ", event)
-- 		local thing_id = event.thing.id
-- 		local thing_entity = event.thing.entity
-- 		if not thing_entity or not thing_entity.valid then
-- 			debug_crash("RIBBON-CABLES: no valid entity for ", thing_id)
-- 			return
-- 		end
-- 		local st = get_multiplexer_state(thing_id)
-- 		if not st then
-- 			debug_crash("RIBBON-CABLES: no state for ", thing_id)
-- 			return
-- 		end
-- 		local _, children = remote.call("things", "get_children", thing_id)
-- 		if not children then
-- 			debug_crash("RIBBON-CABLES: get_children failed")
-- 			return
-- 		end
-- 		for i = 1, 2 do
-- 			local child = children[i]
-- 			if child and child.entity and child.entity.valid then
-- 				local O = orientation_lib.from_data(event.new_orientation)
-- 				if not O then
-- 					debug_crash("RIBBON-CABLES: failed to decode orientation")
-- 					return
-- 				end
-- 				local pin_pos = pos_lib.pos_add(
-- 					pos_lib.pos_new(thing_entity.position),
-- 					pin_distance,
-- 					O:local_to_world_offset(pin_offsets[i])
-- 				)
-- 				child.entity.teleport(pin_pos, nil, false, false)
-- 			else
-- 				debug_log("RIBBON-CABLES: no pin at index ", i)
-- 			end
-- 		end
-- 	end
-- )

-- events.bind(
-- 	"ribbon-cables-on_status_changed",
-- 	---@param event things.EventData.on_status
-- 	function(event)
-- 		if event.new_status == "destroyed" then
-- 			local st = get_multiplexer_state(event.thing.id)
-- 			if st then st:destroy() end
-- 		end
-- 	end
-- )

-- events.bind(
-- 	"ribbon-cables-on_edges_changed",
-- 	---@param event things.EventData.on_edges_changed
-- 	function(event)
-- 		if event.graph_name ~= "ribbon-cables" then return end
-- 		debug_log("RIBBON-CABLES: things-on_edges_changed: ", event.nodes)
-- 		for thing_id in pairs(event.nodes) do
-- 			local st = get_multiplexer_state(thing_id)
-- 			if st then st:update_connection_render_objects() end
-- 		end
-- 	end
-- )

require("control.pins")
require("control.wiring-tool")

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
		local _, thing = remote.call("things", "get", selected)
		if not thing then
			strace.debug("ribbon-cables-click: not a thing?")
			return
		end
		-- XXX: debugging
		local tags = thing.tags
		if not tags then tags = { clicker = 0 } end
		tags.clicker = (tags.clicker or 0) + 1
		remote.call("things", "set_tags", selected, tags)
	end
)
