local _, ns = ...
local R = ns.Recommendations

--成对槽位：戒指/饰品/双手各占两格，推荐物品戴在另一格同样算已装备。
local function slotPartner(slot)
    if slot == 11 then return 12 elseif slot == 12 then return 11 end
    if slot == 13 then return 14 elseif slot == 14 then return 13 end
    if slot == 16 then return 17 elseif slot == 17 then return 16 end
end

local function equippedAnywhere(equipped, itemID)
    if not itemID then return false end
    if type(equipped) ~= "table" then return equipped == itemID end
    for _, id in pairs(equipped) do
        if id == itemID then return true end
    end
    return false
end

function R:GearRank(slotData, itemID)
    if not self.C.Number(itemID) then return end
    for rank, entry in ipairs(slotData and slotData.top3 or {}) do
        if entry.itemID == itemID then return rank, entry.bis end
    end
end

function R:PairRank(gearSlots, slot, itemID)
    if not self.C.Number(itemID) then return end
    local rank, bis = self:GearRank(gearSlots and gearSlots[slot], itemID)
    if not rank then
        local partner = slotPartner(slot)
        if partner then rank, bis = self:GearRank(gearSlots and gearSlots[partner], itemID) end
    end
    return rank, bis
end

function R:GearBadge(gearSlots, slot, link)
    if not self.C.Safe(link) or type(link) ~= "string" then return end
    local rank, bis = self:PairRank(gearSlots, slot, tonumber(link:match("item:(%d+)")))
    if rank then return bis and self.L.bis or string.format(self.L.topN, rank), true end
    local partner = slotPartner(slot)
    for _, s in ipairs({slot, partner}) do
        local slotData = gearSlots and gearSlots[s]
        if slotData and slotData.top3 and #slotData.top3 > 0 then return self.L.unrankedShort, false end
    end
end

function R:EnchantState(enchant, current)
    if not enchant or not self.C.Number(enchant.enchantID) then return end
    if not self.C.Number(current) then return "unknown" end
    return current == enchant.enchantID and "match" or "mismatch"
end

function R:EnchantColor(state)
    if state == "match" then return 0.25,1,0.35 end
    if state == "mismatch" then return 1,0.3,0.3 end
    return 1,0.85,0.2
end

local function comboGroup(slot)
    if slot >= 11 and slot <= 12 then return "rings" end
    if slot >= 13 and slot <= 14 then return "trinkets" end
    if slot >= 16 then return "weapons" end
end

function R:GearTooltip(row)
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
    local top = row.choices and row.choices[1]
    local link = row.displayLink
    if not link and top then local _; _, link = self:Item(top.itemID) end
    if link then
        GameTooltip:SetHyperlink(link)
    else
        GameTooltip:AddLine(row.slotName)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(self.L.top3, 1,0.82,0)
    for i, item in ipairs(row.choices or {}) do
        local name = self:ItemLabel(item.itemID)
        local prefix = item.bis and ("|cff33ff55" .. self.L.bis .. "|r ") or ""
        local equipped = (row.equippedID and item.itemID == row.equippedID)
            or (row.equippedPairID and item.itemID == row.equippedPairID)
        local suffix = equipped and (" · " .. self.L.equipped) or ""
        GameTooltip:AddLine(string.format("%d. %s%s · %.1f%% · %s%s", i, prefix, name,
            (item.usage or 0)*100, self:Source(item.itemID, self.data), suffix), 1,1,1, true)
    end
    if self.data and self.data.combinations then
        local combinations = self.data.combinations[comboGroup(row.slot)]
        if combinations then
            for _, combo in ipairs(combinations) do
                local names = {}
                for _, id in ipairs(combo.items) do names[#names+1]=self:ItemLabel(id) end
                GameTooltip:AddLine(self.L.combinations .. ": " .. table.concat(names, " + ") .. string.format(" (%.1f%%)", combo.usage*100), 1,0.82,0, true)
            end
        end
    end
    GameTooltip:Show()
end

function R:EmbellishmentName(entry)
    local function one(id, fallback)
        if id then
            return self:ItemLabel(id)
        end
        return fallback and self:ItemLabel(nil, fallback)
    end
    local first = one(entry.itemID, entry.name)
    local second
    if entry.itemID2 and entry.itemID2 ~= entry.itemID then
        second = one(entry.itemID2, entry.name2)
    end
    if first and second then return first .. " / " .. second end
    if first and entry.duplicate then return first .. " ×2" end
    return first or "—"
end

function R:EmbellishmentTooltip(row)
    local top = row.choices and row.choices[1]
    if not top then return end
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
    GameTooltip:AddLine(self.L.embellishment)
    for i, entry in ipairs(row.choices) do
        GameTooltip:AddLine(string.format("%d. %s · %.1f%%", i, self:EmbellishmentName(entry), (entry.usage or 0)*100), 1,1,1, true)
    end
    GameTooltip:Show()
end

function R:EnchantTooltip(star)
    local enchant = star.enchant
    if not enchant then return end
    GameTooltip:SetOwner(star, "ANCHOR_CURSOR")
    GameTooltip:AddLine(self.L.enchant)
    if star.enchantState then
        local status = star.enchantState == "match" and self.L.enchantMatch
            or star.enchantState == "mismatch" and self.L.enchantMismatch or self.L.enchantUnknown
        GameTooltip:AddLine(status, self:EnchantColor(star.enchantState))
        if star.currentEnchantText then
            GameTooltip:AddLine(self.L.equipped .. ": " .. star.currentEnchantText, 1,1,1, true)
        elseif star.currentEnchantID == 0 then
            GameTooltip:AddLine(self.L.missingEnchant, 1,0.3,0.3)
        end
        GameTooltip:AddLine(" ")
    end
    local list = star.enchantList
    if list and #list > 0 then
        for i, entry in ipairs(list) do
            local name = self:ItemLabel(entry.itemID, entry.name)
            GameTooltip:AddLine(string.format("%d. %s · %.1f%%", i, name, (entry.usage or 0)*100), 1,1,1, true)
        end
    else
        local name = self:ItemLabel(enchant.itemID, enchant.name)
        GameTooltip:AddLine(name, 1,1,1, true)
    end
    GameTooltip:Show()
end

--主图标显示推荐物品（未获取时标在主图标上），当前已装备不同则放在副图标。
function R:RenderGear(row, equipped)
    local gearSlots = self.data and self.data.gearSlots
    local slot = row.slot
    local own = type(equipped) == "table" and equipped[slot] or equipped
    local partner = slotPartner(slot)
    local other = partner and type(equipped) == "table" and equipped[partner] or nil
    row.equippedID = own
    row.equippedPairID = other
    local slotData = gearSlots and gearSlots[slot]
    row.choices = slotData and slotData.top3 or {}
    local item = row.choices[1]
    row.link = nil
    row.displayLink = nil
    row.extra.link = nil
    row.state:SetText("")
    row.extra:Hide()
    row.star:Hide()
    row.enchant = slotData and slotData.enchant or nil
    row.enchantState = self:EnchantState(row.enchant, self.C.EquippedEnchantID(row.slot, self.owner and self.owner.slotCache))
    row.star.tex:SetVertexColor(self:EnchantColor(row.enchantState))
    local mainID = item and item.itemID or own
    if not mainID then
        row.icon:SetTexture(134400)
        row.icon:SetDesaturated(false)
        return
    end
    local _, link, icon = self:Item(mainID)
    row.link = link
    row.displayLink = link
    row.icon:SetTexture(icon or 134400)
    row.icon:SetDesaturated(not icon)
    if item then
        local owned = equippedAnywhere(equipped, item.itemID) or self.C.Owned(item.itemID)
        if self.personal and not owned then
            row.state:SetText(self.L.notOwned)
            row.state:SetTextColor(0.55,0.55,0.55)
            row.icon:SetDesaturated(true)
        else
            row.state:SetText(item.bis and self.L.bis or string.format(self.L.topN, 1))
            row.state:SetTextColor(0.25,1,0.35)
        end
    else
        local rank, bis = self:PairRank(gearSlots, slot, own)
        if rank then
            row.state:SetText(bis and self.L.bis or string.format(self.L.topN, rank))
            row.state:SetTextColor(0.25,1,0.35)
        else
            row.state:SetText(self.L.unlisted)
            row.state:SetTextColor(0.55,0.55,0.55)
        end
    end
    if own and item and item.itemID ~= own then
        local _, extraLink, extraIcon = self:Item(own)
        local extra = row.extra
        extra.link = extraLink
        extra.icon:SetTexture(extraIcon or 134400)
        extra.icon:SetDesaturated(not extraIcon)
        local rank, bis = self:PairRank(gearSlots, slot, own)
        if rank then
            extra.state:SetText(bis and self.L.bis or string.format(self.L.topN, rank))
            extra.state:SetTextColor(0.25,1,0.35)
        else
            extra.state:SetText(self.L.unlisted)
            extra.state:SetTextColor(0.55,0.55,0.55)
        end
        extra:Show()
    end
    if row.enchant then
        local anchor = (own and item and own ~= item.itemID) and row.extra or row
        row.star.enchant = row.enchant
        row.star.enchantList = slotData and slotData.enchantList or nil
        row.star:ClearAllPoints()
        if row.starSide == "left" then
            row.star:SetPoint("TOPRIGHT",anchor,"TOPLEFT",-2,-4)
        else
            row.star:SetPoint("TOPLEFT",anchor,"TOPRIGHT",2,-4)
        end
        row.star:Show()
    end
end
