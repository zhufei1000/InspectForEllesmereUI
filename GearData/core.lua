-- InspectForEllesmereUI recommendation data core (generated, do not edit).
local addon, ns = ...
ns = ns or _G.InspectForEllesmereUIDataNS or {}
_G.InspectForEllesmereUIDataNS = ns

local RD = {specs = {}, sourcesLoaded = false}
ns.RecommendationData = RD

local function hasSplit(name)
    local api = _G[name]
    return type(api) == "table" and type(api.manifest) == "table"
        and api.manifest.modules ~= nil and not api.__gearSingle
end

if hasSplit("QFXGearData") or hasSplit("QFXConsumableData") then
    print("|cffff5555InspectForEllesmereUI|r: split QFX data addons detected; disable them to use this file.")
    return
end

local MANIFEST = {["seasonID"]=18,["seasonSlug"]="season-mn-2",["patch"]="12.1.0",["region"]="world",["windowStart"]="2026-10-08T14:21:19",["windowEnd"]="2026-10-22T14:21:19",["version"]="1.0.0",["updatedAt"]="2026-10-22T14:21:19",["schemaVersion"]=1,["internalTest"]=true,["modules"]={["62:mythic_plus"]="GearData",["62:raid"]="GearData",["63:mythic_plus"]="GearData",["63:raid"]="GearData",["64:mythic_plus"]="GearData",["64:raid"]="GearData",["65:mythic_plus"]="GearData",["65:raid"]="GearData",["66:mythic_plus"]="GearData",["66:raid"]="GearData",["70:mythic_plus"]="GearData",["70:raid"]="GearData",["71:mythic_plus"]="GearData",["71:raid"]="GearData",["72:mythic_plus"]="GearData",["72:raid"]="GearData",["73:mythic_plus"]="GearData",["73:raid"]="GearData",["102:mythic_plus"]="GearData",["102:raid"]="GearData",["103:mythic_plus"]="GearData",["103:raid"]="GearData",["104:mythic_plus"]="GearData",["104:raid"]="GearData",["105:mythic_plus"]="GearData",["105:raid"]="GearData",["250:mythic_plus"]="GearData",["250:raid"]="GearData",["251:mythic_plus"]="GearData",["251:raid"]="GearData",["252:mythic_plus"]="GearData",["252:raid"]="GearData",["253:mythic_plus"]="GearData",["253:raid"]="GearData",["254:mythic_plus"]="GearData",["254:raid"]="GearData",["255:mythic_plus"]="GearData",["255:raid"]="GearData",["256:mythic_plus"]="GearData",["256:raid"]="GearData",["257:mythic_plus"]="GearData",["257:raid"]="GearData",["258:mythic_plus"]="GearData",["258:raid"]="GearData",["259:mythic_plus"]="GearData",["259:raid"]="GearData",["260:mythic_plus"]="GearData",["260:raid"]="GearData",["261:mythic_plus"]="GearData",["261:raid"]="GearData",["262:mythic_plus"]="GearData",["262:raid"]="GearData",["263:mythic_plus"]="GearData",["263:raid"]="GearData",["264:mythic_plus"]="GearData",["264:raid"]="GearData",["265:mythic_plus"]="GearData",["265:raid"]="GearData",["266:mythic_plus"]="GearData",["266:raid"]="GearData",["267:mythic_plus"]="GearData",["267:raid"]="GearData",["268:mythic_plus"]="GearData",["268:raid"]="GearData",["269:mythic_plus"]="GearData",["269:raid"]="GearData",["270:mythic_plus"]="GearData",["270:raid"]="GearData",["577:mythic_plus"]="GearData",["577:raid"]="GearData",["581:mythic_plus"]="GearData",["581:raid"]="GearData",["1467:mythic_plus"]="GearData",["1467:raid"]="GearData",["1468:mythic_plus"]="GearData",["1468:raid"]="GearData",["1473:mythic_plus"]="GearData",["1473:raid"]="GearData",["1480:mythic_plus"]="GearData",["1480:raid"]="GearData"}}

local function ensure(name)
    local api = _G[name]
    if type(api) ~= "table" then api = {} _G[name] = api end
    api.schemaVersion = 1
    api.data = {}
    api.itemSources = api.itemSources or {}
    api.failedLoads = api.failedLoads or {}
    api.manifest = MANIFEST
    if not api.__gearSingle then
        function api:Register(specID, mode, data)
            if type(data) ~= "table" or data.schemaVersion ~= 1 or data.seasonID ~= self.manifest.seasonID then return end
            self.data[specID] = self.data[specID] or {}
            self.data[specID][mode] = data
        end
        function api:GetRecommendation(specID, mode)
            return self.data[specID] and self.data[specID][mode]
        end
        function api:GetMetadata() return self.manifest end
    end
    api.__gearSingle = true
    return api
end

ensure("QFXGearData")
ensure("QFXConsumableData")

function RD.Load(specID)
    local fn = RD.specs[specID]
    if not fn then return end
    RD.specs[specID] = nil
    if not RD.sourcesLoaded then
        RD.sourcesLoaded = true
        if RD.loadSources then
            RD.loadSources()
            RD.loadSources = nil
        end
    end
    fn()
end
