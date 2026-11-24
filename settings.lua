-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

data:extend{
  {
    type = "bool-setting",
    name = "insert-into-furnace-output",
    setting_type = "runtime-per-user",
    default_value = false,
  },
  {
    type = "bool-setting",
    name = "furnace-input-priority",
    setting_type = "runtime-per-user",
    default_value = true,
  },
  {
    type = "string-setting",
    name = "item-insertion-targets",
    setting_type = "runtime-per-user",
    default_value = "general",
    allowed_values = {
      "general",
      "fuel",
      "modules"
    }
  },
}