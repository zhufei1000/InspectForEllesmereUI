local _, ns = ...
local R = ns.Recommendations

function R:GearRank(slotData, itemID)
    if not self.C.Number(itemID) then return end
    for rank, entry in ipairs(slotData and slotData.top3 or {}) do
        if entry.itemID == itemID then return rank, entry.bis end
    end
end

function R:GearBadge(slotData, link)
    if not self.C.Safe(link) or type(link) ~= "string" then return end
    local rank, bis = self:GearRank(slotData, tonumber(link:match("item:(%d+)")))
    if rank then return bis and self.L.bis or string.format(self.L.topN, rank), true end
    if slotData and slotData.top3 and #slotData.top3 > 0 then return self.L.unrankedShort, false end
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
    local link
    if top then local _; _, link = self:Item(top.itemID) end
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
        local suffix = (row.equippedID and item.itemID == row.equippedID) and (" · " .. self.L.equipped) or ""
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

function R:RenderGear(row, equipped)
    row.equippedID = equipped
    local slotData = self.data and self.data.gearSlots and self.data.gearSlots[row.slot]
    row.choices = slotData and slotData.top3 or {}
    local item = row.choices[1]
    row.link = nil
    row.state:SetText("")
    row.extra:Hide()
    row.star:Hide()
    row.enchant = slotData and slotData.enchant or nil
    row.enchantState = self:EnchantState(row.enchant, self.C.EquippedEnchantID(row.slot, self.owner and self.owner.slotCache))
    row.star.tex:SetVertexColor(self:EnchantColor(row.enchantState))
    if not item then
        row.icon:SetTexture(134400)
        row.icon:SetDesaturated(false)
        return
    end
    local _, link, icon = self:Item(item.itemID)
    row.link = link
    row.icon:SetTexture(icon or 134400)
    row.icon:SetDesaturated(not icon)
    if equipped and equipped == item.itemID then
        if item.bis then
            row.state:SetText(self.L.bis)
        else
            row.state:SetText(string.format(self.L.topN, 1))
        end
        row.state:SetTextColor(0.25,1,0.35)
    elseif self.personal and not self.C.Owned(item.itemID) then
        row.state:SetText(self.L.notOwned)
        row.state:SetTextColor(0.55,0.55,0.55)
        row.icon:SetDesaturated(true)
    end
    if equipped and equipped ~= item.itemID then
        local _, extraLink, extraIcon = self:Item(equipped)
        local extra = row.extra
        extra.link = extraLink
        extra.icon:SetTexture(extraIcon or 134400)
        extra.icon:SetDesaturated(not extraIcon)
        local rank, bis = self:GearRank(slotData, equipped)
        if rank then
            if bis then
                extra.state:SetText(self.L.bis)
            else
                extra.state:SetText(string.format(self.L.topN, rank))
            end
            extra.state:SetTextColor(0.25,1,0.35)
        else
            extra.state:SetText(self.L.unlisted)
            extra.state:SetTextColor(0.55,0.55,0.55)
        end
        extra:Show()
    end
    if row.enchant then
        local anchor = (equipped and equipped ~= item.itemID) and row.extra or row
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
