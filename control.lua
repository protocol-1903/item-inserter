local function create_gui(player)

  if not storage[player.index] then
    storage[player.index] = {}
  end

  if player.gui.center["item-inserter-window"] then return end

  local window = player.gui.center.add{
    type = "frame",
    name = "item-inserter-window",
    direction = "vertical",
    style = "no_header_filler_frame",
    caption = {"item-inserter.title"}
  }
  player.opened = window

  -- main content
  window = window.add{
    type = "frame",
    name = "main",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding_and_vertical_spacing"
  }

  local flow = window.add{
    type = "flow",
    name = "flow",
    style = "player_input_horizontal_flow",
    direction = "horizontal"
  }

  flow.add{
    type = "choose-elem-button",
    name = "item",
    style = "slot_button_in_shallow_frame",
    elem_type = "item",
    item = storage[player.index].name
  }

  field = flow.add{
    type = "textfield",
    name = "count",
    style = "very_short_number_textfield",
    numeric = true,
    lose_focus_on_confirm = true,
    text = storage[player.index].count or 1
  }

  flow = window.add{
    type = "flow",
    style = "dialog_buttons_horizontal_flow",
    direction = "horizontal"
  }

  flow.add{
    type = "empty-widget"
  }.style.horizontally_stretchable = true

  flow.add{
    type = "button",
    style = "confirm_button",
    caption = {"item-inserter.confirm"}
  }
end

script.on_event("item-inserter-gui-shortcut", function (event)
  create_gui(game.players[event.player_index])
end)

script.on_event(defines.events.on_lua_shortcut, function (event)
  if event.prototype_name ~= "item-inserter-gui-shortcut" then return end
  create_gui(game.players[event.player_index])
end)

local recipes_per_category = {}
local fuels_per_category = {}

script.on_event(defines.events.on_player_selected_area, function (event)
  if event.item ~= "item-inserter-tool" then return end

  local player = game.players[event.player_index]
  local item = storage[player.index]

  if not item.name or item.count == 0 then return end

  local recipes = {}
  local furnaces = {}
  local fueled_entities = {}
  local to_create_requests = {}

  for _, entity in pairs(event.entities) do
    local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
    local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name

    if entity.type == "assembling-machine" and entity.get_recipe() then
      local recipe = entity.get_recipe()
      if not recipes[recipe.name] then
        recipes[recipe.name] = -1
        for i, ingredient in pairs(recipe.ingredients) do
          if ingredient.name == item.name then
            -- save the slot index so we know where to insert it
            recipes[recipe.name] = i - 1
            break
          end
        end
      end

      -- if this entity is using the right recipe (and not full)
      if recipes[recipe.name] >= 0 and entity.get_inventory(defines.inventory.crafter_input).can_insert{
        name = item.name
      } then
        -- queue proxy request
        to_create_requests[#to_create_requests+1] = {entity = entity, slot = recipes[recipe.name], inventory = defines.inventory.crafter_input}
      end
    elseif entity.type == "furnace" then
      if furnaces[entity.type] == nil then
        furnaces[entity.type] = entity.get_inventory(defines.inventory.crafter_input).can_insert{
        name = item.name
      }
      end
      -- if this furnace has an appliccable recipe, and has empty input
      if furnaces[entity.type] and entity.get_inventory(defines.inventory.crafter_input).get_item_count(item.name) >= entity.get_inventory(defines.inventory.crafter_input).get_item_count() then
        -- queue proxy request
        to_create_requests[#to_create_requests+1] = {entity = entity, slot = 0, inventory = defines.inventory.crafter_input}
      end
    elseif entity.type == "entity-ghost" then
      if entity.ghost_type == "assembling-machine" and entity.get_recipe() then
        local recipe = entity.get_recipe()
        if not recipes[recipe.name] then
          recipes[recipe.name] = -1
          for i, ingredient in pairs(recipe.ingredients) do
            if ingredient.name == item.name then
              -- save the slot index so we know where to insert it
              recipes[recipe.name] = i - 1
              break
            end
          end
        end

        -- if this entity is using the right recipe (and not full)
        if recipes[recipe.name] >= 0 then
          -- queue proxy request
          to_create_requests[#to_create_requests+1] = {entity = entity, slot = recipes[recipe.name], inventory = defines.inventory.crafter_input}
        end
      elseif entity.ghost_type == "furnace" then
        if furnaces[entity.ghost_type] == nil then
          -- make sure we have category/recipe data saved
          for category in pairs(entity.ghost_prototype.crafting_categories or {}) do
            recipes_per_category[category] = recipes_per_category[category] or {}
            for _, recipe in pairs(prototypes.recipe) do
              -- recipe must be of this category and only have one ingredient (i.e. furnace compatible)
              recipes_per_category[category][recipe.name] = recipe.has_category(category) and #recipe.ingredients == 1 or nil
            end
          end

          local found = false
          for category in pairs(entity.ghost_prototype.crafting_categories or {}) do
            for recipe in pairs(recipes_per_category[category] or {}) do
              if prototypes.recipe[recipe].ingredients[1].name == item.name then
                to_create_requests[#to_create_requests+1] = {entity = entity, slot = 0, inventory = defines.inventory.crafter_input}
                found = true
                break
              end
            end
            -- if a valid recipe is found, no need to keep looking
            if found then break end
          end
        end
        -- if this furnace has an appliccable recipe
        if furnaces[entity.ghost_type] then
          -- queue proxy request
          to_create_requests[#to_create_requests+1] = {entity = entity, slot = 0, inventory = defines.inventory.crafter_input}
        end
      end
    end

    -- fuel requesting (warning: slow!)
    if entity.type == "entity-ghost" and entity.ghost_prototype.burner_prototype or entity.prototype.burner_prototype then
      local source = entity.type == "entity-ghost" and entity.ghost_prototype.burner_prototype or entity.prototype.burner_prototype
      for category in pairs(source.fuel_categories or {}) do
        if not fuels_per_category[category] then
          fuels_per_category[category] = {}
          for _, item in pairs(prototypes.item) do
            fuels_per_category[category][item.name] = item.fuel_category == category or nil
          end
        end
      end

      local found = false
      for category in pairs(source.fuel_categories or {}) do
        for fuel in pairs(fuels_per_category[category] or {}) do
          if fuel == item.name then
            to_create_requests[#to_create_requests+1] = {entity = entity, slot = 0, inventory = defines.inventory.fuel}
            found = true
            break
          end
        end
        -- if a valid fuel is found, no need to keep looking
        if found then break end
      end
    end
  end

  for _, metadata in pairs(to_create_requests) do
    if metadata.entity.type ~= "entity-ghost" then
      metadata.entity.surface.create_entity{
        name = "item-request-proxy",
        position = metadata.entity.position,
        player = player,
        force = metadata.entity.force,
        target = metadata.entity,
        modules = {{
          id = { name = item.name },
          items = { in_inventory = {{
            inventory = metadata.inventory,
            stack = metadata.slot,
            count = item.count
          }}}
        }}
      }
    else
      local insert_plan = metadata.entity.insert_plan or {}
      insert_plan[#insert_plan+1] = {
        id = { name = item.name },
        items = { in_inventory = {{
          inventory = metadata.inventory,
          stack = metadata.slot,
          count = item.count
        }}}
      }
      metadata.entity.insert_plan = insert_plan
    end
  end
end)

local function save_data(event)
  if not event.element or event.element.get_mod() ~= "item-inserter" then return end

  local window = game.players[event.player_index].gui.center["item-inserter-window"]

  if event.element.type == "button" or event.name == defines.events.on_gui_closed then
    storage[event.player_index] = {
      name = window.main.flow.item.elem_value,
      count = window.main.flow.count.text
    }
    window.destroy()
    game.players[event.player_index].clear_cursor()
    game.players[event.player_index].cursor_stack.set_stack("item-inserter-tool")
  end
end

script.on_event({defines.events.on_gui_closed, defines.events.on_gui_click}, save_data)