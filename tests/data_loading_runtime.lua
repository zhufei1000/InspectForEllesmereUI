-- Embedded data must yield to legacy split providers without executing its payloads.
for _, providers in ipairs({{"QFXGearData"}, {"QFXConsumableData"}, {"QFXGearData","QFXConsumableData"}}) do
    QFXGearData, QFXConsumableData = nil, nil
    local originals = {}
    for _, name in ipairs(providers) do
        local api = {manifest={modules={}}, data={sentinel=true}, schemaVersion=1}
        function api:GetRecommendation() return nil end
        originals[name] = api
        _G[name] = api
    end
    local ns = {}
    assert(loadfile("GearData/core.lua"))("InspectForEllesmereUI",ns)
    assert(ns.RecommendationData and not ns.RecommendationData.Load,
        "split providers leave a safe registration namespace and disable embedded loading")
    assert(loadfile("GearData/sources.lua"))("InspectForEllesmereUI",ns)
    for _, path in ipairs(TEST_DATA_MODULES) do
        assert(loadfile(path))("InspectForEllesmereUI",ns)
    end
    for name, api in pairs(originals) do
        assert(_G[name]==api and api.data.sentinel and not api.__gearSingle,
            "embedded registration never replaces an enabled split provider")
    end
end
print("PASS legacy gear/consumable providers alone and together; all embedded modules register safely")
