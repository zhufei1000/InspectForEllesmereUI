local _, ns = ...

--Complete English base shared by every client locale.
ns.L = setmetatable({
    EnableItemLevel = "Show item levels",
    ShowColoredItemLevelString = "Color item levels by quality",
    ShowItemSlotString = "Show item slot labels",
    ShowInspectAngularBorder = "Use square inspect borders",
    ShowInspectColoredLabel = "Color inspect slot labels",
    ShowCharacterItemSheet = "Show your equipment list",
    ShowInspectItemSheet = "Show inspected equipment list",
    ShowOwnFrameWhenInspecting = "Show your equipment when inspecting",
    ShowItemStats = "Show equipment statistics",
    ShowInspectItemSetSummary = "Show equipped set summary",
    ShowPluginGreenState = "Show secondary-stat prefixes |cffcccc33(reload required)|r",
    AltEquipment = "Alternate equipment",
    GuildNews = "Guild news",
    Other = "Other frames",
    ShowGemAndEnchant = "Show gems and enchants",
    ShowUpgradeInfo = "Show equipment upgrade information",
    CraftedEquipment = "Crafted",
    NoUpgradeTrack = "No upgrade track",
    LoadingGemInfo = "Loading gem information…",
    EnchantedEquipment = "Enchanted",
    ShowGearDurability = "Show equipment durability",
    GearDurabilityAnchorPoint = "Durability position",
}, {__index = function(_, key) return key:gsub("([a-z])([A-Z])", "%1 %2") end})
