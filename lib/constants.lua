local constants = {}

__MOD_NAME__ = "ribbon-cables"

constants.pin_name = "ribbon-cables-pin"
constants.mux_name = "ribbon-cables-mux"
constants.tech_name = "ribbon-cables-tech"

constants.circuit_wire_max_distance = 9

constants.PIN_OFFSETS = {
	-- Beginning in top left corner (-1, -1) and going clockwise hitting each cardinal direction and each corner.
	{ -1, -1 },
	{ 0, -1 },
	{ 1, -1 },
	{ 1, 0 },
	{ 1, 1 },
	{ 0, 1 },
	{ -1, 1 },
	{ -1, 0 },
}

constants.PIN_DISTANCE = 2

constants.N_PINS = 2

return constants
