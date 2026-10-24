EditorMotionPathOperator = EditorMotionPathOperator or class(MissionScriptEditor)
EditorMotionPathOperator.CLASS = "ElementMotionPathOperator"
EditorMotionPathOperator.LINK_ELEMENTS = {"elements"}
EditorMotionPathOperator.ELEMENT_FILTER = {"ElementMotionpathMarker"}
EditorMotionPathOperator.OPERATIONS = {"activate_bridge", "deactivate_bridge", "path_start", "path_stop", "goto_marker", "teleport", "move", "wait", "rotate"}
function EditorMotionPathOperator:create_element()
	EditorMotionPathOperator.super.create_element(self)
	self._element.values.operation = "path_start"
	self._element.values.elements = {}
	self._element.values.marker = ""
	self._element.values.marker_ids = {}
end

--- Editor names and ids of all motion path markers of the level.
function EditorMotionPathOperator:_markers()
	local markers = {}
	for _, unit in pairs(managers.editor:GetPart("mission"):units()) do
		local element = alive(unit) and unit:mission_element() and unit:mission_element().element
		if element and element.class == "ElementMotionpathMarker" then
			markers[element.editor_name] = element.id
		end
	end
	return markers
end

function EditorMotionPathOperator:set_element_data(item, ...)
	EditorMotionPathOperator.super.set_element_data(self, item, ...)
	if item and item:Name() == "marker" then
		-- the game looks the target marker up by name
		local marker = self._element.values.marker
		self._element.values.marker_ids = {}
		self._element.values.marker_ids[marker] = self:_markers()[marker]
	end
end

function EditorMotionPathOperator:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
	self:ComboCtrl("operation", self.OPERATIONS, {help = "Operation on the linked markers/path"})
	self:ComboCtrl("marker", table.map_keys(self:_markers()), {help = "Target marker for goto_marker and teleport", free_typing = true})
end
