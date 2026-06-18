local class = require("lib.core.class").class
local ovl_lib = require("lib.core.overlay")
local pos_lib = require("lib.core.math.pos")
local constants = require("lib.constants")
local orientation_lib = require("lib.core.orientation.orientation")
local strace = require("lib.core.strace")
local event = require("lib.core.event")

---@class ribbon_cables.Multiplexer
---@field thing_id int
---@field n_pins 0|2|4|8|16
---@field connection_render_objects LuaRenderObject[]
local Multiplexer = class("ribbon_cables.Multiplexer")
_G.Multiplexer = Multiplexer

function Multiplexer:new(thing_id)
	local obj = setmetatable(
		{ thing_id = thing_id, connection_render_objects = {}, n_pins = 0 },
		self
	)
	storage.multiplexers[thing_id] = obj
	return obj
end

function Multiplexer:get_n_pins() return self.n_pins end

function Multiplexer:set_n_pins(n)
	if self.n_pins == n then return end
	if self.n_pins ~= 0 then
		strace.error(
			"Attempted to change number of pins on Mux",
			self.thing_id,
			"from",
			self.n_pins,
			"to",
			n
		)
		return
	end
	self.n_pins = n
	event.raise("ribbon-cables.mux_pins_changed", self)
end

---@return {[string]: string}
function Multiplexer:get_pin_labels()
	local _, labels =
		remote.call("things-tags-v1", "get_tag", self.thing_id, "labels")
	labels = labels or {}
	return labels
end

---@param pin_index uint
---@param label string?
function Multiplexer:set_pin_label(pin_index, label)
	if label == "" then label = nil end
	local labels = self:get_pin_labels()
	labels[tostring(pin_index)] = label
	remote.call("things-tags-v1", "set_tag", self.thing_id, "labels", labels)
end

function Multiplexer:get_connection_key()
	local _, key = remote.call("things-tags-v1", "get_tag", self.thing_id, "key")
	return key
end

function Multiplexer:set_connection_key(key)
	key = key and tostring(key)
	remote.call("things-tags-v1", "set_tag", self.thing_id, "key", key)
end

function Multiplexer:destroy_connection_render_objects()
	ovl_lib.destroy_render_objects(self.connection_render_objects)
	self.connection_render_objects = {}
end

function Multiplexer:update_connection_render_objects()
	self:destroy_connection_render_objects()
	local render_objects = self.connection_render_objects
	local _, self_thing = remote.call("things", "get", self.thing_id)
	local self_entity = self_thing and self_thing.entity
	if not self_entity or not self_entity.valid then return end
	local _, out_edges, in_edges =
		remote.call("things", "get_edges", "ribbon-cables", self.thing_id)
	if not out_edges or not in_edges then return end

	strace.trace("Thing", self.thing_id, "is rendering edges", out_edges)
	for dst_id, edge in pairs(out_edges) do
		local _, dst_thing = remote.call("things", "get", dst_id)
		local dst_entity = dst_thing and dst_thing.entity
		if
			dst_entity
			and dst_entity.valid
			and dst_entity.surface == self_entity.surface
		then
			-- Render emanation circle
			table.insert(
				render_objects,
				rendering.draw_circle({
					color = { r = 0, g = 1, b = 1, a = 1 },
					radius = 0.25,
					filled = true,
					target = self_entity,
					surface = self_entity.surface,
				})
			)
			-- Render connection line
			table.insert(
				render_objects,
				rendering.draw_line({
					color = { r = 0, g = 1, b = 1, a = 0.5 },
					width = 6,
					from = self_entity,
					to = dst_entity,
					surface = self_entity.surface,
				})
			)
			-- Render emanation circle
			table.insert(
				render_objects,
				rendering.draw_circle({
					color = { r = 0, g = 1, b = 1, a = 1 },
					radius = 0.25,
					filled = true,
					target = dst_entity,
					surface = dst_entity.surface,
				})
			)
		end
	end
end

function Multiplexer:destroy()
	self:destroy_connection_render_objects()
	storage.multiplexers[self.thing_id] = nil
end

return Multiplexer
