data:extend{
  {
    type = "selection-tool",
    name = "item-inserter-tool",
    select = {
      border_color = {0, 0.8, 0, 1},
      cursor_box_type = "entity",
      entity_type_filters = {"assembling-machine", "furnace", "reactor"},
      mode = {
        "buildable-type",
        "same-force",
        -- "entity-ghost"
      }
    },
    alt_select = {
      border_color = {0, 0.8, 0, 1},
      cursor_box_type = "entity",
      entity_type_filters = {"assembling-machine", "furnace", "reactor"},
      mode = {
        "buildable-type",
        "same-force",
        -- "entity-ghost"
      }
    },
    stack_size = 1,
    icon = "__item-inserter__/selection-tool.png",
    flags = { "only-in-cursor", "not-stackable" }
  },
  {
    type = "custom-input",
    name = "item-inserter-shortcut",
    key_sequence = "ALT + P",
    action = "lua"
  },
  -- {
  --   type = "shortcut",
  --   name = "item-inserter-shortcut"
  -- }
}