EditorSlowMotion = EditorSlowMotion or class(MissionScriptEditor)
function EditorSlowMotion:create_element()
	EditorSlowMotion.super.create_element(self)
    self._element.class = "ElementSlowMotion"
    self._element.values.eff_name = ""
end

function EditorSlowMotion:_build_panel()
	self:_create_panel()
	self:ComboCtrl("eff_name", table.map_keys(tweak_data.timespeed), {help = "Choose effect. Descriptions in lib/TimeSpeedEffectTweakData.lua"})
end
