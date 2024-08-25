EditorEscort = EditorEscort or class(MissionScriptEditor)

function EditorEscort:create_element()
	EditorEscort.super.create_element(self)
	self._element.class = "ElementEscort"
	self._test_units = {}
	self._element.values.break_so = "none"
	self._element.values.break_point = false
	self._element.values.next_points = {}
	self._element.values.spawn_elements = {}
	self._element.values.usage_times = 0
	self._element.values.test_unit = "units/vanilla/characters/enemies/models/german_grunt_light_test/german_grunt_light_test"

end

function EditorEscort:_build_panel()
	self:_create_panel()
    self:Text("Not finished recreating to work in raid BLE")
end