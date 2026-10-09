local _, ns = ...
local R = {schemaVersion=1, mode="mythic_plus", frames=setmetatable({}, {__mode="k"})}
ns.Recommendations = R
R.L = ns.RecommendationLocale
R.C = ns.RecommendationCompat
R.slots = {
    {1,HEADSLOT}, {2,NECKSLOT}, {3,SHOULDERSLOT}, {5,CHESTSLOT}, {6,WAISTSLOT},
    {7,LEGSSLOT}, {8,FEETSLOT}, {9,WRISTSLOT}, {10,HANDSSLOT}, {11,FINGER0SLOT},
    {12,FINGER1SLOT}, {13,TRINKET0SLOT}, {14,TRINKET1SLOT}, {15,BACKSLOT}, {16,MAINHANDSLOT}, {17,SECONDARYHANDSLOT},
}

function R:LoadSpecData(specID)
    if type(specID) ~= "number" then return end
    local rd = ns.RecommendationData
    if not rd then
        local host = _G.InspectForEllesmereUIDataNS
        rd = host and host.RecommendationData
    end
    if rd and rd.Load then rd.Load(specID) end
end

function R:GetData(specID, mode)
    if not specID then return nil, self.L.unavailable end
    local api = _G.QFXGearData
    if not api then return nil, self.L.missing end
    if api.schemaVersion ~= self.schemaVersion or type(api.GetRecommendation) ~= "function" then return nil, self.L.incompatible end
    self:LoadSpecData(specID)
    local data, reason = api:GetRecommendation(specID, mode, true)
    if not data then return nil, reason == "combat" and self.L.combat or self.L.unavailable end
    if type(data) ~= "table" or type(data.sampleCount) ~= "number" or type(data.gearSlots) ~= "table" or type(data.statRanges) ~= "table" then return nil, self.L.incompatible end
    if data.expiresAt and time() > data.expiresAt then return nil, self.L.expired end
    return data
end

function R:GetConsumables(specID, mode, seasonID)
    local api = _G.QFXConsumableData
    if not api or api.schemaVersion ~= self.schemaVersion or type(api.GetRecommendation) ~= "function" then return end
    self:LoadSpecData(specID)
    local data = api:GetRecommendation(specID, mode, true)
    if data and data.seasonID == seasonID and (not data.expiresAt or time() <= data.expiresAt) then return data end
end

--側欄按自己的角色取資料，不依賴推薦窗口目前的 owner/data。
function R:SidebarData(unit)
    local specID = self.C.Spec(unit)
    return self:GetData(specID, self.mode)
end

function R:RefreshSidebars()
    if InCombatLockdown() then self.sidebarDirty=true; return end
    self.sidebarDirty=nil
    if not ShowInspectItemListFrame then return end
    for frame in pairs(self.frames) do
        if frame.unit and frame:IsShown() and frame:GetParent() then
            ShowInspectItemListFrame(frame.unit, frame:GetParent())
        end
    end
end

function R:RequestRefresh()
    if not self.panel or not self.panel:IsShown() or self.pending then return end
    if InCombatLockdown() then self.dirty=true; return end
    self.pending = C_Timer.NewTimer(0.1, function()
        R.pending=nil
        if R.panel and R.panel:IsShown() then R:Refresh() end
    end)
end

function R:StopRefresh()
    if self.pending then self.pending:Cancel(); self.pending=nil end
    self.itemRequests = {}
end

function R:Item(itemID)
    local name, link, icon = self.C.Item(itemID, false)
    if not name and itemID and not self.itemRequests[itemID] then
        self.itemRequests[itemID] = true
        self.C.Item(itemID, true)
    end
    return name, link, icon
end
R.itemRequests = {}

--Verified IDs resolve through the client, never through scraped English names.
function R:ItemLabel(itemID, fallback)
    if self.C.Number(itemID) and itemID > 0 then
        return self:Item(itemID) or string.format(self.L.itemLoading, itemID)
    end
    if type(fallback) == "table" then fallback = fallback[GetLocale()] or fallback.enUS end
    return fallback or self.L.unmapped
end

function R:EffectLabel(entry)
    if self.C.Number(entry.itemID) and entry.itemID > 0 then return self:ItemLabel(entry.itemID) end
    local spell = self.C.SpellName(entry.spellID or entry.spellId)
    local effect = entry.effect and (entry.effect[GetLocale()] or entry.effect.enUS)
    return spell or effect or self:ItemLabel(nil, entry.name)
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("COMBAT_RATING_UPDATE")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("INSPECT_READY")
events:SetScript("OnEvent", function(_, event, arg)
    if event == "PLAYER_REGEN_DISABLED" then
        R:StopRefresh()
        return
    end
    if event == "ITEM_DATA_LOAD_RESULT" then
        if not R.C.Safe(arg) or not R.itemRequests[arg] then return end
        -- Keep completed requests marked for this open session, including failures.
    elseif event == "ADDON_LOADED" then
        if not R.C.Safe(arg) or not (arg:match("^QFXGearData") or arg:match("^QFXConsumableData")) then return end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if not R.C.Safe(arg) or arg ~= "player" then return end
    elseif event == "INSPECT_READY" then
        if not R.C.Safe(arg) then return end
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" or event == "INSPECT_READY" or event == "ADDON_LOADED"
        or (event == "PLAYER_REGEN_ENABLED" and R.sidebarDirty) then
        R:RefreshSidebars()
    end
    R:RequestRefresh()
end)
