ModLuaFileAppend("data/scripts/gun/gun_actions.lua", "mods/semi_auto_wands/tauko.lua")

local MOD_ID = "semi_auto_wands"
local PENDING = MOD_ID .. "_tauko_pending"
local latched_players = {}

local function get_storage(entity, name)
        for _, component in ipairs(EntityGetComponentIncludingDisabled(entity, "VariableStorageComponent") or {}) do
                if ComponentGetValue2(component, "name") == name then
                        return component
                end
        end
end

local function migrate_wand(wand)
        if get_storage(wand, MOD_ID .. "_tauko_migrated") then
                return
        end
        local ability = EntityGetFirstComponentIncludingDisabled(wand, "AbilityComponent")
        local item = EntityGetFirstComponentIncludingDisabled(wand, "ItemComponent")
        if not ability or not item or not ComponentGetValue2(ability, "use_gun_script") then
                return
        end

        EntityRemoveTag(wand, MOD_ID .. "_semi_auto")
        local description = get_storage(wand, MOD_ID .. "_base_description")
        if description then
                ComponentSetValue2(item, "ui_description", ComponentGetValue2(description, "value_string"))
        end
        local item_name = ComponentGetValue2(item, "item_name")
        local ability_name = ComponentGetValue2(ability, "ui_name")
        if item_name:match(" %(Semi%-auto%)$") or ability_name:match(" %(Semi%-auto%)$") then
                local stored = get_storage(wand, MOD_ID .. "_base_name")
                local name = stored and ComponentGetValue2(stored, "value_string")
                    or item_name:gsub(" %(Semi%-auto%)$", "")
                if name == "" or name == "[NOT_SET]"
                    or name:lower() == "default_gun" or name:lower() == "bomb_wand" then
                        name = "$item_wand"
                end
                ComponentSetValue2(item, "item_name", name)
                ComponentSetValue2(ability, "ui_name", name)
                ComponentSetValue2(item, "always_use_item_name_in_ui", false)
        end
        EntityAddComponent2(wand, "VariableStorageComponent", { name = MOD_ID .. "_tauko_migrated" })
end

function OnWorldPreUpdate()
        for _, player in ipairs(EntityGetWithTag("player_unit") or {}) do
                local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
                local wand = inventory and ComponentGetValue2(inventory, "mActiveItem") or 0
                if wand ~= 0 then
                        migrate_wand(wand)
                end
                if latched_players[player] and latched_players[player] ~= wand then
                        local shooter = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
                        if shooter then
                                ComponentSetValue2(shooter, "mRequireTriggerPull", false)
                        end
                        latched_players[player] = nil
                end
        end
end

function OnWorldPostUpdate()
        for _, player in ipairs(EntityGetWithTag("player_unit") or {}) do
                local pending = get_storage(player, PENDING)
                local pending_wand = pending and ComponentGetValue2(pending, "value_int") or 0
                if pending_wand ~= 0 then
                        ComponentSetValue2(pending, "value_int", 0)
                end

                local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
                local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
                local shooter = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
                local wand = inventory and ComponentGetValue2(inventory, "mActiveItem") or 0
                local held = controls and ComponentGetValue2(controls, "mButtonDownFire")
                if shooter then
                        if wand ~= 0 and held and (pending_wand == wand or latched_players[player] == wand) then
                                -- Wait until the whole cast has finished before blocking the next
                                -- cast. Reapply while held, without manufacturing input edges.
                                ComponentSetValue2(shooter, "mRequireTriggerPull", true)
                                latched_players[player] = wand
                        elseif latched_players[player] then
                                ComponentSetValue2(shooter, "mRequireTriggerPull", false)
                                latched_players[player] = nil
                        end
                end
        end

        if GameGetFrameNum() % 30 == 0 then
                for _, wand in ipairs(EntityGetWithTag("wand") or {}) do
                        migrate_wand(wand)
                end
        end
end
