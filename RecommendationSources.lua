local _, ns = ...
local R = ns.Recommendations

function R:Source(itemID, data)
    if not data then return self.L.unknownSource end
    local api = _G.QFXGearData
    local sources = api and api.itemSources and api.itemSources[itemID]
    local labels = {}
    for _, source in ipairs(sources or {}) do
        if source.seasonID == data.seasonID then
            local name = source.sourceName
            local instance, encounter
            if source.instanceID and source.instanceID > 0 and EJ_GetInstanceInfo then instance=EJ_GetInstanceInfo(source.instanceID) end
            if source.encounterID and source.encounterID > 0 and EJ_GetEncounterInfo then encounter=EJ_GetEncounterInfo(source.encounterID) end
            if source.sourceType == "raid" then name = (instance or source.instanceName or "") .. (encounter and (" · " .. encounter) or source.encounterName and (" · " .. source.encounterName) or "")
            elseif source.sourceType == "dungeon" then name = instance or name
            elseif self.L[source.sourceType] then name = self.L[source.sourceType] end
            if name and name ~= "" then labels[#labels+1]=name end
        end
    end
    return #labels > 0 and table.concat(labels, " / ") or self.L.unknownSource
end
