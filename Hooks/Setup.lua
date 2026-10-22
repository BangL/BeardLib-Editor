Hooks:PreHook(Setup, "init_managers", "BeardLibEditorInitManagersPre", function()
	if managers.editor then
		BLE:SetLoadingText("Starting Loading Managers")
	end
end)

Hooks:PostHook(Setup, "init_managers", "BeardLibEditorInitManagers", function()
	if managers.editor then
		BLE:SetLoadingText("Done Loading Managers")
		managers.raid_menu:set_pause_menu_enabled(true)
	end
end)