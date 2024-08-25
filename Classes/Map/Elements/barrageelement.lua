EditorBarrage = EditorBarrage or class(MissionScriptEditor)

function EditorBarrage:create_element()
	EditorBarrage.super.create_element(self)
	self._element.class = "ElementBarrage"
	self._element.values.elements = {}
	self._element.values.operation = "start"
	self._element.values.type = "default"
end

function EditorBarrage:_build_panel()
	self:_create_panel()
	self:ComboCtrl("operation", {"start","stop","set_spotter_type"}, {help = "Select which check operation to perform"})
    self:Text("idk what this does")
end