-------------------------------------
-- 裝備側欄寶石、插槽與附魔顯示
-------------------------------------

local addon, ns = ...
local L = ns.L or {}
local LibItemGem = LibStub:GetLibrary("LibItemGem.7000")
local LibSchedule = LibStub:GetLibrary("LibSchedule.7000")
local LibEvent = LibStub:GetLibrary("LibEvent.7000")
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemIcon = C_Item and C_Item.GetItemIconByID
local RequestItem = C_Item and C_Item.RequestLoadItemDataByID
local panels = setmetatable({}, {__mode = "k"})
local nextPanelID = 0
local ENCHANT_LINE_TYPE = Enum and Enum.TooltipDataLineType
    and (Enum.TooltipDataLineType.ItemEnchantmentPermanent or Enum.TooltipDataLineType.ItemEnchant) or 15
local enchantPattern
if (ENCHANTED_TOOLTIP_LINE) then
    local head, tail = ENCHANTED_TOOLTIP_LINE:match("^(.-)%%s(.*)$")
    if (head) then
        local function EscapePattern(text)
            return text:gsub("([%(%)%.%[%]%^%$%*%+%-%?%%])", "%%%1")
        end
        enchantPattern = "^" .. EscapePattern(head) .. "(.+)" .. EscapePattern(tail) .. "$"
    end
end
local SOCKET_ATLAS = {
    EMPTY_SOCKET_META = "socket-meta", EMPTY_SOCKET_RED = "socket-red",
    EMPTY_SOCKET_YELLOW = "socket-yellow", EMPTY_SOCKET_BLUE = "socket-blue",
    EMPTY_SOCKET_HYDRAULIC = "socket-hydraulic", EMPTY_SOCKET_COGWHEEL = "socket-cogwheel",
    EMPTY_SOCKET_PRISMATIC = "socket-prismatic", EMPTY_SOCKET_DOMINATION = "socket-domination",
    EMPTY_SOCKET_CYPHER = "socket-cypher", EMPTY_SOCKET_PRIMORDIAL = "socket-primordial",
    EMPTY_SOCKET_TINKER = "socket-tinker", EMPTY_SOCKET_PUNCHCARDRED = "socket-punchcardred",
    EMPTY_SOCKET_PUNCHCARDYELLOW = "socket-punchcardyellow", EMPTY_SOCKET_PUNCHCARDBLUE = "socket-punchcardblue",
}

local function ItemID(link)
    return type(link) == "string" and tonumber(link:match("item:(%d+):")) or nil
end

local function ReadEnchant(row, unit, link)
    local id = tonumber(link:match("item:%d+:(%d+)"))
    if (not id or id == 0) then return end
    if (row.enchantLink == link and row.enchantName) then return row.enchantName end
    local text
    if (ns.Skin.IsEnabled() and EllesmereUI and type(EllesmereUI.GetEnchantText) == "function") then
        text = EllesmereUI.GetEnchantText(row.index, unit)
    end
    if (issecretvalue and issecretvalue(text)) then text = nil end
    local data
    if (not text or text == "") then
        data = C_TooltipInfo and C_TooltipInfo.GetInventoryItem and C_TooltipInfo.GetInventoryItem(unit, row.index)
        if (data and TooltipUtil and TooltipUtil.SurfaceArgs) then TooltipUtil.SurfaceArgs(data) end
        for _, line in ipairs(data and data.lines or {}) do
            local raw = line.leftText
            if (not (issecretvalue and (issecretvalue(raw) or issecretvalue(line.type))) and type(raw) == "string") then
                raw = raw:gsub("|cn.-:(.-)|r", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                local matched = enchantPattern and raw:match(enchantPattern)
                if (line.type == ENCHANT_LINE_TYPE or matched) then
                    text = matched or raw
                    if (text ~= "") then break end
                end
            end
        end
    end
    if (issecretvalue and issecretvalue(text)) then text = nil end
    if (type(text) == "string" and text ~= "") then
        text = text:gsub("|cn.-:(.-)|r", "%1"):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        text = (enchantPattern and text:match(enchantPattern)) or text
        row.enchantLink, row.enchantName = link, text
        return text
    end
    return L.EnchantedEquipment or "Enchanted", true, data and data.dataInstanceID
end

local function ShowEnchant(row, anchor, text, link, slotData)
    local recommendations = ns.Recommendations
    local display = row.enchantFrame
    if (not display) then
        display = CreateFrame("Button", nil, row)
        display:SetSize(16, 16)
        display.tex = display:CreateTexture(nil, "ARTWORK")
        display.tex:SetAllPoints(display)
        display.tex:SetAtlas("PetJournal-FavoritesIcon")
        display:SetScript("OnEnter", function(self)
            local r = ns.Recommendations
            if (r and self.enchant) then r:EnchantTooltip(self); return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.currentEnchantText or (L.EnchantedEquipment or "Enchanted"))
            GameTooltip:Show()
        end)
        display:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.enchantFrame = display
    end
    display.itemLink = link
    display.currentEnchantText = text
    display.currentEnchantID = tonumber(link:match("item:%d+:(%d+)"))
    display.enchant = slotData and slotData.enchant
    display.enchantList = slotData and slotData.enchantList
    display.enchantState = recommendations and recommendations:EnchantState(display.enchant, display.currentEnchantID) or "unknown"
    if (recommendations) then
        display.tex:SetVertexColor(recommendations:EnchantColor(display.enchantState))
    else
        display.tex:SetVertexColor(1, 0.85, 0.2)
    end
    display:ClearAllPoints()
    display:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
    display:Show()
    return 20
end

local function CreateIcon(frame, index)
    local icon = CreateFrame("Button", nil, frame, "BackdropTemplate")
    icon:SetSize(16, 16)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetPoint("TOPLEFT", 1, -1)
    icon.texture:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if (self.itemLink) then
            GameTooltip:SetHyperlink(self.itemLink)
        else
            GameTooltip:SetText(self.title or EMPTY)
        end
        GameTooltip:Show()
    end)
    icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    icon:SetScript("OnDoubleClick", function(self)
        if (self.itemLink) then
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_InsertLink(self.itemLink)
        end
    end)
    frame["xicon" .. index] = icon
    return icon
end

local function HideIcons(frame)
    local rowIndex = 1
    while (frame["item" .. rowIndex]) do
        local row = frame["item" .. rowIndex]
        if (row.enchantFrame) then
            row.enchantFrame.itemLink = nil
            row.enchantFrame.currentEnchantText = nil
            row.enchantFrame.enchant, row.enchantFrame.enchantList, row.enchantFrame.enchantState = nil, nil, nil
            row.enchantFrame:Hide()
        end
        rowIndex = rowIndex + 1
    end
    local index = 1
    while (frame["xicon" .. index]) do
        local icon = frame["xicon" .. index]
        icon.itemLink, icon.title = nil, nil
        icon:Hide()
        index = index + 1
    end
end

local function RefreshGems(frame, settled)
    if (InCombatLockdown()) then return false end
    HideIcons(frame)
    if (not InspectForEllesmereUIDB or not InspectForEllesmereUIDB.ShowGemAndEnchant) then return false end
    local width = frame.gemBaseWidth or frame:GetWidth()
    local iconIndex, rowIndex, pending = 0, 1, false
    frame.gemWaitItems = {}
    frame.enchantWaitTooltips = {}
    while (frame["item" .. rowIndex]) do
        local row = frame["item" .. rowIndex]
        --重讀原始裝備連結，讓 /reload 後補齊的寶石資料能進入側欄。
        local link = GetInventoryItemLink(frame.unit, row.index)
        if (not (issecretvalue and issecretvalue(link)) and link) then
            local equipmentID = ItemID(link)
            if (equipmentID) then frame.gemWaitItems[equipmentID] = true end
            local count, info, _, loading = LibItemGem:GetItemGemInfo(link)
            pending = pending or loading
            if (loading and RequestItem and equipmentID and not frame.gemRequestedItems[equipmentID]) then
                frame.gemRequestedItems[equipmentID] = true
                RequestItem(equipmentID)
            end
            local anchor = row.itemString
            for i, gem in ipairs(info) do
                iconIndex = iconIndex + 1
                local icon = frame["xicon" .. iconIndex] or CreateIcon(frame, iconIndex)
                local data = gem.link or gem.itemID
                local quality, texture
                icon.texture:SetAtlas(nil)
                if (data) then
                    local _, _, rarity, _, _, _, _, _, _, art = GetItemInfo(data)
                    quality = rarity
                    texture = art or (GetItemIcon and GetItemIcon(data))
                    local gemID = gem.itemID or ItemID(gem.link)
                    if (gemID) then frame.gemWaitItems[gemID] = true end
                    if (not art or not gem.link) then
                        pending = true
                        if (RequestItem and gemID and not frame.gemRequestedItems[gemID]) then
                            frame.gemRequestedItems[gemID] = true
                            RequestItem(gemID)
                        end
                    end
                    icon.itemLink = gem.link or (gemID and ("item:" .. gemID))
                    icon.title = gem.name
                    icon.texture:SetTexture(texture or 134400)
                    icon.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                else
                    --暫時沒有寶石連結不能直接斷言空槽；短時間重讀後再顯示空槽提示。
                    pending = pending or not settled
                    icon.title = settled and gem.name or (L.LoadingGemInfo or "Loading gem information…")
                    icon.texture:SetTexture(nil)
                    icon.texture:SetAtlas(SOCKET_ATLAS[gem.socket] or "socket-prismatic")
                    icon.texture:SetTexCoord(0, 1, 0, 1)
                    if (RequestItem and equipmentID and not frame.gemRequestedItems[equipmentID]) then
                        frame.gemRequestedItems[equipmentID] = true
                        RequestItem(equipmentID)
                    end
                end
                ns.Skin.GemIcon(icon, quality)
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", anchor, "RIGHT", i == 1 and 4 or 2, 0)
                icon:Show()
                anchor = icon
            end
            local enchant, enchantLoading, tooltipID = ReadEnchant(row, frame.unit, link)
            local iconWidth = count > 0 and (4 + count * 16 + (count - 1) * 2) or 0
            local slotData = frame.recommendationData and frame.recommendationData.gearSlots[row.index]
            if (enchant or (slotData and slotData.enchant)) then
                iconWidth = iconWidth + ShowEnchant(row, anchor, enchant, link, slotData)
            end
            width = math.max(width, row.width + iconWidth + 36)
            pending = pending or enchantLoading
            if (not (issecretvalue and issecretvalue(tooltipID)) and tooltipID) then
                frame.enchantWaitTooltips[tooltipID] = true
            end
            if (enchantLoading and RequestItem and equipmentID and not frame.gemRequestedItems[equipmentID]) then
                frame.gemRequestedItems[equipmentID] = true
                RequestItem(equipmentID)
            end
        elseif (row.link and not settled) then
            pending = true
        end
        rowIndex = rowIndex + 1
    end
    frame:SetWidth(width)
    return pending
end

local function QueueRefresh(frame)
    if (not frame:IsShown() or InCombatLockdown()) then return end
    local tasks = LibSchedule:SearchTask(frame.gemTaskKey)
    if (tasks and #tasks > 0) then return end
    LibSchedule:AddTask({
        identity = frame.gemTaskKey, elasped = 0.2, expired = GetTime() + 5,
        onExecute = function()
            if (not frame:IsShown() or InCombatLockdown()) then return true end
            local settled = GetTime() >= frame.gemRetryUntil
            return not RefreshGems(frame, settled) or settled
        end,
        onTimeout = function()
            if (frame:IsShown() and not InCombatLockdown()) then RefreshGems(frame, true) end
        end,
    }, true)
end

hooksecurefunc("ShowInspectItemListFrame", function(unit, parent)
    local frame = parent.inspectFrame
    if (not frame) then return end
    if (not panels[frame]) then
        nextPanelID = nextPanelID + 1
        frame.gemTaskKey = "InspectGemAndEnchantPanel" .. nextPanelID
        panels[frame] = true
        frame:HookScript("OnHide", function()
            LibSchedule:RemoveTask(frame.gemTaskKey)
            HideIcons(frame)
        end)
    end
    LibSchedule:RemoveTask(frame.gemTaskKey)
    frame.gemBaseWidth = frame:GetWidth()
    local changed = frame.gemUnit ~= unit
    frame.gemEquipment = frame.gemEquipment or {}
    for slot, entry in pairs(frame.slotCache or {}) do
        if frame.gemEquipment[slot] ~= entry.link then changed = true end
        frame.gemEquipment[slot] = entry.link
    end
    frame.gemUnit = unit
    if changed or not frame.gemRetryUntil then
        frame.gemRetryUntil = GetTime() + 4
        frame.gemRequestedItems = {}
    end
    if (RefreshGems(frame, GetTime() >= frame.gemRetryUntil)) then QueueRefresh(frame) end
end)

--沿用統一事件庫，只刷新可見面板並合併連續物品載入事件。
LibEvent:attachEvent("GET_ITEM_INFO_RECEIVED, ITEM_DATA_LOAD_RESULT", function(_, itemID)
    if (issecretvalue and issecretvalue(itemID)) then return end
    for frame in pairs(panels) do
        if (frame.gemWaitItems and frame.gemWaitItems[itemID]) then QueueRefresh(frame) end
    end
end)
LibEvent:attachEvent("UNIT_INVENTORY_CHANGED", function(_, unit)
    for frame in pairs(panels) do
        if (frame.unit == unit) then QueueRefresh(frame) end
    end
end)
LibEvent:attachEvent("TOOLTIP_DATA_UPDATE", function(_, tooltipID)
    if (issecretvalue and issecretvalue(tooltipID)) then return end
    for frame in pairs(panels) do
        if (frame.enchantWaitTooltips and frame.enchantWaitTooltips[tooltipID]) then QueueRefresh(frame) end
    end
end)
LibEvent:attachEvent("SOCKET_INFO_UPDATE, PLAYER_REGEN_ENABLED", function()
    for frame in pairs(panels) do QueueRefresh(frame) end
end)
