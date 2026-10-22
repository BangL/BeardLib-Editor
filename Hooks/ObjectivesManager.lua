function ObjectivesManager:objectives_by_name()
    local t = {}
    for name, _ in pairs(self._objectives) do
        table.insert(t, name)
    end

    return t
end
