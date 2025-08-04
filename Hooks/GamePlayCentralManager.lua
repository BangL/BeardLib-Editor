Hooks:PostHook(GamePlayCentralManager, "init", "BLE_GamePlayCentralManager_post_init",
    function(self)
        if Global.editor_mode then
            -- self._spawned_warcry_units = {} -- TODO?
            self._spawned_projectiles = {}
            -- self._spawned_pickups = {} -- TODO?
            -- self._dropped_weapons = {} -- TODO?
        end
    end
)

function GamePlayCentralManager:add_spawned_projectiles(unit, world_id)
    if Global.editor_mode then
        table.insert(self._spawned_projectiles, unit)
    else
        managers.worldcollection:register_spawned_unit(unit, unit:position(), world_id)
    end

    return unit
end
