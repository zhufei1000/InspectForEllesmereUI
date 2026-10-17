-- Real bridge under ancestor visibility changes, without loot or a settings click.
local locale, root = ...
root = root or ""
function GetLocale() return locale or "enUS" end
local frames, methods = {}, {}
local function visible(frame)
    return frame.shown and (not frame.parent or visible(frame.parent))
end
local function change(fn)
    local before = {}
    for _, frame in ipairs(frames) do before[frame] = visible(frame) end
    fn()
    for _, frame in ipairs(frames) do
        if visible(frame) and not before[frame] and frame.onShow then frame.onShow(frame) end
    end
end
local function Frame(parent)
    local frame = setmetatable({shown = true, parent = parent}, {__index = methods})
    frames[#frames + 1] = frame
    return frame
end
function methods:IsVisible() return visible(self) end
function methods:IsShown() return self.shown end
function methods:GetParent() return self.parent end
function methods:SetParent(parent) change(function() self.parent = parent end) end
function methods:Show() change(function() self.shown = true end) end
function methods:Hide() change(function() self.shown = false end) end
function methods:HookScript(event, callback) assert(event == "OnShow"); self.onShow = callback end

UIParent = Frame()
SettingsPanel = Frame(UIParent); SettingsPanel:Hide()
InterfaceOptionsFrame = Frame(UIParent); InterfaceOptionsFrame:Hide()
local canvas = Frame(SettingsPanel)
local panel = Frame(UIParent)
local calls, nativeCalls, selected = {}, 0, "QFXBeggar"
local manager = {OpenAddonSettings = function(name, key)
    assert(name == "InspectForEllesmereUI")
    calls[#calls + 1] = {name = name, key = key}
    selected = name
    return true
end}
QFXAddonManagerAPI = manager
SlashCmdList = {InspectForEllesmereUI = function() nativeCalls = nativeCalls + 1 end}
local ns = {SettingsFrame = panel}
assert(loadfile(root .. "ManagerBridge.lua"))("InspectForEllesmereUI", ns)

-- Cinematic/UI restoration can deliver OnShow to a still-shown UIParent child.
for _ = 1, 5 do UIParent:Hide(); UIParent:Show() end
assert(#calls == 0 and selected == "QFXBeggar", "Ancestor visibility must not open the manager or select Inspect")
panel:Hide(); panel:Show()
assert(#calls == 0, "An orphan canvas OnShow is not a settings request")
SettingsPanel:Show()
panel:Hide(); panel:Show()
assert(#calls == 0, "An unrelated visible settings window must not authorize an orphan canvas")

-- Blizzard parents the selected category canvas before showing it.
panel:Hide(); panel:SetParent(canvas); panel:Show()
assert(#calls == 1 and not panel:IsShown(), "Explicit native settings category must route and hide its proxy")
UIParent:Hide(); UIParent:Show()
assert(#calls == 1, "Restoring the UI after routing must not reopen the proxy")
SettingsPanel:Hide(); panel:Show()
assert(#calls == 1, "Hidden native settings must not authorize routing")
UIParent:Hide(); SettingsPanel:Show()
assert(#calls == 1, "An IsShown settings window under a hidden ancestor is not visible")
panel:Hide(); SettingsPanel:Hide(); UIParent:Show()

-- Legacy settings and explicit slash/public entries keep working.
local legacyCanvas = Frame(InterfaceOptionsFrame)
panel:SetParent(legacyCanvas); InterfaceOptionsFrame:Show(); panel:Show()
assert(#calls == 2 and not panel:IsShown(), "Legacy native settings category must still route")
InterfaceOptionsFrame:Hide()
SlashCmdList.InspectForEllesmereUI("")
assert(#calls == 3 and nativeCalls == 0, "Manual slash entry must route without a native settings window")
assert(ns.TryOpenManager("gear") and calls[4].key == "gear", "Public settings tab request must be preserved")
QFXAddonManagerAPI = nil
assert(not ns.TryOpenManager())
SlashCmdList.InspectForEllesmereUI("")
assert(nativeCalls == 1, "Standalone slash fallback must remain")
InterfaceOptionsFrame:Show(); panel:Show()
assert(panel:IsShown() and #calls == 4, "Standalone canvas must stay available without the manager")
assert(ns.GetSettingsDefinition() == ns.GetSettingsDefinition(), "Settings definition caching must remain")
print("PASS: " .. GetLocale() .. " Inspect ancestor/orphan OnShow isolation, native settings ancestry/visibility, slash/public entries and standalone fallback")
