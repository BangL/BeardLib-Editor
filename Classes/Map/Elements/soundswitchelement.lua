EditorSoundSwitch = EditorSoundSwitch or class(MissionScriptEditor)
EditorSoundSwitch.CLASS = "ElementSoundSwitch"
EditorSoundSwitch.SWITCHES = {"daytime_set_day", "daytime_set_night"}
function EditorSoundSwitch:create_element()
	EditorSoundSwitch.super.create_element(self)
	self._element.values.switch = self.SWITCHES[1]
end

function EditorSoundSwitch:_build_panel()
	self:_create_panel()
	self:ComboCtrl("switch", self.SWITCHES, {help = "Ambience switch to apply"})
end
