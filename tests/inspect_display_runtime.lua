-- Regression coverage for item prefixes, socket hydration and pooled gem frames.
local locale, useSkin = ...
local ns = {}
local clock, combat, created = 0, false, 0
function GetLocale() return locale end
function GetTime() return clock end
function time() return 100 end
function InCombatLockdown() return combat end
function issecretvalue() return false end
strmatch = string.match
format = string.format
tinsert, tremove = table.insert, table.remove
min, max, floor, abs = math.min, math.max, math.floor, math.abs
UNIT_NAME_FONT = "stock.ttf"
EMPTY, EMPTY_SOCKET_PRISMATIC = "Empty", "Prismatic socket"
ENCHANTED_TOOLTIP_LINE = locale=="zhCN" and "附魔：%s" or locale=="zhTW" and "附魔：%s" or "Enchanted: %s"
Enum={TooltipDataLineType={ItemEnchantmentPermanent=15}}
RAID_CLASS_COLORS = {WARRIOR = {r=1, g=0.8, b=0.5}}
NORMAL_FONT_COLOR = {r=1, g=1, b=1}
for _, slot in ipairs({"HEAD","NECK","SHOULDERS","CHEST","WAIST","LEGS","FEET","WRIST","HANDS","FINGER0","FINGER1","TRINKET0","TRINKET1","BACK","MAINHAND","SECONDARYHAND"}) do
    _G[slot .. "SLOT"] = slot
end
local frames, methods = {}, {}
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:SetWidth(w) self.width=w end
function methods:SetHeight(h) self.height=h end
function methods:GetWidth() return (self.width and self.width>0) and self.width or self:GetStringWidth() end
function methods:GetHeight() return self.height or 500 end
function methods:GetEffectiveScale() return 0.8 end
function methods:GetStringWidth()
    local text=(self.text or ""):gsub("|H.-|h",""):gsub("|h",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|A:.-|a","Q")
    local width=0
    for character in text:gmatch(".") do width=width+(character=="1" and 2 or character=="4" and 6 or 5) end
    return text~="" and width+2 or 0
end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text end
function methods:SetFont(path,size,flags) self.font=path; self.fontSize=size; self.flags=flags end
function methods:GetFont() return self.font or "stock.ttf", self.fontSize or 14, self.flags or "" end
function methods:SetScript(event,fn) self.scripts[event]=fn end
function methods:HookScript(event,fn)
    local old=self.scripts[event]
    self.scripts[event]=function(...) if old then old(...) end; fn(...) end
end
function methods:IsShown() return self.shown and (not self.parent or self.parent:IsShown()) end
function methods:Show() self.shown=true end
function methods:Hide()
    self.shown=false
    if self.scripts.OnHide then self.scripts.OnHide(self) end
end
function methods:SetTexture(t) self.art=t; self.atlas=nil end
function methods:SetAtlas(atlas) self.atlas=atlas end
function methods:SetBackdrop(backdrop) self.backdrop=backdrop end
function methods:SetBackdropColor(...) self.bgColor={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:GetBackdrop() return self.backdrop end
function methods:GetBackdropColor() return 0,0,0,0.2 end
function methods:GetParent() return self.parent end
function methods:IsForbidden() return false end
function methods:GetFrameLevel() return 0 end
function methods:CreateTexture() return CreateFrame("Texture",nil,self) end
function methods:CreateFontString() return CreateFrame("FontString",nil,self) end
function methods:SetNormalTexture(art) self.normal=self:CreateTexture(); self.normal:SetTexture(art) end
function methods:GetNormalTexture() return self.normal end
function methods:SetPoint(...) self.point={...} end
function methods:SetJustifyV(value) self.justifyV=value end
function methods:SetJustifyH(value) self.justifyH=value end
function methods:SetTextColor(...) self.textColor={...} end
function methods:SetVertexColor(...) self.vertexColor={...} end
for _, method in ipairs({"SetFrameLevel","SetScale","ClearAllPoints","SetTexCoord","SetWordWrap","SetAllPoints","SetAlpha","SetLevel","RegisterEvent","EnableMouse"}) do
    methods[method]=function() end
end
function CreateFrame(kind,name,parent,template)
    created=created+1
    local frame=setmetatable({parent=parent,shown=true,scripts={}}, {__index=methods})
    frames[#frames+1]=frame
    if name then _G[name]=frame end
    if template=="GarrisonFollowerPortraitTemplate" then
        frame.PortraitRingQuality=frame:CreateTexture()
        frame.LevelBorder=frame:CreateTexture()
        frame.Portrait=frame:CreateTexture()
    end
    return frame
end
function hooksecurefunc(name,fn)
    local old=_G[name]
    _G[name]=function(...)
        local result=old(...)
        fn(...)
        return result
    end
end
function SetPortraitTexture() end
function UnitClass() return "Warrior","WARRIOR" end
function UnitLevel() return 90 end
function UnitName() return "Tester" end
UIParent=CreateFrame("Frame")
PaperDollFrame=CreateFrame("Frame")
CharacterFrame=CreateFrame("Frame")
GameTooltip={lines={}, SetOwner=function() end, SetText=function() end, SetHyperlink=function() end, Show=function() end, Hide=function() end,
    AddLine=function(self,text) self.lines[#self.lines+1]=text end}
local function itemLink(id, suffix) return "|cffa335ee|Hitem:"..id..":0:"..(suffix or "0:0:0:0").."|h[Item "..id.."]|h|r" end
local inventory={player={[1]=itemLink(100,"201:202:0:0"),[2]=itemLink(101),[16]=itemLink(102)},
    target={[1]=itemLink(103,"0:203:0:0")}}
function GetInventoryItemLink(unit,slot) return inventory[unit] and inventory[unit][slot] end
local equipment={
    [100]={sockets=2, gems={201,202}, track="Hero",current=6,maximum=6},
    [101]={sockets=0,level=334}, [102]={sockets=0,crafted=2,level=331},
    [103]={sockets=2,gems={0,203}}, [104]={sockets=0},
    [105]={sockets=1,gems={204}}, [106]={sockets=0,track="Myth"},
}
local loaded, requested = {}, {}
local enchantNames={}
C_TooltipInfo={GetInventoryItem=function(unit,slot)
    local link=GetInventoryItemLink(unit,slot)
    local id=link and tonumber(link:match("item:%d+:(%d+)"))
    local text=enchantNames[id]
    return {dataInstanceID=7001, lines=text and {{type=1,leftText="|cff00ff00"..format(ENCHANTED_TOOLTIP_LINE,text).."|r"}} or {}}
end}
local function idOf(item) return type(item)=="number" and item or tonumber(item:match("item:(%d+)")) end
C_Item={}
C_LootJournal={}
function C_Item.GetItemInfo(item)
    local id=idOf(item)
    if not equipment[id] and not loaded[id] then return end
    return "Item "..id,itemLink(id),4,321,nil,nil,nil,nil,nil,1000+id
end
function C_Item.GetItemStats(link)
    local item=equipment[idOf(link)]
    if item.missingStats then return end
    return item.sockets>0 and {EMPTY_SOCKET_PRISMATIC=item.sockets} or {}
end
function C_Item.GetItemGemID(link,index)
    local id=idOf(link)
    local item=equipment[id]
    -- Generic GetItemInfo links deliberately lack instance gem data.
    if link==itemLink(id) then return end
    return item.gems and item.gems[index]
end
function C_Item.GetItemGem(link,index)
    local id=C_Item.GetItemGemID(link,index)
    if id and id>0 and loaded[id] then return "Gem "..id,itemLink(id) end
end
function C_Item.GetItemIconByID(item) return 1000+idOf(item) end
function C_Item.RequestLoadItemDataByID(id) requested[id]=(requested[id] or 0)+1 end
function C_Item.GetItemUpgradeInfo(link)
    local item=equipment[idOf(link)]
    if item.track then return {trackString=item.track,currentLevel=item.current,maxLevel=item.maximum} end
end
function C_Item.GetItemQualityColor() return 1,0.82,0 end
C_TradeSkillUI={GetItemCraftedQualityInfo=function(link)
    local quality=equipment[idOf(link)].crafted
    if quality then return {quality=quality,iconChat="Professions-ChatIcon-Quality-Tier"..quality} end
end}
InspectForEllesmereUIDB={ShowGemAndEnchant=true, ShowUpgradeInfo=true}
assert(loadfile("libs/LibStub.lua"))()
assert(loadfile("libs/LibEvent.lua"))()
assert(loadfile("libs/LibSchedule.lua"))()
assert(loadfile("libs/LibItemGem.lua"))()
local itemInfo=LibStub:NewLibrary("LibItemInfo.7000",8)
function itemInfo:GetUnitItemInfo(unit,slot)
    local link=inventory[unit] and inventory[unit][slot]
    if link then return 0,equipment[idOf(link)].level or 321,C_Item.GetItemInfo(link) end
    return 0,0
end
local event=LibStub:GetLibrary("LibEvent.7000")
local schedule=LibStub:GetLibrary("LibSchedule.7000")
local function HasTask(key)
    local tasks=schedule:SearchTask(key)
    return tasks and #tasks>0
end
local gems=LibStub:GetLibrary("LibItemGem.7000")
if useSkin then
    EllesmereUI={RegisterSkin=function(_,fn)
        fn({Shell=function() end,Inset=function() end,Panel=function() end,CloseButton=function() end,
            Font=function(fs) fs:SetFont("eui.ttf",select(2,fs:GetFont()),"") end})
    end,PP={
        perfect=1,
        SnapForES=function(value,scale) return math.floor(value*scale+0.5+0.001)/scale end,
    },PanelPP={
        CreateBorder=function(frame,...) frame.ppBorder=frame.ppBorder or {...} end,
        SetBorderColor=function(frame,...) frame.ppColor={...} end,
    }}
end
for _,lang in ipairs({"enUS","zhTW","zhCN","ruRU"}) do
    assert(loadfile("locales/"..lang..".lua"))("InspectForEllesmereUI",ns)
end
assert(loadfile("EllesmereSkin.lua"))("InspectForEllesmereUI",ns)
assert(loadfile("InspectUnit.lua"))("InspectForEllesmereUI",ns)
assert(loadfile("InspectUnitGemAndEnchant.lua"))("InspectForEllesmereUI",ns)
C_SpecializationInfo={GetSpecialization=function() return 1 end,GetSpecializationInfo=function() return 71,"Arms",nil,123 end,
    GetInspectSpecialization=function() return 72 end}
function GetSpecializationInfoByID() return 72,"Fury",nil,123 end
for _,module in ipairs({"Locale","Compat","Core","Gear"}) do assert(loadfile("Recommendation"..module..".lua"))("InspectForEllesmereUI",ns) end
local recommendations=ns.Recommendations
local function tick(delta)
    clock=clock+delta
    local count=#frames
    for i=1,count do
        local fn=frames[i].scripts.OnUpdate
        if fn then fn(frames[i],delta) end
    end
end
local parent=CreateFrame("Frame")
local panel=ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item1.link==inventory.player[1],"Inventory instance link must survive GetItemInfo")
assert(panel.item1.itemString.text:find("[Hero 6/6]",1,true),"Upgrade track")
assert(panel.item2.itemString.text:find((ns.L and ns.L.NoUpgradeTrack) or "No upgrade track",1,true))
assert(panel.item15.itemString.text:find((ns.L and ns.L.CraftedEquipment) or "Crafted",1,true))
local qualitySize=useSkin and 11 or 14
assert(panel.item15.itemString.text:find("|A:Professions-ChatIcon-Quality-Tier2:"..qualitySize..":"..qualitySize.."|a",1,true))
assert(panel.item1.levelDigits[1].text=="3" and panel.item1.levelDigits[2].text=="2" and panel.item1.levelDigits[3].text=="1","First row renders all item-level digits")
assert(panel.item2.levelDigits[1].text=="3" and panel.item2.levelDigits[2].text=="3" and panel.item2.levelDigits[3].text=="4","Different proportional-width numbers retain their values")
assert(panel.item1.levelString:GetStringWidth()~=panel.item2.levelString:GetStringWidth(),"Fixture reproduces the proportional-font width mismatch")
local firstDigit,secondDigit=panel.item1.levelDigits[1],panel.item1.levelDigits[2]
local digitPitch=secondDigit.point[4]-firstDigit.point[4]
assert(digitPitch<firstDigit:GetWidth(),"Repeated-run advance avoids single-character boundary padding between digits")
assert(digitPitch<=ns.Skin.Pixel((6*10+2)/10,panel,"ceil"),"Digit pitch reserves no additional even-pixel padding")
assert(panel.item1.badgeString.point[4]-panel.item1.levelString.point[4]-panel.item1.levelString:GetWidth()<=3.5,"Compact gap between item level and recommendation badge")
local rowPixels=panel.item1:GetHeight()*(useSkin and panel:GetEffectiveScale() or 1)
assert(rowPixels%2==0,"Row centers stay on the same physical pixel grid")
for i=1,16 do
    local row=panel["item"..i]
    assert(row:GetHeight()==panel.item1:GetHeight(),"Uniform row spacing")
    assert(row.levelString:GetWidth()==panel.item1.levelString:GetWidth(),"Shared item-level column")
    assert(row.width==row.itemString.point[4]+row.itemString:GetWidth(),"Each row reserves only its own displayed name width")
    assert(row.itemString.point[4]==panel.item1.itemString.point[4],"Names start in the same column")
    assert(row.itemString.justifyV=="MIDDLE" and row.levelString.justifyV=="MIDDLE" and row.label.text.justifyV=="MIDDLE","Shared vertical text alignment")
    for digitIndex=1,3 do
        local digit=row.levelDigits[digitIndex]
        local reference=panel.item1.levelDigits[digitIndex]
        assert(digit:GetWidth()==reference:GetWidth() and digit.point[4]==reference.point[4],"Digits occupy identical cell positions across every row")
        assert(digit.justifyH=="CENTER" and digit.justifyV=="MIDDLE","Digits share centered placement")
    end
end
assert(panel.xicon1.texture.art==1201 and panel.xicon2.texture.art==1202,"Uncached gems render through gem IDs")
assert(panel.xicon1.itemLink=="item:201" and requested[201]==1)
assert(panel:GetWidth()>=panel.item1.width+4+16*2+2+36,"All filled gems reserve width")
if useSkin then assert(panel.xicon1.ppBorder and panel.xicon1.ppBorder[5]==2,"Use EUI pixel borders") end
local compactParent=CreateFrame("Frame")
compactParent:SetHeight(424)
local compact=ShowInspectItemListFrame("player",compactParent,321,321)
assert(-compact.item1.point[5]+16*compact.item1:GetHeight()<=compact:GetHeight()-10,"Pixel-aligned rows fit the minimum panel height")
compact:Hide()
loaded[201],loaded[202]=true,true
event:event("GET_ITEM_INFO_RECEIVED",201,true)
tick(0.25)
assert(panel.xicon1.itemLink==itemLink(201),"Hydration updates gem tooltip")
inventory.player[2]=itemLink(105,"204:0:0:0")
panel=ShowInspectItemListFrame("player",parent,321,321)
assert(panel.xicon1.point[2]==panel.item1.itemString and panel.xicon3.point[2]==panel.item2.itemString,"First socket follows each equipment name")
assert(panel.xicon1.point[3]=="RIGHT" and panel.xicon1.point[4]==4,"Compact spacing after names")
assert(panel.xicon2.point[2]==panel.xicon1 and panel.xicon2.point[3]=="RIGHT","Additional sockets retain their horizontal spacing")
inventory.player[2]=itemLink(101)
ShowInspectItemListFrame("player",parent,321,321)
local otherParent=CreateFrame("Frame")
local other=ShowInspectItemListFrame("target",otherParent,321,321)
assert(other.xicon1.texture.atlas=="socket-prismatic" and other.xicon2.texture.art==1203,"Noncontiguous sockets preserve order")
assert(HasTask(other.gemTaskKey))
panel:Hide()
assert(HasTask(other.gemTaskKey),"Hiding one panel must not cancel another")
panel=ShowInspectItemListFrame("player",parent,321,321)
assert(panel.xicon1:IsShown(),"Reopen shows cached gems")
inventory.player[1]=itemLink(105,"204:0:0:0")
panel=ShowInspectItemListFrame("player",parent,321,321)
assert(HasTask(panel.gemTaskKey),"New task starts even while removed task is pending cleanup")
assert(panel.xicon1.texture.art==1204 and not panel.xicon2:IsShown(),"Replacing gear clears extra old gems")
inventory.player[1]=itemLink(104)
event:event("UNIT_INVENTORY_CHANGED","player")
tick(0.25)
assert(not panel.xicon1:IsShown(),"No gems remain after changing to unsocketed gear")
loaded[203]=true
event:event("ITEM_DATA_LOAD_RESULT",203,true)
tick(4.1)
assert(other.xicon1.title==EMPTY_SOCKET_PRISMATIC and other.xicon2.itemLink==itemLink(203),"Real empty socket settles")
assert(not HasTask(other.gemTaskKey),"Socket retry terminates")
local allocated=created
for i=1,20 do
    ShowInspectItemListFrame("target",otherParent,321,321)
    tick(4.1)
end
assert(created==allocated,"Repeated refreshes reuse icon frames")
ShowInspectItemListFrame("target",otherParent,321,321)
tick(5.5)
assert(other.xicon1.title==EMPTY_SOCKET_PRISMATIC,"Expired retry also settles empty socket state")
other:Hide()
tick(0.25)
event:event("GET_ITEM_INFO_RECEIVED",203,true)
assert(not HasTask(other.gemTaskKey),"Closed panels do not refresh")
local count,info=gems:GetItemGemInfo(inventory.target[1])
assert(count==2 and info[2].link==itemLink(203))
equipment[103].missingStats=true
count,info=gems:GetItemGemInfo(inventory.target[1])
assert(count==2 and info[2].link==itemLink(203),"Missing item stats must not prevent filled gem display")
equipment[103].missingStats=false
inventory.player[2]=itemLink(106)
panel=ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item2.itemString.text:find("[Myth]",1,true),"Track-only info stays valid")
InspectForEllesmereUIDB.ShowUpgradeInfo=false
panel=ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item15.itemString.text==inventory.player[16],"Disabled prefix setting remains respected")
inventory.player[16]=itemLink(102):gsub("item:102:0:","item:102:9001:")
ShowInspectItemListFrame("player",parent,321,321)
local enchantPanel=panel.item15.enchantFrame
assert(enchantPanel and enchantPanel:IsShown(),"Actual enchanted gear gets an enchant display")
assert(enchantPanel.currentEnchantText==((ns.L and ns.L.EnchantedEquipment) or "Enchanted"),"Pending enchant is not marked missing")
assert(enchantPanel.tex.atlas=="PetJournal-FavoritesIcon" and enchantPanel:GetWidth()==16,"Reuse the recommendation star at a compact size")
assert(enchantPanel.enchantState=="unknown" and enchantPanel.tex.vertexColor[2]==0.85,"Unavailable recommendations do not produce a false mismatch")
assert(panel.enchantWaitTooltips[7001] and HasTask(panel.gemTaskKey))
enchantNames[9001]="Radiant Power |A:Professions-ChatIcon-Quality-Tier2:14:14|a"
event:event("TOOLTIP_DATA_UPDATE",7001)
tick(0.25)
assert(enchantPanel.currentEnchantText==enchantNames[9001],"Tooltip hydration resolves localized enchant name and preserves quality atlas")
assert(enchantPanel.itemLink==inventory.player[16],"Enchant hover uses the equipped instance link")
assert(panel:GetWidth()>=panel.item15.width+enchantPanel:GetWidth()+4+36,"Reserve enchant width")
inventory.player[1]=itemLink(100,"201:202:0:0"):gsub("item:100:0:","item:100:9001:")
ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item1.enchantFrame.point[2]==panel.xicon2 and enchantPanel.point[2]==panel.item15.itemString,"Stars follow the final gem or the item name")
assert(panel.item1.enchantFrame.point[3]=="RIGHT" and panel.item1.enchantFrame.point[5]==0,"Stars retain vertical centering")
inventory.player[1]=itemLink(104)
ShowInspectItemListFrame("player",parent,321,321)
assert(enchantPanel.point[2]==panel.item15.itemString,"No empty gem column before an enchant")
if useSkin then
    EllesmereUI.GetEnchantText=function() return "EUI enchant name" end
    inventory.player[16]=itemLink(102):gsub("item:102:0:","item:102:9002:")
    ShowInspectItemListFrame("player",parent,321,321)
    assert(enchantPanel.currentEnchantText=="EUI enchant name","Use the installed EUI enchant helper")
    EllesmereUI.GetEnchantText=nil
end
inventory.player[16]=itemLink(102)
ShowInspectItemListFrame("player",parent,321,321)
assert(not enchantPanel:IsShown(),"Removing the enchant clears the old label")
local enchantFrames=created
inventory.player[16]=itemLink(102):gsub("item:102:0:","item:102:9001:")
for i=1,10 do ShowInspectItemListFrame("player",parent,321,321) end
assert(created==enchantFrames and enchantPanel:IsShown(),"Enchant labels are pooled")

local function dataset(slots)
    return {sampleCount=100,statRanges={},gearSlots=slots}
end
local playerData=dataset({[1]={top3={{itemID=104,bis=true}}},[2]={top3={{itemID=106}}},
    [16]={top3={{itemID=999},{itemID=102}},enchant={itemID=300,enchantID=9001},enchantList={{itemID=300,name="Recommended",usage=1}}}})
local targetData=dataset({[1]={top3={{itemID=103}},enchant={itemID=301,enchantID=7777}}})
local raidData=dataset({[16]={top3={{itemID=102,bis=true}},enchant={itemID=302,enchantID=9002}}})
QFXGearData={schemaVersion=1,GetRecommendation=function(_,spec,mode) return spec==72 and targetData or mode=="raid" and raidData or playerData end}
recommendations.frames[panel]=true
recommendations.frames[other]=true
ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item1.badgeString.text=="[BIS]" and panel.item2.badgeString.text=="[TOP1]" and panel.item15.badgeString.text=="[TOP2]","Sidebar BIS and Top ranks are independent of the upgrade-prefix preference")
for i=1,16 do
    local row=panel["item"..i]
    assert(row.badgeString.point[4]==panel.item1.badgeString.point[4] and row.badgeString:GetWidth()==panel.item1.badgeString:GetWidth(),"Recommendation badges share a measured column")
    assert(row.itemString.point[4]==panel.item1.itemString.point[4],"Names start in the same place after differently sized badges")
end
assert(enchantPanel.enchantState=="match" and enchantPanel.tex.vertexColor[1]==0.25,"Matching enchant uses the recommendation green")
inventory.player[16]=itemLink(102):gsub("item:102:0:","item:102:9002:")
ShowInspectItemListFrame("player",parent,321,321)
assert(enchantPanel.enchantState=="mismatch" and enchantPanel.tex.vertexColor[1]==1 and enchantPanel.tex.vertexColor[2]==0.3,"Wrong enchant uses the recommendation red")
inventory.player[16]=itemLink(102)
ShowInspectItemListFrame("player",parent,321,321)
assert(enchantPanel:IsShown() and enchantPanel.enchantState=="mismatch","Missing recommended enchant still displays a red star")
enchantPanel.scripts.OnEnter(enchantPanel)
assert(GameTooltip.lines[1]==recommendations.L.enchant and GameTooltip.lines[3]==recommendations.L.missingEnchant,"Star tooltip explains a missing enchant")
other=ShowInspectItemListFrame("target",otherParent,321,321)
recommendations.data=playerData
assert(other.item1.badgeString.text=="[TOP1]" and other.item1.enchantFrame.enchant.enchantID==7777,"Inspected unit uses its own specialization, independent of the recommendation owner")
inventory.player[16]=itemLink(102):gsub("item:102:0:","item:102:9002:")
recommendations.mode="raid"
recommendations:RefreshSidebars()
assert(panel.item15.badgeString.text=="[BIS]" and enchantPanel.enchantState=="match","Changing recommendation mode refreshes badges and stars")
assert(not panel.item1.enchantFrame:IsShown(),"A slot without actual or recommended enchant clears its old star")
inventory.player[16]=itemLink(104)
ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item15.badgeString.text=="[N/R]" and panel.item15.badgeRanked==false,"Known unlisted equipment has the English N/R badge")
assert(panel.item15.badgeString.textColor[1]==0.55 and panel.item15.badgeString.textColor[2]==0.55 and panel.item15.badgeString.textColor[3]==0.55,"N/R uses gray")
assert(not panel.item1.badgeString.text:find("N/R",1,true),"A slot without ranking data is not mislabeled unranked")
inventory.player[16]=itemLink(102):gsub("item:102:0:","item:102:9002:")
ShowInspectItemListFrame("player",parent,321,321)
assert(panel.item15.badgeString.text=="[BIS]" and panel.item15.badgeString.textColor[2]==1,"Replacing an unlisted item restores its ranked badge and color")
equipment[102].level=1001
ShowInspectItemListFrame("player",parent,321,1001)
assert(panel.item15.levelDigits[4]:IsShown() and panel.item15.levelDigits[4].text=="1" and panel.item15.levelDigits[1].text=="1","Larger item levels expand the shared number column")
equipment[102].level=331
ShowInspectItemListFrame("player",parent,321,331)
assert(not panel.item15.levelDigits[4]:IsShown(),"Extra digit cells clear when the column shrinks")
QFXGearData=nil
recommendations:RefreshSidebars()
assert(panel.item15.badgeString.text=="" and enchantPanel.enchantState=="unknown","Missing recommendation data clears stale badges without false red stars")
tick(4.1)
combat=true
local old=panel.xicon1 and panel.xicon1.itemLink
event:event("SOCKET_INFO_UPDATE")
assert(not HasTask(panel.gemTaskKey),"No socket task starts in combat")
combat=false
InspectForEllesmereUIDB.ShowGemAndEnchant=false
ShowInspectItemListFrame("player",parent,321,321)
assert(not panel.xicon1:IsShown(),"Disabled socket setting clears gems")
assert(not enchantPanel:IsShown(),"Disabled gem/enchant setting clears enchant labels")
print("PASS inspect display "..locale.." "..(useSkin and "EllesmereUI" or "native").."; compact layout, BIS/TOP badges, enchant stars, hydration, swaps, unit isolation and pooling")
