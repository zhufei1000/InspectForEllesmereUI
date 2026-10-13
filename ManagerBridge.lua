------------------------------------------------------------------
-- QFX 插件管理中心桥：设置定义导出与入口接管
------------------------------------------------------------------

local addon, ns = ...

local function Manager()
    local api = rawget(_G, "QFXAddonManagerAPI")
    if api and type(api.OpenAddonSettings) == "function" then return api end
    return nil
end

function ns.TryOpenManager(key)
    local manager = Manager()
    if not manager then return false end
    return manager.OpenAddonSettings("InspectForEllesmereUI", key)
end

-- 管理中心适配器通过此表读取设置定义。
_G.InspectForEllesmereUIManagerAPI = ns

local L = ns.L or {}

local function Text(en, cn, tw)
    local locale = GetLocale and GetLocale() or "enUS"
    return locale == "zhCN" and cn or locale == "zhTW" and tw or en
end

local function DB()
    local db = rawget(_G, "InspectForEllesmereUIDB")
    if not db then
        db = {}
        _G.InspectForEllesmereUIDB = db
    end
    return db
end

local function Get(key, default)
    local value = DB()[key]
    if value == nil then return default end
    return value
end

local function Set(key, value)
    DB()[key] = value
end

local function Trigger(event, ...)
    local lib = LibStub and LibStub("LibEvent.7000", true)
    if lib and type(lib.trigger) == "function" then lib:trigger(event, ...) end
end

local AnchorOptions
local function GetAnchorOptions()
    if AnchorOptions then return AnchorOptions end
    AnchorOptions = {}
    for _, pair in ipairs({
        { "TOPLEFT", "Top left", "左上", "左上" },
        { "TOP", "Top", "上", "上" },
        { "TOPRIGHT", "Top right", "右上", "右上" },
        { "LEFT", "Left", "左", "左" },
        { "CENTER", "Center", "居中", "居中" },
        { "RIGHT", "Right", "右", "右" },
        { "BOTTOMLEFT", "Bottom left", "左下", "左下" },
        { "BOTTOM", "Bottom", "下", "下" },
        { "BOTTOMRIGHT", "Bottom right", "右下", "右下" },
    }) do
        AnchorOptions[#AnchorOptions + 1] = { value = pair[1], text = Text(pair[2], pair[3], pair[4]) }
    end
    return AnchorOptions
end

local definition

function ns.GetSettingsDefinition(context)
    if definition then return definition end
    definition = { external = true, tabs = {
        { key = "itemlevel", title = Text("Item level", "物品等级", "物品等級"), build = function(page)
            local levelOn = function() return Get("EnableItemLevel", true) end
            local child = { getEnabled = levelOn }
            local s = page:NewSection(Text("Item level", "物品等级", "物品等級"))
            s:Check(L.EnableItemLevel or "EnableItemLevel", levelOn,
                function(on) Set("EnableItemLevel", on) end)
            s:Check(L.ShowColoredItemLevelString or "ShowColoredItemLevelString",
                function() return Get("ShowColoredItemLevelString", false) end,
                function(on) Set("ShowColoredItemLevelString", on) end, nil, child)
            s:Check(L.ShowItemSlotString or "ShowItemSlotString",
                function() return Get("ShowItemSlotString", true) end,
                function(on) Set("ShowItemSlotString", on) end, nil, child)
            s:Check(L.Other or "Other",
                function() return Get("EnableItemLevelOther", true) end,
                function(on) Set("EnableItemLevelOther", on) end, nil, child)
            s:Check(L.AltEquipment or "AltEquipment",
                function() return Get("EnableItemLevelAltEquipment", true) end,
                function(on) Set("EnableItemLevelAltEquipment", on) end, nil, child)
            s:Check(L.GuildNews or "GuildNews",
                function() return Get("EnableItemLevelGuildNews", true) end,
                function(on) Set("EnableItemLevelGuildNews", on) end, nil, child)
            page:AddSection(s)
        end },
        { key = "panel", title = Text("Inspect panel", "观察面板", "觀察面板"), build = function(page)
            local sheetOn = function() return Get("ShowInspectItemSheet", true) end
            local child = { getEnabled = sheetOn }
            local s = page:NewSection(Text("Inspect panel", "观察面板", "觀察面板"))
            s:Check(L.ShowInspectAngularBorder or "ShowInspectAngularBorder",
                function() return Get("ShowInspectAngularBorder", false) end,
                function(on) Set("ShowInspectAngularBorder", on) end)
            s:Check(L.ShowInspectColoredLabel or "ShowInspectColoredLabel",
                function() return Get("ShowInspectColoredLabel", true) end,
                function(on) Set("ShowInspectColoredLabel", on) end)
            s:Check(L.ShowCharacterItemSheet or "ShowCharacterItemSheet",
                function() return Get("ShowCharacterItemSheet", true) end,
                function(on) Set("ShowCharacterItemSheet", on) end)
            s:Check(L.ShowInspectItemSheet or "ShowInspectItemSheet", sheetOn,
                function(on) Set("ShowInspectItemSheet", on) end)
            s:Check(L.ShowOwnFrameWhenInspecting or "ShowOwnFrameWhenInspecting",
                function() return Get("ShowOwnFrameWhenInspecting", false) end,
                function(on) Set("ShowOwnFrameWhenInspecting", on) end, nil, child)
            s:Check(L.ShowItemStats or "ShowItemStats",
                function() return Get("ShowItemStats", false) end,
                function(on) Set("ShowItemStats", on) end, nil, child)
            s:Check(L.ShowUpgradeInfo or "ShowUpgradeInfo",
                function() return Get("ShowUpgradeInfo", true) end,
                function(on) Set("ShowUpgradeInfo", on) end, nil, child)
            s:Check(L.ShowInspectItemSetSummary or "ShowInspectItemSetSummary",
                function() return Get("ShowInspectItemSetSummary", true) end,
                function(on) Set("ShowInspectItemSetSummary", on) end, nil, child)
            page:AddSection(s)
        end },
        { key = "gear", title = Text("Gear info", "装备信息", "裝備資訊"), build = function(page)
            local s = page:NewSection(Text("Gear info", "装备信息", "裝備資訊"))
            s:Check(L.ShowGemAndEnchant or "ShowGemAndEnchant",
                function() return Get("ShowGemAndEnchant", true) end,
                function(on) Set("ShowGemAndEnchant", on) end)
            s:Check(L.ShowGearDurability or "ShowGearDurability",
                function() return Get("ShowGearDurability", true) end,
                function(on)
                    Set("ShowGearDurability", on)
                    Trigger("GEAR_DURABILITY_DISPLAY_CHANGED")
                end)
            s:Dropdown(L.GearDurabilityAnchorPoint or "GearDurabilityAnchorPoint",
                function() return Get("GearDurabilityAnchorPoint", "BOTTOM") end,
                function(value)
                    Set("GearDurabilityAnchorPoint", value)
                    Trigger("ANCHOR_POINT_CHANGED", "GearDurabilityAnchorPoint", value)
                end, GetAnchorOptions())
            if (GetLocale and GetLocale():sub(1, 2) == "zh") then
                s:Check(L.ShowPluginGreenState or "ShowPluginGreenState",
                    function() return Get("ShowPluginGreenState", false) end,
                    function(on) Set("ShowPluginGreenState", on) end)
            end
            page:AddSection(s)
        end },
    } }
    return definition
end

-- 斜杠命令接管：管理中心可用时打开右侧扩展栏，否则保留原设置窗口。
local nativeSlash = SlashCmdList and SlashCmdList.InspectForEllesmereUI
if type(nativeSlash) == "function" then
    SlashCmdList.InspectForEllesmereUI = function(msg, editbox)
        if ns.TryOpenManager() then return end
        return nativeSlash(msg, editbox)
    end
end

-- 游戏设置分类接管：打开原生分类时跳转到管理中心扩展栏。
local settingsFrame = ns.SettingsFrame
if settingsFrame and type(settingsFrame.HookScript) == "function" then
    settingsFrame:HookScript("OnShow", function(self)
        if ns.TryOpenManager() then self:Hide() end
    end)
end
