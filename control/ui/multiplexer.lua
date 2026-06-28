local event = require("lib.core.event")
local relm = require("lib.core.relm.relm")
local ultros = require("lib.core.relm.ultros")
local relm_util = require("lib.core.relm.util")
local strace = require("lib.core.strace")
local entities_lib = require("lib.core.entities")

relm.define("MuxUi", function(props)
	local root_id = props.root_id
	local player_index = props.player_index
	local player = game.get_player(player_index)
	local mux = props.mux --[[@as ribbon_cables.Multiplexer]]
	local n_pins = mux:get_n_pins()
	local pin_labels = mux:get_pin_labels()

	if (not player) or not player.valid then return end

	-- Window management
	local function close_me() relm.root_destroy(root_id) end

	local handle_close = ultros.use_memoized_window_position(close_me, function()
		local st = get_player_state(player_index)
		return st and st.mux_window_position
	end, function(xy)
		local st = get_or_create_player_state(player_index)
		st.mux_window_position = xy
	end, function(elt) elt.force_auto_center() end)

	ultros.use_close_on_gui_closed(player_index, close_me, false)
	ultros.use_player_opened(player_index)

	relm_util.use_event_handler(
		"ribbon-cables.mux_pins_changed",
		function(_me, _, _ic)
			if _ic.thing_id == mux.thing_id then relm.paint(_me) end
		end
	)

	local elts = {}

	elts[#elts + 1] = ultros.CallIf(n_pins == 0, function()
		return ultros.HFlow({ width = 300 }, {
			ultros.Button({
				caption = "2 pins",
				width = 300 / 4,
				on_click = function() mux:set_n_pins(2) end,
			}),
			ultros.Button({
				caption = "4 pins",
				width = 300 / 4,
				on_click = function() mux:set_n_pins(4) end,
			}),
			ultros.Button({
				caption = "8 pins",
				width = 300 / 4,
				on_click = function() mux:set_n_pins(8) end,
			}),
			ultros.Button({
				caption = "16 pins",
				width = 300 / 4,
				on_click = function() mux:set_n_pins(16) end,
			}),
		})
	end)

	if n_pins > 0 then
		for i = 1, n_pins do
			local string_index = tostring(i)
			elts[#elts + 1] = ultros.Labeled({
				caption = "Pin " .. string_index .. ":",
			}, {
				ultros.UncontrolledInput({
					value = pin_labels[string_index] or "",
					icon_selector = true,
					on_change = function(_, new_label)
						local value = tostring(new_label) or ""
						mux:set_pin_label(i, value)
					end,
				}),
			})
		end

		elts[#elts + 1] = ultros.Labeled({ caption = "Connection key:" }, {
			ultros.UncontrolledInput({
				value = mux:get_connection_key() or "",
				on_change = function(_, new_key) mux:set_connection_key(new_key) end,
			}),
		})
	end

	return ultros.WindowFrame({
		caption = "Multiplexer",
		on_close = handle_close,
		width = 345,
	}, elts)
end)

---@param player LuaPlayer
---@param mux ribbon_cables.Multiplexer
function _G.open_mux_ui(player, mux)
	-- Already open
	if player.gui.screen["RibbonCablesMuxUi"] then return end
	relm.root_create(
		player.gui.screen,
		"RibbonCablesMuxUi",
		"MuxUi",
		{ mux = mux }
	)
end

event.bind("ribbon-cables-click", function(ev)
	local player = game.get_player(ev.player_index)
	if not player then return end
	if not player.is_cursor_empty() then return end

	local selected = player.selected
	if not selected or not selected.valid then return end
	if entities_lib.true_prototype_name(selected) ~= "ribbon-cables-mux" then
		return
	end

	local _, thing = remote.call("things", "get", selected)
	if not thing or not thing.entity then return end
	local mux = get_multiplexer_state(thing.id)
	if not mux then return end

	open_mux_ui(player, mux)
end)
