if not Global.editor_mode then
	return
end

-- The environment feeders re-apply the SSAO setting whenever an environment is applied, which would turn
-- SSAO back on in the editor viewport, where it renders buildings/interiors black (issue #3).
local set_ssao_setting = CoreEnvironmentControllerManager.set_ssao_setting
function CoreEnvironmentControllerManager:set_ssao_setting(setting, ...)
	local editor = managers.editor
	if editor and editor:enabled() and not (BLE.Options:GetValue("Map/PostProcessingEffects") and BLE.Options:GetValue("Map/PostFXSSAO")) then
		setting = "off"
	end
	return set_ssao_setting(self, setting, ...)
end
