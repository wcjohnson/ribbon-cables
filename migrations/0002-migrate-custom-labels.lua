local strace = require("lib.core.strace")

-- Migrate custom labels to use a "labels" table in tags
for _, surface in pairs(game.surfaces) do
	for _, entity in
		pairs(surface.find_entities_filtered({ name = "ribbon-cables-mux" }))
	do
		local _, tags = remote.call("things", "get_tags", entity)
		if tags and next(tags) then
			local labels = {}
			for i = 1, 8 do
				local label = tags[i] or tags[tostring(i)]
				if label and label ~= "" then labels[i] = label end
			end
			if next(labels) then
				remote.call("things", "set_tags", entity, { labels = labels })
			end
		end
	end
end
