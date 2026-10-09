
-------------------------------------
-- 物品寶石庫
-------------------------------------

local MAJOR, MINOR = "LibItemGem.7000", 3
local lib = LibStub:NewLibrary(MAJOR, MINOR)

local GetItemGem = C_Item and C_Item.GetItemGem or GetItemGem
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
local GetItemStats = C_Item and C_Item.GetItemStats or GetItemStats
local GetItemGemID = C_Item and C_Item.GetItemGemID

if not lib then return end

function lib:GetItemGemInfo(ItemLink)
    local total, info = 0, {}
    if (issecretvalue and issecretvalue(ItemLink)) then return total, info end
    if (type(ItemLink) ~= "string" or ItemLink == "") then return total, info end
    local stats = GetItemStats(ItemLink)
    local pending = not stats
    for key, num in pairs(stats or {}) do
        if (string.find(key, "EMPTY_SOCKET_") and type(num) == "number" and num > 0) then
            for i = 1, num do
                total = total + 1
                table.insert(info, { name = _G[key] or EMPTY, socket = key })
            end
        end
    end
    local quality = select(3, GetItemInfo(ItemLink))
    local name, link, itemID
    for i = 1, 4 do
        name, link = GetItemGem(ItemLink, i)
        itemID = GetItemGemID and GetItemGemID(ItemLink, i)
        if (issecretvalue and issecretvalue(itemID)) then itemID = nil end
        if (type(itemID) ~= "number" or itemID <= 0) then itemID = nil end
        --寶石名稱/連結可能尚未快取；ID 仍能取得圖標並觸發後續載入。
        if (link or itemID) then
            if (not link and itemID) then
                name, link = GetItemInfo(itemID)
                pending = pending or not link
            end
            while (#info < i) do
                table.insert(info, { name = EMPTY_SOCKET_PRISMATIC or EMPTY, socket = "EMPTY_SOCKET_PRISMATIC" })
            end
            info[i].name = name or info[i].name
            info[i].link = link
            info[i].itemID = itemID
        end
    end
    --填滿的插槽也要計入佈局寬度，不能只返回 GetItemStats 的插槽計數。
    return math.max(total, #info), info, quality, pending
end
