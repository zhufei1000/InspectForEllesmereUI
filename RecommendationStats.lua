local _, ns = ...
local R = ns.Recommendations

function R:StatDisplay(key, data, current)
    local range = data and data.statRanges and data.statRanges[key]
    local median = range and range.median
    if not median then
        return self.L[key] .. "  —", nil, current, nil
    end
    local text = self.L[key] .. "  " .. string.format("%.0f", median)
    local diff
    if current then
        diff = current - median
        text = text .. string.format("  (%+d)", diff)
    end
    return text, median, current, diff
end

function R:StatTooltip(row)
    GameTooltip:SetOwner(row, "ANCHOR_CURSOR")
    GameTooltip:AddLine(self.L[row.key])
    if row.median then
        GameTooltip:AddDoubleLine(self.L.median, string.format("%.0f", row.median), 1,1,1, 1,1,1)
        if row.current then
            GameTooltip:AddDoubleLine(self.L.yourRating, string.format("%.0f", row.current), 1,1,1, 1,1,1)
            GameTooltip:AddDoubleLine(self.L.difference, string.format("%+d", row.current - row.median), 1,1,1, 1,1,1)
        end
    else
        GameTooltip:AddLine(self.L.unavailable, 0.7,0.7,0.7)
    end
    GameTooltip:Show()
end
