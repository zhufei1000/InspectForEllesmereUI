
local _, ns = ...


if (GetLocale() ~= "zhTW") then return end

ns.L = setmetatable({
    EnableItemLevel             = "物品等級顯示",
    ShowColoredItemLevelString  = "裝等文字隨物品品質",
    ShowItemSlotString          = "顯示物品部位文字",
    ShowInspectAngularBorder    = "觀察面板直角邊框",
    ShowInspectColoredLabel     = "觀察面板高亮橙裝武器標簽",
    ShowCharacterItemSheet      = "顯示玩家自己裝備列表",
    ShowInspectItemSheet        = "顯示觀察面板裝備列表",
    ShowOwnFrameWhenInspecting  = "觀察同時顯示自己裝備列表",
    ShowItemStats               = "顯示裝備屬性統計",
    ShowInspectItemSetSummary   = "顯示套裝摘要",
    ShowPluginGreenState        = "顯示綠字屬性前綴 |cffcccc33(重載生效)|r",
    AltEquipment                = "ALT換裝",
    GuildNews                   = "公會新聞",
    Other                       = "其他介面",
    ShowGemAndEnchant           = "顯示寶石與附魔資訊",
    ShowUpgradeInfo             = "顯示裝備升級資訊",
    CraftedEquipment            = "製造業",
    NoUpgradeTrack              = "無升級路線",
    LoadingGemInfo              = "寶石資訊載入中…",
    EnchantedEquipment          = "已附魔",
    ShowGearDurability          = "顯示裝備耐久度",
    GearDurabilityAnchorPoint   = "耐久度位置",
}, {__index = ns.L})
