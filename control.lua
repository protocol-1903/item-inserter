-- ============================================================================
-- HUMAN-CREATED SOFTWARE
-- Human-authored. Original work. Not AI-generated.
-- AI training, fine-tuning, dataset creation, and model evaluation prohibited.
-- See LICENSE for complete terms.
-- ============================================================================

local glib = require "__glib__.glib"

local handlers = {}

---@type table<int, {item: string?, count: int}?>
storage = {}

local function create_gui(player_index)
  local player = game.get_player(player_index) ---@cast player -?

  local item_data = storage[player_index] or {count = 0}
  storage[player_index] = item_data
  local insertion_target = player.mod_settings["item-insertion-targets"].value

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
            args = {type = "choose-elem-button", name = "item", elem_type = "item", item = item_data.item, tooltip = {"item-inserter-gui.item-tooltip"}},
            _elem_changed = handlers.update_selection
          },
          {
            args = {type = "textfield", name = "count", numeric = true, text = item_data.count, tooltip = {"item-inserter-gui.count-tooltip"}},
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
          args = {type = "flow"},
          style_mods = {vertical_align = "center"},
          {
            args = {type = "label", caption = {"", {"mod-setting-name.item-insertion-targets"}, " [img=info]"}, tooltip = {"item-inserter-gui.item-insertion-targets-tooltip"}}
          },
          {
            args = {
              type = "drop-down",
              name = "item-insertion-targets",
              items = {{"string-mod-setting.item-insertion-targets-general"}, {"string-mod-setting.item-insertion-targets-fuel"}, {"string-mod-setting.item-insertion-targets-modules"}},
              selected_index = insertion_target == "general" and 1 or insertion_target == "fuel" and 2 or 3,
              tooltip = {"item-inserter-gui.item-insertion-targets-tooltip"},
            },
            _selection_state_changed = handlers.update_settings
          }
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

---@param event EventData.on_gui_checked_state_changed|EventData.on_gui_selection_state_changed
handlers.update_settings = function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
  if event.element.type == "checkbox" then
    player.mod_settings[event.element.name] = {value = event.element.state}
    local gui = player.gui.screen["item-inserter-gui"]
    gui.main.sub["furnace-input-priority"].enabled = player.mod_settings["insert-into-furnace-output"].value --[[@as boolean]]
  elseif event.element.type == "drop-down" then
    player.mod_settings["item-insertion-targets"] = {value = event.element.selected_index == 1 and "general" or event.element.selected_index == 2 and "fuel" or "modules"}
  end
end


---@param event EventData.on_gui_elem_changed|EventData.on_gui_text_changed
handlers.update_selection = function (event)
  local player = game.get_player(event.player_index) ---@cast player -?
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

---@param entity LuaEntity
---@param request {slot: uint, inventory: defines.inventory, item: string, count: uint, quality: string?}
---@return uint
local function add_request_to_entity(entity, request)
  if entity.type ~= "entity-ghost" then
    local proxy = entity.item_request_proxy
    if proxy then
      local insert_plan = proxy.insert_plan --[[@as BlueprintInsertPlan[] ]]
      for _, plan in pairs(insert_plan) do
        if plan.id.name == request.item and plan.id.quality == request.quality then
          for _, inv in pairs(plan.items.in_inventory or {}) do
            if inv.inventory == request.inventory and inv.stack == request.slot - 1 then
              inv.count = (inv.count or 1) + request.count
              goto continue
            end
          end
          plan.items.in_inventory[#plan.items.in_inventory+1] = {
            inventory = request.inventory,
            stack = request.slot - 1,
            count = request.count
          }
          goto continue
        end
      end
      insert_plan[#insert_plan+1] = {
        id = { name = request.item, quality = request.quality },
        items = { in_inventory = {{
          inventory = request.inventory,
          stack = request.slot - 1,
          count = request.count
        }}}
      }
      ::continue::
      proxy.insert_plan = insert_plan
      return request.count
    else
      entity.surface.create_entity{
        name = "item-request-proxy",
        position = entity.position,
        force = entity.force,
        target = entity,
        modules = {{
          id = { name = request.item, quality = request.quality },
          items = { in_inventory = {{
            inventory = request.inventory,
            stack = request.slot - 1,
            count = request.count
          }}}
        }}
      }
      return request.count
    end
  else
    local insert_plan = entity.insert_plan or {}
    for _, plan in pairs(insert_plan) do
      if plan.id.name == request.item and plan.id.quality == request.quality then
        for _, inv in pairs(plan.items.in_inventory or {}) do
          ---@cast inv InventoryPosition
          if inv.inventory == request.inventory and inv.stack == request.slot - 1 then
            inv.count = (inv.count or 1) + request.count
            goto continue
          end
        end
        plan.items.in_inventory[#plan.items.in_inventory + 1] = {
          inventory = request.inventory,
          stack = request.slot - 1,
          count = request.count
        }
        goto continue
      end
    end
    insert_plan[#insert_plan+1] = {
      id = { name = request.item, quality = request.quality },
      items = { in_inventory = {{
        inventory = request.inventory,
        stack = request.slot - 1,
        count = request.count
      }}}
    }
    ::continue::
    entity.insert_plan = insert_plan
    return request.count
  end
end

---@type {[data.RecipeCategoryID]: {[data.ItemID]: LuaRecipePrototype[]}}
local products_by_category = {} -- a list of all items that can be crafted by this category
---@type {[data.RecipeCategoryID]: {[data.ItemID]: RecipeID}}
local ingredients_by_category = {} -- a list of all items that can used to craft by this category

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
-- lab
-- modules (lab, craftingmachine, mining drill, beacon)
-- roboport
-- spider/car?
-- right click remove requests?
-- quality?
-- profit????

-- insertion options:
-- fuel
-- modules
-- general (crafting, labs, rocket silos, ammo) (i/o)
-- 

script.on_event(defines.events.on_player_selected_area, function (event)
  if event.item ~= "item-inserter-tool" then return end

  local player = game.get_player(event.player_index) --[[@cast player -?]]
  local item_data = storage[player.index]
  local insert_target = player.mod_settings["item-insertion-targets"].value

  if not item_data or item_data.count == 0 then return end

  if not (insert_target == "modules" and item_data.item and prototypes.item[item_data.item].type == "module")
    and not (insert_target == "fuel" and item_data.item and prototypes.item[item_data.item].fuel_categories)
    and insert_target ~= "general" then
    player.create_local_flying_text{
      create_at_cursor = true,
      text = not item_data.item and {"notification.no-item-selected"} or
        {(insert_target == "modules" and "inventory-restriction.cant-be-module" or "inventory-restriction.cant-be-burned"), {"item-name." .. item_data.item}}
    }
    return
  end

  local requests = 0

  for _, entity in pairs(event.entities) do

    local prototype = entity.type == "entity-ghost" and entity.ghost_prototype or entity.prototype

    --[[
    defines.inventory.fuel (1)
    defines.inventory.roboport_robot (1)
    defines.inventory.turret_ammo (1)
    defines.inventory.beacon_modules (1)

    defines.inventory.crafter_input (2)
    defines.inventory.roboport_material (2)
    defines.inventory.mining_drill_modules (2)
    defines.inventory.lab_input (2)
    defines.inventory.car_trunk (2)
    defines.inventory.spider_trunk (2)

    defines.inventory.spider_ammo (3)
    defines.inventory.lab_modules (3)
    defines.inventory.car_ammo (3)
    defines.inventory.crafter_output (3)

    defines.inventory.crafter_modules (4)
    defines.inventory.car_trash (4)
    defines.inventory.spider_trash (4)

    defines.inventory.lab_trash (8)
    defines.inventory.crafter_trash (8)
    ]]

    local ghost = entity.type == "entity-ghost"
    local type = ghost and entity.ghost_type or entity.type

    local crafter_input = (type == "assembling-machine" or type == "furnace" or type == "rocket-silo") and entity.get_inventory(defines.inventory.crafter_input)
    local crafter_output = (type == "assembling-machine" or type == "furnace" or type == "rocket-silo") and entity.get_inventory(defines.inventory.crafter_output)
    local turret_inventory = (type == "ammo-turret" or type == "artillery-turret") and entity.get_inventory(defines.inventory.turret_ammo)
    local fuel_inventory = prototype.burner_prototype and entity.get_inventory(defines.inventory.fuel)
    local module_inventory = type == "beacon" and entity.get_inventory(defines.inventory.beacon_modules) or
      type == "mining-drill" and entity.get_inventory(defines.inventory.mining_drill_modules) or
      type == "lab" and entity.get_inventory(defines.inventory.lab_modules) or
      (type == "assembling-machine" or type == "furnace" or type == "rocket-silo") and entity.get_inventory(defines.inventory.crafter_modules)


    if insert_target == "general" and item_data.item then
      local item = prototypes.item[item_data.item]
      if not ghost and type == "assembling-machine" and entity.get_recipe() then
        local recipe = entity.get_recipe() ---@cast recipe -?
        for i, ingredient in pairs(recipe.ingredients) do
          if ingredient.name == item_data.item and crafter_input.can_insert(item_data.item) then
            add_request_to_entity(entity, {
              entity = entity,
              slot = i,
              inventory = defines.inventory.crafter_input,
              item = item_data.item,
              count = item_data.count
            })
            requests = requests + 1
          end
        end
        for i, product in pairs(recipe.products) do
          if product.name == item_data.item and crafter_output.can_insert(item_data.item) then
            add_request_to_entity(entity, {
              entity = entity,
              slot = i,
              inventory = defines.inventory.crafter_output,
              item = item_data.item,
              count = item_data.count
            })
            requests = requests + 1
          end
        end
      elseif ghost and type == "assembling-machine" then
        -- TODO
      elseif not ghost and type == "furnace" then
        local recipe = entity.get_recipe() ---@cast recipe -?
        local input_priority = player.mod_settings["furnace-input-priority"].value
        local insert_to_output = player.mod_settings["insert-into-furnace-output"].value

        local function check_furnace_input()
          if recipe then
            for _, ingredient in pairs(recipe.ingredients) do
              if ingredient.name == item_data.item then
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = 1,
                  inventory = defines.inventory.crafter_input,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                return true
              end
            end
          elseif crafter_input.can_insert(item_data.item) then
            -- make sure the possible recipe doesn't interfere with any existing outputs (or output requests)
            local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
            for category in pairs(entity.prototype.crafting_categories --[[@as table<string,true>]]) do
              local recipe_name = ingredients_by_category[category][item_data.item]
              if recipe_name then
                local i = 1
                for _, product in pairs(prototypes.recipe[recipe_name].products) do
                  if product.type == "item" then
                    if crafter_output[i].valid_for_read and product.name ~= crafter_output[i].name then
                      goto skip
                    elseif not crafter_output[i].valid_for_read then
                      for _, request in pairs(plan or {}) do
                        for _, inv in pairs(request.items.in_inventory or {}) do
                          ---@cast inv InventoryPosition
                          if inv.inventory == defines.inventory.crafter_output and inv.stack == i - 1 and request.id.name ~= product then
                            -- invalid, this item request collides with whats part of the recipe
                            goto skip
                          end
                        end
                      end
                    end
                    i = i + 1
                  end
                end
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = 1,
                  inventory = defines.inventory.crafter_input,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                do return true end
                ::skip::
              end
            end
          end
        end

        -- if input priority is on, check if its a valid ingredient
        if input_priority and crafter_input then
          if check_furnace_input() then goto continue end
        end

        -- if not yet found or input priority is off, check if its a valid product
        if insert_to_output and crafter_output then
          if recipe then
            local i = 0
            for _, product in pairs(recipe.products) do
              if product.type == "item" then i = i + 1 end
              if product.name == item_data.item then
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = i,
                  inventory = defines.inventory.crafter_output,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                goto continue
              end
            end
          else
            -- check if it has a valid recipe that produces this item
            for category in pairs(entity.prototype.crafting_categories --[[@as table<string,true>]]) do
              if products_by_category[category][item_data.item] then
                local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
                -- make sure a valid recipe exists
                for _, pos_recipe in pairs(products_by_category[category][item_data.item]) do
                  for _, ingredient in pairs(pos_recipe.ingredients) do
                    -- if the ingredients of this possible recipe do not match what is in the machine, it is not valid
                    if ingredient.type == "item" and crafter_input[1].valid_for_read and crafter_input[1].name ~= ingredient.name then
                      goto skip
                    elseif ingredient.type == "item" and plan then
                      for _, request in pairs(plan or {}) do
                        for _, inv in pairs(request.items.in_inventory or {}) do
                          ---@cast inv InventoryPosition
                          if inv.inventory == defines.inventory.crafter_input and inv.stack == 0 and request.id.name ~= ingredient.name then
                            -- invalid, this item request collides with whats part of the recipe
                            goto skip
                          end
                        end
                      end
                    elseif ingredient.type == "fluid" and entity.fluids_count ~= 0 and entity.get_fluid(1) and entity.get_fluid(1) then
                      goto skip
                    end
                  end
                  add_request_to_entity(entity, {
                    entity = entity,
                    slot = 1,
                    inventory = defines.inventory.crafter_output,
                    item = item_data.item,
                    count = item_data.count
                  })
                  requests = requests + 1
                  goto continue
                  ::skip::
                end
                break
              end
            end
          end
        end

        -- if product was not found and input priority is off, check if its a valid ingredient
        if crafter_input and not input_priority then
          if check_furnace_input() then goto continue end
        end

      elseif ghost and type == "furnace" then
        -- TODO
      elseif not ghost and type == "ammo-turret" and turret_inventory then
        for _, category in pairs(prototype.attack_parameters.ammo_categories --[[@as string[] ]]) do
          if item.ammo_category and item.ammo_category.name == category then
            local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
            local inventory = {}
            if plan then
              for _, request in pairs(plan) do
                for _, inv in pairs(request.items.in_inventory or {}) do
                  ---@cast inv InventoryPosition
                  if inv.inventory == defines.inventory.turret_ammo then
                    inventory[inv.stack + 1] = request.id.name
                  end
                end
              end
            end
            for i = 1, #turret_inventory do
              local stack = turret_inventory[i] --[[@as LuaItemStack]]
              inventory[i] = inventory[i] or stack.valid_for_read and stack.name or nil
            end
            for i = 1, #turret_inventory do
              if inventory[i] == item_data.item or not inventory[i] then
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = i,
                  inventory = defines.inventory.turret_ammo,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                goto continue
              end
            end
            break
          end
        end
      elseif ghost and type == "ammo-turret" then
        for _, category in pairs(prototype.attack_parameters.ammo_categories --[[@as string[] ]]) do
          if item.ammo_category and item.ammo_category.name == category then
            local plan = entity.insert_plan ---@cast plan -?
            local inventory = {}
            if plan then
              for _, request in pairs(plan) do
                for _, inv in pairs(request.items.in_inventory or {}) do
                  ---@cast inv InventoryPosition
                  if inv.inventory == defines.inventory.turret_ammo then
                    inventory[inv.stack + 1] = request.id.name
                  end
                end
              end
            end
            for i = 1, prototype.get_inventory_size(defines.inventory.turret_ammo) do
              if inventory[i] == item_data.item or not inventory[i] then
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = i,
                  inventory = defines.inventory.turret_ammo,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                goto continue
              end
            end
            break
          end
        end
      elseif not ghost and type == "artillery-turret" then
        for _, category in pairs(prototype.attack_parameters.ammo_categories --[[@as string[] ]]) do
          if item.ammo_category and item.ammo_category.name == category then
            local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
            local inventory = {}
            if plan then
              for _, request in pairs(plan) do
                for _, inv in pairs(request.items.in_inventory or {}) do
                  ---@cast inv InventoryPosition
                  if inv.inventory == defines.inventory.artillery_turret_ammo then
                    inventory[inv.stack + 1] = request.id.name
                  end
                end
              end
            end
            for i = 1, #turret_inventory do
              local stack = turret_inventory[i] --[[@as LuaItemStack]]
              inventory[i] = inventory[i] or stack.valid_for_read and stack.name or nil
            end
            for i = 1, #turret_inventory do
              if inventory[i] == item_data.item or not inventory[i] then
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = i,
                  inventory = defines.inventory.artillery_turret_ammo,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                goto continue
              end
            end
            break
          end
        end
      elseif ghost and type == "artillery-turret" then
        for _, category in pairs(prototype.attack_parameters.ammo_categories --[[@as string[] ]]) do
          if item.ammo_category and item.ammo_category.name == category then
            local plan = entity.insert_plan ---@cast plan -?
            local inventory = {}
            if plan then
              for _, request in pairs(plan) do
                for _, inv in pairs(request.items.in_inventory or {}) do
                  ---@cast inv InventoryPosition
                  if inv.inventory == defines.inventory.artillery_turret_ammo then
                    inventory[inv.stack + 1] = request.id.name
                  end
                end
              end
            end
            for i = 1, prototype.get_inventory_size(defines.inventory.artillery_turret_ammo) do
              if inventory[i] == item_data.item or not inventory[i] then
                add_request_to_entity(entity, {
                  entity = entity,
                  slot = i,
                  inventory = defines.inventory.artillery_turret_ammo,
                  item = item_data.item,
                  count = item_data.count
                })
                requests = requests + 1
                goto continue
              end
            end
            break
          end
        end
      elseif not ghost and type == "artillery-wagon" then
        -- TODO
      elseif ghost and type == "artillery-wagon" then
        -- TODO
      end
    elseif insert_target == "general" and not item_data.item then
      if entity.type == "assembling-machine" and entity.get_recipe() then
        local recipe = entity.get_recipe() ---@cast recipe -?
        local i = 1
        for _, ingredient in pairs(recipe.ingredients) do
          if ingredient.type == "item" then
            add_request_to_entity(entity, {
              entity = entity,
              slot = i,
              inventory = defines.inventory.crafter_input,
              item = ingredient.name,
              count = item_data.count * ingredient.amount --[[@as int]]
            })
            requests = requests + 1
            i = i + 1
          end
        end
      end
    elseif insert_target == "fuel" and fuel_inventory then
      ---@cast item_data.item -?
      local valid
      for _, category in pairs(prototypes.item[item_data.item].fuel_categories --[[@as string[] ]]) do
          if prototype.burner_prototype.fuel_categories[category] then
            valid = true
            break
        end
      end
      if valid and ghost then
        -- TODO
        game.print("ghost fuel insertion not yet implemented, try again later", {skip = defines.print_skip.never})
      elseif valid and fuel_inventory and fuel_inventory.name == "fuel" then
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
          local stack = fuel_inventory[i] --[[@as LuaItemStack]]
          inventory[i] = inventory[i] or stack.valid_for_read and stack.name or nil
          inventory[i] = inventory[i] or fuel_inventory.get_filter(i) and fuel_inventory.get_filter(i).name or nil
        end
        for i = 1, #fuel_inventory do
          if inventory[i] == item_data.item or not inventory[i] then
            add_request_to_entity(entity, {
              entity = entity,
              slot = i,
              inventory = defines.inventory.fuel,
              item = item_data.item,
              count = item_data.count
            })
            requests = requests + 1
            goto continue
          end
        end
      end
    elseif insert_target == "modules" then
      ---@cast item_data.item -?
      if entity.type == "entity-ghost" then
        -- TODO
        game.print("ghost module insertion not yet implemented, try again later", {skip = defines.print_skip.never})
      elseif module_inventory and module_inventory.name--[[@as string]]:find("module") then
        local inventory_index = module_inventory.index ---@cast inventory_index -?
        local plan = entity.item_request_proxy and entity.item_request_proxy.insert_plan ---@cast plan -?
        local inventory = {}
        if plan then
          for _, request in pairs(plan) do
            for _, inv in pairs(request.items.in_inventory or {}) do
              ---@cast inv InventoryPosition
              if inv.inventory == inventory_index then
                inventory[inv.stack + 1] = request.id.name
              end
            end
          end
        end
        for i = 1, #module_inventory do
          local stack = module_inventory[i] --[[@as LuaItemStack]]
          inventory[i] = inventory[i] or stack.valid_for_read and stack.name or nil
        end
        for i = 1, #module_inventory do
          if not inventory[i] then
            add_request_to_entity(entity, {
              entity = entity,
              slot = i,
              inventory = inventory_index,
              item = item_data.item,
              count = item_data.count
            })
            requests = requests + 1
            goto continue
          end
        end
      end
    end
    ::continue::
  end

  if #requests == 0 then
    player.create_local_flying_text{
      create_at_cursor = true,
      text = {"notification.no-valid-entities-selected"}
    }
    return
  end

  -- if total_items == 0 then
  --   player.create_local_flying_text{
  --     create_at_cursor = true,
  --     text = {"notification.no-items-requested"}
  --   }
  -- else
  --   player.create_local_flying_text{
  --     create_at_cursor = true,
  --     text = {"notification.requested-n-items", total_items}
  --   }
  -- end
end)
