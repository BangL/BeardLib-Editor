function RaidMenuCallbackHandler:is_not_ble() -- for RaidMainMenuGui:_list_menu_data_source
    return not Global.editor_mode
end

Hooks:PreHook(RaidMenuCallbackHandler, "_dialog_end_game_yes", "BLE_RaidMenuCallbackHandler__dialog_end_game_yes",
    function(self)
        if Global.editor_mode then
            managers.menu:fade_to_black()
            Global.editor_mode = nil
            -- Global.current_mission_filter = nil
            Global.editor_loaded_instance = nil
            BLE.MapEditor:destroy()
        end
    end
)
