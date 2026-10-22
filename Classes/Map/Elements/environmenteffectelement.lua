EditorEnvironmentEffect = EditorEnvironmentEffect or class(MissionScriptEditor)
EditorEnvironmentEffect.CLASS = "ElementEnvironmentEffect"
EditorEnvironmentEffect.ACTIONS = {"set", "remove"}
EditorEnvironmentEffect.EFFECTS = {"rain", "rain_light", "raindrop_screen", "lightning", "speed_lines", "smoke_of_war"}
function EditorEnvironmentEffect:create_element()
	EditorEnvironmentEffect.super.create_element(self)
	self._element.values.action = "set"
	self._element.values.effect = "rain"
	self._element.values.local_only = true
end

function EditorEnvironmentEffect:_build_panel()
	self:_create_panel()
	self:ComboCtrl("action", self.ACTIONS, {help = "Start or stop the effect"})
	self:ComboCtrl("effect", self.EFFECTS, {help = "The environment effect", free_typing = true})
	self:BooleanCtrl("local_only", {help = "The game only applies the effect when the instigator is the local player, leave it on"})
end
