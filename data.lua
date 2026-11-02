local MOD = "__solar-halo-cooler_add_on__"

data:extend({
  {
    type = "custom-input",
    name = "halo-cooler-overview",
    key_sequence = "CONTROL + SHIFT + H",
    order = "a",
  },
  {
    type = "shortcut",
    name = "halo-cooler-overview",
    order = "z[halo]-a[cooler-overview]",
    action = "lua",
    toggleable = true,
    associated_control_input = "halo-cooler-overview",
    icon = MOD .. "/graphics/shortcut-56.png",
    icon_size = 56,
    small_icon = MOD .. "/graphics/shortcut-24.png",
    small_icon_size = 24,
  },
})
