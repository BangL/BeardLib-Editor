EditorFilter = EditorFilter or class(MissionScriptEditor)
function EditorFilter:create_element()
	self.super.create_element(self)
	self._element.class = "ElementFilter"
	self._element.values.difficulty_normal = true
	self._element.values.difficulty_hard = true
	self._element.values.difficulty_overkill = true
	self._element.values.difficulty_overkill_145 = true
	self._element.values.player_1 = true
	self._element.values.player_2 = true
	self._element.values.player_3 = true
	self._element.values.player_4 = true
	self._element.values.platform_win32 = true
	self._element.values.platform_console = true
	self._element.values.mode_assault = true
	self._element.values.mode_control = true
	self._element.values.alarm_on = true
	self._element.values.alarm_off = true

end

function EditorFilter:init(...)
	local unit = EditorFilter.super.init(self, ...)
	self:_check_convertion()

	return unit
end

function EditorFilter:_check_convertion()
	if self._element.values.difficulty_overkill_290 == nil then
		self._element.values.difficulty_overkill_290 = self._element.values.difficulty_overkill_145
	end

	if self._element.values.difficulty_easy_wish == nil then
		self._element.values.difficulty_easy_wish = self._element.values.difficulty_overkill_290
	end

	if self._element.values.difficulty_sm_wish == nil then
		self._element.values.difficulty_sm_wish = self._element.values.difficulty_overkill_290
	end
end

function EditorFilter:_build_panel()
	self:_create_panel()

	local difficulty = self._class_group:group("Difficulty", {align_method = "grid"})
	self:BooleanCtrl("difficulty_normal", {text = "Easy", group = difficulty})
	self:BooleanCtrl("difficulty_hard", {text = "Normal", group = difficulty})
	self:BooleanCtrl("difficulty_overkill", {text = "Hard", group = difficulty})
	self:BooleanCtrl("difficulty_overkill_145", {text = "Very Hard", group = difficulty})

	local players = self._class_group:group("Players", {align_method = "grid"}) 
	self:BooleanCtrl("player_1", {text = "One Player", group = players})
	self:BooleanCtrl("player_2", {text = "Two Players", group = players})
	self:BooleanCtrl("player_3", {text = "Three Players", group = players})
	self:BooleanCtrl("player_4", {text = "Four Players", group = players})

	local platform = self._class_group:group("Platform", {align_method = "grid"}) 
	self:BooleanCtrl("platform_win32", {text = "Windows", group = platform})
	self:BooleanCtrl("platform_console", {text = "Console (as if your gonna need this)", group = platform})

	local mode = self._class_group:group("Mode", {align_method = "grid"}) 
	self:BooleanCtrl("mode_control", {text = "Control", group = mode})
	self:BooleanCtrl("mode_assault", {text = "Assault", group = mode})
	mode:separator()
	self:BooleanCtrl("alarm_on", {text = "Alarmed", group = mode})
	self:BooleanCtrl("alarm_off", {text = "Unalarmed", group = mode})
end
