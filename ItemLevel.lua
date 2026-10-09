
-------------------------------------
-- 物品等級顯示
-------------------------------------
-- 兼容性补丁：防止旧版神器圣物函数报错
if not IsArtifactRelicItem then
    IsArtifactRelicItem = function(link)
        if not link then return false end
        return C_ArtifactUI and C_ArtifactUI.IsArtifactRelicItem and C_ArtifactUI.IsArtifactRelicItem(link)
    end
end

local LibEvent = LibStub:GetLibrary("LibEvent.7000")
local LibSchedule = LibStub:GetLibrary("LibSchedule.7000")
local LibItemInfo = LibStub:GetLibrary("LibItemInfo.7000")

local ARMOR = ARMOR or "Armor"
local WEAPON = WEAPON or "Weapon"
local MOUNTS = MOUNTS or "Mount"
local RELICSLOT = RELICSLOT or "Relic"
local ARTIFACT_POWER = ARTIFACT_POWER or "Artifact"
if (GetLocale():sub(1,2) == "zh") then ARTIFACT_POWER = "能量" end

--fixed for 8.x
local GetLootInfoByIndex = EJ_GetLootInfoByIndex
if (C_EncounterJournal and C_EncounterJournal.GetLootInfoByIndex) then
    GetLootInfoByIndex = C_EncounterJournal.GetLootInfoByIndex
end


--fixed for 10.x
local GetContainerItemLink = GetContainerItemLink or function() end
if (C_Container and C_Container.GetContainerItemInfo) then
    GetContainerItemLink = function(bag, id)
        local info = C_Container.GetContainerItemInfo(bag, id)
        return info and info.hyperlink
    end
end

local GetItemInfoAPI = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemQualityColorAPI = C_Item and C_Item.GetItemQualityColor or GetItemQualityColor
local IsEquippableItemAPI = C_Item and C_Item.IsEquippableItem or IsEquippableItem
local IsArtifactPowerItemAPI = C_Item and C_Item.IsArtifactPowerItem or IsArtifactPowerItem
local GetInventoryItemDurability = GetInventoryItemDurability

local function SafeNumber(value, fallback)
    if (type(value) ~= "number") then
        return fallback
    end
    local ok, normalized = pcall(function()
        return value + 0
    end)
    if (ok and type(normalized) == "number") then
        return normalized
    end
    return fallback
end

local function SafeGetSize(frame, fallbackW, fallbackH)
    local w, h = fallbackW, fallbackH
    if (frame and frame.GetSize) then
        local ok, fw, fh = pcall(frame.GetSize, frame)
        if (ok) then
            w = SafeNumber(fw, w)
            h = SafeNumber(fh, h)
        end
    end
    return w, h
end

local function SafeIsEquippableItem(link)
    if (not IsEquippableItemAPI or type(link) ~= "string") then
        return false
    end
    local ok, equippable = pcall(IsEquippableItemAPI, link)
    return ok and equippable or false
end


--框架 #category AltEquipment|GuildNews|Others
local function GetItemLevelFrame(self, category)
    if (not self.ItemLevelFrame) then
        local fontAdjust = GetLocale():sub(1,2) == "zh" and 0 or -3
        local anchor = self.IconBorder or self
        local w, h = SafeGetSize(self, 32, 32)
        local ww, hh = SafeGetSize(anchor, w, h)
        if (ww <= 0 or hh <= 0) then
            anchor = self.Icon or self.icon or self
            w, h = SafeGetSize(anchor, w, h)
        else
            w, h = min(w, ww), min(h, hh)
        end
        if (w <= 0) then w = 32 end
        if (h <= 0) then h = 32 end
        self.ItemLevelFrame = CreateFrame("Frame", nil, self)
        self.ItemLevelFrame:SetScale(max(0.75, h<32 and h/32 or 1))
        self.ItemLevelFrame:SetFrameLevel(110)
        self.ItemLevelFrame:SetSize(w, h)
        self.ItemLevelFrame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        self.ItemLevelFrame.slotString = self.ItemLevelFrame:CreateFontString(nil, "OVERLAY")
        self.ItemLevelFrame.slotString:SetFont(STANDARD_TEXT_FONT, 10+fontAdjust, "OUTLINE")
        self.ItemLevelFrame.slotString:SetPoint("BOTTOMRIGHT", 1, 2)
        self.ItemLevelFrame.slotString:SetTextColor(1, 1, 1)
        self.ItemLevelFrame.slotString:SetJustifyH("RIGHT")
        self.ItemLevelFrame.slotString:SetWidth(30)
        self.ItemLevelFrame.slotString:SetHeight(0)
        self.ItemLevelFrame.levelString = self.ItemLevelFrame:CreateFontString(nil, "OVERLAY")
        self.ItemLevelFrame.levelString:SetFont(STANDARD_TEXT_FONT, 14+fontAdjust, "OUTLINE")
        self.ItemLevelFrame.levelString:SetPoint("TOP")
        self.ItemLevelFrame.levelString:SetTextColor(1, 0.82, 0)
        LibEvent:trigger("ITEMLEVEL_FRAME_CREATED", self.ItemLevelFrame, self)
    end
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.EnableItemLevel) then
        self.ItemLevelFrame:Show()
        LibEvent:trigger("ITEMLEVEL_FRAME_SHOWN", self.ItemLevelFrame, self, category or "")
    else
        self.ItemLevelFrame:Hide()
    end
    if (category) then
        self.ItemLevelCategory = category
    end
    return self.ItemLevelFrame
end

--設置裝等文字
local function SetItemLevelString(self, text, quality, link)
    if (quality and InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowColoredItemLevelString) then
        local r, g, b, hex = GetItemQualityColorAPI(quality)
        text = format("|c%s%s|r", hex, text)
    end
    self:SetText(text)
end

--設置部位文字
local function SetItemSlotString(self, class, equipSlot, link)
    local slotText = ""
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowItemSlotString) then
        if (equipSlot and string.find(equipSlot, "INVTYPE_") and (not link or SafeIsEquippableItem(link))) then
            slotText = _G[equipSlot] or ""
        elseif (class == ARMOR and (not link or SafeIsEquippableItem(link))) then
            slotText = class
        elseif (link and IsArtifactPowerItemAPI and IsArtifactPowerItemAPI(link)) then
            slotText = ARTIFACT_POWER
        elseif (link and IsArtifactRelicItem(link)) then
            slotText = RELICSLOT
        end
    end
    self:SetText(slotText)
end

--部分裝備無法一次讀取
local function SetItemLevelScheduled(button, ItemLevelFrame, link)
    if (not string.match(link, "item:(%d+):")) then return end
    LibSchedule:AddTask({
        identity  = link,
        elasped   = 1,
        expired   = GetTime() + 3,
        frame     = ItemLevelFrame,
        button    = button,
        onTimeout = function(self)
            --任务超时后清理悬挂状态，避免按钮一直处于待加载标记
            self.button.PendingItemLevelLink = nil
        end,
        onExecute = function(self)
            if (self.button.PendingItemLevelLink ~= self.identity) then
                return true
            end
            local count, level, _, _, quality, _, _, class, _, _, equipSlot = LibItemInfo:GetItemInfo(self.identity)
            if (count == 0) then
                SetItemLevelString(self.frame.levelString, level > 0 and level or "", quality)
                SetItemSlotString(self.frame.slotString, class, equipSlot, link)
                self.button.OrigItemLevel = (level and level > 0) and level or ""
                self.button.OrigItemQuality = quality
                self.button.OrigItemClass = class
                self.button.OrigItemEquipSlot = equipSlot
                self.button.OrigItemLink = self.identity
                self.button.PendingItemLevelLink = nil
                return true
            end
        end,
    })
end

--設置物品等級
local function SetItemLevel(self, link, category, BagID, SlotID)
    if (not self) then return end
    if (tonumber(link)) then
        link = select(2, GetItemInfoAPI(link))
    end
    if (not link or type(link) ~= "string" or not string.match(link, "item:(%d+):")) then
        --非物品/无效链接：仅在已创建框架时清空，不为材料等按钮创建UI对象
        if (self.ItemLevelFrame) then
            SetItemLevelString(self.ItemLevelFrame.levelString, "")
            SetItemSlotString(self.ItemLevelFrame.slotString)
        end
        self.PendingItemLevelLink = nil
        self.OrigItemLink = nil
        self.OrigItemLevel = ""
        self.OrigItemQuality = nil
        self.OrigItemClass = nil
        self.OrigItemEquipSlot = nil
        return
    end
    if (self.OrigItemLink == link) then
        if (self.ItemLevelFrame) then
            SetItemLevelString(self.ItemLevelFrame.levelString, self.OrigItemLevel, self.OrigItemQuality, link)
            SetItemSlotString(self.ItemLevelFrame.slotString, self.OrigItemClass, self.OrigItemEquipSlot, self.OrigItemLink)
        end
        return
    end
    local level = ""
    local _, count, quality, class, subclass, equipSlot
    _, _, quality, _, _, class, subclass, _, equipSlot = GetItemInfoAPI(link)
    --除了装备和圣物外,其它不显示装等（先判断再创建框架）
    local showable = (((equipSlot and string.find(equipSlot, "INVTYPE_")) and SafeIsEquippableItem(link))
        or (subclass and string.find(subclass, RELICSLOT))
        or (category == "AltEquipment"))
    if (showable) then
        count, level = LibItemInfo:GetItemInfo(link, nil, true)
        --坐骑还是要显示的
        if (subclass and subclass == MOUNTS) then
            class = subclass
        end
    else
        count = 0
        level = ""
    end
    local frame = showable and GetItemLevelFrame(self, category) or self.ItemLevelFrame
    if (frame) then
        if (count > 0) then
            self.PendingItemLevelLink = link
            SetItemLevelString(frame.levelString, "...")
            SetItemSlotString(frame.slotString)
            return SetItemLevelScheduled(self, frame, link)
        else
            self.PendingItemLevelLink = nil
            if (tonumber(level) == 0) then level = "" end
            SetItemLevelString(frame.levelString, level, quality, link)
            SetItemSlotString(frame.slotString, class, equipSlot, link)
        end
    else
        self.PendingItemLevelLink = nil
    end
    self.OrigItemLink = link
    self.OrigItemLevel = level
    self.OrigItemQuality = quality
    self.OrigItemClass = class
    self.OrigItemEquipSlot = equipSlot
end

--[[ All ]]
hooksecurefunc("SetItemButtonQuality", function(self, quality, itemIDOrLink, suppressOverlays, isBound)
    if (self.ItemLevelCategory or self.isBag) then return end
    if (InspectForEllesmereUIDB and not InspectForEllesmereUIDB.EnableItemLevelOther) then
        if (self.ItemLevelFrame) then self.ItemLevelFrame:Hide() end
        return
    end
    
    if (itemIDOrLink) then
        local link
        --Artifact
        if (IsArtifactRelicItem(itemIDOrLink) or (IsArtifactPowerItemAPI and IsArtifactPowerItemAPI(itemIDOrLink))) then
            SetItemLevel(self)
        --QuestInfo
        elseif (self.type and self.objectType == "item") then
            if (QuestInfoFrame and QuestInfoFrame.questLog) then
                link = LibItemInfo:GetQuestItemlink(self.type, self:GetID())
            else
                link = GetQuestItemLink(self.type, self:GetID())
            end
            -- Some quest bonus rewards  are not real item links.
            -- Falling back to numeric itemIDOrLink can resolve to unrelated equippable items.
            if (not link and type(itemIDOrLink) == "string" and string.match(itemIDOrLink, "item:(%d+):")) then
                link = itemIDOrLink
            end
            SetItemLevel(self, link)
        --EncounterJournal
        elseif (self.encounterID and self.link) then
            local itemInfo = GetLootInfoByIndex(self.index)
            SetItemLevel(self, itemInfo.link or self.link)
        --EmbeddedItemTooltip
        elseif (self.Tooltip) then
            link = select(2, self.Tooltip:GetItem())
            SetItemLevel(self, link)
        else    --if (string.match(itemIDOrLink,"item:%d+:")) then
            if (type(itemIDOrLink) == "string") then
                SetItemLevel(self, itemIDOrLink)
            else
                SetItemLevel(self, nil)
            end
        end
    else
        if (self.ItemLevelFrame) then
            SetItemLevelString(self.ItemLevelFrame.levelString, "")
            SetItemSlotString(self.ItemLevelFrame.slotString)
        end
    end
end)

-- ALT
if (EquipmentFlyout_DisplayButton) then
    local EquipmentManager_GetLocationData = EquipmentManager_GetLocationData
    local UnpackLocation = EquipmentManager_UnpackLocation or (C_EquipmentSet and C_EquipmentSet.UnpackLocation)
    local ItemLocation = ItemLocation
    local Item = Item
    local EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION = EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION
    local function TryUnpackLocation(location)
        if (not UnpackLocation and LoadAddOn) then
            pcall(LoadAddOn, "Blizzard_EquipmentManager")
            UnpackLocation = EquipmentManager_UnpackLocation or (C_EquipmentSet and C_EquipmentSet.UnpackLocation)
        end
        if (UnpackLocation) then
            return UnpackLocation(location)
        end
    end
    local function SetItemLevelFromItemLocation(button, itemLocation)
        if (not itemLocation) then return false end
        if (C_Item and C_Item.GetItemLink) then
            local link = C_Item.GetItemLink(itemLocation)
            if (link) then
                SetItemLevel(button, link, "AltEquipment")
                return true
            end
        end
        if (Item and Item.CreateFromItemLocation) then
            local item = Item:CreateFromItemLocation(itemLocation)
            item:ContinueOnItemLoad(function()
                local link = item:GetItemLink()
                SetItemLevel(button, link, "AltEquipment")
            end)
            return true
        end
        return false
    end
    local function GetItemLocationFromButton(button)
        if (button.itemLocation) then
            return button.itemLocation
        end
        if (type(button.location) == "number"
            and (not EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION or button.location < EQUIPMENTFLYOUT_FIRST_SPECIAL_LOCATION)
            and EquipmentManager_GetLocationData
            and ItemLocation
            and ItemLocation.CreateFromBagAndSlot
            and ItemLocation.CreateFromEquipmentSlot) then
            local data = EquipmentManager_GetLocationData(button.location)
            if (data) then
                if (data.isBags) then
                    return ItemLocation:CreateFromBagAndSlot(data.bag, data.slot)
                else
                    return ItemLocation:CreateFromEquipmentSlot(data.slot)
                end
            end
        end
    end
    hooksecurefunc("EquipmentFlyout_DisplayButton", function(button, paperDollItemSlot)
        local itemLocation = GetItemLocationFromButton(button)
        if (itemLocation and SetItemLevelFromItemLocation(button, itemLocation)) then
            return
        end
        local location = button.location
        if (not location) then return end
        local player, bank, bags, voidStorage, slot, bag, tab, voidSlot = TryUnpackLocation(location)
        if (not player and not bank and not bags and not voidStorage) then return end
        if (voidStorage) then
            SetItemLevel(button, nil, "AltEquipment")
        elseif (bags) then
            local link = GetContainerItemLink(bag, slot)
            SetItemLevel(button, link, "AltEquipment", bag, slot)
        else
            local link = GetInventoryItemLink("player", slot)
            SetItemLevel(button, link, "AltEquipment")
        end
    end)
end

-- GuildNews
LibEvent:attachEvent("ADDON_LOADED", function(self, addonName)
    if (addonName == "Blizzard_Communities" and GuildNewsButton_SetText) then
        local cache, cacheSize, CACHE_LIMIT = {}, 0, 200
        hooksecurefunc("GuildNewsButton_SetText", function(button, text_color, text, text1, text2, ...)
            if (not InspectForEllesmereUIDB or 
                not InspectForEllesmereUIDB.EnableItemLevel or 
                not InspectForEllesmereUIDB.EnableItemLevelGuildNews) then
              return
            end
            if (text2 and type(text2) == "string") then
                local link = string.match(text2, "|H(item:%d+:.-)|h.-|h")
                if (link) then
                    local level = cache[link]
                    if (level == nil) then
                        --缓存有上限，超出时清空防止内存无限上涨
                        if (cacheSize >= CACHE_LIMIT) then
                            wipe(cache)
                            cacheSize = 0
                        end
                        level = select(2, LibItemInfo:GetItemInfo(link))
                        if (level > 0) then
                            cache[link] = level
                            cacheSize = cacheSize + 1
                        end
                    end
                    if (level > 0) then
                        text2 = text2:gsub("(%|Hitem:%d+:.-%|h%[)(.-)(%]%|h)", "%1"..level..":%2%3")
                        button.text:SetFormattedText(text, text1, text2, ...)
                    end
                end
            end
        end)
    end
end)

-------------------
--   PaperDoll   --
-------------------

local CharacterPaperDollButtons = {
    CharacterHeadSlot, CharacterNeckSlot, CharacterShoulderSlot, CharacterBackSlot, CharacterChestSlot, CharacterWristSlot,
    CharacterHandsSlot, CharacterWaistSlot, CharacterLegsSlot, CharacterFeetSlot, CharacterFinger0Slot, CharacterFinger1Slot,
    CharacterTrinket0Slot, CharacterTrinket1Slot, CharacterMainHandSlot, CharacterSecondaryHandSlot
}

local function SetFrameTextAnchor(fontString, parent, anchorPoint)
    anchorPoint = anchorPoint or "BOTTOM"
    local x, y = 0, 0
    if (string.find(anchorPoint, "LEFT")) then
        x = 2
    elseif (string.find(anchorPoint, "RIGHT")) then
        x = -2
    end
    if (string.find(anchorPoint, "TOP")) then
        y = -2
    elseif (string.find(anchorPoint, "BOTTOM")) then
        y = 2
    end
    fontString:ClearAllPoints()
    fontString:SetWidth(0)
    fontString:SetPoint(anchorPoint, parent, anchorPoint, x, y)
end

local function GetDurabilityFrame(button)
    if (not button) then return end
    if (not button.InspectForEllesmereUIDurabilityFrame) then
        local fontAdjust = GetLocale():sub(1,2) == "zh" and 0 or -2
        local anchor = button.IconBorder or button
        local w, h = SafeGetSize(button, 32, 32)
        local ww, hh = SafeGetSize(anchor, w, h)
        if (ww <= 0 or hh <= 0) then
            anchor = button.Icon or button.icon or button
            w, h = SafeGetSize(anchor, w, h)
        else
            w, h = min(w, ww), min(h, hh)
        end
        if (w <= 0) then w = 32 end
        if (h <= 0) then h = 32 end
        button.InspectForEllesmereUIDurabilityFrame = CreateFrame("Frame", nil, button)
        button.InspectForEllesmereUIDurabilityFrame:SetScale(max(0.75, h<32 and h/32 or 1))
        button.InspectForEllesmereUIDurabilityFrame:SetFrameLevel(111)
        button.InspectForEllesmereUIDurabilityFrame:SetSize(w, h)
        button.InspectForEllesmereUIDurabilityFrame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
        button.InspectForEllesmereUIDurabilityFrame.text = button.InspectForEllesmereUIDurabilityFrame:CreateFontString(nil, "OVERLAY")
        button.InspectForEllesmereUIDurabilityFrame.text:SetFont(STANDARD_TEXT_FONT, 11+fontAdjust, "OUTLINE")
        button.InspectForEllesmereUIDurabilityFrame.text:SetHeight(0)
    end
    return button.InspectForEllesmereUIDurabilityFrame
end

local function ClearPaperDollDurability(button)
    local frame = button and button.InspectForEllesmereUIDurabilityFrame
    if (frame and frame.text) then
        frame.text:SetText("")
    end
end

local function SetDurabilityTextColor(fontString, percentage)
    if (percentage > 66) then
        fontString:SetTextColor(0, 1, 0)
    elseif (percentage > 33) then
        fontString:SetTextColor(1, 1, 0)
    else
        fontString:SetTextColor(1, 0, 0)
    end
end

--裝備耐久度（位置可調，EUI 的耐久度位置不可調）
local function SetPaperDollDurability(button)
    if (not button) then return end
    if (InspectForEllesmereUIDB and InspectForEllesmereUIDB.ShowGearDurability == false) then
        ClearPaperDollDurability(button)
        return
    end
    if (not GetInventoryItemDurability) then return end
    local frame = GetDurabilityFrame(button)
    if (not frame or not frame.text) then return end

    local current, maxDurability = GetInventoryItemDurability(button:GetID())
    if (not current or not maxDurability or maxDurability <= 0) then
        frame.text:SetText("")
        return
    end

    local percentage = (current / maxDurability) * 100
    SetFrameTextAnchor(frame.text, frame, InspectForEllesmereUIDB and InspectForEllesmereUIDB.GearDurabilityAnchorPoint or "BOTTOM")
    SetDurabilityTextColor(frame.text, percentage)
    frame.text:SetFormattedText("%.0f%%", percentage)
end

local function CharacterPaperDollDurabilityUpdate()
    for _, button in ipairs(CharacterPaperDollButtons) do
        SetPaperDollDurability(button)
    end
end
PaperDollFrame:HookScript("OnShow", function(self)
    CharacterPaperDollDurabilityUpdate()
end)
LibEvent:attachEvent("PLAYER_EQUIPMENT_CHANGED", function(self)
    if (CharacterFrame:IsShown()) then
        CharacterPaperDollDurabilityUpdate()
    end
end)
LibEvent:attachEvent("UPDATE_INVENTORY_DURABILITY", function(self)
    if (CharacterFrame:IsShown()) then
        CharacterPaperDollDurabilityUpdate()
    end
end)
LibEvent:attachTrigger("GEAR_DURABILITY_DISPLAY_CHANGED", function(self)
    if (CharacterFrame:IsShown()) then
        CharacterPaperDollDurabilityUpdate()
    end
end)
LibEvent:attachTrigger("ANCHOR_POINT_CHANGED", function(self, anchorkey)
    if (anchorkey == "GearDurabilityAnchorPoint" and CharacterFrame:IsShown()) then
        CharacterPaperDollDurabilityUpdate()
    end
end)

-------------------
--   ItemLevel   --
-------------------

-- 位置設置
LibEvent:attachTrigger("ITEMLEVEL_FRAME_SHOWN", function(self, frame, parent, category)
    if (InspectForEllesmereUIDB and not InspectForEllesmereUIDB["EnableItemLevel"..category]) then
        return frame:Hide()
    end
end)

