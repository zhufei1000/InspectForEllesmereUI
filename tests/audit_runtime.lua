-- Cross-class statistics, restricted values and independent asynchronous item updates.
local locale = ...
function GetLocale() return locale end
local secret = {}
function issecretvalue(value) return rawequal(value,secret) end
function issecrettable() return false end
local clock, restricted, ready = 0, false, false
function GetTime() return clock end
function time() return 100 end
function InCombatLockdown() return false end
min,max,floor,abs = math.min,math.max,math.floor,math.abs
tinsert,tremove,format = table.insert,table.remove,string.format
strmatch=string.match
STANDARD_TEXT_FONT="stock.ttf"
for _,key in ipairs({"ITEM_MOD_INTELLECT_SHORT","ITEM_MOD_STRENGTH_SHORT","ITEM_MOD_AGILITY_SHORT",
    "ITEM_MOD_STAMINA_SHORT","STAT_HASTE","STAT_MASTERY","STAT_CRITICAL_STRIKE","STAT_VERSATILITY",
    "STAT_AVOIDANCE","STAT_SPEED","STAT_LIFESTEAL","LEVEL","STAT_AVERAGE_ITEM_LEVEL","HEALTH"}) do _G[key]=key end
local frames, methods, hooks = {}, {}, {}
function methods:SetText(value) assert(not issecretvalue(value),"secret passed to statistics text");self.text=value end
function methods:GetText() return self.text end
function methods:SetTextColor(...) self.color={...} end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:HookScript(event,fn) self.scripts[event]=fn end
function methods:SetSize(w,h) self.width,self.height=w,h end
function methods:GetSize() return self.width or 40,self.height or 40 end
function methods:GetParent() return self.parent end
function methods:IsShown() return self.shown end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:SetShown(value) self.shown=value end
function methods:SetNormalTexture() self.normal=CreateFrame("Texture") end
function methods:GetNormalTexture() return self.normal end
function methods:CreateFontString() return CreateFrame("FontString",nil,self) end
function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
for _,method in ipairs({"SetWidth","SetHeight","SetPoint","SetTexture","SetTexCoord","SetFont","SetFontObject",
    "GetFontObject","SetJustifyH","SetVertexColor","EnableMouse","RegisterEvent","SetScale","SetFrameLevel"}) do
    methods[method]=function() end
end
function CreateFrame(kind,name,parent,template)
    local frame=setmetatable({parent=parent,shown=true,scripts={}}, {__index=methods})
    frames[#frames+1]=frame
    if template=="CharacterStatFrameTemplate" then
        frame.Label,frame.Value,frame.Background=CreateFrame("FontString"),CreateFrame("FontString"),CreateFrame("Texture")
    end
    return frame
end
UIParent,PaperDollFrame,CharacterFrame=CreateFrame("Frame"),CreateFrame("Frame"),CreateFrame("Frame")
function hooksecurefunc(name,fn) hooks[name]=fn end
function UnitExists() return true end
function UnitGUID() return "test-guid" end
function UnitName() return "Tester" end
function GetRealmName() return "Realm" end
local targetClass,targetSpec="WARRIOR",71
function UnitClass(unit) return "Class",unit=="player" and "MAGE" or targetClass end
function UnitLevel() return restricted and secret or 90 end
function UnitHealthMax() return restricted and secret or 10000 end
function UnitStat(unit,index) return 0, restricted and secret or index*100 end
function AbbreviateLargeNumbers(value) assert(not issecretvalue(value));return tostring(value) end
local link="|Hitem:999:8017:0:0:0|h[Equipment]|h"
local secretLink,secretStats,secretInfo=false,false,false
function GetInventoryItemLink() return secretLink and secret or link end
function GetInventoryItemID() return secretLink and secret or 999 end
C_Item={GetItemInfo=function()
    return secretInfo and secret or "Equipment",link,4,321,80,"Armor","Plate",1,"INVTYPE_HEAD",123
end, GetItemStats=function()
    if secretStats then return {ITEM_MOD_CRIT_RATING_SHORT=secret} end
    return {ITEM_MOD_CRIT_RATING_SHORT=50}
end, GetDetailedItemLevelInfo=function() return ready and 321 or nil end,
    IsEquippableItem=function() return true end}
C_SpecializationInfo={GetSpecialization=function() return 1 end,
    GetSpecializationInfo=function() return 63,"Fire",nil,123,"DAMAGER",4 end,
    GetInspectSpecialization=function() return targetSpec end}
assert(loadfile("libs/LibStub.lua"))()
assert(loadfile("libs/LibEvent.lua"))()
assert(loadfile("libs/LibSchedule.lua"))()
assert(loadfile("libs/LibItemInfo.lua"))()
local info=LibStub:GetLibrary("LibItemInfo.7000")
secretStats=true
local stats={}
info:GetStatsViaAPI(link,stats)
assert(not next(stats),"restricted item ratings are not accumulated")
secretStats=false;secretLink=true
local unknown,level=info:GetUnitItemInfo("target",1)
assert(unknown==0 and level==0,"restricted inventory links and IDs are not parsed")
secretLink=false;secretInfo=true;ready=true
local _,_,name=info:GetUnitItemInfo("target",1)
assert(name==nil,"restricted item names are filtered before returning metadata")
secretInfo=false;ready=false
InspectForEllesmereUIDB={EnableItemLevel=true,EnableItemLevelOther=true}
assert(loadfile("ItemLevel.lua"))()
local first,second=CreateFrame("Button"),CreateFrame("Button")
hooks.SetItemButtonQuality(first,4,link)
hooks.SetItemButtonQuality(second,4,link)
assert(first.ItemLevelFrame.levelString.text=="..." and second.ItemLevelFrame.levelString.text=="...")
ready=true;clock=1
for _,frame in ipairs(frames) do if frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame,1) end end
assert(first.ItemLevelFrame.levelString.text==321 and second.ItemLevelFrame.levelString.text==321,
    "two buttons with the same pending item both receive their item levels")
local ns={Skin={Font=function() end,Panel=function() end}}
assert(loadfile("InspectCore.lua"))("InspectForEllesmereUI",ns)
hooks.NotifyInspect("target")
ReInspect("target")
LibStub:GetLibrary("LibEvent.7000"):event("INSPECT_READY","test-guid")
local scheduler=LibStub:GetLibrary("LibSchedule.7000")
assert(scheduler:SearchTask("ReInspect:test-guid") and scheduler:SearchTask("InspectReady:test-guid"),
    "initial inspect and reinspect tasks coexist for the same unit")
local scans={}
function info:GetUnitItemLevel(unit,values)
    scans[unit]=(scans[unit] or 0)+1
    values[STAT_CRITICAL_STRIKE]={value=100}
    return 0,321
end
assert(loadfile("InspectUnitStats.lua"))("InspectForEllesmereUI",ns)
local panel=CreateFrame("Frame")
panel.expandButton,panel.statsFrame=CreateFrame("Button"),CreateFrame("Frame")
panel.itemStats={[STAT_CRITICAL_STRIKE]={value=50}}
panel.itemLevel=321
local function findStat(key)
    for i=1,20 do
        local row=panel.statsFrame["stat"..i]
        if row and row.shown and row.Label.text==key then return row end
    end
end
ShowInspectItemStatsFrame(panel,"target")
assert(findStat(ITEM_MOD_INTELLECT_SHORT) and findStat(ITEM_MOD_STRENGTH_SHORT),
    "a mage inspecting a warrior sees both primary stats")
assert(not scans.target and scans.player==1,"target statistics reuse the sidebar snapshot")
for _,case in ipairs({{"PALADIN",65,ITEM_MOD_INTELLECT_SHORT},{"MONK",270,ITEM_MOD_INTELLECT_SHORT},
    {"SHAMAN",263,ITEM_MOD_AGILITY_SHORT},{"DEMONHUNTER",1480,ITEM_MOD_INTELLECT_SHORT}}) do
    targetClass,targetSpec=case[1],case[2]
    ShowInspectItemStatsFrame(panel,"target")
    assert(findStat(case[3]),"target specialization determines its primary stat")
    assert(not findStat(ITEM_MOD_STRENGTH_SHORT),"pooled rows clear old class stats")
end
restricted=true
panel.itemStats[STAT_CRITICAL_STRIKE].value=secret
ShowInspectItemStatsFrame(panel,"target")
assert(findStat(HEALTH).Value.text=="-" and findStat(LEVEL).Value.text=="-",
    "restricted levels and health use unknown placeholders")
assert(findStat(STAT_CRITICAL_STRIKE).Value.text=="-","restricted cached ratings never reach the UI")
function GetSpecializationInfoByID() return targetSpec,secret,nil,secret end
assert(loadfile("InspectUnitSpecialization.lua"))("InspectForEllesmereUI",ns)
local specializationPanel=CreateFrame("Frame")
specializationPanel.specicon,specializationPanel.spectext=CreateFrame("Texture"),CreateFrame("FontString")
hooks.ShowInspectItemListFrame("target",{inspectFrame=specializationPanel})
assert(not specializationPanel.specicon.shown and specializationPanel.spectext.text=="",
    "restricted target specialization text and icon clear safely")
if locale:sub(1,2)=="zh" then
    C_Item.GetItemStats=function() return nil end
    InspectForEllesmereUIDB.ShowPluginGreenState=true
    assert(loadfile("PluginGreenState.lua"))()
    LibStub:GetLibrary("LibEvent.7000"):trigger("INSPECT_ITEMFRAME_UPDATED",{link=link})
end
print("PASS audit "..locale.."; cross-class stats, cached scan, secret guards, duplicate item buttons and inspect tasks")
