EditorStatisticsContact = EditorStatisticsContact or class(MissionScriptEditor)
EditorStatisticsContact.ELEMENT_FILTER = {}
function EditorStatisticsContact:create_element()
	self.super.create_element(self)
	self._element.class = "ElementStatisticsContact"
	self._element.values.elements = {}
	self._element.values.contact = "bain"
	self._element.values.state = "completed"
	self._element.values.difficulty = "all"
	self._element.values.include_dropin = false
	self._element.values.required = 1
end
function EditorStatisticsContact:_build_panel()
	self:_create_panel()
	local states = {
		"started",
		"started_dropin",
		"completed",
		"completed_dropin",
		"failed",
		"failed_dropin"
	}
	self:ComboCtrl("state", states, {help = "Select the required play state."})
	local difficulties = deep_clone(tweak_data.difficulties)
	table.insert(difficulties, "all")
	self:ComboCtrl("difficulty", difficulties, {help = "Select the required difficulty."})
	self:BooleanCtrl("include_dropin", {help = "Select if drop-in is counted as well."})
	self:NumberCtrl("required", {floats = 0, min = 1, help = "Type the required amount that is needed."})
end