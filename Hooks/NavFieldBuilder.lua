if not Global.editor_mode then
	return
end

function NavFieldBuilder:_create_build_progress_bar(title, num_divistions)
	if not self._progress_dialog then
		local status = BLE.Utils:GetPart("status")
		self._progress_dialog = status:StatusDialog(title, "expanding room", {{name = "Cancel", callback = function()
			self._progress_dialog_cancel = true
			BLE.Utils:GetLayer("ai"):reenable_disabled_units()
		end}})
	end
end

-- The build is a task that does one small step per call. The game calls it once per frame (so a room per frame, and a
-- frame costs a lot more than the step: drawing, gui), the editor runs as many steps as fit into the budget instead.
NavFieldBuilder.STEP_TIME_BUDGET = 0.04 -- seconds per frame spent on the build
NavFieldBuilder.PROGRESS_TEXT_INTERVAL = 0.1 -- seconds between two updates of the text of the progress dialog

function NavFieldBuilder:update(t, dt)
	if not self._building then
		return
	end
	local start = os.clock()
	repeat
		if self._progress_dialog_cancel then
			self._progress_dialog_cancel = nil
			self:clear()
			self:_destroy_progress_bar()
			self._building = nil
			return
		end
		self._building.task_clbk(self)
	until not self._building or os.clock() - start >= self.STEP_TIME_BUDGET
end

function NavFieldBuilder:_update_progress_bar(percent_complete, title)
	-- the step runs many times per frame, the text of a gui item is not cheap
	local now = os.clock()
	if self._progress_dialog and (not self._progress_text_t or now - self._progress_text_t >= self.PROGRESS_TEXT_INTERVAL) then
		self._progress_text_t = now
		self._progress_dialog:GetItem("Sub"):SetText(title)
	end
end

function NavFieldBuilder:_destroy_progress_bar()
	if self._progress_dialog then
		self._progress_dialog:Destroy()
		self._progress_dialog = nil
	end
end