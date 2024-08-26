EditorGlobalStateTrigger = EditorGlobalStateTrigger or class(MissionScriptEditor)
-- EditorGlobalStateTrigger.WEIRD_ELEMENTS_VALUE = true
EditorGlobalStateTrigger.ACTIONS = {
	"on_set",
	"on_clear",
	"on_event",
	"on_value"
}
function EditorGlobalStateTrigger:create_element()
	self.super.create_element(self)
	self._element.class = "ElementGlobalStateTrigger"
	self._element.values.flag = ""
	self._element.values.on_set = false
	self._element.values.on_clear = false
end

function EditorGlobalStateTrigger:_build_panel()
	self:_create_panel()
	self:ComboCtrl("flag", managers.global_state:flag_names(), {help = "Select a flag"})
	self:BooleanCtrl("on_set", {help = "On Flag Set"})
	self:BooleanCtrl("on_clear", {help = "On Flag Clear"})
	self:BooleanCtrl("on_event", {help = "On Event"})
	self:BooleanCtrl("on_value", {help = "On Value"})
	self:ComboCtrl("check_type", {"equal","less_than","greater_than","less_or_equal","greater_or_equal"}, {help = "Select which check operation to perform"})

	self:Text("Trigger depending on global state flags. Check type is only applicable on value elements.")
end
