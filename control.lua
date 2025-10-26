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
require("control.custom-labels")

-- Enable support for the Global Variable Viewer debugging mod, if it is
-- installed.
if script.active_mods["gvv"] then require("__gvv__.gvv")() end
