local _, ns = ...
local R = ns.Recommendations

function R:ConsumableTooltip(row)
    local top = row.choices and row.choices[1]
    if not top then return end
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
    GameTooltip:AddLine(self.L[row.columnKey or row.key] or self.L.consumables)
    for i, entry in ipairs(row.choices) do
        local label
        if entry.itemID2 then
            label = self:ItemLabel(entry.itemID) .. " + " .. self:ItemLabel(entry.itemID2)
        else
            label = self:EffectLabel(entry)
        end
        GameTooltip:AddLine(string.format("%d. %s · %.1f%%", i, label, (entry.usage or 0)*100), 1,1,1, true)
        if not entry.itemID then GameTooltip:AddLine(self.L.unmapped, 0.7,0.7,0.7) end
    end
    GameTooltip:Show()
end
