EditorGlobalStateFilter = EditorGlobalStateFilter or class(MissionScriptEditor)
-- EditorGlobalStateFilter.WEIRD_ELEMENTS_VALUE = true
EditorGlobalStateFilter.STATES = {
	"set",
	"cleared",
	"value"
}
function EditorGlobalStateFilter:create_element()
	self.super.create_element(self)
	self._element.class = "ElementGlobalStateFilter"
	self._element.values.flag = ""
	self._element.values.state = ""
	self._element.values.check_type = ""
end

function EditorGlobalStateFilter:_build_panel()
	self:_create_panel()
	self:ComboCtrl("flag", managers.global_state:flag_names(), {help = "Select a flag to test"})
	self:ComboCtrl("state", EditorGlobalStateFilter.STATES, {help = "What state of the flag to test"})
	self:ComboCtrl("check_type", {"equal","less_than","greater_than","less_or_equal","greater_or_equal"}, {help = "Select which check operation to perform"})

	self:Text("Filter will execute depending filter condition and global state flags. Check type is applicable only on value global states.")
end
