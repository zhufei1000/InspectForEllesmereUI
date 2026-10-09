
-------------------------------------
-- EllesmereUI 皮膚適配（可選依賴）
-- 安裝並啟用 EllesmereUI 時，觀察面板/屬性面板/選項分框
-- 自動套用 EUI 主題；未安裝時保持原有外觀，功能不變。
-- 依 EllesmereUI 公開接口 SKINNING_API.md 接入
-------------------------------------

local addon, ns = ...

local Skin = {}
ns.Skin = Skin

local shells       = setmetatable({}, {__mode = "k"})
local panels       = setmetatable({}, {__mode = "k"})
local closeButtons = setmetatable({}, {__mode = "k"})
local fonts        = setmetatable({}, {__mode = "k"})
local buttons      = setmetatable({}, {__mode = "k"})
local icons        = setmetatable({}, {__mode = "k"})
local gemIcons     = setmetatable({}, {__mode = "k"})

function Skin.Button(button)
    if (not button) then return end
    buttons[button] = true
    if (Skin.S and type(Skin.S.Button) == "function") then Skin.S.Button(button) end
end

--圖標：方形裁切 + 1px 邊框（EUI 風格）
function Skin.SquareIcon(icon, parent)
    if (not icon) then return end
    icons[icon] = parent
    if (Skin.S and type(Skin.S.SquareIcon) == "function") then Skin.S.SquareIcon(icon, parent) end
end

--使用 EUI 角色欄同一個像素邊框 API；寶石框仍由本插件持有。
function Skin.GemIcon(button, quality)
    if (not button) then return end
    quality = quality or 0
    gemIcons[button] = quality
    local r, g, b = 0.75, 0.75, 0.75
    if (quality >= 3) then r, g, b = 1, 0.82, 0 end
    local pp = Skin.S and EllesmereUI and EllesmereUI.PanelPP
    if (pp and pp.CreateBorder and pp.SetBorderColor) then
        button:SetBackdrop(nil)
        button.texture:ClearAllPoints()
        button.texture:SetAllPoints(button)
        pp.CreateBorder(button, r, g, b, 1, 2, "OVERLAY", 1)
        pp.SetBorderColor(button, r, g, b, 1)
    else
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1,
            insets = {left = 1, right = 1, top = 1, bottom = 1},
        })
        button:SetBackdropColor(0.08, 0.08, 0.08, 1)
        button:SetBackdropBorderColor(r, g, b, 1)
    end
    button.texture:SetAlpha(1)
end

--主題是否已生效（EUI 未安裝或未啟用時為 false）
function Skin.IsEnabled()
    return Skin.S ~= nil
end

--側欄自身縮放使用世界 UI 的像素單位，不套用 EUI 選項面板的縮放。
function Skin.Pixel(value, frame, rounding)
    local pp = Skin.S and EllesmereUI and EllesmereUI.PP
    if (pp and pp.SnapForES and frame and frame.GetEffectiveScale) then
        local scale = frame:GetEffectiveScale()
        if (rounding and pp.perfect and scale > 0) then
            local pixel = pp.perfect / scale
            local round = rounding == "ceil" and math.ceil or math.floor
            return round(value / pixel) * pixel
        end
        return pp.SnapForES(value, scale)
    end
    if (rounding == "ceil") then return math.ceil(value) end
    if (rounding == "floor") then return math.floor(value) end
    return math.floor(value + 0.5)
end

function Skin.InlineQualityIcons(text, size)
    if (Skin.S and type(text) == "string") then
        text = text:gsub("(|A:Professions%-ChatIcon%-Quality%-Tier%d+:)%d+:%d+", function(prefix)
            return prefix .. size .. ":" .. size
        end)
    end
    return text
end

--主窗口：EUI 主題背景、邊框、標題欄
function Skin.Shell(frame, opts)
    if (not frame) then return false end
    shells[frame] = opts or false
    if (not Skin.S) then return false end
    if (frame.SetBackdrop) then frame:SetBackdrop(nil) end
    Skin.S.Shell(frame, opts)
    if (type(frame.InspectForEllesmereUIAfterSkin) == "function") then
        frame.InspectForEllesmereUIAfterSkin()
    end
    return true
end

local function ApplyPanel(frame)
    Skin.S.Inset(frame)
    Skin.S.Panel(frame, {inset = true})
end

--子面板：削掉原生 Inset 外觀，鋪 EUI 內嵌底色
function Skin.Panel(frame)
    if (not frame) then return false end
    panels[frame] = true
    if (not Skin.S) then return false end
    ApplyPanel(frame)
    return true
end

--關閉按鈕：EUI 樣式關閉圖標
function Skin.CloseButton(button)
    if (not button) then return false end
    closeButtons[button] = true
    if (not Skin.S) then return false end
    Skin.S.CloseButton(button)
    return true
end

--側欄字級獨立於聊天字體；未指定角色的文字保留原字號。
local fontSizes = { sidebarTitle = 13, sidebarBody = 11, sidebarSmall = 10 }

local function ApplyFont(fontString, role)
    if (not Skin.S) then return end
    Skin.S.Font(fontString)
    local size = fontSizes[role]
    if (size) then
        local path, _, flags = fontString:GetFont()
        if (path and path ~= "") then
            fontString:SetFont(path, size, flags or "")
        end
    end
end

--字體及描邊跟隨 EUI，側欄可指定統一字級。
function Skin.Font(fontString, role)
    if (not fontString) then return end
    fonts[fontString] = role or true
    ApplyFont(fontString, role)
end

local function ApplyFonts()
    if (not Skin.S) then return end
    for fontString, role in pairs(fonts) do
        ApplyFont(fontString, role)
    end
end

--皮膚就緒（例如會話中途開啟 EUI 皮膚）時補刷已創建窗口
local function ApplyAll()
    if (not Skin.S) then return end
    for frame, opts in pairs(shells) do
        if (frame and not frame:IsForbidden()) then
            Skin.Shell(frame, opts or nil)
        end
    end
    for frame in pairs(panels) do
        if (frame and not frame:IsForbidden()) then
            ApplyPanel(frame)
        end
    end
    for button in pairs(closeButtons) do
        if (button and not button:IsForbidden()) then
            Skin.S.CloseButton(button)
        end
    end
    ApplyFonts()
    if (type(Skin.S.Button) == "function") then
        for button in pairs(buttons) do
            if (not button:IsForbidden()) then Skin.S.Button(button) end
        end
    end
    if (type(Skin.S.SquareIcon) == "function") then
        for icon, parent in pairs(icons) do
            if (icon and not icon:IsForbidden()) then Skin.S.SquareIcon(icon, parent) end
        end
    end
    for button, quality in pairs(gemIcons) do
        if (not button:IsForbidden()) then Skin.GemIcon(button, quality) end
    end
end

if (EllesmereUI and EllesmereUI.RegisterSkin) then
    EllesmereUI.RegisterSkin("Inspect for EllesmereUI", function(S)
        Skin.S = S
        ApplyAll()
        if (type(S.OnLooksChanged) == "function") then
            S.OnLooksChanged(ApplyFonts)
        end
    end)
end
