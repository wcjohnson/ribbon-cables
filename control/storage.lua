---@class ribbon_cables.PlayerState
---@field connection_source? int64 ID of the Thing selected as source for a connection

---@class ribbon_cables.Storage
---@field players {[uint]: ribbon_cables.PlayerState}
---@field multiplexers {[int]: ribbon_cables.Multiplexer}
storage = {}

---@param player_index uint
---@return ribbon_cables.PlayerState
function _G.get_or_create_player_state(player_index)
	if not storage.players then storage.players = {} end
	if not storage.players[player_index] then
		storage.players[player_index] = {}
	end
	return storage.players[player_index]
end

---@param player_index uint
---@return ribbon_cables.PlayerState?
function _G.get_player_state(player_index)
	return storage.players and storage.players[player_index]
end

---@param thing_id int
---@return ribbon_cables.Multiplexer
function _G.get_or_create_multiplexer_state(thing_id)
	if not storage.multiplexers then storage.multiplexers = {} end
	if not storage.multiplexers[thing_id] then
		storage.multiplexers[thing_id] = Multiplexer:new(thing_id)
	end
	return storage.multiplexers[thing_id]
end

---@param thing_id int
---@return ribbon_cables.Multiplexer?
function _G.get_multiplexer_state(thing_id)
	return storage.multiplexers and storage.multiplexers[thing_id]
end
