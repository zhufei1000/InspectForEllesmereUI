local _, ns = ...
local C = {}
ns.RecommendationCompat = C

function C.Safe(value)
    return not issecretvalue or not issecretvalue(value)
end

function C.Number(value)
    return C.Safe(value) and type(value) == "number" and value or nil
end

function C.Spec(unit)
    if InCombatLockdown() then return end
    local api = C_SpecializationInfo
    if unit == "player" then
        local index = api and api.GetSpecialization and api.GetSpecialization()
        if C.Number(index) and index > 0 then
            local id, name, _, icon = api.GetSpecializationInfo(index)
            if C.Number(id) and id > 0 and C.Safe(name) then return id, name, icon end
        end
    elseif api and api.GetInspectSpecialization then
        local id = api.GetInspectSpecialization(unit)
        if C.Number(id) and id > 0 then
            local _, name, _, icon = GetSpecializationInfoByID(id)
            return id, name, icon
        end
    end
end

function C.ClassIcon(unit)
    if InCombatLockdown() or not UnitClass then return end
    local _, classFile = UnitClass(unit)
    if C.Safe(classFile) and classFile and CLASS_ICON_TCOORDS then return CLASS_ICON_TCOORDS[classFile] end
end

function C.Item(itemID, request)
    if not C.Number(itemID) or itemID <= 0 then return end
    local name, link, _, _, _, _, _, _, _, icon = C_Item.GetItemInfo(itemID)
    if not name and request and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(itemID) end
    return name, link, icon
end

function C.ItemQuality(itemID)
    if not C.Number(itemID) or itemID <= 0 then return end
    local _, _, quality = C_Item.GetItemInfo(itemID)
    return C.Number(quality)
end

function C.CraftedQuality(itemID)
    if not C.Number(itemID) or itemID <= 0 then return end
    local api = C_TradeSkillUI
    if not (api and api.GetItemCraftedQualityByItemInfo) then return end
    local _, link = C.Item(itemID)
    local quality
    if link then quality = C.Number(api.GetItemCraftedQualityByItemInfo(link)) end
    if not quality then quality = C.Number(api.GetItemCraftedQualityByItemInfo(itemID)) end
    if quality and quality >= 1 and quality <= 5 then return quality end
end

local function atlasName(value)
    if not value or not C.Safe(value) or type(value) ~= "string" then return end
    return value
end

function C.CraftedQualityAtlas(itemID)
    local api = C_TradeSkillUI
    if not api then return end
    local _, link = C.Item(itemID)
    if api.GetItemCraftedQualityInfo then
        local info = api.GetItemCraftedQualityInfo(link or itemID)
        if info then
            local small = atlasName(info.iconSmall)
            if small then return small end
            local large = atlasName(info.icon)
            if large then return large end
        end
    end
    local quality = C.CraftedQuality(itemID)
    if quality then return "Professions-ChatIcon-Quality-Tier" .. quality end
end

function C.SpellTexture(spellId, fallbackFile)
    local id = C.Number(spellId)
    if id and C_Spell and C_Spell.GetSpellTexture then
        local ok, texture = pcall(C_Spell.GetSpellTexture, id)
        if ok and texture then return texture end
    end
    if type(fallbackFile) == "string" and fallbackFile ~= "" then
        return "Interface\\Icons\\" .. fallbackFile:gsub("%.jpg$", "")
    end
end

function C.SpellName(spellId)
    local id = C.Number(spellId)
    if not id then return end
    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, id)
        if ok and info and info.name then return info.name end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, id)
        if ok and type(name) == "string" and name ~= "" then return name end
    end
end

function C.EquippedID(slot, cache)
    if InCombatLockdown() then return end
    local entry = cache and cache[slot]
    local link = entry and entry.link or GetInventoryItemLink("player", slot)
    if not link or not C.Safe(link) then return end
    return tonumber(link:match("item:(%d+)"))
end

function C.EquippedEnchantID(slot, cache)
    if InCombatLockdown() then return end
    local entry = cache and cache[slot]
    local link = entry and entry.link or GetInventoryItemLink("player", slot)
    if not link or not C.Safe(link) or type(link) ~= "string" then return end
    return tonumber(link:match("item:%d+:(%d+)")) or 0
end

function C.Owned(itemID)
    if not C.Number(itemID) then return true end
    local count
    if C_Item and C_Item.GetItemCount then
        count = C_Item.GetItemCount(itemID, true, false, true)
    elseif GetItemCount then
        count = GetItemCount(itemID, true)
    end
    count = C.Number(count)
    if not count then return true end
    return count > 0
end

function C.Ratings()
    if InCombatLockdown() then return end
    local keys = {crit=CR_CRIT_MELEE, haste=CR_HASTE_MELEE, mastery=CR_MASTERY, versatility=CR_VERSATILITY_DAMAGE_DONE}
    local values = {}
    for key, index in pairs(keys) do
        local value = index and C.Number(GetCombatRating(index))
        if value then values[key] = value end
    end
    return next(values) and values or nil
end

function C.InspectRatings(unit)
    if InCombatLockdown() or not unit then return end
    local lib = LibStub and LibStub.GetLibrary and LibStub:GetLibrary("LibItemInfo.7000", true)
    if not (lib and lib.GetUnitItemLevel) then return end
    local stats = {}
    local ok = pcall(lib.GetUnitItemLevel, lib, unit, stats)
    if not ok then return end
    local values = {}
    for key, token in pairs({crit=STAT_CRITICAL_STRIKE, haste=STAT_HASTE, mastery=STAT_MASTERY, versatility=STAT_VERSATILITY}) do
        local entry = stats[token]
        local value = entry and C.Number(entry.value)
        if value then values[key] = value end
    end
    return next(values) and values or nil
end

local omniumSystemID

-- 万奥宝典符文: Archon 数据 spellID -> 游戏 trait 定义 spellID
local OMNIUM_TRAIT_MAP = {
    [1287425] = 1279596, -- Void-Touched Orbs
    [1286970] = 1279599, -- Rune of Unleashed Fire
    [1287908] = 1279603, -- Rune of Self-Mending
    [1287955] = 1279604, -- Rune of Void-Tainted Shell
    [1287978] = 1279605, -- Rune of Lynxlike Reflexes
    [1287770] = 1279613, -- Rune of the Versatile Warrior
    [1287771] = 1279612, -- Rune of Masterful Cunning
    [1287772] = 1279609, -- Rune of Critical Power
    [1287774] = 1279610, -- Rune of Burning Haste
    [1289063] = 1279616, -- Rune of Echoes
    [1279614] = 1279614, -- Rune of Overload
    [1279615] = 1279615, -- Rune of Residual Energy
}

function C.OmniumTraitID(spellId)
    return OMNIUM_TRAIT_MAP[spellId] or spellId
end

function C.OmniumName(spellId, fallback)
    return C.SpellName(C.OmniumTraitID(spellId)) or C.SpellName(spellId) or fallback
end

function C.TraitSelection(wantedSpells)
    local traits = C_Traits
    if not (traits and traits.GetConfigIDBySystemID and traits.GetConfigInfo
            and traits.GetTreeNodes and traits.GetNodeInfo) then
        return
    end
    local GetConfigInfo, GetTreeNodes, GetNodeInfo = traits.GetConfigInfo, traits.GetTreeNodes, traits.GetNodeInfo
    local GetEntryInfo, GetDefinitionInfo = traits.GetEntryInfo, traits.GetDefinitionInfo
    local function collect(configID)
        local info = GetConfigInfo(configID)
        local selected = {}
        local systemHit = false
        for _, treeID in ipairs(info and info.treeIDs or {}) do
            for _, nodeID in ipairs(GetTreeNodes(treeID) or {}) do
                local nodeInfo = GetNodeInfo(configID, nodeID)
                if nodeInfo and type(nodeInfo.entryIDs) == "table" then
                    local committed = {}
                    local ranked = nodeInfo.entryIDsWithCommittedRanks
                    if type(ranked) == "table" then
                        for _, entryID in ipairs(ranked) do committed[entryID] = true end
                    end
                    for _, entryID in ipairs(nodeInfo.entryIDs) do
                        local entryInfo = GetEntryInfo and GetEntryInfo(configID, entryID)
                        local defID = entryInfo and entryInfo.definitionID
                        local defInfo = defID and GetDefinitionInfo and GetDefinitionInfo(defID)
                        local spellID = defInfo and C.Number(defInfo.spellID)
                        if spellID then
                            if wantedSpells and wantedSpells[spellID] then systemHit = true end
                            if committed[entryID] then selected[spellID] = true end
                        end
                    end
                end
            end
        end
        return selected, systemHit
    end
    if omniumSystemID then
        local configID = traits.GetConfigIDBySystemID(omniumSystemID)
        if configID then
            local selected, hit = collect(configID)
            if hit then return selected end
        end
        omniumSystemID = nil
    end
    for systemID = 1, 100 do
        local configID = traits.GetConfigIDBySystemID(systemID)
        if configID then
            local selected, hit = collect(configID)
            if hit then
                omniumSystemID = systemID
                return selected
            end
        end
    end
    return nil
end

function C.SpellSelected(spellId)
    local id = C.Number(spellId)
    if not id then return end
    local detectable = false
    if IsPlayerSpell then
        detectable = true
        local ok, known = pcall(IsPlayerSpell, id)
        if ok and known then return true end
    end
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        detectable = true
        local ok, known = pcall(C_SpellBook.IsSpellKnown, id)
        if ok and known then return true end
    end
    if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID then
        detectable = true
        local ok, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, id)
        if ok and aura then return true end
    end
    if detectable then return false end
end
