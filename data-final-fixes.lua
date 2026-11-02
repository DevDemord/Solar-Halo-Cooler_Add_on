-- The supercomputer's control script raises the heat buffer's temperature by a fixed
-- number of degrees per craft. Energy added = degrees * specific_heat, so scaling the
-- buffer's specific_heat scales the heat that the heatsinks have to remove.
-- The setting is capped at 75 (percent of the original 200 MJ/degC).
local pct = math.min(75, settings.startup["solar-halo-cooler-heat-percent"].value)
local heat = data.raw["heat-pipe"] and data.raw["heat-pipe"]["halo-computer-heat"]

if heat and heat.heat_buffer then
  local mj = math.max(1, math.floor(200 * pct / 100 + 0.5))
  heat.heat_buffer.specific_heat = mj .. "MJ"
end
