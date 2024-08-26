EditorGlobalStateOperator = EditorGlobalStateOperator or class(MissionScriptEditor)
-- EditorGlobalStateOperator.WEIRD_ELEMENTS_VALUE = true
EditorGlobalStateOperator.ACTIONS = {
	"set",
	"set_value",
	"clear",
	"default",
	"event"
}
function EditorGlobalStateOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementGlobalStateOperator"
	self._element.values.action = "set"
	self._element.values.flag = ""
end

function EditorGlobalStateOperator:_build_panel()
	self:_create_panel()
	self:ComboCtrl("flag", managers.global_state:flag_names(), {help = "Select an flag"})
	self:ComboCtrl("action", EditorGlobalStateOperator.ACTIONS, {help = "Select an action for the selected flag"})

	self:Text("Changes the global state flags")
end
