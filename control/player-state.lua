local class = require("lib.core.class").class
local ovl_lib = require("lib.core.overlay")
local pos_lib = require("lib.core.math.pos")

local pos_new = pos_lib.pos_new
local pos_add = pos_lib.pos_add
local pos_normalize = pos_lib.pos_normalize
local pos_scale = pos_lib.pos_scale
local dir_from = pos_lib.dir_from

local lib = {}

---@class ribbon_cables.PlayerState
---@field player_index uint Index of the player this state belongs to
---@field connection_source? int64 ID of the Thing selected as source for a connection
---@field possible_connection? LuaRenderObject[] Possible connection rendering objects
---@field pin_labels? LuaRenderObject[] Pin label rendering objects
local PlayerState = class("ribbon_cables.PlayerState")
lib.PlayerState = PlayerState

---@param player_index uint
function PlayerState:new(player_index)
	local instance = {}
	setmetatable(instance, self)
	instance.player_index = player_index
	return instance
end

---Clear player connection state.
function PlayerState:clear_connection()
	self.connection_source = nil
	self:clear_possible_connection_rendering()
end

---@param thing_id int64?
function PlayerState:set_connection_source(thing_id)
	if not thing_id then
		self:clear_connection()
		return
	end
	self.connection_source = thing_id
end

function PlayerState:clear_possible_connection_rendering()
	ovl_lib.destroy_render_objects(self.possible_connection)
	self.possible_connection = nil
end

local PC_LINE_WIDTH = 4
local PC_DASH_LENGTH = 0.2
local PC_GAP_LENGTH = 0.2
local PC_CIRCLE_RADIUS = 0.3
local PC_CIRCLE_WIDTH = 2

---@param from LuaEntity
---@param to LuaEntity
---@param color Color?
function PlayerState:render_possible_connection(from, to, color)
	self:clear_possible_connection_rendering()
	color = color or { r = 0, g = 1, b = 0 }
	local ros = {}
	ros[#ros + 1] = rendering.draw_line({
		from = from,
		to = to,
		surface = from.surface,
		color = color,
		width = PC_LINE_WIDTH,
		dash_length = PC_DASH_LENGTH,
		gap_length = PC_GAP_LENGTH,
	})
	ros[#ros + 1] = rendering.draw_circle({
		surface = from.surface,
		color = color,
		radius = PC_CIRCLE_RADIUS,
		filled = false,
		target = from,
		width = PC_CIRCLE_WIDTH,
	})
	ros[#ros + 1] = rendering.draw_circle({
		surface = to.surface,
		color = color,
		radius = PC_CIRCLE_RADIUS,
		filled = false,
		target = to,
		width = PC_CIRCLE_WIDTH,
	})
	self.possible_connection = ros
end

function PlayerState:render_possible_disconnection(from, to)
	self:render_possible_connection(from, to, { r = 1, g = 0, b = 0 })
end

function PlayerState:clear_pin_labels()
	ovl_lib.destroy_render_objects(self.pin_labels)
	self.pin_labels = nil
end

local BASE_LABELS = { "1", "2", "3", "4", "5", "6", "7", "8" }

local default_dir_orientations = { 0, 0, 0, 0, 0, 0, 0, 0 }
local default_dir_aligns = {
	"center",
	"center",
	"center",
	"center",
	"center",
	"center",
	"center",
	"center",
}
local default_dir_offsets = {
	{ 0, -0.6 },
	{ 0.15, -0.6 },
	{ 0.3, -0.3 },
	{ 0.15, 0 },
	{ 0, 0 },
	{ -0.15, 0 },
	{ -0.3, -0.3 },
	{ -0.15, -0.6 },
}
local custom_dir_orientations =
	{ 6 / 8, 7 / 8, 0 / 8, 1 / 8, 6 / 8, 7 / 8, 0 / 8, 1 / 8 }
local custom_dir_aligns =
	{ "left", "left", "left", "left", "right", "right", "right", "right" }
local custom_dir_offsets = {
	{ -0.3, -0.15 },
	{ -0.15, -0.3 },
	{ 0.15, -0.3 },
	{ 0.3, -0.15 },
	{ -0.3, 0.15 },
	{ -0.3, -0.15 },
	{ -0.15, -0.3 },
	{ 0.15, -0.3 },
}

---@param parent things.ThingSummary
---@param children things.ThingChildrenSummary?
function PlayerState:render_pin_labels(parent, children)
	local parent_entity = parent.entity
	if not parent_entity then return end
	local parent_pos = parent_entity.position
	if not children then
		_, children = remote.call("things", "get_children", parent.id)
	end
	if not children then return end
	local labels = BASE_LABELS
	if parent.tags and next(parent.tags) then labels = parent.tags end

	self:clear_pin_labels()
	local ros = {}
	for index, child in pairs(children) do
		local entity = child.entity
		if entity then
			local text = (labels or BASE_LABELS)[index] or BASE_LABELS[index] or "?"
			local child_pos = entity.position
			local dir = math.floor(dir_from(parent_pos, child_pos) / 2) + 1
			local orientations = (#text > 1) and custom_dir_orientations
				or default_dir_orientations
			local offsets = (#text > 1) and custom_dir_offsets or default_dir_offsets
			local aligns = (#text > 1) and custom_dir_aligns or default_dir_aligns
			ros[#ros + 1] = rendering.draw_text({
				text = text,
				surface = entity.surface,
				target = { entity = entity, offset = offsets[dir] or { 0, 0 } },
				orientation = orientations[dir] or 0,
				color = { r = 1, g = 1, b = 0 },
				alignment = aligns[dir] or "center",
				players = { self.player_index },
				use_rich_text = true,
			})
		end
	end
	self.pin_labels = ros
end

return lib
