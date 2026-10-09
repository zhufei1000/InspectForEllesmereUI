
local _, ns = ...

if (GetLocale() ~= "zhCN") then return end

ns.L = setmetatable({
    EnableItemLevel             = "物品等级显示",
    ShowColoredItemLevelString  = "装等文字随物品品质",
    ShowItemSlotString          = "显示物品部位文字",
    ShowInspectAngularBorder    = "观察面板直角边框",
    ShowInspectColoredLabel     = "观察面板高亮橙装武器标签",
    ShowCharacterItemSheet      = "显示玩家自己装备列表",
    ShowInspectItemSheet        = "显示观察对象装备列表",
    ShowOwnFrameWhenInspecting  = "观察同时显示自己装备列表",
    ShowItemStats               = "显示装备属性统计",
    ShowInspectItemSetSummary   = "显示套装摘要",
    ShowPluginGreenState        = "显示绿字属性前缀 |cffcccc33(重载生效)|r",
    AltEquipment                = "ALT换装",
    GuildNews                   = "公会新闻",
    Other                       = "其他界面",
    ShowGemAndEnchant           = "显示宝石与附魔信息",
    ShowUpgradeInfo             = "显示装备升级信息",
    CraftedEquipment            = "制造业",
    NoUpgradeTrack              = "无升级路线",
    LoadingGemInfo              = "宝石信息加载中…",
    EnchantedEquipment          = "已附魔",
    ShowGearDurability          = "显示装备耐久度",
    GearDurabilityAnchorPoint   = "耐久度位置",
}, {__index = ns.L})
