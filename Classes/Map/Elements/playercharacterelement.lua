EditorPlayerCharacterFilter = EditorPlayerCharacterFilter or class(MissionScriptEditor)
function EditorPlayerCharacterFilter:create_element(...)
	EditorPlayerCharacterFilter.super.create_element(self, ...)
	self._element.class = "ElementPlayerCharacterFilter"
	self._element.values.character = tweak_data.criminals.character_names[1]
	self._element.values.require_presence = true
	self._element.values.check_instigator = false
end

function EditorPlayerCharacterFilter:_build_panel()
	self:_create_panel()
	self:ComboCtrl("character", tweak_data.criminals.character_names)
	self:BooleanCtrl("require_presence", {text = "Require character presence"})
	self:BooleanCtrl("check_instigator", {text = "Check character's instigator"})
	self:Text("Will only execute if the character is/is not in the game.")
end