Hooks:PostHook(CoreWorldCollection, "on_world_loaded", "BLELoadTest", function(self, index)
    if managers.worlddefinition and managers.worlddefinition._continent_definitions then
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
    end
    --local definition = self._world_definitions[index]
    --self._mission_params[definition._world_id] = nil

    --definition:init_done()
end)