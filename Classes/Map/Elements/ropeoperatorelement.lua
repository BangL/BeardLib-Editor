EditorRopeOperator = EditorRopeOperator or class(MissionScriptEditor)
EditorRopeOperator.CLASS = "ElementRopeOperator"
EditorRopeOperator.OPERATIONS = {"attach", "detach"}
function EditorRopeOperator:create_element()
	EditorRopeOperator.super.create_element(self)
	self._element.values.operation = "attach"
	self._element.values.rope_unit_id = nil
end

function EditorRopeOperator:_build_panel()
	self:_create_panel()
	self:ComboCtrl("operation", self.OPERATIONS, {help = "Attach the rope to this element's position or let it go"})
	self:NumberCtrl("rope_unit_id", {floats = 0, min = 0, max = 100000000, help = "Unit id of the rope unit, see its unit id in the unit's menu"})
end
