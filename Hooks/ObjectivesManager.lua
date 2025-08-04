-- FIXME: remove this when implementing Editor Layers !
function ObjectivesManager:objectives_by_name()
    local t = {}
    -- local level_id = managers.editor:layer("Level Settings"):get_setting("simulation_level_id")

    -- if level_id and level_id ~= "none" then
    -- 	for name, data in pairs(self._objectives) do
    -- 		if data.level_id and data.level_id == level_id then
    -- 			table.insert(t, name)
    -- 		end
    -- 	end
    -- else
    log("OOOOOF OOOOOF OOOOOF OOOOOF OOOOOF!!!!!")
    for name, _ in pairs(self._objectives) do
        table.insert(t, name)
    end
    -- end

    return t
end
