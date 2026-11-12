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


function OnWorldPreUpdate()
        for _, player in ipairs(EntityGetWithTag("player_unit") or {}) do
                local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
                local wand = inventory and ComponentGetValue2(inventory, "mActiveItem") or 0

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
end
