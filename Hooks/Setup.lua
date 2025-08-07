-- FIXME: dead code, these hooked functions dont exist in raid.
-- TODO: do we need a re-impl for raid?

-- Hooks:PreHook(Setup, "start_loading_screen", "BeardLibEditorStartLoadingScreen", function()
-- 	if not Global.editor_mode then
-- 		return
-- 	end
-- 	Global.level_data.editor_load = nil
-- 	if Global.level_data then
-- 		local level_tweak_data = tweak_data.levels[Global.current_level_id]
-- 		if level_tweak_data or Global.editor_loaded_instance then
-- 			local gui_data = CoreGuiDataManager.GuiDataManager:new(LoadingEnvironmentScene:gui())
-- 			local ws = gui_data:create_fullscreen_workspace()
-- 			local panel = ws:panel():panel({name = "Load", layer = 50})
-- 			local bgcolor = BLE.Options:GetValue("BackgroundColor")
-- 			panel:rect({
-- 				name = "Background",
-- 		       	color = bgcolor:with_alpha(1),
-- 			})
-- 			Global.LoadingText = panel:text({
-- 				name = "Loading",
-- 				font = "fonts/font_large_buttons",
-- 				font_size = 32,
-- 				layer = 99999,
-- 				color = bgcolor:contrast(),
-- 				align = "center",
-- 				vertical = "center",
-- 			})
-- 			Global.LoadingText:set_text(BLE:SetLoadingText("Waiting For Response"))
-- 			if Global.check_load_time then
-- 				Global.check_load_time = os.clock()
-- 			end
-- 			Global.level_data.editor_load = true
-- 		end
-- 	end
-- end)

-- Hooks:PreHook(Setup, "stop_loading_screen", "BeardLibEditorStopLoading", function()
-- 	if Global.editor_mode then
-- 		if Global.check_load_time then
-- 			Global.check_load_time = os.clock() - Global.check_load_time
-- 		end
-- 		if managers.editor then
-- 			managers.editor:animate_bg_fade()
-- 		end
-- 		Global.LoadingText = nil
-- 	end
-- end)

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