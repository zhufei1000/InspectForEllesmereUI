
-------------------------------------
-- 顯示天賦信息
-- @DepandsOn: InspectUnit.lua
-------------------------------------

local addon, ns = ...

local GetSpecializationAPI = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
local GetSpecializationInfoAPI = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo

hooksecurefunc("ShowInspectItemListFrame", function(unit, parent, itemLevel, maxLevel)
    local frame = parent.inspectFrame
    if (not frame) then return end
    if (not frame.specicon) then
        frame.specicon = frame:CreateTexture(nil, "BORDER")
        frame.specicon:SetSize(42, 42)
        --右上角讓位給關閉鍵
        frame.specicon:SetPoint("TOPRIGHT", -26, -6)
        frame.specicon:SetAlpha(0.4)
        frame.specicon:SetMask("Interface\\Minimap\\UI-Minimap-Background")
        frame.spectext = frame:CreateFontString(nil, "BORDER")
        frame.spectext:SetFont(SystemFont_Outline_Small:GetFont(), 10, "THINOUTLINE")
        frame.spectext:SetPoint("BOTTOM", frame.specicon, "BOTTOM")
        frame.spectext:SetJustifyH("CENTER")
        frame.spectext:SetAlpha(0.5)
        ns.Skin.Font(frame.spectext, "sidebarSmall")
        --EUI 皮膚化會淡出窗口貼圖，皮膚後恢復天賦圖標
        frame.InspectForEllesmereUIAfterSkin = function()
            if (frame.specicon) then
                frame.specicon:SetAlpha(0.4)
            end
        end
    end
    local _, specID, specName, specIcon
    if (unit == "player") then
        specID = GetSpecializationAPI()
        _, specName, _, specIcon = GetSpecializationInfoAPI(specID)
    else
        specID = ns.GetReadableInspectSpecID(unit)
        if specID then
            _, specName, _, specIcon = GetSpecializationInfoByID(specID)
        end
    end
    if (specIcon) then
        frame.spectext:SetText(specName)
        frame.specicon:SetTexture(specIcon)
        frame.specicon:Show()
    else
        frame.spectext:SetText("")
        frame.specicon:Hide()
    end
end)
