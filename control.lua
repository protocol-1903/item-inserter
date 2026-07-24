-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

local glib = require "__glib__.glib"

local handlers = {}

local function create_gui(player_index)
  local player = game.get_player(player_index) ---@cast player -?

  storage[player_index] = storage[player_index] or {}

  player.opened = glib.add(player.gui.screen, {
    args = {type = "frame", name = "item-inserter-gui", direction = "vertical"},
    elem_mods = {auto_center = true},
    _closed = handlers.confirm,
    {
      args = {type = "flow"},
      style_mods = {horizontal_spacing = 8},
      drag_target = "item-inserter-gui",
      {
        args = {type = "label", caption = {"item-inserter-gui.title"}, style = "frame_title"},
        style_mods = {top_margin = -3, bottom_margin = 3},
        drag_target = "item-inserter-gui",
      },
      {
        args = {type = "empty-widget", style = "draggable_space_header"},
        style_mods = {right_margin = 4, horizontally_stretchable = true, height = 24},
        drag_target = "item-inserter-gui",
      },
      {
        args = {type = "sprite-button", style = "close_button", sprite = "utility/close"},
        _click = handlers.close
      },
    },
    {
      args = {type = "frame", name = "main", style = "inside_shallow_frame_with_padding", direction = "vertical"},
      {
        args = {type = "flow", name = "sub", direction = "vertical"},
        style_mods = {vertical_spacing = 8},
        {
          args = {type = "flow"},
          style_mods = {vertical_align = "center"},
          {
            args = {type = "choose-elem-button", name = "item", elem_type = "item", item = storage[player_index].item, tooltip = {"item-inserter-gui.item-tooltip"}},
            _elem_changed = handlers.update_selection
          },
          {
            args = {type = "textfield", name = "count", numeric = true, text = storage[player_index].count, tooltip = {"item-inserter-gui.count-tooltip"}},
            style_mods = {natural_width = 60, width = 60},
            _text_changed = handlers.update_selection
          },
          {
            args = {type = "label", caption = "[img=info]", tooltip = {"item-inserter-gui.no-selected-item-tooltip"}}
          },
        },
        {
          args = {
            type = "checkbox",
            name = "insert-into-furnace-output",
            caption = {"item-inserter-gui.insert-into-furnace-output"},
            state = player.mod_settings["insert-into-furnace-output"].value,
          },
          _checked_state_changed = handlers.update_settings
        },
        {
          args = {
            type = "checkbox",
            name = "furnace-input-priority",
            caption = {"", {"item-inserter-gui.furnace-input-priority"}, " [img=info]"},
            state = player.mod_settings["furnace-input-priority"].value,
            tooltip = {"item-inserter-gui.furnace-input-priority-tooltip"},
            enabled = player.mod_settings["insert-into-furnace-output"].value,
          },
          _checked_state_changed = handlers.update_settings
        },
        {
          args = {
            type = "checkbox",
            name = "insert-into-fuel",
            caption = {"", {"item-inserter-gui.insert-into-fuel"}, " [img=info]"},
            state = player.mod_settings["insert-into-fuel"].value,
            tooltip = {"item-inserter-gui.insert-into-fuel-tooltip"},
          },
          _checked_state_changed = handlers.update_settings
        },
      },
    },
    {
      args = {type = "flow", style = "dialog_buttons_horizontal_flow"},
      {
        args = {type = "empty-widget", style = "draggable_space"},
        style_mods = {horizontally_stretchable = true, vertically_stretchable = true},
        drag_target = "item-inserter-gui",
      },
      {
        args = {type = "button", name = "confirm", caption = {"gui.confirm"}, style = "confirm_button"},
        _click = handlers.confirm
      },
    },
  })
end

---@param event EventData.on_gui_click
handlers.close = function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
  player.gui.screen["item-inserter-gui"].destroy()
end

---@param event EventData.on_gui_click|EventData.on_gui_closed
handlers.confirm = function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
  player.gui.screen["item-inserter-gui"].destroy()
  player.clear_cursor()
  player.cursor_stack.set_stack("item-inserter-tool")
end

---@param event EventData.on_gui_checked_state_changed
handlers.update_settings = function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
  player.mod_settings[event.element.name] = {value = event.element.state}
  local gui = player.gui.screen["item-inserter-gui"]
  gui.main.sub["furnace-input-priority"].enabled = player.mod_settings["insert-into-furnace-output"].value
end


---@param event EventData.on_gui_elem_changed|EventData.on_gui_text_changed
handlers.update_selection = function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
  storage[event.player_index] = storage[event.player_index] or {}
  storage[event.player_index][event.element.name] = event.element.type == "textfield" and (tonumber(event.element.text) or 0) or event.element.elem_value
end

glib.register_handlers(handlers)

script.on_configuration_changed(function ()
  for _, player in pairs(game.players) do
    local gui = player.gui.screen["item-inserter-gui"]
    if gui then gui.destroy() end
  end
end)

---@param event EventData.CustomInputEvent
script.on_event("item-inserter-shortcut", function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
  if not player.cursor_stack or not player.cursor_stack.valid_for_read or player.cursor_stack.name ~= "item-inserter-tool" then
    player.clear_cursor()
    player.cursor_stack.set_stack("item-inserter-tool")
  elseif not player.gui.screen["item-inserter-gui"] then
    player.clear_cursor()
    create_gui(event.player_index)
  end
end)

---@param event EventData.on_lua_shortcut
script.on_event(defines.events.on_lua_shortcut, function (event)
  if event.prototype_name ~= "item-inserter-shortcut" then return end
  local player = game.get_player(event.player_index) ---@cast player -?
  if not player.cursor_stack or not player.cursor_stack.valid_for_read or player.cursor_stack.name ~= "item-inserter-tool" then
    player.clear_cursor()
    player.cursor_stack.set_stack("item-inserter-tool")
  elseif not player.gui.screen["item-inserter-gui"] then
    player.clear_cursor()
    create_gui(event.player_index)
  end
end)

---@type {[data.RecipeCategoryID]: {[data.ItemID]: LuaRecipePrototype[]}}
local products_by_category = {} -- a list of all items that can be crafted by this category
---@type {[data.RecipeCategoryID]: {[data.ItemID]: RecipeID}}
local ingredients_by_category = {} -- a list of all items that can used to craft by this category
local fuels_per_category = {}
local fuels_per_burnt_result = {}

for _, category in pairs(prototypes.recipe_category) do
  products_by_category[category.name] = {}
  ingredients_by_category[category.name] = {}
end

for _, recipe in pairs(prototypes.recipe) do
  for _, category in pairs(recipe.categories) do
    for _, product in pairs(recipe.products) do
      if product.type == "item" then
        products_by_category[category][product.name] = products_by_category[category][product.name] or {}
        products_by_category[category][product.name][#products_by_category[category][product.name]+1] = recipe
      end
    end
    for _, ingredient in pairs(recipe.ingredients) do
      if ingredient.type == "item" then
        ingredients_by_category[category][ingredient.name] = recipe.name
      end
    end
  end
end

-- todo:
-- default respect inventory limits, setting to disable
-- ghosts (yay...)
-- rocket silos
-- turrets
-- profit????

script.on_event(defines.events.on_player_selected_area, function (event)
  if event.item ~= "item-inserter-tool" then return end

  local player = game.players[event.player_index]
  local item_data = storage[player.index]

  if not item_data or item_data.count == 0 then return end

  local ingredient_index = {}
  local product_index = {}
  local furnaces_input = {}
  local furnaces_output = {}
  local fueled_entities = {}
  local burnt_entities = {}
  ---@type {entity: LuaEntity, slot: uint, inventory: defines.inventory, item: ItemID, count: uint}[]
  local requests = {}

  for _, entity in pairs(event.entities) do

    local crafter_input = entity.get_inventory(defines.inventory.crafter_input) ---@cast crafter_input -?
    local crafter_output = entity.get_inventory(defines.inventory.crafter_output) ---@cast crafter_output -?
    local fuel_inventory = entity.get_inventory(defines.inventory.fuel) ---@cast fuel_inventory -?
    local burner = entity.get_inventory(defines.inventory.fuel) ---@cast burner -?

    if item_data.item then
      if entity.type == "assembling-machine" and entity.get_recipe() then
        local recipe = entity.get_recipe() ---@cast recipe -?
        for i, ingredient in pairs(recipe.ingredients) do
          if ingredient.name == item_data.item and crafter_input.can_insert(item_data.item) then
            requests[#requests+1] = {
              entity = entity,
              slot = i,
              inventory = defines.inventory.crafter_input,
              item = item_data.item,
              count = item_data.count
            }
            break
          end
        end
        for i, product in pairs(recipe.products) do
          if product.name == item_data.item and crafter_output.can_insert(item_data.item) then
            requests[#requests+1] = {
              entity = entity,
              slot = i,
              inventory = defines.inventory.crafter_output,
              item = item_data.item,
              count = item_data.count
            }
            break
          end
        end
      elseif entity.type == "furnace" then
        local recipe = entity.get_recipe() ---@cast recipe -?
        local input_priority = player.mod_settings["furnace-input-priority"].value
        local insert_to_output = player.mod_settings["insert-into-furnace-output"].value
        local found
        -- if input priority is on, check if its a valid ingredient
        if input_priority and crafter_input then
          if recipe then
            for _, ingredient in pairs(recipe.ingredients) do
              if ingredient.name == item_data.item then
                found = true
                requests[#requests+1] = {
                  entity = entity,
                  slot = 1,
                  inventory = defines.inventory.crafter_input,
                  item = item_data.item,
                  count = item_data.count
                }
                break
              end
            end
          elseif crafter_input.can_insert(item_data.item) then
            -- make sure the possible recipe doesn't interfere with any existing outputs (or output requests)
            local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
            for category in pairs(entity.prototype.crafting_categories) do
              local recipe_name = ingredients_by_category[category][item_data.item]
              if recipe_name then
                local valid = true
                local i = 1
                for _, product in pairs(prototypes.recipe[recipe_name].products) do
                  if product.type == "item" then
                    if crafter_output[i].valid_for_read and product.name ~= crafter_output[i].name then
                      valid = false
                    elseif not crafter_output[i].valid_for_read then
                      for _, request in pairs(plan or {}) do
                        for _, inv in pairs(request.items.in_inventory or {}) do
                          ---@cast inv InventoryPosition
                          if inv.inventory == defines.inventory.crafter_output and inv.stack == i - 1 and request.id.name ~= product then
                            -- invalid, this item request collides with whats part of the recipe
                            valid = false
                            break
                          end
                        end
                        if not valid then break end
                      end
                    end
                    i = i + 1
                  end
                  if not valid then break end
                end
                if valid then
                  found = true
                  requests[#requests+1] = {
                    entity = entity,
                    slot = 1,
                    inventory = defines.inventory.crafter_input,
                    item = item_data.item,
                    count = item_data.count
                  }
                end
              end
            end
          end
        end
        -- if not yet found or input priority is off, check if its a valid product
        if not found and insert_to_output and crafter_output then
          if recipe then
            for _, product in pairs(recipe.products) do
              if product.name == item_data.item then
                found = true
                requests[#requests+1] = {
                  entity = entity,
                  slot = 1,
                  inventory = defines.inventory.crafter_output,
                  item = item_data.item,
                  count = item_data.count
                }
                break
              end
            end
          else
            -- check if it has a valid recipe that produces this item
            for category in pairs(entity.prototype.crafting_categories) do
              if products_by_category[category][item_data.item] then
                local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
                local valid_recipe_found = false
                -- make sure a valid recipe exists
                for _, pos_recipe in pairs(products_by_category[category][item_data.item]) do
                  local valid_recipe = true
                  ---@cast pos_recipe LuaRecipePrototype
                  for _, ingredient in pairs(pos_recipe.ingredients) do
                    -- if the ingredients of this possible recipe do not match what is in the machine, it is not valid
                    if ingredient.type == "item" and crafter_input[1].valid_for_read and crafter_input[1].name ~= ingredient.name then
                      valid_recipe = false
                    elseif ingredient.type == "item" and plan then
                      for _, request in pairs(plan or {}) do
                        for _, inv in pairs(request.items.in_inventory or {}) do
                          ---@cast inv InventoryPosition
                          if inv.inventory == defines.inventory.crafter_input and inv.stack == 0 and request.id.name ~= ingredient.name then
                            -- invalid, this item request collides with whats part of the recipe
                            valid_recipe = false
                            break
                          end
                        end
                        if not valid_recipe then break end
                      end
                    elseif ingredient.type == "fluid" and entity.fluids_count ~= 0 and entity.get_fluid(1) and entity.get_fluid(1)  then
                      valid_recipe = false
                    end
                  end
                  if valid_recipe then
                    valid_recipe_found = true
                    break
                  end
                end
                if valid_recipe_found then
                  found = true
                  requests[#requests+1] = {
                    entity = entity,
                    slot = 1,
                    inventory = defines.inventory.crafter_output,
                    item = item_data.item,
                    count = item_data.count
                  }
                end
                break
              end
            end
          end
        end
        -- if product was not found and input priority is off, check if its a valid ingredient
        if not found and crafter_input and not input_priority then
          if recipe then
            for _, ingredient in pairs(recipe.ingredients) do
              if ingredient.name == item_data.item then
                found = true
                requests[#requests+1] = {
                  entity = entity,
                  slot = 1,
                  inventory = defines.inventory.crafter_input,
                  item = item_data.item,
                  count = item_data.count
                }
                break
              end
            end
          elseif crafter_input.can_insert(item_data.item) then
            -- make sure the possible recipe doesn't interfere with any existing outputs (or output requests)
            local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
            for category in pairs(entity.prototype.crafting_categories) do
              local recipe_name = ingredients_by_category[category][item_data.item]
              if recipe_name then
                local valid = true
                local i = 1
                for _, product in pairs(prototypes.recipe[recipe_name].products) do
                  if product.type == "item" then
                    if crafter_output[i].valid_for_read and product.name ~= crafter_output[i].name then
                      valid = false
                    elseif not crafter_output[i].valid_for_read then
                      for _, request in pairs(plan or {}) do
                        for _, inv in pairs(request.items.in_inventory or {}) do
                          ---@cast inv InventoryPosition
                          if inv.inventory == defines.inventory.crafter_output and inv.stack == i - 1 and request.id.name ~= product then
                            -- invalid, this item request collides with whats part of the recipe
                            valid = false
                            break
                          end
                        end
                        if not valid then break end
                      end
                    end
                    i = i + 1
                  end
                  if not valid then break end
                end
                if valid then
                  found = true
                  requests[#requests+1] = {
                    entity = entity,
                    slot = 1,
                    inventory = defines.inventory.crafter_input,
                    item = item_data.item,
                    count = item_data.count
                  }
                end
              end
            end
          end
        end
      elseif entity.type == "entity-ghost" then
        if entity.ghost_type == "assembling-machine" and entity.get_recipe() then
          game.print("ghost assembling machine not yet implemented, try again later", {skip = defines.print_skip.never})
          local recipe = entity.get_recipe() ---@cast recipe -?
          game.print("  recipe: " .. recipe.name, {skip = defines.print_skip.never})
        elseif entity.ghost_type == "furnace" then
          game.print("ghost furnace not yet implemented, try again later", {skip = defines.print_skip.never})
          local recipe = entity.get_recipe() ---@cast recipe -?
          game.print("  recipe: " .. (recipe and recipe.name or "nil"), {skip = defines.print_skip.never})
        end
      end
    else
      if entity.type == "assembling-machine" and entity.get_recipe() then
        local recipe = entity.get_recipe() ---@cast recipe -?
        local i = 1
        for _, ingredient in pairs(recipe.ingredients) do
          if ingredient.type == "item" then
            requests[#requests+1] = {
              entity = entity,
              slot = i,
              inventory = defines.inventory.crafter_input,
              item = ingredient.name,
              count = item_data.count * ingredient.amount
            }
            i = i + 1
          end
        end
      end
    end

    if item_data.item and player.mod_settings["insert-into-fuel"].value and prototypes.item[item_data.item].fuel_category then
      if entity.type == "entity-ghost" then
        game.print("attempt to insert fuel into ghost, if possible", {skip = defines.print_skip.never})
      elseif fuel_inventory then
        local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
        local inventory = {}
        if plan then
          for _, request in pairs(plan) do
            for _, inv in pairs(request.items.in_inventory or {}) do
              ---@cast inv InventoryPosition
              if inv.inventory == defines.inventory.fuel then
                inventory[inv.stack + 1] = request.id.name
              end
            end
          end
        end
        for i = 1, #fuel_inventory do
          local stack = fuel_inventory[i]
          inventory[i] = inventory[i] or stack.valid_for_read and stack.name or nil
          inventory[i] = inventory[i] or fuel_inventory.get_filter(i) and fuel_inventory.get_filter(i).name or nil
        end
        for i = 1, #fuel_inventory do
          if inventory[i] == item_data.item then
            requests[#requests+1] = {
              entity = entity,
              slot = i,
              inventory = defines.inventory.fuel,
              item = item_data.item,
              count = item_data.count
            }
          elseif entity.prototype.burner_prototype.fuel_categories[prototypes.item[item_data.item].fuel_category] then
            requests[#requests+1] = {
              entity = entity,
              slot = i,
              inventory = defines.inventory.fuel,
              item = item_data.item,
              count = item_data.count
            }
          end
        end
      end
    end
  end

  ---@type {[uint]: LuaEntity?}
  local proxies = {}
  for _, request in pairs(requests) do
    if request.entity.type ~= "entity-ghost" then
      local proxy = proxies[request.entity.unit_number] or request.entity.item_request_proxy
      if proxy then
        local insert_plan = proxy.insert_plan
        local found_request
        for _, plan in pairs(insert_plan) do
          local item = plan.id.name
          if item == request.item then
            found_request = true
            local found
            for _, inv in pairs(plan.items.in_inventory or {}) do
              if inv.inventory == request.inventory and inv.stack == request.slot - 1 then
                inv.count = (inv.count or 1) + request.count
                found = true
              end
            end
            if not found then
              plan.items.in_inventory[#plan.items.in_inventory+1] = {
                inventory = request.inventory,
                stack = request.slot - 1,
                count = request.count
              }
            end
            break
          end
        end
        if not found_request then
          insert_plan[#insert_plan+1] = {
            id = { name = request.item },
            items = { in_inventory = {{
              inventory = request.inventory,
              stack = request.slot - 1,
              count = request.count
            }}}
          }
        end
        proxy.insert_plan = insert_plan
      else
        proxies[request.entity.unit_number] = request.entity.surface.create_entity{
          name = "item-request-proxy",
          position = request.entity.position,
          force = request.entity.force,
          target = request.entity,
          modules = {{
            id = { name = request.item },
            items = { in_inventory = {{
              inventory = request.inventory,
              stack = request.slot - 1,
              count = request.count
            }}}
          }}
        }
      end
    else
      local insert_plan = request.entity.insert_plan or {}
      insert_plan[#insert_plan+1] = {
        id = { name = request.item },
        items = { in_inventory = {{
          inventory = request.inventory,
          stack = request.slot - 1,
          count = request.count
        }}}
      }
      request.entity.insert_plan = insert_plan
    end
  end
end)