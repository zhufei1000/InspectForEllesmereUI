
-- Thanks to BLizzatron

local _, ns = ...

if (GetLocale() ~= "ruRU") then return end

ns.L = setmetatable({
    EnableItemLevel             = "Показывать уровень предметов",
    ShowColoredItemLevelString  = "Окрашивать уровень предмета по качеству",
    ShowItemSlotString          = "Показывать название слота предмета",
    ShowInspectAngularBorder    = "Прямоугольные рамки окна осмотра",
    ShowInspectColoredLabel     = "Подсвечивать названия ячеек осмотра",
    ShowCharacterItemSheet      = "Список экипировки персонажа",
    ShowInspectItemSheet        = "Список экипировки осматриваемой цели",
    ShowOwnFrameWhenInspecting  = "Показывать своё окно экипировки при осмотре",
    ShowItemStats               = "Характеристики предметов",
    ShowInspectItemSetSummary   = "Сводка комплектов экипировки",
    ShowPluginGreenState        = "Префиксы второстепенных характеристик |cffcccc33(требуется перезагрузка)|r",
    AltEquipment                = "ALT экипировка",
    GuildNews                   = "Новости гильдии",
    Other                       = "Прочие окна",
    ShowGemAndEnchant           = "Показать самоцветы и чары",
    ShowUpgradeInfo             = "Показать информацию об улучшении",
    CraftedEquipment            = "Крафт",
    NoUpgradeTrack              = "Без пути улучшения",
    LoadingGemInfo              = "Загрузка данных о самоцветах…",
    EnchantedEquipment          = "Зачаровано",
    ShowGearDurability          = "Прочность снаряжения",
    GearDurabilityAnchorPoint   = "Положение прочности",
}, {__index = ns.L})
