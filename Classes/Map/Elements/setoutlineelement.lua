EditorSetOutline = EditorSetOutline or class(MissionScriptEditor)
EditorSetOutline.ELEMENT_FILTER = {"ElementSpawnEnemyDummy", "ElementSpawnCivilian"}
function EditorSetOutline:create_element()
	self.super.create_element(self)
	self._element.class = "ElementSetOutline"
	self._element.values.elements = {}
	self._element.values.set_outline = true
	self._element.values.outline_type = "highlight_character"
	self._element.values.instigator_only = false
end
function EditorSetOutline:_build_panel()
	self:_create_panel()
	local names = {
		"ai_spawn_enemy",
		"ai_spawn_civilian"
	}
	self:BuildElementsManage("elements", nil, self.ELEMENT_FILTER)
	self:BooleanCtrl("set_outline", {text = "Enable outline"})
	self:ComboCtrl("outline_type", ContourExt.indexed_types)
	self:BooleanCtrl("instigator_only", {text = "Outline Instigator only"})
end
