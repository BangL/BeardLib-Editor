EditorCarry = EditorCarry or class(MissionScriptEditor)
EditorCarry.CARRY_OPTIONS = {
	"remove",
	"remove_align",
	"freeze",
	"secure",
	"secure_silent",
	"add_to_respawn",
	"filter_only"
}
function EditorCarry:create_element()
	self.super.create_element(self)
	self._element.class = "ElementCarry"
	self._element.values.elements = {}
	self._element.values.operation = "secure"
	self._element.values.type_filter = "none" 
	self._align_units = {}
	self._element.values.anim_align_unit_ids = {}
end
function EditorCarry:_build_panel()
	self:_create_panel()
	self:ComboCtrl("operation", EditorCarry.CARRY_OPTIONS, {help = "Select which check operation to perform"})
	self:ComboCtrl("type_filter", table.list_add({"none"}, tweak_data.carry:get_carry_ids()), {not_close = true, searchbox = true, fit_text = true})
end
