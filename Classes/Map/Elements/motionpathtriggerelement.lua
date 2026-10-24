EditorMotionPathTrigger = EditorMotionPathTrigger or class(MissionScriptEditor)
EditorMotionPathTrigger.CLASS = "ElementMotionPathTrigger"
EditorMotionPathTrigger.LINK_ELEMENTS = {"elements"}
EditorMotionPathTrigger.ELEMENT_FILTER = {"ElementMotionpathMarker"}
function EditorMotionPathTriggerreate_element()
	EditorMotionPathTrigger.super.create_element(self)
	self._element.values.elements = {}
	self._element.values.outcome = ""
end

function EditorMotionPathTrigger:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
	self:StringCtrl("outcome", {help = "Outcome of the linked elements to trigger on"})
end
