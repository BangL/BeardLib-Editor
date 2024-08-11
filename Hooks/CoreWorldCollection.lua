Hooks:PostHook(CoreWorldCollection, "on_world_loaded", "BLELoadTest", function(self, index)
    if managers.worlddefinition and managers.worlddefinition._continent_definitions and managers.editor then
        managers.editor:load_continents(managers.worlddefinition._continent_definitions)
    end
end)