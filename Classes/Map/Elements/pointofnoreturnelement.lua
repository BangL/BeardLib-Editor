EditorPointOfNoReturn = EditorPointOfNoReturn or class(MissionScriptEditor)
function EditorPointOfNoReturn:create_element()
	self.super.create_element(self)
	self._element.class = "ElementPointOfNoReturn"
	self._element.values.elements = {}
	self._element.values.time_difficulty_1 = 240
	self._element.values.time_difficulty_2 = 120
	self._element.values.time_difficulty_3 = 60
	self._element.values.time_difficulty_4 = 30
	self._element.values.tweak_id = "noreturn"
end

function EditorPointOfNoReturn:_build_panel()
	self:_create_panel()
	self:BuildElementsManage("elements", nil, {"ElementAreaTrigger"})
	self:ComboCtrl("tweak_id", table.map_keys(tweak_data.point_of_no_returns), {help = "Select a tweak id."})
	self:NumberCtrl("time_difficulty_1", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Easy"})
	self:NumberCtrl("time_difficulty_2", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Normal"})
	self:NumberCtrl("time_difficulty_3", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Hard"})
	self:NumberCtrl("time_difficulty_4", {floats = 0, min = 1, help = "Set the time left(seconds)", text = "Very hard"})
end
