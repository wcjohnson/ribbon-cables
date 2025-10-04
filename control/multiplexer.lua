local class = require("lib.core.class").class
local ovl_lib = require("lib.core.overlay")

---@class ribbon_cables.Multiplexer
---@field thing_id int
---@field connection_render_objects LuaRenderObject[]
local Multiplexer = class("ribbon_cables.Multiplexer")
_G.Multiplexer = Multiplexer

function Multiplexer:new(thing_id)
	local obj =
		setmetatable({ thing_id = thing_id, connection_render_objects = {} }, self)
	storage.multiplexers[thing_id] = obj
	return obj
end

function Multiplexer:destroy_connection_render_objects()
	ovl_lib.destroy_render_objects(self.connection_render_objects)
	self.connection_render_objects = {}
end

function Multiplexer:update_connection_render_objects()
	self:destroy_connection_render_objects()
	local render_objects = self.connection_render_objects
	local _, _, self_entity = remote.call("things", "get_status", self.thing_id)
	if not self_entity or not self_entity.valid then return end
	local _, edges =
		remote.call("things", "get_edges", "ribbon-cables", self.thing_id)
	if not edges then return end
	for dst_id, edge in pairs(edges) do
		-- Only draw edges for which we are the lower ID. This will ensure each
		-- edge is drawn only once.
		if edge.first ~= self.thing_id then goto continue end
		local _, _, dst_entity = remote.call("things", "get_status", dst_id)
		if
			dst_entity
			and dst_entity.valid
			and dst_entity.surface == self_entity.surface
		then
			table.insert(
				render_objects,
				rendering.draw_line({
					color = { r = 0, g = 1, b = 1, a = 0.5 },
					width = 2,
					from = self_entity,
					to = dst_entity,
					surface = self_entity.surface,
					forces = self_entity.force,
				})
			)
		end
		::continue::
	end
end

function Multiplexer:destroy()
	self:destroy_connection_render_objects()
	storage.multiplexers[self.thing_id] = nil
end

return Multiplexer
