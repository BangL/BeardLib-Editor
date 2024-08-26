EditorExecLuaOperator = EditorExecLuaOperator or class(MissionScriptEditor)
-- EditorExecLuaOperator.WEIRD_ELEMENTS_VALUE = true
function EditorExecLuaOperator:create_element()
	self.super.create_element(self)
	self._element.class = "ElementExecLuaOperator"
	self._element.values.lua_string = ""
	self._element.values.local_only = false
end

function EditorExecLuaOperator:_build_panel()
	self:_create_panel()
	self:BooleanCtrl("local_only", {help = "Local Only"})
	self:StringCtrl("lua_string", {min = 0})

	self:Text("!!EXPERIMENTAL!! Executes arbitrary LUA code")
end
