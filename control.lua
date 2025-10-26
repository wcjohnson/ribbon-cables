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

require("control.multiplexer")
require("control.storage")

require("control.pins")
require("control.wiring-tool")
require("control.undo-wire-fix")

-- Enable support for the Global Variable Viewer debugging mod, if it is
-- installed.
if script.active_mods["gvv"] then require("__gvv__.gvv")() end

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
