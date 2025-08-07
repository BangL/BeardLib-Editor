local _list_menu_data_source_original = RaidMainMenuGui._list_menu_data_source

RaidGUIItemAvailabilityFlag.IS_NOT_BLE = "is_not_ble" -- func in RaidMenuCallbackHandler

function RaidMainMenuGui:_list_menu_data_source(...)
    local _list_items = _list_menu_data_source_original(self, ...)

    -- add BLE entry to main menu
    table.insert(_list_items, 21, {
        callback = "BeardLibEditorMenu",
        availability_flags = {
            RaidGUIItemAvailabilityFlag.IS_IN_MAIN_MENU
        },
        text = managers.localization:text("BeardLibEditorMenu"),
        icon = "menu_item_skills"
    })

    -- disable 'restart mission' and 'return to camp' buttons in BLE
    local disable_in_editor = {
        ["menu_item_restart"] = true,
        ["menu_item_camp"] = true,
    }
    for _, item in ipairs(_list_items) do
        if table.has(disable_in_editor, item.icon) and not table.contains(item.availability_flags, RaidGUIItemAvailabilityFlag.IS_NOT_BLE) then
            table.insert(item.availability_flags, RaidGUIItemAvailabilityFlag.IS_NOT_BLE)
        end
    end

    return _list_items
end
