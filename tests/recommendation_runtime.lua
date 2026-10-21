-- Lua 5.1 contract tests. Test fixtures never enter the game database or release.
local locale, skin = ...
function GetLocale() return locale end
local combat=false
function InCombatLockdown() return combat end
local secret={}
function issecretvalue(v) return v==secret end
local created=0
local frames={}
local methods={}
function methods:SetSize(w,h) self.width=w;self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return self.width or 560 end
function methods:GetHeight() return self.height or 600 end
function methods:GetRight() return 700 end
function methods:GetParent() return self.parent end
function methods:SetText(t) assert(t~=nil);self.text=t end
function methods:GetText() return self.text end
function methods:SetTexture(t) self.texture=t end
function methods:SetTextColor(...) self.color={...} end
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:HookScript(key,fn)
    local old=self.scripts[key]
    self.scripts[key]=function(...) if old then old(...) end;fn(...) end
end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function methods:Show() local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:Hide() local was=self.shown;self.shown=false;if was and self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:IsForbidden() return false end
function methods:CreateFontString() return setmetatable({scripts={},events={},shown=true},{__index=methods}) end
function methods:CreateTexture() return self:CreateFontString() end
for _,key in ipairs({"SetPoint","ClearAllPoints","SetScale","SetTexCoord","SetClampedToScreen","SetFrameStrata","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetJustifyH","SetJustifyV","SetEnabled","EnableMouseWheel","EnableMouse","SetNormalTexture","SetHighlightTexture","SetDesaturated","SetAllPoints","SetColorTexture","SetVertexColor","SetDrawLayer","SetShadowOffset","SetAtlas"}) do methods[key]=function() end end
function CreateFrame(kind,name,parent,template)
    created=created+1
    local f=setmetatable({parent=parent,scripts={},events={},shown=true},{__index=methods})
    frames[#frames+1]=f
    if name then _G[name]=f end
    return f
end
UIParent=CreateFrame("Frame");UIParent:SetSize(1920,1080)
UISpecialFrames={}
GameTooltip=setmetatable({lines={}},{__index=function(t,k)
    if k=="AddLine" or k=="AddDoubleLine" then return function(self,...) self.lines[#self.lines+1]={...} end end
    return function() end
end})
local tasks={}
C_Timer={NewTimer=function(_,fn)
    local timer={fn=fn};function timer:Cancel() self.cancelled=true end
    tasks[#tasks+1]=timer;return timer
end}
local function tick() local queue=tasks;tasks={};for _,t in ipairs(queue) do if not t.cancelled then t.fn() end end end
local event={listeners={}}
function event:attachTrigger(name,fn) self.listeners[name]=fn end
LibStub={GetLibrary=function() return event end}
local function trigger(name,...) event.listeners[name](nil,...) end
HEADSLOT="Head";NECKSLOT="Neck";SHOULDERSLOT="Shoulder";CHESTSLOT="Chest";WAISTSLOT="Waist";LEGSSLOT="Legs";FEETSLOT="Feet";WRISTSLOT="Wrist";HANDSSLOT="Hands";FINGER0SLOT="Ring 1";FINGER1SLOT="Ring 2";TRINKET0SLOT="Trinket 1";TRINKET1SLOT="Trinket 2";BACKSLOT="Back";MAINHANDSLOT="Main hand";SECONDARYHANDSLOT="Off-hand"
function time() return 100 end
C_SpecializationInfo={GetSpecialization=function() return 1 end,GetSpecializationInfo=function() return 71,"Arms",nil,123 end,GetInspectSpecialization=function() return 71 end}
function GetSpecializationInfoByID() return 71,"Arms",nil,123 end
function UnitClass() return "Warrior","WARRIOR",1 end
CLASS_ICON_TCOORDS={WARRIOR={0,0.25,0,0.25}}
local loaded=true
local requests=0
local link="|Hitem:100:8017:0:0:0:0:0:0:80:71:0:16:1:900|h[Test]|h"
C_Item={GetItemInfo=function(id) if loaded then return "Localized item",link,4,300,nil,nil,nil,nil,nil,123 end end,
    RequestLoadItemDataByID=function() requests=requests+1 end,
    GetItemCount=function() return 1 end}
C_TradeSkillUI={GetItemCraftedQualityByItemInfo=function() return 3 end,
    GetItemCraftedQualityInfo=function() return {quality=3,icon="Professions-ChatIcon-Quality-Tier3"} end}
function IsPlayerSpell() return true end
CR_CRIT_MELEE=1;CR_HASTE_MELEE=2;CR_MASTERY=3;CR_VERSATILITY_DAMAGE_DONE=4
function GetCombatRating() return 100 end
function GetInventoryItemLink() return nil end
function IsShiftKeyDown() return true end
local inserted=0
function ChatEdit_InsertLink() inserted=inserted+1 end
local ns={}
for _,lang in ipairs({"enUS","zhTW","zhCN","ruRU"}) do
    assert(loadfile("locales/"..lang..".lua"))("InspectForEllesmereUI",ns)
end
assert(ns.L.Other and ns.L.ShowInspectItemSetSummary and ns.L.LoadingGemInfo)
if locale=="zhCN" then assert(ns.L.Other=="其他界面")
elseif locale=="zhTW" then assert(ns.L.Other=="其他介面")
elseif locale=="ruRU" then assert(ns.L.Other=="Прочие окна")
else assert(ns.L.Other=="Other frames") end
local skinnedButtons=0
if skin then EllesmereUI={RegisterSkin=function(_,fn) fn({Shell=function() end,Inset=function() end,Panel=function() end,CloseButton=function() end,Font=function() end,OnLooksChanged=function() end,Button=function() skinnedButtons=skinnedButtons+1 end,SquareIcon=function() end}) end} end
assert(loadfile("EllesmereSkin.lua"))("InspectForEllesmereUI",ns)
for _,file in ipairs({"Locale","Compat","Core","Stats","Sources","Gear","Consumables","Panel"}) do assert(loadfile("Recommendation"..file..".lua"))("InspectForEllesmereUI",ns) end
local R=ns.Recommendations
assert(R.C.Number(secret)==nil)
local originalInventoryLink=GetInventoryItemLink
GetInventoryItemLink=function() return link end
assert(R.C.EquippedID(1)==100 and R.C.EquippedEnchantID(1)==8017)
for _,cache in ipairs({{[1]={}}, {}}) do
    assert(R.C.EquippedID(1,cache)==nil and R.C.EquippedEnchantID(1,cache)==nil,
        "target empty or missing snapshot entries never fall back to player equipment")
end
assert(R.C.EquippedID(1,{[1]={link=secret}})==nil and R.C.EquippedEnchantID(1,{[1]={link=secret}})==nil)
GetInventoryItemLink=originalInventoryLink
local originalSpecInfo=GetSpecializationInfoByID
GetSpecializationInfoByID=function() return 71,secret,nil,secret end
local safeSpec,safeSpecName,safeSpecIcon=R.C.Spec("target")
assert(safeSpec==71 and safeSpecName==nil and safeSpecIcon==nil,"restricted specialization display values are filtered")
GetSpecializationInfoByID=originalSpecInfo
C_Spell={GetSpellInfo=function(id)
    if id==1279599 then return {name="Localized trait name"} end
    if id==1286970 then return {name="Scraped effect spell"} end
end}
assert(R.C.OmniumName(1286970,"Scraped rune")=="Localized trait name")
C_Spell=nil
assert(R:ItemLabel(100,"Scraped English name")=="Localized item")
local tooltipLink
GameTooltip.SetHyperlink=function(_,value) tooltipLink=value end
R:GearTooltip({choices={{itemID=100}},slotName="Head"})
assert(tooltipLink==link,"Gear tooltip must receive the actual localized item link")
local owner=CreateFrame("Frame",nil,UIParent);owner.unit="player";owner.slotCache={[1]={link=link}}
owner.statsFrame=CreateFrame("Frame",nil,owner)
trigger("INSPECT_FRAME_CREATED",owner)
local count=created
trigger("INSPECT_FRAME_CREATED",owner)
assert(created==count,"duplicate button")
R:Open(owner)
assert(R.panel:IsShown() and R.reason==R.L.missing)
assert(R.panel.status:GetText()==R.L.missing and R.panel.status:IsShown(),"missing-data reason is visible")
assert(not owner.statsFrame:IsShown())
R.panel:Hide()
assert(owner.statsFrame:IsShown(),"stats panel not restored")
local range={median=100}
local item={itemID=100,usage=.8,count=40,sampleCount=50,bis=true}
local data={schemaVersion=1,seasonID=18,version="test only",sampleCount=50,updatedAt="test",statRanges={crit=range,haste=range,mastery=range,versatility=range},statOrder={"crit","haste","mastery","versatility"},gearSlots={},gems={{itemID=100,name="Test Gem"}},gemTables={primaryGems={{itemID=100,name="Gem A",usage=.56},{itemID=101,name="Gem B",usage=.25}},secondaryGems={{itemID=102,name="Gem C",usage=.55}}},omnium={talents={{spellId=100,name="Test Rune",row=0,selected=true,pickRate=.88,icon="test_icon.jpg"}}},embellishments={{itemID=100,name="Test Embellishment",usage=.5,count=25,sampleCount=50}}}
for _,slot in ipairs(R.slots) do data.gearSlots[slot[1]]={top3={item}} end
data.gearSlots[1].enchant={itemID=100,name="Test Enchant",enchantID=8017}
data.gearSlots[1].enchantList={{itemID=100,name="Ench A",usage=.53},{itemID=101,name="Ench B",usage=.29}}
local secondLink="|Hitem:101:0:0:0:0:0:0:0:80:71:0:16:1:900|h[Second]|h"
owner.slotCache[2]={link=secondLink}
data.gearSlots[2]={top3={{itemID=102,usage=.7,bis=true},{itemID=101,usage=.5,count=25,sampleCount=50}},enchant={itemID=100,name="Test Enchant",enchantID=8017}}
local label,median,current,diff=R:StatDisplay("crit",data,150)
assert(label and median==100 and current==150 and diff==50)
QFXGearData={schemaVersion=1,GetRecommendation=function() return data end,itemSources={}}
QFXGearData.itemSources[100]={{seasonID=18,sourceType="tier",sourceName="Scraped English set name"}}
assert(R:Source(100,data)==R.L.tier,"Class-set sources must use the selected locale")
QFXConsumableData={schemaVersion=1,GetRecommendation=function() return {seasonID=18,sampleCount=50,consumables={flask={{itemID=100,spellID=1,usage=1,count=50,sampleCount=50}},weaponOil={{itemID=100,usage=.85,count=42,sampleCount=50}}}} end}
R:Open(owner)
assert(R.data==data)
assert(not R.panel.status:IsShown() and R.panel.stats[1]:IsShown(),"loaded data clears the empty state")
assert(R.panel.gear[1].state:GetText()==R.L.bis)
assert(R.panel.updated:GetText()~="")
assert(R.panel.gear[1].enchantState=="match")
local row2
for _,r in ipairs(R.panel.gear) do if r.slot==2 then row2=r end end
--主图标显示推荐，当前已装备不同则放在副图标并按自己的名次标注。
assert(row2 and row2.state:GetText()==R.L.bis,"recommendation owns the main slot")
assert(row2.extra:IsShown() and row2.extra.state:GetText()==string.format(R.L.topN,2),
    "equipped item shows in the extra slot with its rank")
assert(row2.enchantState=="mismatch")
--成对槽位：推荐的戒指/饰品戴在另一格也算已装备（交换佩戴两行都应达标）。
local function ringLink(id) return "|Hitem:"..id..":0:0:0:0:0:0:0:80:71:0:16:1:900|h[Ring "..id.."]|h" end
data.gearSlots[11]={top3={{itemID=200,usage=.6,bis=true},{itemID=202,usage=.2}}}
data.gearSlots[12]={top3={{itemID=201,usage=.5},{itemID=202,usage=.2}}}
owner.slotCache[11]={link=ringLink(201)}
owner.slotCache[12]={link=ringLink(200)}
R:Refresh()
local row11,row12
for _,r in ipairs(R.panel.gear) do
    if r.slot==11 then row11=r elseif r.slot==12 then row12=r end
end
assert(row11 and row12,"ring rows exist")
assert(row11.state:GetText()==string.format(R.L.topN,1) and row12.state:GetText()==R.L.bis,
    "swapped rings count as equipped on both rows")
assert(not row11.extra:IsShown() and not row12.extra:IsShown(),
    "swapped optimal rings do not repeat the equipped items in extra slots")
assert(row11.choices==data.gearSlots[12].top3 and row12.choices==data.gearSlots[11].top3,
    "swapped recommendations keep the matching tooltip choices")
--戒指、饰品、主副手均按两格整体匹配；已达标的一格不遮掉另一格仍需替换的装备。
local originalItem=R.Item
function R:Item(id) return "Item "..id,ringLink(id),id end
for _,pair in ipairs({{11,12},{13,14},{16,17}}) do
    local first,second=pair[1],pair[2]
    local a,b=300+first,300+second
    local firstData={top3={{itemID=a,usage=.8,bis=true}}}
    local secondData={top3={{itemID=b,usage=.7,bis=true}}}
    local savedFirst,savedSecond=data.gearSlots[first],data.gearSlots[second]
    local savedEquipFirst,savedEquipSecond=owner.slotCache[first],owner.slotCache[second]
    data.gearSlots[first],data.gearSlots[second]=firstData,secondData
    local firstRow,secondRow
    for _,row in ipairs(R.panel.gear) do
        if row.slot==first then firstRow=row elseif row.slot==second then secondRow=row end
    end
    for _,swapped in ipairs({false,true}) do
        owner.slotCache[first]={link=ringLink(swapped and b or a)}
        owner.slotCache[second]={link=ringLink(swapped and a or b)}
        R:Refresh()
        assert(firstRow.link==owner.slotCache[first].link and secondRow.link==owner.slotCache[second].link,
            "paired main icons follow the equipped order")
        assert(firstRow.state:GetText()==R.L.bis and secondRow.state:GetText()==R.L.bis)
        assert(not firstRow.extra:IsShown() and not secondRow.extra:IsShown(),
            "both optimal items hide their extra slots in either order")
        tooltipLink=nil;R:GearTooltip(firstRow)
        assert(tooltipLink==firstRow.link,"paired tooltip follows the displayed item")
    end
    owner.slotCache[first]={link=ringLink(999)}
    owner.slotCache[second]={link=ringLink(a)}
    R:Refresh()
    assert(firstRow.link==ringLink(b) and firstRow.extra.link==ringLink(999) and firstRow.extra:IsShown(),
        "the remaining recommendation compares against the nonoptimal equipped item")
    assert(secondRow.link==ringLink(a) and not secondRow.extra:IsShown(),
        "one optimal item in the opposite slot satisfies only its matched row")
    local savedCount=C_Item.GetItemCount
    C_Item.GetItemCount=function() return 0 end
    R:Refresh()
    assert(firstRow.state:GetText()==R.L.notOwned and secondRow.state:GetText()==R.L.bis,
        "swapped matching still marks only the missing recommendation as not owned")
    C_Item.GetItemCount=savedCount
    owner.slotCache[first]=nil
    R:Refresh()
    assert(firstRow.link==ringLink(b) and not firstRow.extra:IsShown(),
        "an empty partner slot has no phantom equipped item")
    --BIS 可以位于使用率榜的第二/三名，不应再推荐替换成非 BIS 的 TOP1。
    firstData.top3={{itemID=a+100,usage=.9},{itemID=a,usage=.8,bis=true}}
    owner.slotCache[first]={link=ringLink(a)}
    owner.slotCache[second]={link=ringLink(b)}
    R:Refresh()
    assert(firstRow.link==ringLink(a) and firstRow.state:GetText()==R.L.bis and not firstRow.extra:IsShown(),
        "an equipped BIS below Top1 is already optimal")
    --两格都推荐同一件时，一件已装备物品不能同时隐藏另一格的对照。
    secondData.top3=firstData.top3
    owner.slotCache[second]={link=ringLink(999)}
    R:Refresh()
    assert(not firstRow.extra:IsShown() and secondRow.extra:IsShown(),
        "duplicate recommendation IDs still require a separate equipped copy per row")
    assert(data.gearSlots[first]==firstData and data.gearSlots[second]==secondData,
        "matching never rewrites source slot data")
    --换推荐顺序不换物理附魔栏位；隐藏副图标后星号跟回主图标。
    firstData.top3={{itemID=a,bis=true}}
    secondData.top3={{itemID=b,bis=true}}
    firstData.enchant={itemID=100,enchantID=8017}
    secondData.enchant={itemID=101,enchantID=8020}
    owner.slotCache[first]={link=ringLink(b):gsub(":0:",":8020:",1)}
    owner.slotCache[second]={link=ringLink(a):gsub(":0:",":8017:",1)}
    local firstAnchor
    local savedSetPoint=firstRow.star.SetPoint
    firstRow.star.SetPoint=function(_,_,anchor) firstAnchor=anchor end
    R:Refresh()
    firstRow.star.SetPoint=savedSetPoint
    assert(firstRow.enchant==firstData.enchant and secondRow.enchant==secondData.enchant
        and firstRow.enchantState=="mismatch" and secondRow.enchantState=="mismatch",
        "enchant checks remain attached to the physical equipment slots")
    assert(firstAnchor==firstRow,"the enchant star follows the main icon when the extra icon is hidden")
    data.gearSlots[second]=nil
    R:Refresh()
    assert(firstRow.choices==firstData.top3 and #secondRow.choices==0,
        "a missing partner recommendation never borrows a main-hand-only list")
    data.gearSlots[first],data.gearSlots[second]=savedFirst,savedSecond
    owner.slotCache[first],owner.slotCache[second]=savedEquipFirst,savedEquipSecond
end
R.Item=originalItem
--同一饰品推荐两格但只戴一个：只有真正戴着的那格算达标。
data.gearSlots[13]={top3={{itemID=203,usage=.7,bis=true}}}
data.gearSlots[14]={top3={{itemID=203,usage=.7,bis=true}}}
owner.slotCache[13]={link=ringLink(203)}
owner.slotCache[14]={link=ringLink(999)}
R:Refresh()
local row13,row14
for _,r in ipairs(R.panel.gear) do
    if r.slot==13 then row13=r elseif r.slot==14 then row14=r end
end
assert(row13.state:GetText()==R.L.bis,"worn copy matches its own slot")
assert(row14.state:GetText()==R.L.bis,
    "the recommendation worn in the partner slot is not reported as missing")
assert(row14.extra:IsShown() and row14.extra.state:GetText()==R.L.unlisted,
    "the actually worn item stays in the extra slot")
--推荐物品既不在身上也不在背包时，未获取标在主图标（推荐），装备放在副图标。
local originalCount=C_Item.GetItemCount
C_Item.GetItemCount=function(id) return id==204 and 0 or 1 end
data.gearSlots[5]={top3={{itemID=204,usage=.8,bis=true}}}
owner.slotCache[5]={link=ringLink(205)}
R:Refresh()
local row5
for _,r in ipairs(R.panel.gear) do if r.slot==5 then row5=r end end
assert(row5 and row5.state:GetText()==R.L.notOwned,"not-owned recommendation marks the main slot")
assert(row5.extra:IsShown() and row5.extra.state:GetText()==R.L.unlisted,
    "the equipped item stays in the extra slot")
C_Item.GetItemCount=originalCount
owner.slotCache[5]=nil
local savedLegData,savedLegItem=data.gearSlots[7],owner.slotCache[7]
data.gearSlots[7]={top3={{itemID=301,usage=.9},{itemID=302,usage=.8,bis=true}}}
owner.slotCache[7]={link=ringLink(302)}
R:Refresh()
local legRow
for _,row in ipairs(R.panel.gear) do if row.slot==7 then legRow=row end end
assert(legRow.state:GetText()==R.L.bis and not legRow.extra:IsShown(),
    "a single-slot BIS at rank 2 is not replaced by non-BIS Top1")
data.gearSlots[7],owner.slotCache[7]=savedLegData,savedLegItem
assert(R:Source(100,nil)==R.L.unknownSource,"missing source data uses the unknown label")
assert(R:StatDisplay("future_stat",nil)=="future_stat  —","unknown statistic keys have a safe label")
local savedStatOrder=data.statOrder
data.statOrder={"crit","future_stat","haste"}
R:Refresh()
assert(R.panel.statOrder:GetText()==R.L.crit..">"..R.L.haste,"unknown stat-order entries are skipped")
data.statOrder=savedStatOrder
R:Refresh()
--侧栏徽章同样按成对槽位查找名次。
local badge,ranked=R:GearBadge(data.gearSlots,12,ringLink(200))
assert(badge==R.L.bis and ranked,"partner-slot bis earns the badge")
badge,ranked=R:GearBadge(data.gearSlots,11,ringLink(999))
assert(badge==R.L.unrankedShort and not ranked,"unlisted items stay gray")
owner.slotCache[11]=nil;owner.slotCache[12]=nil;owner.slotCache[13]=nil;owner.slotCache[14]=nil
assert(R.panel.stats[1].current==100 and R.panel.stats[1].median==100)
assert(R.panel.consumableColumns[1].rows[1].quality:IsShown())
assert(R.panel.gear[1].star:IsShown())
assert(R.panel.gear[1].star.enchantList and R.panel.gear[1].star.enchantList[1])
assert(row2.star:IsShown())
assert(R.panel.gems[1]:IsShown() and not R.panel.gems[4]:IsShown())
assert(R.panel.omniumIcons[1]:IsShown() and not R.panel.omniumIcons[2]:IsShown())
assert(R.panel.omniumIcons[1].mark:GetText()==R.L.spellOn)
assert(R.panel.weaponBuff:IsShown())
R:EnchantTooltip(R.panel.gear[1].star)
assert(R.panel.statOrder:GetText()==(R.L.crit..">"..R.L.haste..">"..R.L.mastery..">"..R.L.versatility))
R:StatTooltip(R.panel.stats[1])
R:GearTooltip(R.panel.gear[1])
R:ConsumableTooltip(R.panel.consumableColumns[1].rows[1])
local sidebarRefreshes=0
function ShowInspectItemListFrame(unit,parent)
    assert(unit==owner.unit and parent==UIParent,"Refresh the visible sidebar's own unit and parent")
    sidebarRefreshes=sidebarRefreshes+1
end
R.panel.tabs.raid.scripts.OnClick()
assert(R.mode=="raid" and sidebarRefreshes==1,"Changing recommendation mode also refreshes sidebars")
local coreEvents
for _,frame in ipairs(frames) do if frame.events.PLAYER_SPECIALIZATION_CHANGED then coreEvents=frame end end
assert(coreEvents)
local originalRating=GetCombatRating
GetCombatRating=function() return 150 end
coreEvents.scripts.OnEvent(coreEvents,"COMBAT_RATING_UPDATE")
tick()
assert(R.panel.stats[1].current==150,"a rating event refreshes the open personal comparison")
GetCombatRating=originalRating
coreEvents.scripts.OnEvent(coreEvents,"PLAYER_EQUIPMENT_CHANGED",1)
tick()
assert(R.panel.stats[1].current==100,"equipment updates recalculate the comparison")
combat=true
coreEvents.scripts.OnEvent(coreEvents,"PLAYER_SPECIALIZATION_CHANGED","player")
assert(R.sidebarDirty and sidebarRefreshes==1,"Specialization refresh is deferred during combat")
combat=false
coreEvents.scripts.OnEvent(coreEvents,"PLAYER_REGEN_ENABLED")
assert(not R.sidebarDirty and sidebarRefreshes==2,"Deferred sidebar refresh runs after combat")
ShowInspectItemListFrame=nil
R.panel.gear[1].scripts.OnClick(R.panel.gear[1]);assert(inserted==1)
local before=created
for i=1,20 do R:Refresh();R:RequestRefresh() end
assert(#tasks==1,"refresh not coalesced")
tick();assert(created==before,"refresh allocated new frames")
loaded=false
assert(R:ItemLabel(100,"Scraped English name")==string.format(R.L.itemLoading,100))
assert(R:EffectLabel({itemID=100,name="Scraped effect"})==string.format(R.L.itemLoading,100))
local combination=R:EmbellishmentName({itemID=100,itemID2=101,name="English A",name2="English B"})
assert(combination==string.format(R.L.itemLoading,100).." / "..string.format(R.L.itemLoading,101))
R:StopRefresh();R:Refresh();local requested=requests
R:Refresh();assert(requests==requested,"repeated item loads")
assert(requested>0)
R:RequestRefresh();R.panel:Hide();tick();assert(not R.pending)
loaded=true
R:Open(owner);combat=true
before=created
R:RequestRefresh();R:Refresh()
assert(created==before and R.dirty)
combat=false
owner:Hide();assert(not R.panel:IsShown())
owner:Show();owner.unit="target";R:Open(owner);assert(not R.personal)
data.expiresAt=99;R:Refresh();assert(not R.data and R.reason==R.L.expired)
assert(R.panel.status:GetText()==R.L.expired and not R.panel.stats[1]:IsShown(),"expired-data reason is visible")
data.expiresAt=nil;QFXGearData.schemaVersion=999;R:Refresh();assert(R.reason==R.L.incompatible)
assert(R.panel.status:GetText()==R.L.incompatible,"incompatible-data reason is visible")
local traitLookups=0
C_Traits={GetConfigIDBySystemID=function(system)
    traitLookups=traitLookups+1
    if system==1 then return 1 end
end,GetConfigInfo=function() return {treeIDs={1}} end,GetTreeNodes=function() return {1} end,
    GetNodeInfo=function() return {entryIDs={1},entryIDsWithCommittedRanks={1}} end,
    GetEntryInfo=function() return {definitionID=1} end,GetDefinitionInfo=function() return {spellID=555} end}
R.C.InvalidateTraitSelection()
assert(R.C.TraitSelection({[555]=true})[555])
local cachedLookups=traitLookups
assert(R.C.TraitSelection({[555]=true})[555] and traitLookups==cachedLookups,
    "unchanged talent selection uses the cached result")
coreEvents.scripts.OnEvent(coreEvents,"TRAIT_CONFIG_UPDATED",1)
assert(R.C.TraitSelection({[555]=true})[555] and traitLookups>cachedLookups,
    "trait updates invalidate the selection cache")
assert(R.C.TraitSelection({[556]=true})==nil)
cachedLookups=traitLookups
assert(R.C.TraitSelection({[556]=true})==nil and traitLookups==cachedLookups,
    "a missing trait system is not scanned again on every refresh")
C_Traits=nil;R.C.InvalidateTraitSelection()
if TEST_READ_ADDON then
    R.panel:Hide()
    local realLike=TEST_REAL_DATA or TEST_AGGREGATE_DATA
    local function loadAddon(addon)
        assert(loadstring(TEST_READ_ADDON(addon),addon))()
        return true
    end
    C_AddOns={LoadAddOn=loadAddon}
    loadAddon("QFXGearData");loadAddon("QFXConsumableData")
    local manifest=QFXGearData:GetMetadata()
    assert(manifest.internalTest)
    assert(realLike and not manifest.testData or not realLike and manifest.testData)
    local datasetCount,sampleCount=0,0
    before=created
    owner.unit="player"
    for key in pairs(manifest.modules) do
        local spec,mode=key:match("^(%d+):(.+)$")
        spec=tonumber(spec)
        C_SpecializationInfo.GetSpecializationInfo=function() return spec,"Mock specialization",nil,123 end
        R.mode=mode
        if not R.panel:IsShown() then R:Open(owner) else R:Refresh() end
        assert(R.data and R.data.sampleCount>0 and (realLike or R.data.sampleCount<=50),key)
        assert(realLike and not R.data.testData or not realLike and R.data.testData)
        local consumables=R:GetConsumables(spec,mode,R.data.seasonID)
        assert(consumables and consumables.sampleCount==R.data.sampleCount)
        R:Refresh()
        for _,row in ipairs(R.panel.gear) do R:GearTooltip(row) end
        for _,row in ipairs(R.panel.stats) do R:StatTooltip(row) end
        for _,col in ipairs(R.panel.consumableColumns) do
            for _,row in ipairs(col.rows) do R[row.tooltip](R,row) end
        end
        datasetCount=datasetCount+1;sampleCount=sampleCount+R.data.sampleCount
    end
    if not TEST_REAL_DATA then assert(datasetCount==80) end
    if not realLike then assert(sampleCount==4000) end
    assert(created==before,"dataset changes allocated frames")
    R.panel:Hide();tick()
    print("PASS generated Lua databases: "..datasetCount.." datasets / "..sampleCount..(TEST_REAL_DATA and " real" or TEST_AGGREGATE_DATA and " aggregate" or " synthetic").." samples; zero added UI frames")
end
if skin then assert(skinnedButtons>=3,"recommendation buttons missed EllesmereUI bridge") end
print("PASS "..locale.." "..(skin and "EllesmereUI" or "native").."; "..created.." frames, bounded allocations")
