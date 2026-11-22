-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

data:extend{
  {
    type = "selection-tool",
    name = "item-inserter-tool",
    select = {
      border_color = {0, 0.8, 0, 1},
      cursor_box_type = "entity",
      entity_type_filters = {"assembling-machine", "furnace", "ammo-turret", "artillery-turret", "artillery-wagon", "locomotive", "reactor"},
      mode = {
        "buildable-type",
        "same-force",
        "entity-ghost"
      }
    },
    alt_select = {
      border_color = {0, 0.8, 0, 1},
      cursor_box_type = "entity",
      entity_type_filters = {"assembling-machine", "furnace", "ammo-turret", "artillery-turret", "artillery-wagon", "locomotive", "reactor"},
      mode = {
        "buildable-type",
        "same-force",
        "entity-ghost"
      }
    },
    stack_size = 1,
    icon = "__item-inserter__/selection-tool.png",
    flags = { "only-in-cursor", "not-stackable", "spawnable" }
  },
  {
    type = "custom-input",
    name = "item-inserter-shortcut",
    key_sequence = "ALT + P",
    action = "lua"
  },
  {
    type = "shortcut",
    name = "item-inserter-shortcut",
    icon = "__item-inserter__/selection-tool.png",
    small_icon = "__item-inserter__/selection-tool.png",
    style = "green",
    action = "lua",
    associated_control_input = "item-inserter-shortcut"
  }
}

-- uncomment to generate a new thumbnail
-- data.raw["assembling-machine"]["assembling-machine-2"].icons_positioning = {
-- {inventory_index = defines.inventory.crafter_input},
-- }
