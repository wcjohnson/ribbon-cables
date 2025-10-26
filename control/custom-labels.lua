--------------------------------------------------------------------------------
-- UI for configuring custom labels
--------------------------------------------------------------------------------

local relm = require("lib.core.relm.relm")
local events = require("lib.core.event")
local ultros = require("lib.core.relm.ultros")
local tlib = require("lib.core.table")
local strace = require("lib.core.strace")

local EMPTY = tlib.EMPTY_STRICT

local Pr = relm.Primitive
local HF = ultros.HFlow
local VF = ultros.VFlow

---@return Relm.Handle?
---@return int?
local function get_gui(player_index)
	local result_handle, result_id = nil, nil
	relm.root_foreach(function(handle, id, _, pi)
		if pi == player_index then
			result_handle = handle
			result_id = id
		end
	end)
	return result_handle, result_id
end

local function close_gui(player_index)
	local _, id = get_gui(player_index)
	relm.root_destroy(id)
end

local function open_gui(player_index, thing_id)
	local _, opened_id = get_gui(player_index)
	if opened_id then return false end
	local player = game.get_player(player_index)
	if not player then return false end
	local screen = player.gui.screen
	local id, elt = relm.root_create(
		screen,
		"RibbonCablesLabelWindow",
		"RibbonCablesLabelWindow",
		{
			player_index = player_index,
			player = player,
			thing_id = thing_id,
		}
	)
	if not id then return false end
	return true
end

events.bind(
	"ribbon-cables-click",
	---@param event EventData.on_lua_shortcut
	function(event)
		local player = game.get_player(event.player_index)
		if not player then return end
		if not player.is_cursor_empty() then return end
		local selected = player.selected
		if not selected then return end
		local _, thing = remote.call("things", "get", selected)
		if not thing or thing.name ~= "ribbon-cables-mux" then return end
		if not get_gui(event.player_index) then
			open_gui(event.player_index, thing.id)
		else
			close_gui(event.player_index)
		end
	end
)

--------------------------------------------------------------------------------
-- Element defs
--------------------------------------------------------------------------------

local RibbonCablesLabelRow = relm.define_element({
	name = "RibbonCablesLabelRow",
	render = function(props)
		local index = props.index
		local label = props.label or ""

		return ultros.Labeled({
			caption = "Pin " .. tostring(index) .. ":",
		}, {
			ultros.Input({
				value = label,
				icon_selector = true,
			}),
		})
	end,
})

relm.define_element({
	name = "RibbonCablesLabelWindow",
	render = function(props, state)
		local player = props.player
		local child = nil
		state = state or EMPTY

		return ultros.WindowFrame({
			caption = "Custom Labels",
		}, {
			VF({
				width = 300,
				height = 275,
			}, {
				ultros.gather({
					ultros.tag(
						1,
						RibbonCablesLabelRow({
							index = 1,
							label = state[1] or state["1"] or "",
						})
					),
					ultros.tag(
						2,
						RibbonCablesLabelRow({
							index = 2,
							label = state[2] or state["2"] or "",
						})
					),
					ultros.tag(
						3,
						RibbonCablesLabelRow({
							index = 3,
							label = state[3] or state["3"] or "",
						})
					),
					ultros.tag(
						4,
						RibbonCablesLabelRow({
							index = 4,
							label = state[4] or state["4"] or "",
						})
					),
					ultros.tag(
						5,
						RibbonCablesLabelRow({
							index = 5,
							label = state[5] or state["5"] or "",
						})
					),
					ultros.tag(
						6,
						RibbonCablesLabelRow({
							index = 6,
							label = state[6] or state["6"] or "",
						})
					),
					ultros.tag(
						7,
						RibbonCablesLabelRow({
							index = 7,
							label = state[7] or state["7"] or "",
						})
					),
					ultros.tag(
						8,
						RibbonCablesLabelRow({
							index = 8,
							label = state[8] or state["8"] or "",
						})
					),
				}),
			}),
			ultros.Button({ caption = "Save", on_click = "save" }),
		})
	end,
	message = function(me, payload, props, state)
		if payload.key == "close" then
			close_gui(props.player_index)
			return true
		elseif payload.key == "save" then
			local _, new_labels = relm.query_broadcast(me, { key = "value" })
			if new_labels then
				local labels = {}
				for i = 1, 8 do
					local label = new_labels[i]
					if label and label ~= "" then labels[tostring(i)] = label end
				end
				remote.call("things", "set_tags", props.thing_id, { labels = labels })
			end
			close_gui(props.player_index)
			return true
		end
		return false
	end,
	state = function(props)
		local _, thing = remote.call("things", "get", props.thing_id)
		if not thing or not thing.tags or not thing.tags.labels then return {} end
		return thing.tags.labels
	end,
})
