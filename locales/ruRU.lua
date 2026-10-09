
-- Thanks to BLizzatron

local _, ns = ...

if (GetLocale() ~= "ruRU") then return end

ns.L = setmetatable({
    EnableItemLevel             = "Включить ур. предмета",
    ShowColoredItemLevelString  = "Показать цветную, строку уровня предмета",
    ShowItemSlotString          = "Показать строку слота элемента",
    ShowInspectAngularBorder    = "Показать угловую границу осмотра",
    ShowInspectColoredLabel     = "Показать окрашенный, ярлычок осмотра",
    ShowCharacterItemSheet      = "Показать список предметов персонажа",
    ShowInspectItemSheet        = "Показать окрашенный предметов персонажа",
    ShowOwnFrameWhenInspecting  = "Показывать собственную рамку, при осмотре",
    ShowItemStats               = "Показать характеристики преметов",
    AltEquipment                = "ALT экипировка",
    GuildNews                   = "Новости гильдии",
    ShowGemAndEnchant           = "Показать самоцветы и чары",
    ShowUpgradeInfo             = "Показать информацию об улучшении",
    ShowGearDurability          = "Показать прочность",
    GearDurabilityAnchorPoint   = "Положение прочности",
}, {__index = ns.L})
