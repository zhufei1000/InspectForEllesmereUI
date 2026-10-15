
-------------------------------------
-- 查看装备等级
-------------------------------------

local addon, ns = ...

local LibEvent = LibStub:GetLibrary("LibEvent.7000")
local LibItemInfo = LibStub:GetLibrary("LibItemInfo.7000")
local GetItemUpgradeInfoAPI = C_Item.GetItemUpgradeInfo
local GetItemInfoAPI = C_Item.GetItemInfo
local GetItemSetInfoAPI = C_Item.GetItemSetInfo
local GetLootJournalItemSetItemsAPI = C_LootJournal.GetItemSetItems
local GetItemQualityColorAPI = C_Item and C_Item.GetItemQualityColor or GetItemQualityColor
local L = ns.L or {}

--bliz func
--裝備清單
local slots_retail = {
    { index = 1, name = HEADSLOT, },
    { index = 2, name = NECKSLOT, },
    { index = 3, name = SHOULDERSLOT, },
    { index = 5, name = CHESTSLOT, },
    { index = 6, name = WAISTSLOT, },
    { index = 7, name = LEGSSLOT, },
    { index = 8, name = FEETSLOT, },
    { index = 9, name = WRISTSLOT, },
    { index = 10, name = HANDSSLOT, },
    { index = 11, name = FINGER0SLOT, },
    { index = 12, name = FINGER1SLOT, },
    { index = 13, name = TRINKET0SLOT, },
    { index = 14, name = TRINKET1SLOT, },
    { index = 15, name = BACKSLOT, },
    { index = 16, name = MAINHANDSLOT, },
    { index = 17, name = SECONDARYHANDSLOT, },

}

local slots_wotlk = {
    { index = 1, name = HEADSLOT, },
    { index = 2, name = NECKSLOT, },
    { index = 3, name = SHOULDERSLOT, },
    { index = 5, name = CHESTSLOT, },
    { index = 6, name = WAISTSLOT, },
    { index = 7, name = LEGSSLOT, },
    { index = 8, name = FEETSLOT, },
    { index = 9, name = WRISTSLOT, },
    { index = 10, name = HANDSSLOT, },
    { index = 11, name = FINGER0SLOT, },
    { index = 12, name = FINGER1SLOT, },
    { index = 13, name = TRINKET0SLOT, },
    { index = 14, name = TRINKET1SLOT, },
    { index = 15, name = BACKSLOT, },
    { index = 16, name = MAINHANDSLOT, },
    { index = 17, name = SECONDARYHANDSLOT, },
    { index = 18, name = RANGEDSLOT, },
    { index = 4, name = SHIRTSLOT, },
    { index = 19, name = TABARDSLOT, },
}

local slots_classic = {
    { index = 1, name = HEADSLOT, },
    { index = 2, name = NECKSLOT, },
    { index = 3, name = SHOULDERSLOT, },
    { index = 5, name = CHESTSLOT, },
    { index = 6, name = WAISTSLOT, },
    { index = 7, name = LEGSSLOT, },
    { index = 8, name = FEETSLOT, },
    { index = 9, name = WRISTSLOT, },
    { index = 10, name = HANDSSLOT, },
    { index = 11, name = FINGER0SLOT, },
    { index = 12, name = FINGER1SLOT, },
    { index = 13, name = TRINKET0SLOT, },
    { index = 14, name = TRINKET1SLOT, },
    { index = 15, name = BACKSLOT, },
    { index = 16, name = MAINHANDSLOT, },
    { index = 17, name = SECONDARYHANDSLOT, },
    { index = 18, name = RANGEDSLOT, },
}

local slots = slots_retail
if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
    slots = slots_wotlk
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    slots = slots_classic
end

local UPGRADE_TEXT_COLOR = "ffffd200"

local function ColorizeUpgradeText(text)
    if (not text) then
        return ""
    end

    return format("|c%s%s|r", UPGRADE_TEXT_COLOR, text)
end

local function FormatInspectItemText(link, name)
    if (issecretvalue and issecretvalue(link)) then return name or "" end
    if (not link or not InspectForEllesmereUIDB or not InspectForEllesmereUIDB.ShowUpgradeInfo) then
        return link or name or ""
    end

    local crafting = C_TradeSkillUI
    local crafted = crafting and crafting.GetItemCraftedQualityInfo and crafting.GetItemCraftedQualityInfo(link)
    local craftedQuality = crafted and crafted.quality
    if (not craftedQuality and crafting and crafting.GetItemCraftedQualityByItemInfo) then
        craftedQuality = crafting.GetItemCraftedQualityByItemInfo(link)
    end
    if (issecretvalue and issecretvalue(craftedQuality)) then craftedQuality = nil end
    if (type(craftedQuality) == "number" and craftedQuality > 0 and craftedQuality <= 5) then
        local atlas = crafted and (crafted.iconChat or crafted.iconSmall or crafted.icon)
            or ("Professions-ChatIcon-Quality-Tier" .. craftedQuality)
        local qualityIcon = format("|A:%s:14:14|a", atlas)
        local displayLink = link:gsub("|A:Professions%-ChatIcon%-Quality%-Tier%d+:[^|]*|a", "")
        return format("%s %s", ColorizeUpgradeText(format("[%s %s]", L.CraftedEquipment or "Crafted", qualityIcon)), displayLink)
    end

    local info = GetItemUpgradeInfoAPI and GetItemUpgradeInfoAPI(link)
    if (not info or not info.trackString or info.trackString == "") then
        return format("%s %s", ColorizeUpgradeText(format("[%s]", L.NoUpgradeTrack or "No upgrade track")), link)
    end
    if (info.currentLevel ~= nil and info.maxLevel ~= nil) then
        return format("%s %s", ColorizeUpgradeText(format("[%s %d/%d]", info.trackString, info.currentLevel, info.maxLevel)), link)
    end

    return format("%s %s", ColorizeUpgradeText(format("[%s]", info.trackString)), link)
end

local function SafeGetItemSetID(link)
    if (not link) then return end
    local info = { pcall(GetItemInfoAPI, link) }
    local setID = info[17]
    if (info[1] and type(setID) == "number" and setID > 0) then
        return setID
    end
end

local function SafeGetItemSetName(setID)
    if (not setID) then return end
    local ok, name = pcall(GetItemSetInfoAPI, setID)
    if (ok and type(name) == "string" and name ~= "") then
        return name
    end
end

local function GetItemSetMaxPieces(setID, equippedCount)
    local maxPieces = equippedCount or 0
    if (not setID) then
        return maxPieces
    end

    local ok, items = pcall(GetLootJournalItemSetItemsAPI, setID)
    if (not ok or type(items) ~= "table") then
        return maxPieces
    end

    local invTypes, invTypeCount = {}, 0
    for _, item in ipairs(items) do
        local invType = item and item.invType
        if (invType and not invTypes[invType]) then
            invTypes[invType] = true
            invTypeCount = invTypeCount + 1
        end
    end

    return max(maxPieces, invTypeCount)
end

local function GetUnitItemSetSummary(unit, slotCache)
    local sets = {}
    for _, slot in ipairs(slots) do
        local info = slotCache and slotCache[slot.index]
        local level, link = info and info.level, info and info.link
        if (link and level and level > 0) then
            local setID = SafeGetItemSetID(link)
            if (setID) then
                local setInfo = sets[setID]
                if (not setInfo) then
                    setInfo = { id = setID, count = 0 }
                    sets[setID] = setInfo
                end
                setInfo.count = setInfo.count + 1
            end
        end
    end

    local best
    for _, setInfo in pairs(sets) do
        if (not best or setInfo.count > best.count) then
            best = setInfo
        end
    end
    if (not best) then return end

    local name = SafeGetItemSetName(best.id)
    if (not name) then return end

    return name, best.count, GetItemSetMaxPieces(best.id, best.count)
end

--固定數字格沿用側欄字體，避免比例字體的 1/4 寬度差造成整串縮進不一致。
local function EnsureLevelDigit(row, index)
    row.levelDigits = row.levelDigits or {}
    local digit = row.levelDigits[index]
    if (not digit) then
        digit = row:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
        digit:SetHeight(16)
        digit:SetJustifyH("CENTER")
        digit:SetJustifyV("MIDDLE")
        digit:SetWordWrap(false)
        digit:SetTextColor(1, 1, 1)
        ns.Skin.Font(digit, "sidebarBody")
        row.levelDigits[index] = digit
    end
    return digit
end


--創建面板
local function GetInspectItemListFrame(parent)
    if (not parent.inspectFrame) then
        local itemfont = "ChatFontNormal"
        local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        local height = parent:GetHeight()
        if (height < 424) then
            height = 424
        end
        frame.backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 8,
            edgeSize = 16,
            insets   = {left = 4, right = 4, top = 4, bottom = 4}
        }
        frame:SetSize(160, height)
        frame:SetFrameLevel(0)
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
        if (not ns.Skin.Shell(frame)) then
            frame:SetBackdrop(frame.backdrop)
            frame:SetBackdropColor(0, 0, 0, 0.8)
            frame:SetBackdropBorderColor(0.6, 0.6, 0.6)
        end
        frame.portrait = CreateFrame("Frame", nil, frame, "GarrisonFollowerPortraitTemplate")
        frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
        frame.portrait:SetScale(0.8)
        frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -18)
        frame.setSummary = frame:CreateFontString(nil, "ARTWORK", itemfont)
        frame.setSummary:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -42)
        frame.setSummary:SetFont(frame.setSummary:GetFont(), 14, "THINOUTLINE")
        frame.setSummary:SetTextColor(1, 0.82, 0)
        ns.Skin.Font(frame.title, "sidebarTitle")
        ns.Skin.Font(frame.setSummary, "sidebarBody")

        local itemframe
        local fontsize = GetLocale():sub(1,2) == "zh" and 12 or 9
        local backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile     = true,
            tileSize = 8,
            edgeSize = 1,
            insets   = {left = 1, right = 1, top = 1, bottom = 1}
        }
        --偶數個實體像素的行距，避免相鄰行的中心交替落在半像素上。
        local rowHeight = ns.Skin.Pixel(min((height-82)/#slots,28) / 2, frame, "floor") * 2
        for i, v in ipairs(slots) do
            itemframe = CreateFrame("Button", nil, frame, "BackdropTemplate")
            itemframe:SetSize(120, rowHeight)
            itemframe.index = v.index
            itemframe.backdrop = backdrop
            if (i == 1) then
                itemframe:SetPoint("TOPLEFT", frame, "TOPLEFT", ns.Skin.Pixel(15, frame), -ns.Skin.Pixel(70, frame))
            else
                itemframe:SetPoint("TOPLEFT", frame["item"..(i-1)], "BOTTOMLEFT")
            end
            itemframe.label = CreateFrame("Frame", nil, itemframe, "BackdropTemplate")
            itemframe.label:SetSize(38, 16)
            itemframe.label:SetPoint("LEFT")
            itemframe.label:SetBackdrop(backdrop)
            itemframe.label:SetBackdropBorderColor(0, 0.9, 0.9, 0.2)
            itemframe.label:SetBackdropColor(0, 0.9, 0.9, 0.2)
            itemframe.label.text = itemframe.label:CreateFontString(nil, "ARTWORK")
            itemframe.label.text:SetFont(UNIT_NAME_FONT, fontsize, "THINOUTLINE")
            itemframe.label.text:SetSize(34, 16)
            itemframe.label.text:SetPoint("CENTER", 0, 0)
            itemframe.label.text:SetJustifyV("MIDDLE")
            itemframe.label.text:SetText(v.name)
            itemframe.label.text:SetTextColor(0, 0.9, 0.9)
            itemframe.levelString = itemframe:CreateFontString(nil, "ARTWORK", itemfont)
            itemframe.levelString:SetPoint("LEFT", itemframe.label, "RIGHT", 4, 0)
            itemframe.levelString:SetJustifyH("RIGHT")
            itemframe.levelString:SetHeight(16)
            itemframe.levelString:SetJustifyV("MIDDLE")
            --保留完整數字文字作為資料與測量來源，顯示由固定數字格負責。
            itemframe.levelString:SetAlpha(0)
            for digitIndex = 1, 3 do EnsureLevelDigit(itemframe, digitIndex) end
            itemframe.badgeString = itemframe:CreateFontString(nil, "ARTWORK", itemfont)
            itemframe.badgeString:SetHeight(16)
            itemframe.badgeString:SetJustifyH("LEFT")
            itemframe.badgeString:SetJustifyV("MIDDLE")
            itemframe.badgeString:SetWordWrap(false)
            itemframe.itemString = itemframe:CreateFontString(nil, "ARTWORK", itemfont)
            itemframe.itemString:SetHeight(16)
            itemframe.itemString:SetWordWrap(false)
            itemframe.itemString:SetJustifyH("LEFT")
            itemframe.itemString:SetJustifyV("MIDDLE")
            itemframe.itemString:SetPoint("LEFT", itemframe.levelString, "RIGHT", 2, 0)
            ns.Skin.Font(itemframe.label.text, "sidebarBody")
            ns.Skin.Font(itemframe.levelString, "sidebarBody")
            ns.Skin.Font(itemframe.badgeString, "sidebarBody")
            ns.Skin.Font(itemframe.itemString, "sidebarBody")
            itemframe:SetScript("OnEnter", function(self)
                local r, g, b, a = self.label:GetBackdropColor()
                if (a) then self.label:SetBackdropColor(r, g, b, a+0.5) end
                if (self.link or (self.level and self.level > 0)) then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetInventoryItem(self:GetParent().unit, self.index)
                    GameTooltip:Show()
                end
            end)
            itemframe:SetScript("OnLeave", function(self)
                local r, g, b, a = self.label:GetBackdropColor()
                if (a) then self.label:SetBackdropColor(r, g, b, abs(a-0.5)) end
                GameTooltip:Hide()
            end)
            itemframe:SetScript("OnDoubleClick", function(self)
                if (self.link) then
                    ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
                    ChatEdit_InsertLink(self.link)
                end
            end)
            frame["item"..i] = itemframe
            LibEvent:trigger("INSPECT_ITEMFRAME_CREATED", itemframe)
        end
        
        frame.closeButton = CreateFrame("Button", nil, frame)
        frame.closeButton:SetSize(12, 12)
        frame.closeButton:SetScale(0.85)
        --EUI 風格：關閉鍵固定在右上角（層級高於 EUI 外框貼圖）
        frame.closeButton:SetFrameLevel(frame:GetFrameLevel() + 8)
        frame.closeButton:SetPoint("TOPRIGHT", -6, -6)
        frame.closeButton:SetNormalTexture("Interface\\Cursor\\Item")
        frame.closeButton:GetNormalTexture():SetTexCoord(0, 12/32, 12/32, 0)
        frame.closeButton:SetScript("OnClick", function(self)
            self:GetParent():Hide()
        end)
        ns.Skin.CloseButton(frame.closeButton)

        parent:HookScript("OnHide", function(self) frame:Hide() end)
        parent.inspectFrame = frame
        LibEvent:trigger("INSPECT_FRAME_CREATED", frame, parent)
    end

    return parent.inspectFrame
end

--顯示面板
function ShowInspectItemListFrame(unit, parent, ilevel, maxLevel)
    if (not parent:IsShown()) then return end
    local frame = GetInspectItemListFrame(parent)
    --同目标重复构建时宽度只增不减：徽章/名称/宝石分批到达，重算会忽宽忽窄
    local sameView = frame:IsShown() and frame.unit == unit
    local class = select(2, UnitClass(unit))
    if issecretvalue and issecretvalue(class) then class = nil end
    local color = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR
    frame.unit = unit
    local recommendations = ns.Recommendations
    frame.recommendationData = recommendations and recommendations:SidebarData(unit) or nil
    frame.portrait:SetLevel(UnitLevel(unit))
    frame.portrait.PortraitRingQuality:SetVertexColor(color.r, color.g, color.b)
    frame.portrait.LevelBorder:SetVertexColor(color.r, color.g, color.b)
    SetPortraitTexture(frame.portrait.Portrait, unit)
    frame.title:SetText(UnitName(unit) or "")
    frame.title:SetTextColor(color.r, color.g, color.b)
    frame.setSummary:SetText("")
    frame.setSummary:Hide()
    local _, name, level, link, quality
    local itemframe, mframe, oframe
    local width = max(160, floor(frame.title:GetStringWidth()) + 70)
    --槽位数据缓存（面板复用、观察新人时覆盖，天然有界）
    frame.slotCache = frame.slotCache or {}
    for i, v in ipairs(slots) do
        _, level, name, link, quality = LibItemInfo:GetUnitItemInfo(unit, v.index)
        --保留裝備實例的完整寶石/製作品質資料，不依賴 GetItemInfo 返回的展示連結。
        link = GetInventoryItemLink(unit, v.index) or link
        frame.slotCache[v.index] = { level = level, name = name, link = link, quality = quality }
        itemframe = frame["item"..i]
        itemframe.name = name
        itemframe.link = link
        itemframe.level = level
        itemframe.quality = quality
        itemframe.itemString:SetWidth(0)
        itemframe.badgeString:SetWidth(0)
        itemframe.badgeString:SetText("")
        itemframe.badgeRanked = nil
        if (level > 0) then
            itemframe.levelString:SetText(format("%d", floor(level)))
            local text = FormatInspectItemText(link, name)
            local slotData = frame.recommendationData and frame.recommendationData.gearSlots[v.index]
            if (recommendations) then
                local badge, ranked = recommendations:GearBadge(slotData, link)
                if (badge) then
                    itemframe.badgeString:SetText("[" .. badge .. "]")
                    itemframe.badgeRanked = ranked
                    if (ranked) then
                        itemframe.badgeString:SetTextColor(0.25, 1, 0.35)
                    else
                        itemframe.badgeString:SetTextColor(0.55, 0.55, 0.55)
                    end
                end
            end
            itemframe.itemString:SetText(ns.Skin.InlineQualityIcons(text, 11))
        else
            itemframe.levelString:SetText("")
            itemframe.itemString:SetText("")
        end
        itemframe.levelString:SetTextColor(1, 1, 1)
        if (v.index == 16) then
            mframe = itemframe
            mframe:SetAlpha(1)
        elseif (v.index == 17) then
            oframe = itemframe
            oframe:SetAlpha(1)
        end
        LibEvent:trigger("INSPECT_ITEMFRAME_UPDATED", itemframe)
    end
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowInspectItemSetSummary) then
        local setName, equippedCount, maxPieces = GetUnitItemSetSummary(unit, frame.slotCache)
        if (setName and equippedCount and maxPieces and maxPieces > 0) then
            frame.setSummary:SetText(format("%s (%d/%d)", setName, equippedCount, maxPieces))
            frame.setSummary:Show()
            width = max(width, floor(frame.setSummary:GetStringWidth()) + 70)
        end
    end
    if (mframe and oframe and (mframe.quality == 6 or oframe.quality == 6)) then
        level = max(mframe.level, oframe.level)
        if mframe.link then
            mframe.levelString:SetText(format("%d", floor(level)))
        end
        if oframe.link then
            oframe.levelString:SetText(format("%d", floor(level)))
        end
    end
    if (mframe and mframe.level <= 0) then
        mframe:SetAlpha(0.4)
    end
    if (oframe and oframe.level <= 0) then
        oframe.link = nil
        oframe:SetAlpha(0.4)
    end
    --數字、推薦標記與名稱各自有統一起點，名稱尾部仍按自身寬度緊湊排列。
    local labelWidth, badgeWidth, digitCount = 0, 0, 3
    for i in ipairs(slots) do
        local row = frame["item"..i]
        labelWidth = max(labelWidth, row.label:GetWidth())
        badgeWidth = max(badgeWidth, row.badgeString:GetStringWidth())
        digitCount = max(digitCount, #(row.levelString:GetText() or ""))
    end
    local measure = EnsureLevelDigit(frame.item1, 1)
    measure:SetWidth(0)
    local digitWidth, digitAdvance = 0, 0
    for digit = 0, 9 do
        measure:SetText(tostring(digit))
        digitWidth = max(digitWidth, measure:GetStringWidth())
        --連續數字平均寬度排除單一字串邊界留白，保留正常數字的緊湊字距。
        measure:SetText(string.rep(tostring(digit), 10))
        digitAdvance = max(digitAdvance, measure:GetStringWidth() / 10)
    end
    digitAdvance = ns.Skin.Pixel(digitAdvance, frame, "ceil")
    digitWidth = ns.Skin.Pixel(max(digitWidth, digitAdvance), frame, "ceil")
    local levelWidth = digitWidth + digitAdvance * (digitCount - 1)
    badgeWidth = ns.Skin.Pixel(badgeWidth, frame, "ceil")
    local levelX = ns.Skin.Pixel(labelWidth + 4, frame)
    local badgeX = ns.Skin.Pixel(levelX + levelWidth + 3, frame)
    local nameX = ns.Skin.Pixel(badgeX + badgeWidth + (badgeWidth > 0 and 4 or 0), frame)
    for i in ipairs(slots) do
        local row = frame["item"..i]
        local nameWidth = ns.Skin.Pixel(min(260, row.itemString:GetStringWidth()), frame, "ceil")
        row.levelString:SetWidth(levelWidth)
        row.levelString:ClearAllPoints()
        row.levelString:SetPoint("LEFT", row, "LEFT", levelX, 0)
        local text = row.levelString:GetText() or ""
        text = string.rep(" ", digitCount - #text) .. text
        for digitIndex = 1, digitCount do
            local digit = EnsureLevelDigit(row, digitIndex)
            local character = text:sub(digitIndex, digitIndex)
            digit:SetText(character == " " and "" or character)
            digit:SetWidth(digitWidth)
            digit:ClearAllPoints()
            digit:SetPoint("LEFT", row, "LEFT", levelX + (digitIndex - 1) * digitAdvance, 0)
            digit:Show()
        end
        for digitIndex = digitCount + 1, #row.levelDigits do row.levelDigits[digitIndex]:Hide() end
        row.badgeString:SetWidth(badgeWidth)
        row.badgeString:ClearAllPoints()
        row.badgeString:SetPoint("LEFT", row, "LEFT", badgeX, 0)
        row.itemString:SetWidth(nameWidth)
        row.itemString:ClearAllPoints()
        row.itemString:SetPoint("LEFT", row, "LEFT", nameX, 0)
        row.width = nameX + nameWidth
        row:SetWidth(row.width)
        width = max(width, row.width)
    end
    local newWidth = width + 36
    if (sameView) then
        newWidth = max(newWidth, frame:GetWidth())
    end
    frame:SetWidth(newWidth)
    frame:Show()

    LibEvent:trigger("INSPECT_FRAME_SHOWN", frame, parent, ilevel)
    if (not ns.Skin.IsEnabled()) then
        frame:SetBackdrop(frame.backdrop)
        frame:SetBackdropColor(0, 0, 0, 0.9)
        frame:SetBackdropBorderColor(color.r, color.g, color.b)
    end

    return frame
end


--裝備變更時
LibEvent:attachEvent("UNIT_INVENTORY_CHANGED", function(self, unit)
    if (InspectFrame and InspectFrame.unit and InspectFrame.unit == unit) then
        ReInspect(unit)
    end
end)

--@see InspectCore.lua 
LibEvent:attachTrigger("UNIT_INSPECT_READY, UNIT_REINSPECT_READY", function(self, data)
    if (InspectForEllesmereUIDB and not InspectForEllesmereUIDB.ShowInspectItemSheet) then return end
    if (InspectFrame and InspectFrame.unit and UnitGUID(InspectFrame.unit) == data.guid) then
        local frame = ShowInspectItemListFrame(InspectFrame.unit, InspectFrame, data.ilevel, data.maxLevel)
        LibEvent:trigger("INSPECT_FRAME_COMPARE", frame)
    end
end)

--設置邊框
LibEvent:attachTrigger("INSPECT_FRAME_SHOWN", function(self, frame, parent, ilevel)
    if (ns.Skin.IsEnabled()) then
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
        return
    end
    local backdrop = frame:GetBackdrop() or {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 8,
            edgeSize = 16,
            insets   = {left = 4, right = 4, top = 4, bottom = 4}
          }
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowInspectAngularBorder) then
        backdrop.edgeSize = 1
        backdrop.edgeFile = "Interface\\Buttons\\WHITE8X8"
        backdrop.insets.top = 1
        backdrop.insets.left = 1
        backdrop.insets.right = 1
        backdrop.insets.bottom = 1
        frame.backdrop = backdrop
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)
    else
        backdrop.edgeSize = 16
        backdrop.edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
        backdrop.insets.top = 4
        backdrop.insets.left = 4
        backdrop.insets.right = 4
        backdrop.insets.bottom = 4
        frame.backdrop = backdrop
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
end)

--高亮橙裝和武器
LibEvent:attachTrigger("INSPECT_ITEMFRAME_UPDATED", function(self, itemframe)
    local r, g, b = 0, 0.9, 0.9
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowInspectColoredLabel) then
        if (itemframe.quality and itemframe.quality > 4) then
            r, g, b = GetItemQualityColorAPI(itemframe.quality)
        elseif (itemframe.name and not itemframe.link) then
            r, g, b = 0.9, 0.8, 0.4
        elseif (not itemframe.link) then
            r, g, b = 0.5, 0.5, 0.5
        end
    end
    itemframe.label:SetBackdropBorderColor(r, g, b, 0.2)
    itemframe.label:SetBackdropColor(r, g, b, 0.2)
    itemframe.label.text:SetTextColor(r, g, b)
end)

--自己裝備列表
LibEvent:attachTrigger("INSPECT_FRAME_COMPARE", function(self, frame)
    if (not frame) then return end
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowOwnFrameWhenInspecting) then
        local _, ilevel, _, _, _, maxLevel = LibItemInfo:GetUnitItemLevel("player")
        local playerFrame = ShowInspectItemListFrame("player", frame, ilevel, maxLevel)
        if (frame.statsFrame) then
            frame.statsFrame:SetParent(playerFrame)
        end
    elseif (frame.statsFrame) then
        frame.statsFrame:SetParent(frame)
    end
    if (frame.statsFrame) then
        frame.statsFrame:SetPoint("TOPLEFT", frame.statsFrame:GetParent(), "TOPRIGHT", 1, -1)
    end
end)


----------------
--   Player   --
----------------

PaperDollFrame:HookScript("OnShow", function(self)
    if (InspectForEllesmereUIDB and not InspectForEllesmereUIDB.ShowCharacterItemSheet) then return end
    local _, ilevel, _, _, _, maxLevel = LibItemInfo:GetUnitItemLevel("player")
    ShowInspectItemListFrame("player", self, ilevel, maxLevel)
end)

LibEvent:attachEvent("PLAYER_EQUIPMENT_CHANGED", function(self)
    if (CharacterFrame:IsShown() and InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowCharacterItemSheet) then
        local _, ilevel, _, _, _, maxLevel = LibItemInfo:GetUnitItemLevel("player")
        ShowInspectItemListFrame("player", PaperDollFrame, ilevel, maxLevel)
    end
end)
