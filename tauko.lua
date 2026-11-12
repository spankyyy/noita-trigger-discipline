table.insert(actions, {
        id = "TAUKO",
        name = "Trigger Discipline",
        description =
        "Makes the affected spell group semi-automatic, interrupting continuous casting after it fires.",
        sprite = "mods/semi_auto_wands/trigger_discipline.png",
        sprite_unidentified = "data/ui_gfx/gun_actions/spread_reduce_unidentified.png",
        type = ACTION_TYPE_UTILITY,
        spawn_level = "0,1,2,3,4,5,6",
        spawn_probability = "1,1,1,1,1,1,1",
        price = 100,
        mana = 5,
        action = function()
                c.fire_rate_wait = c.fire_rate_wait - 8
                current_reload_time = current_reload_time - 12
                -- Spell reflection builds tooltips; it must not pause a real wand.
                if not reflecting then
                        local player = EntityGetRootEntity(GetUpdatedEntityID())
                        local shooter = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
                        local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
                        if shooter and inventory then
                                local wand = ComponentGetValue2(inventory, "mActiveItem")
                                if wand ~= 0 then
                                        local pending
                                        for _, component in ipairs(EntityGetComponentIncludingDisabled(player, "VariableStorageComponent") or {}) do
                                                if ComponentGetValue2(component, "name") == "semi_auto_wands_tauko_pending" then
                                                        pending = component
                                                        break
                                                end
                                        end
                                        if pending then
                                                ComponentSetValue2(pending, "value_int", wand)
                                        else
                                                EntityAddComponent2(player, "VariableStorageComponent", {
                                                        name = "semi_auto_wands_tauko_pending",
                                                        value_int = wand,
                                                })
                                        end
                                end
                        end
                end
                draw_actions(1, true)
        end,
})
