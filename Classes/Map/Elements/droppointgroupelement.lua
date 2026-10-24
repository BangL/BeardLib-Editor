EditorDropPointGroup = EditorDropPointGroup or class(MissionScriptEditor)
EditorDropPointGroup.CLASS = "ElementDropPointGroup"
function EditorDropPointGroup:create_element()
	EditorDropPointGroup.super.create_element(self)
	self._element.values.icon = "wp_standard"
end

function EditorDropPointGroup:_build_panel()
	self:_create_panel()
	self:ComboCtrl("icon", EditorWaypoint and EditorWaypoint._icon_options or {"wp_standard"}, {help = "Waypoint icon", free_typing = true})
	self:Text("Add the drop points of this group in the 'on executed' list.")
end
