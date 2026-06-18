-- Set all legacy multiplexers to have 8 pins, since that's what they were hardcoded to before.

local muxes = storage.multiplexers or {}
log(
	"ribbon-cables migration: setting pin count on "
		.. table_size(muxes)
		.. " legacy multiplexers"
)
for _, mux in pairs(muxes) do
	if not mux.n_pins then mux.n_pins = 8 end
end
