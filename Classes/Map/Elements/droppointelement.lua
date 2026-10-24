EditorDropPoint = EditorDropPoint or class(MissionScriptEditor)
EditorDropPoint.CLASS = "ElementDropPoint"
function EditorDropPoint:create_element()
	EditorDropPoint.super.create_element(self)
	self._element.values.icon = "wp_standard"
end

function EditorDropPoint:_build_panel()
	self:_create_panel()
	self:ComboCtrl("icon", EditorWaypoint and EditorWaypoint._icon_options or {"wp_standard"}, {help = "Waypoint icon", free_typing = true})
	self:Text("Position an airdrop can land at. Link it to a drop point group (as on executed) to be picked at random.")
end
