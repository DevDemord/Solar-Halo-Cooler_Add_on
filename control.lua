-- Solar Halo Cooler Add-on: temperature display and overview window.
-- Reads the supercomputer's hidden heat buffer ("halo-computer-heat"), which is the
-- same temperature the Solar Halo script uses to disable the machine at 200 degrees.

local LIMIT = 200       -- Solar Halo disables the machine at this temperature
local WINDOW_LOW = 160  -- the steam heatsink recipe starts working here
local WARN = 180        -- amber band starts here

local BAR_W = 3.2
local BAR_X0 = -BAR_W / 2
local BAR_Y0 = 2.3
local BAR_Y1 = 2.6

local FRAME = "halo_cooler_overview"
local SHORTCUT = "halo-cooler-overview"

local COLORS = {
  none = {r = 0.6, g = 0.6, b = 0.6},
  cool = {r = 0.35, g = 0.65, b = 1},
  window = {r = 0.3, g = 0.85, b = 0.35},
  warn = {r = 1, g = 0.7, b = 0.15},
  disabled = {r = 1, g = 0.25, b = 0.25},
}

local function init_storage()
  storage.computers = storage.computers or {}
  storage.renders = storage.renders or {}
  storage.gui_sig = storage.gui_sig or {}
end

local function band(t)
  if t == nil then return "none" end
  if t >= LIMIT then return "disabled" end
  if t >= WARN then return "warn" end
  if t >= WINDOW_LOW then return "window" end
  return "cool"
end

----------------------------------------------------------------------
-- Tracking supercomputers
----------------------------------------------------------------------

local function register(entity)
  if not (entity and entity.valid and entity.name == "halo-computer") then return end
  init_storage()
  local id = entity.unit_number
  if not storage.computers[id] then
    storage.computers[id] = {id = id, entity = entity}
  end
end

local function scan_all()
  init_storage()
  for _, surface in pairs(game.surfaces) do
    for _, e in pairs(surface.find_entities_filtered{name = "halo-computer"}) do
      register(e)
    end
  end
end

local function get_heat(rec)
  local h = rec.heat
  if h and h.valid then return h end
  local c = rec.entity
  local found = c.surface.find_entities_filtered{
    name = "halo-computer-heat", position = c.position, radius = 1, limit = 1,
  }
  rec.heat = found[1]
  return rec.heat
end

local function temperature(rec)
  if not (rec.entity and rec.entity.valid) then return nil end
  local h = get_heat(rec)
  if h and h.valid then return h.temperature end
  return nil
end

----------------------------------------------------------------------
-- On-machine label and bar
----------------------------------------------------------------------

local function destroy_render(id)
  local r = storage.renders[id]
  if r then
    for _, obj in pairs(r) do
      if obj and obj.valid then obj.destroy() end
    end
  end
  storage.renders[id] = nil
end

local function ensure_render(rec)
  local r = storage.renders[rec.id]
  if r and r.text and r.text.valid and r.bg and r.bg.valid
      and r.fill and r.fill.valid and r.mark and r.mark.valid then
    return r
  end
  if r then destroy_render(rec.id) end

  local c = rec.entity
  local s = c.surface
  r = {}
  r.text = rendering.draw_text{
    text = "", surface = s, target = {entity = c, offset = {0, -2.9}},
    color = COLORS.none, scale = 1.2, alignment = "center", scale_with_zoom = true,
  }
  r.bg = rendering.draw_rectangle{
    color = {r = 0, g = 0, b = 0, a = 0.75}, filled = true, surface = s,
    left_top = {entity = c, offset = {BAR_X0, BAR_Y0}},
    right_bottom = {entity = c, offset = {BAR_X0 + BAR_W, BAR_Y1}},
  }
  r.fill = rendering.draw_rectangle{
    color = COLORS.none, filled = true, surface = s,
    left_top = {entity = c, offset = {BAR_X0, BAR_Y0}},
    right_bottom = {entity = c, offset = {BAR_X0 + BAR_W * 0.01, BAR_Y1}},
  }
  local mx = BAR_X0 + BAR_W * (WINDOW_LOW / LIMIT)
  r.mark = rendering.draw_line{
    color = {r = 1, g = 1, b = 1, a = 0.9}, width = 2, surface = s,
    from = {entity = c, offset = {mx, BAR_Y0 - 0.1}},
    to = {entity = c, offset = {mx, BAR_Y1 + 0.1}},
  }
  storage.renders[rec.id] = r
  return r
end

local function update_render(rec, t)
  local r = ensure_render(rec)
  local color = COLORS[band(t)]
  if t then
    r.text.text = string.format("%d°C / %d°C", math.floor(t + 0.5), LIMIT)
  else
    r.text.text = "--"
  end
  r.text.color = color
  r.fill.color = color
  local frac = t and math.max(0.01, math.min(1, t / LIMIT)) or 0.01
  r.fill.right_bottom = {entity = rec.entity, offset = {BAR_X0 + BAR_W * frac, BAR_Y1}}
end

----------------------------------------------------------------------
-- Overview window
----------------------------------------------------------------------

local function sorted_records()
  local list = {}
  for _, rec in pairs(storage.computers) do
    if rec.entity.valid then list[#list + 1] = rec end
  end
  table.sort(list, function(a, b)
    local sa, sb = a.entity.surface.index, b.entity.surface.index
    if sa ~= sb then return sa < sb end
    return a.id < b.id
  end)
  return list
end

local function machine_status(entity)
  local st = entity.status
  local S = defines.entity_status
  if st == nil then return {"halo-cooler.mach-unknown"} end
  if st == S.working or st == S.normal then return {"halo-cooler.mach-working"} end
  if st == S.low_power then return {"halo-cooler.mach-low"} end
  if st == S.no_power then return {"halo-cooler.mach-nopower"} end
  if st == S.disabled_by_script or st == S.disabled then return {"halo-cooler.mach-disabled"} end
  return {"halo-cooler.mach-idle"}
end

local function get_table(frame)
  local inner = frame.halo_cooler_inner
  if not inner then return nil end
  return inner.halo_cooler_scroll.halo_cooler_table
end

local function build_rows(tbl, list)
  tbl.clear()
  if #list == 0 then return end
  for _, key in pairs({"col-location", "col-temp", "col-heat", "col-state", "col-machine"}) do
    tbl.add{type = "label", caption = {"halo-cooler." .. key}, style = "bold_label"}
  end
  tbl.add{type = "label", caption = ""}
  for _, rec in pairs(list) do
    local id = rec.id
    local c = rec.entity
    tbl.add{
      type = "label", name = "loc_" .. id,
      caption = string.format("%s [%d, %d]", c.surface.name,
        math.floor(c.position.x), math.floor(c.position.y)),
    }
    tbl.add{type = "label", name = "temp_" .. id, caption = ""}
    local pb = tbl.add{type = "progressbar", name = "bar_" .. id, value = 0}
    pb.style.width = 140
    tbl.add{type = "label", name = "state_" .. id, caption = ""}
    tbl.add{type = "label", name = "mach_" .. id, caption = ""}
    tbl.add{type = "button", name = "show_" .. id, caption = {"halo-cooler.show"}, tags = {id = id}}
  end
end

local function fill_rows(tbl, list)
  for _, rec in pairs(list) do
    local id = rec.id
    local t = temperature(rec)
    local key = band(t)
    local color = COLORS[key]

    local temp = tbl["temp_" .. id]
    if temp then
      temp.caption = t and string.format("%d°C", math.floor(t + 0.5)) or "--"
      temp.style.font_color = color
    end
    local bar = tbl["bar_" .. id]
    if bar then
      bar.value = t and math.max(0, math.min(1, t / LIMIT)) or 0
      bar.style.color = color
    end
    local state = tbl["state_" .. id]
    if state then
      state.caption = {"halo-cooler.state-" .. (key == "window" and "window" or key)}
      state.style.font_color = color
    end
    local mach = tbl["mach_" .. id]
    if mach then mach.caption = machine_status(rec.entity) end
  end
end

local function refresh_gui(player)
  local frame = player.gui.screen[FRAME]
  if not frame then return end
  local tbl = get_table(frame)
  if not tbl then return end

  local list = sorted_records()
  local ids = {}
  for i, rec in pairs(list) do ids[i] = rec.id end
  local sig = table.concat(ids, ",")
  if storage.gui_sig[player.index] ~= sig then
    build_rows(tbl, list)
    storage.gui_sig[player.index] = sig
  end
  fill_rows(tbl, list)

  local in_window, overheated = 0, 0
  for _, rec in pairs(list) do
    local t = temperature(rec)
    if t then
      if t >= LIMIT then overheated = overheated + 1
      elseif t >= WINDOW_LOW then in_window = in_window + 1 end
    end
  end
  local summary = frame.halo_cooler_summary
  if summary then
    if #list == 0 then
      summary.caption = {"halo-cooler.none"}
    else
      summary.caption = {"halo-cooler.summary", #list, in_window, overheated}
    end
  end
end

local function close_gui(player)
  local frame = player.gui.screen[FRAME]
  if frame then frame.destroy() end
  storage.gui_sig[player.index] = nil
  player.set_shortcut_toggled(SHORTCUT, false)
end

local function open_gui(player)
  init_storage()
  if player.gui.screen[FRAME] then player.gui.screen[FRAME].destroy() end

  local frame = player.gui.screen.add{type = "frame", name = FRAME, direction = "vertical"}
  local title = frame.add{type = "flow", direction = "horizontal"}
  title.drag_target = frame
  title.add{type = "label", caption = {"halo-cooler.title"}, style = "frame_title", ignored_by_interaction = true}
  local filler = title.add{type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true}
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  filler.style.minimal_width = 24
  title.add{
    type = "sprite-button", name = "halo_cooler_close", style = "frame_action_button",
    sprite = "utility/close", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black",
  }

  frame.add{type = "label", name = "halo_cooler_summary", caption = ""}
  local inner = frame.add{type = "frame", name = "halo_cooler_inner", style = "inside_shallow_frame", direction = "vertical"}
  local scroll = inner.add{type = "scroll-pane", name = "halo_cooler_scroll", horizontal_scroll_policy = "never"}
  scroll.style.maximal_height = 500
  local tbl = scroll.add{type = "table", name = "halo_cooler_table", column_count = 6}
  tbl.style.horizontal_spacing = 14
  tbl.style.vertical_spacing = 6

  frame.auto_center = true
  player.opened = frame
  player.set_shortcut_toggled(SHORTCUT, true)
  storage.gui_sig[player.index] = nil
  refresh_gui(player)
end

local function toggle_gui(player)
  if player.gui.screen[FRAME] then close_gui(player) else open_gui(player) end
end

local function show_on_map(player, rec)
  local e = rec and rec.entity
  if not (e and e.valid) then return end
  local ok = pcall(function()
    player.zoom_to_world{position = e.position, scale = 0.6, surface = e.surface}
  end)
  if not ok then
    pcall(function()
      player.set_controller{type = defines.controllers.remote, position = e.position, surface = e.surface}
    end)
  end
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------

local function update_all()
  if not storage.computers then return end
  for id, rec in pairs(storage.computers) do
    if rec.entity.valid then
      update_render(rec, temperature(rec))
    else
      destroy_render(id)
      storage.computers[id] = nil
    end
  end
  for _, player in pairs(game.connected_players) do
    refresh_gui(player)
  end
end

script.on_init(function()
  init_storage()
  scan_all()
end)

script.on_configuration_changed(function()
  init_storage()
  scan_all()
end)

for _, name in pairs({
  "on_built_entity", "on_robot_built_entity", "script_raised_built",
  "script_raised_revive", "on_entity_cloned", "on_space_platform_built_entity",
}) do
  local ev = defines.events[name]
  if ev then
    script.on_event(ev, function(event)
      register(event.entity or event.destination)
    end)
  end
end

script.on_nth_tick(30, update_all)
script.on_nth_tick(600, function() scan_all() end)

script.on_event(defines.events.on_lua_shortcut, function(event)
  if event.prototype_name ~= SHORTCUT then return end
  local player = game.get_player(event.player_index)
  if player then toggle_gui(player) end
end)

script.on_event(SHORTCUT, function(event)
  local player = game.get_player(event.player_index)
  if player then toggle_gui(player) end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local el = event.element
  if not (el and el.valid) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  if el.name == "halo_cooler_close" then
    close_gui(player)
  elseif el.name:sub(1, 5) == "show_" and el.tags and el.tags.id then
    show_on_map(player, storage.computers[el.tags.id])
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local el = event.element
  if el and el.valid and el.name == FRAME then
    local player = game.get_player(event.player_index)
    if player then close_gui(player) end
  end
end)
