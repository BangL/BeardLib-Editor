EditorRopeTrigger = EditorRopeTrigger or class(MissionScriptEditor)
EditorRopeTrigger.CLASS = "ElementRopeTrigger"
EditorRopeTrigger.LINK_ELEMENTS = {"elements"}
EditorRopeTrigger.ELEMENT_FILTER = {"ElementMotionpathMarker"}
function EditorRopeTriggerreate_element()
	EditorRopeTrigger.super.create_element(self)
	self._element.values.elements = {}
	self._element.values.outcome = ""
end

function EditorRopeTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
	self:StringCtrl("outcome", {help = "Outcome of the linked elements to trigger on"})
end
