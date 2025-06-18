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

script.on_event(defines.events.on_player_selected_area, function (event)
  if event.item ~= "item-inserter-tool" then return end

  local player = game.players[event.player_index]
  local item = storage[player.index]

  if not item.name or item.count == 0 then return end

  local recipes = {}
  local furnaces = {}
  local to_create_requests = {}

  for _, entity in pairs(event.entities) do
    local type = entity.type == "entity-ghost" and entity.ghost_type or entity.type
    local name = entity.name == "entity-ghost" and entity.ghost_name or entity.name

    if type == "assembling-machine" and entity.get_recipe() then
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
        to_create_requests[#to_create_requests+1] = {entity = entity, slot = recipes[recipe.name]}
      end
    elseif type == "furnace" then
      if furnaces[type] == nil then
        furnaces[type] = entity.get_inventory(defines.inventory.crafter_input).can_insert{
        name = item.name
      }
      end
      -- if this furnace has an appliccable recipe
      if furnaces[type] or entity.get_inventory(defines.inventory.crafter_input).can_insert{
        name = item.name
      } then
        -- queue proxy request
        to_create_requests[#to_create_requests+1] = {entity = entity, slot = 0}
      end
    end
  end

  for _, metadata in pairs(to_create_requests) do
    metadata.entity.surface.create_entity{
      name = "item-request-proxy",
      position = metadata.entity.position,
      player = player,
      force = metadata.entity.force,
      target = metadata.entity,
      modules = {{
        id = {
          name = item.name
        },
        items = {
          in_inventory = {{
            inventory = defines.inventory.crafter_input,
            stack = metadata.slot,
            count = item.count
          }}
        }
      }}
    }
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