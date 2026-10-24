EditorMotionpathMarker = EditorMotionpathMarker or class(MissionScriptEditor)
EditorMotionpathMarker.CLASS = "ElementMotionpathMarker"
EditorMotionpathMarker.MOTION_STATES = {"move", "wait"}
function EditorMotionpathMarker:create_element()
	EditorMotionpathMarker.super.create_element(self)
	self._element.values.icon = "wp_standard"
	self._element.values.motion_state = "move"
	self._element.values.path_id = nil
end

function EditorMotionpathMarker:_build_panel()
	self:_create_panel()
	self:ComboCtrl("icon", EditorWaypoint and EditorWaypoint._icon_options or {"wp_standard"}, {help = "Waypoint icon", free_typing = true})
	self:ComboCtrl("motion_state", self.MOTION_STATES, {help = "Initial motion state of the marker"})
	self:NumberCtrl("path_id", {floats = 0, min = 0, help = "Id of the path this marker belongs to, markers with the same id form one path"})
end
