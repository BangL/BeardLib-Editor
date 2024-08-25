EditorNavigationStitcherOperator = EditorNavigationStitcherOperator or class(MissionScriptEditor)
-- todo i lazy
function EditorNavigationStitcherOperator:create_element()
	EditorNavigationStitcherOperator.super.create_element(self)
	self._element.class = "ElementNavigationStitcherOperator"
end

function EditorNavigationStitcherOperator:_build_panel()
	self:_create_panel()
	self:Text("Havent finished remaking this to work in raid BLE")
end