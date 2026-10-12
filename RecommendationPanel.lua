local _, ns = ...
local R = ns.Recommendations
local E = LibStub:GetLibrary("LibEvent.7000")
local L = R.L

local function Text(parent, font, x, y, width)
    local text = parent:CreateFontString(nil, "ARTWORK", font or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, y)
    text:SetWidth(width)
    text:SetJustifyH("LEFT")
    ns.Skin.Font(text)
    return text
end

local function Button(parent, label, width, height)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, height)
    button:SetText(label)
    ns.Skin.Button(button)
    return button
end

function R:Layout()
    if not self.owner or not self.panel or InCombatLockdown() then return end
    local rightmost = self.owner
    if rightmost.inspectFrame and rightmost.inspectFrame:IsShown() then rightmost=rightmost.inspectFrame end
    self.panel:ClearAllPoints()
    self.panel:SetScale(1)
    self.panel:SetPoint("TOPLEFT", rightmost, "TOPRIGHT", 4, 0)
    local right = rightmost:GetRight()
    if right then
        local screen = UIParent:GetWidth()
        local available = screen - right - 8
        local scale = math.min(1, math.max(0.4, available/560), (UIParent:GetHeight()-16)/640)
        self.panel:SetScale(scale)
    end
end

function R:CreatePanel()
    if self.panel then return self.panel end
    local panel = CreateFrame("Frame", "InspectForEllesmereUIRecommendationPanel", UIParent, "BackdropTemplate")
    panel:Hide()
    panel:SetSize(560, 640)
    panel:SetClampedToScreen(true)
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=8, edgeSize=16, insets={left=4,right=4,top=4,bottom=4}})
    panel:SetBackdropColor(0,0,0,0.95)
    ns.Skin.Shell(panel)
    self.panel = panel
    panel.icon = panel:CreateTexture(nil,"ARTWORK")
    panel.icon:SetSize(28,28)
    panel.icon:SetPoint("TOPLEFT",14,-14)
    panel.title=Text(panel,"GameFontNormalLarge",50,-14,450)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT",-8,-8)
    close:SetScript("OnClick",function() panel:Hide() end)
    ns.Skin.CloseButton(close)
    panel.updated=Text(panel,nil,0,0,180)
    panel.updated:ClearAllPoints()
    panel.updated:SetPoint("TOPRIGHT",-40,-16)
    panel.updated:SetJustifyH("RIGHT")
    panel.updated:SetTextColor(0.6,0.6,0.6)
    panel.tabs={}
    for i, mode in ipairs({"mythic_plus","raid"}) do
        local button=Button(panel,L[mode],152,24)
        button:SetPoint("TOPLEFT",14+(i-1)*158,-40)
        button:SetScript("OnClick",function()
            R.mode=mode
            R:RefreshSidebars()
            if R.owner and R.owner.unit == "player" then R.ratings=R.C.Ratings() end
            R:RequestRefresh()
        end)
        panel.tabs[mode]=button
    end
    panel.consumableColumns={}
    local columnDefs={
        {kind="consumable", key="flask", title=L.flaskRec, tooltip="ConsumableTooltip"},
        {kind="consumable", key="combatPotion", title=L.potionRec, tooltip="ConsumableTooltip"},
        {kind="consumable", key="foodBuff", title=L.foodRec, tooltip="ConsumableTooltip"},
        {kind="embellishment", title=L.embellishmentRec, tooltip="EmbellishmentTooltip"},
    }
    for colIdx, def in ipairs(columnDefs) do
        local x=14+(colIdx-1)*133
        local title=Text(panel,"GameFontNormal",x,-78,130)
        title:SetText(def.title)
        local rows={}
        for i=1,3 do
            local row=CreateFrame("Button",nil,panel)
            row:SetSize(129,40)
            row:SetPoint("TOPLEFT",x,-100-(i-1)*42)
            row.icon=row:CreateTexture(nil,"ARTWORK")
            row.icon:SetSize(24,24)
            row.icon:SetPoint("TOPLEFT",0,-2)
            row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
            ns.Skin.SquareIcon(row.icon)
            row.icon2=row:CreateTexture(nil,"ARTWORK")
            row.icon2:SetSize(16,16)
            row.icon2:SetPoint("TOPLEFT",row.icon,"TOPLEFT",10,-10)
            row.icon2:SetTexCoord(0.08,0.92,0.08,0.92)
            ns.Skin.SquareIcon(row.icon2)
            row.icon2:Hide()
            row.quality=row:CreateTexture(nil,"OVERLAY")
            row.quality:SetSize(14,14)
            row.quality:SetPoint("TOPLEFT",row.icon,"TOPLEFT",-2,2)
            row.quality:Hide()
            row.name=Text(row,nil,28,-2,100)
            row.name:SetHeight(14)
            row.rate=Text(row,nil,28,-19,100)
            row.rate:SetHeight(13)
            row.rate:SetTextColor(0.7,0.7,0.7)
            row.tooltip=def.tooltip
            row.columnKey=def.key
            row:SetScript("OnEnter",function(self) R[self.tooltip](R,self) end)
            row:SetScript("OnLeave",function() GameTooltip:Hide() end)
            row:SetScript("OnClick",function(self) if self.link and IsShiftKeyDown() then ChatEdit_InsertLink(self.link) end end)
            rows[i]=row
        end
        panel.consumableColumns[colIdx]={def=def, rows=rows, title=title}
    end
    panel.statOrder=Text(panel,"GameFontNormalSmall",150,-262,260)
    panel.statOrder:SetJustifyH("CENTER")
    panel.statOrder:SetTextColor(0.9,0.8,0.5)
    panel.stats={}
    local statColors={crit={1,0.35,0.1}, haste={1,0.85,0.2}, mastery={0.6,0.3,1}, versatility={0.2,0.95,0.35}}
    for i,key in ipairs({"crit","haste","mastery","versatility"}) do
        local row=CreateFrame("Button",nil,panel)
        row:SetSize(260,34)
        row:SetPoint("TOPLEFT",150,-280-(i-1)*36)
        row.key=key
        row.color=statColors[key]
        row.text=Text(row,nil,0,-1,260)
        row.text:SetJustifyH("CENTER")
        row.text:SetHeight(14)
        row.barBg=row:CreateTexture(nil,"BACKGROUND")
        row.barBg:SetSize(260,9)
        row.barBg:SetPoint("TOPLEFT",0,-19)
        row.barBg:SetColorTexture(0.03,0.03,0.03,1)
        row.barFill=row:CreateTexture(nil,"ARTWORK")
        row.barFill:SetSize(1,9)
        row.barFill:SetPoint("LEFT",row.barBg,"LEFT",0,0)
        row.barFill:SetColorTexture(1,1,1,1)
        row.barMarker=row:CreateTexture(nil,"OVERLAY")
        row.barMarker:SetSize(2,13)
        row.barMarker:SetPoint("LEFT",row.barBg,"LEFT",0,0)
        row.barMarker:SetColorTexture(1,1,1,1)
        row:SetScript("OnEnter",function(self) R:StatTooltip(self) end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        panel.stats[i]=row
    end
    panel.gemTitle=Text(panel,"GameFontNormal",150,-436,260)
    panel.gemTitle:SetJustifyH("CENTER")
    panel.gems={}
    for i=1,4 do
        local gem=CreateFrame("Button",nil,panel)
        gem:SetSize(22,22)
        gem:SetPoint("TOPLEFT",227+(i-1)*28,-456)
        gem.icon=gem:CreateTexture(nil,"ARTWORK")
        gem.icon:SetAllPoints()
        ns.Skin.SquareIcon(gem.icon)
        gem:SetScript("OnEnter",function(self)
            if not self.itemID then return end
            GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
            if self.list and #self.list>0 then
                GameTooltip:AddLine(R.L.gems)
                for i,entry in ipairs(self.list) do
                    local name=R:ItemLabel(entry.itemID, entry.name)
                    GameTooltip:AddLine(string.format("%d. %s · %.1f%%", i, name, (entry.usage or 0)*100), 1,1,1, true)
                end
            else
                local name, link = R:Item(self.itemID)
                if link then GameTooltip:SetHyperlink(link) else GameTooltip:AddLine(R:ItemLabel(self.itemID, self.name)) end
            end
            GameTooltip:Show()
        end)
        gem:SetScript("OnLeave",function() GameTooltip:Hide() end)
        gem:Hide()
        panel.gems[i]=gem
    end
    panel.omniumIcons={}
    for i=1,6 do
        local icon=CreateFrame("Button",nil,panel)
        icon:SetSize(22,22)
        icon:SetPoint("TOPLEFT",204+(i-1)*26,-488)
        icon.icon=icon:CreateTexture(nil,"ARTWORK")
        icon.icon:SetAllPoints()
        icon.icon:SetTexCoord(0.08,0.92,0.08,0.92)
        ns.Skin.SquareIcon(icon.icon)
        icon.mark=icon:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
        icon.mark:SetPoint("TOP",0,-23)
        ns.Skin.Font(icon.mark)
        icon:SetScript("OnEnter",function(self)
            local spell=self.spell
            if not spell then return end
            GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
            GameTooltip:AddLine(R.L.omnium .. " · " .. string.format(R.L.omniumRow, (spell.row or 0)+1))
            local list={}
            local talents=R.data and R.data.omnium and R.data.omnium.talents
            for _,t in ipairs(talents or {}) do
                if t.row==spell.row then list[#list+1]=t end
            end
            table.sort(list,function(a,b) return (a.pickRate or 0)>(b.pickRate or 0) end)
            for i,t in ipairs(list) do
                local name=R.C.OmniumName(t.spellId, t.name) or R.L.unmapped
                if t.selected then
                    GameTooltip:AddLine(string.format("%d. %s · %.0f%%", i, name, (t.pickRate or 0)*100), 0.25,1,0.35, true)
                else
                    GameTooltip:AddLine(string.format("%d. %s · %.0f%%", i, name, (t.pickRate or 0)*100), 1,1,1, true)
                end
            end
            GameTooltip:Show()
        end)
        icon:SetScript("OnLeave",function() GameTooltip:Hide() end)
        icon:Hide()
        panel.omniumIcons[i]=icon
    end
    panel.gear={}
    local slotNames={}
    for _,slot in ipairs(R.slots) do slotNames[slot[1]]=slot[2] end
    local function slotButton(slotNum, x, y, extraX, starSide)
        local function makeSlot(px)
            local row=CreateFrame("Button",nil,panel)
            row:SetSize(44,44)
            row:SetPoint("TOPLEFT",px,y)
            row.slot=slotNum
            row.slotName=slotNames[slotNum]
            row.bg=row:CreateTexture(nil,"BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0.08,0.08,0.08,0.6)
            row.icon=row:CreateTexture(nil,"ARTWORK")
            row.icon:SetSize(40,40)
            row.icon:SetPoint("CENTER")
            row.icon:SetTexCoord(0.08,0.92,0.08,0.92)
            ns.Skin.SquareIcon(row.icon)
            row.state=row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
            row.state:SetPoint("BOTTOM",0,0)
            row.state:SetJustifyH("CENTER")
            row.state:SetShadowOffset(1,-1)
            ns.Skin.Font(row.state)
            row:SetScript("OnLeave",function() GameTooltip:Hide() end)
            return row
        end
        local row=makeSlot(x)
        row:SetScript("OnEnter",function(self) if R.data then R:GearTooltip(self) end end)
        row:SetScript("OnClick",function(self) if self.link and IsShiftKeyDown() then ChatEdit_InsertLink(self.link) end end)
        local extra=makeSlot(extraX)
        extra.isExtra=true
        extra:Hide()
        extra:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
            if self.link then GameTooltip:SetHyperlink(self.link) else GameTooltip:AddLine(self.slotName) end
            GameTooltip:Show()
        end)
        extra:SetScript("OnClick",function(self) if self.link and IsShiftKeyDown() then ChatEdit_InsertLink(self.link) end end)
        local star=CreateFrame("Button",nil,panel)
        star:SetSize(20,20)
        star.tex=star:CreateTexture(nil,"ARTWORK")
        star.tex:SetAllPoints()
        star.tex:SetAtlas("PetJournal-FavoritesIcon")
        star.tex:SetVertexColor(1,0.85,0.2)
        star:SetScript("OnEnter",function(self) R:EnchantTooltip(self) end)
        star:SetScript("OnLeave",function() GameTooltip:Hide() end)
        star:Hide()
        row.star=star
        row.starSide=starSide
        row.extra=extra
        panel.gear[#panel.gear+1]=row
    end
    local gearLeft={1,2,3,15,5,false,false,9}
    local gearRight={10,6,7,8,11,12,13,14}
    for rowIdx=1,8 do
        local y=-248-(rowIdx-1)*46
        if gearLeft[rowIdx] then slotButton(gearLeft[rowIdx], 14, y, 62, "right") end
        if gearRight[rowIdx] then slotButton(gearRight[rowIdx], 494, y, 446, "left") end
    end
    slotButton(16, 225, -570, 177, "left")
    slotButton(17, 273, -570, 325, "right")
    panel.weaponBuff=CreateFrame("Button",nil,panel)
    panel.weaponBuff:SetSize(26,26)
    panel.weaponBuff:SetPoint("TOPLEFT",258,-544)
    panel.weaponBuff.icon=panel.weaponBuff:CreateTexture(nil,"ARTWORK")
    panel.weaponBuff.icon:SetAllPoints()
    panel.weaponBuff.icon:SetTexCoord(0.08,0.92,0.08,0.92)
    ns.Skin.SquareIcon(panel.weaponBuff.icon)
    panel.weaponBuff.columnKey="weaponOil"
    panel.weaponBuff:SetScript("OnEnter",function(self) R:ConsumableTooltip(self) end)
    panel.weaponBuff:SetScript("OnLeave",function() GameTooltip:Hide() end)
    panel.weaponBuff:Hide()
    panel:SetScript("OnHide",function()
        R:StopRefresh()
        GameTooltip:Hide()
        for _,stats in ipairs(R.hiddenStats or {}) do
            if stats:GetParent():IsShown() then stats:Show() end
        end
        R.hiddenStats=nil
    end)
    table.insert(UISpecialFrames,"InspectForEllesmereUIRecommendationPanel")
    return panel
end

function R:Open(owner)
    if InCombatLockdown() then return end
    local panel=self:CreatePanel()
    if panel:IsShown() and self.owner == owner then panel:Hide(); return end
    panel:Hide()
    self.owner=owner
    self.hiddenStats={}
    self.ratings=(owner.unit == "player") and self.C.Ratings() or nil
    for frame in pairs(self.frames) do
        local stats=frame.statsFrame
        if stats then
            if not self.watchedStats[stats] then
                self.watchedStats[stats]=true
                stats:HookScript("OnShow",function() if R.panel and R.panel:IsShown() then R.panel:Hide() end end)
            end
            if stats:IsShown() then self.hiddenStats[#self.hiddenStats+1]=stats; stats:Hide() end
        end
    end
    self:Layout()
    panel:Show()
    self:Refresh()
end

function R:Refresh()
    if InCombatLockdown() then self.dirty=true; return end
    self.dirty=nil
    local panel=self.panel
    if not panel or not panel:IsShown() or not self.owner then return end
    self.personal=self.owner.unit == "player"
    local specID,name,icon=self.C.Spec(self.owner.unit)
    local classCoords=self.C.ClassIcon(self.owner.unit)
    if classCoords then
        panel.icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
        panel.icon:SetTexCoord(unpack(classCoords))
    else
        panel.icon:SetTexture(icon or 134400)
        panel.icon:SetTexCoord(0,1,0,1)
    end
    panel.title:SetText((name or "—") .. " · " .. L.title)
    self.data,self.reason=self:GetData(specID,self.mode)
    local data=self.data
    local updated=data and data.updatedAt
    if updated then
        local text=tostring(updated):gsub("T"," "):sub(1,16)
        panel.updated:SetText(L.updated..": "..text)
    else
        panel.updated:SetText("")
    end
    for mode,button in pairs(panel.tabs) do button:SetEnabled(mode ~= self.mode) end
    local ratings
    if data then
        if self.personal then
            ratings=self.ratings
        elseif self.owner then
            ratings=self.C.InspectRatings(self.owner.unit)
        end
    end
    local order=data and data.statOrder
    if order and #order>0 then
        local names={}
        for _,key in ipairs(order) do names[#names+1]=L[key] end
        panel.statOrder:SetText(table.concat(names,">"))
    else
        panel.statOrder:SetText("")
    end
    for _,row in ipairs(panel.stats) do
        local label,median,current,diff=self:StatDisplay(row.key,data,ratings and ratings[row.key])
        row.median,row.current=median,current
        row.text:SetText(label)
        if diff and diff>=0 then row.text:SetTextColor(0.25,1,0.35)
        elseif diff then row.text:SetTextColor(1,0.85,0.2)
        else row.text:SetTextColor(1,1,1) end
        local c=row.color
        row.barFill:SetColorTexture(c[1],c[2],c[3],1)
        local scale=math.max(median or 0, current or 0)*1.3
        if scale>0 then
            row.barFill:SetWidth(math.max(1,260*math.min(1,(current or 0)/scale)))
            row.barMarker:ClearAllPoints()
            row.barMarker:SetPoint("LEFT",row.barBg,"LEFT",260*math.min(1,(median or 0)/scale),0)
            row.barMarker:Show()
        else
            row.barFill:SetWidth(1)
            row.barMarker:Hide()
        end
    end
    local gemList={}
    local gemTables=data and data.gemTables
    if gemTables then
        for _,key in ipairs({"primaryGems","secondaryGems"}) do
            local list=gemTables[key]
            if list then
                for i=1,2 do
                    if list[i] then gemList[#gemList+1]={entry=list[i],list=list} end
                end
            end
        end
    end
    if #gemList==0 then
        for _,entry in ipairs(data and data.gems or {}) do
            gemList[#gemList+1]={entry=entry}
        end
    end
    panel.gemTitle:SetText(#gemList>0 and L.gems or "")
    for i,gem in ipairs(panel.gems) do
        local g=gemList[i]
        if g then
            local entry=g.entry
            local name, link, icon=self:Item(entry.itemID)
            gem.itemID=entry.itemID
            gem.name=entry.name
            gem.link=link
            gem.list=g.list
            gem.icon:SetTexture(icon or 134400)
            gem:Show()
        else
            gem.itemID=nil
            gem.list=nil
            gem:Hide()
        end
    end
    local omnium=data and data.omnium
    local talents=omnium and omnium.talents
    local selectedRunes={}
    if talents then
        local byRow={}
        for _,t in ipairs(talents) do
            local rowKey=t.row or 0
            if t.selected and not byRow[rowKey] then byRow[rowKey]=t end
        end
        for rowKey=0,7 do
            if byRow[rowKey] then selectedRunes[#selectedRunes+1]=byRow[rowKey] end
        end
    end
    local traitSelection
    if self.personal and talents then
        local wanted={}
        for _,t in ipairs(talents) do
            if t.spellId then wanted[self.C.OmniumTraitID(t.spellId)]=true end
        end
        traitSelection=self.C.TraitSelection(wanted)
    end
    local shown=math.min(#selectedRunes,#panel.omniumIcons)
    local totalWidth=28*shown-6
    local startX=150+(260-totalWidth)/2
    for i,icon in ipairs(panel.omniumIcons) do
        local spell=selectedRunes[i]
        if spell then
            icon.spell=spell
            icon.icon:SetTexture(self.C.SpellTexture(spell.spellId,spell.icon) or 134400)
            icon:ClearAllPoints()
            icon:SetPoint("TOPLEFT",startX+(i-1)*28,-488)
            local mark=""
            if self.personal then
                if traitSelection then
                    if traitSelection[self.C.OmniumTraitID(spell.spellId)] then
                        mark=L.spellOn
                        icon.mark:SetTextColor(0.25,1,0.35)
                    else
                        local anyInRow=false
                        for _,t in ipairs(talents or {}) do
                            if t.row==spell.row and traitSelection[self.C.OmniumTraitID(t.spellId)] then anyInRow=true break end
                        end
                        if anyInRow then
                            mark=L.spellOff
                            icon.mark:SetTextColor(1,0.3,0.3)
                        end
                    end
                elseif self.C.SpellSelected(spell.spellId) then
                    mark=L.spellOn
                    icon.mark:SetTextColor(0.25,1,0.35)
                end
            end
            icon.mark:SetText(mark)
            icon:Show()
        else
            icon.spell=nil
            icon.mark:SetText("")
            icon:Hide()
        end
    end
    local consumables=data and self:GetConsumables(specID,self.mode,data.seasonID)
    for _,col in ipairs(panel.consumableColumns) do
        local list
        if col.def.kind=="embellishment" then
            list=data and data.embellishments or {}
        else
            list=consumables and consumables.consumables and consumables.consumables[col.def.key] or {}
        end
        for i,row in ipairs(col.rows) do
            local entry=list[i]
            row.choices=list
            row.link=nil
            row.icon:SetTexture(134400)
            row.icon2:Hide()
            row.quality:Hide()
            row.name:SetTextColor(1,1,1)
            if not entry then
                row.name:SetText("—")
                row.rate:SetText("")
            elseif col.def.kind=="embellishment" then
                local _, link, icon=self:Item(entry.itemID)
                row.link=link
                row.icon:SetTexture(icon or 134400)
                row.name:SetText(self:EmbellishmentName(entry))
                row.rate:SetText(string.format("%.1f%%", (entry.usage or 0)*100))
            else
                local name, link, icon
                if entry.itemID then name,link,icon=self:Item(entry.itemID) end
                row.link=link
                row.icon:SetTexture(icon or 134400)
                local label
                if entry.itemID2 then
                    local name2, link2, icon2=self:Item(entry.itemID2)
                    row.icon2:SetTexture(icon2 or 134400)
                    row.icon2:Show()
                    row.link=link2 or link
                    label=self:ItemLabel(entry.itemID) .. " + " .. self:ItemLabel(entry.itemID2)
                else
                    label=self:EffectLabel(entry)
                end
                row.name:SetText(label)
                row.rate:SetText(string.format("%.1f%%", (entry.usage or 0)*100))
            end
            if entry and entry.itemID then
                local quality=self.C.ItemQuality(entry.itemID)
                local colors=ITEM_QUALITY_COLORS and quality and ITEM_QUALITY_COLORS[quality]
                if colors and colors.color then row.name:SetTextColor(colors.color.r, colors.color.g, colors.color.b) end
                local atlas=self.C.CraftedQualityAtlas(entry.itemID)
                if atlas then
                    row.quality:SetAtlas(atlas)
                    row.quality:Show()
                end
            end
        end
    end
    local weaponBuff=consumables and consumables.consumables and consumables.consumables.weaponOil
    local wbRow=panel.weaponBuff
    wbRow.choices=weaponBuff or {}
    wbRow.link=nil
    local wbTop=weaponBuff and weaponBuff[1]
    if wbTop and wbTop.itemID then
        local _, link, icon=self:Item(wbTop.itemID)
        wbRow.link=link
        wbRow.icon:SetTexture(icon or 134400)
        wbRow:Show()
    else
        wbRow:Hide()
    end
    local equipped={}
    if data then
        for _,slot in ipairs(self.slots) do
            local id=self.C.EquippedID(slot[1], self.owner and self.owner.slotCache)
            if id then equipped[slot[1]]=id end
        end
    end
    for _,row in ipairs(panel.gear) do self:RenderGear(row, equipped[row.slot]) end
    self:Layout()
end

local function Attach(frame)
    if R.frames[frame] then return end
    R.frames[frame]=true
    local button=Button(frame,L.title,154,22)
    button:SetPoint("TOPRIGHT",frame,"BOTTOMRIGHT",-4,-2)
    button:SetScript("OnClick",function() R:Open(frame) end)
    frame:HookScript("OnHide",function() if R.owner==frame and R.panel then R.panel:Hide() end end)
    frame:HookScript("OnSizeChanged",function() if R.owner==frame then R:RequestRefresh() end end)
end
R.watchedStats=setmetatable({}, {__mode="k"})
E:attachTrigger("INSPECT_FRAME_CREATED",function(_,frame) Attach(frame) end)

SLASH_INSPECTFORELLESMEREUITRAITS1 = "/ifeuitraits"
if SlashCmdList then
SlashCmdList["INSPECTFORELLESMEREUITRAITS"] = function()
    print("== Inspect for EllesmereUI " .. (R.L.omnium or "Omnium Folio") .. " diagnostics v2 ==")
    if not C_Traits then print("此客户端无 C_Traits") return end
    print("GetConfigIDBySystemID=" .. type(C_Traits.GetConfigIDBySystemID)
        .. " GetConfigInfo=" .. type(C_Traits.GetConfigInfo)
        .. " GetTreeNodes=" .. type(C_Traits.GetTreeNodes)
        .. " GetNodeInfo=" .. type(C_Traits.GetNodeInfo))
    local data = R.data
    local wanteds = {}
    for _, t in ipairs(data and data.omnium and data.omnium.talents or {}) do
        if t.spellId then wanteds[t.spellId] = true end
    end
    local function spellName(id)
        if C_Spell and C_Spell.GetSpellInfo then
            local ok, spellInfo = pcall(C_Spell.GetSpellInfo, id)
            if ok and spellInfo and spellInfo.name then return spellInfo.name end
        end
        local ok, name = pcall(GetSpellInfo, id)
        if ok and type(name) == "string" then return name end
        return "?"
    end
    local found = false
    for systemID = 1, 200 do
        local ok, configID = pcall(C_Traits.GetConfigIDBySystemID, systemID)
        if ok and configID then
            found = true
            local treeCount, nodeCount, entryCount, committedCount = 0, 0, 0, 0
            local detail = {}
            local okInfo, info = pcall(C_Traits.GetConfigInfo, configID)
            if okInfo and info and type(info.treeIDs) == "table" then
                for _, treeID in ipairs(info.treeIDs) do
                    treeCount = treeCount + 1
                    local okNodes, nodes = pcall(C_Traits.GetTreeNodes, treeID)
                    for _, nodeID in ipairs(okNodes and type(nodes) == "table" and nodes or {}) do
                        nodeCount = nodeCount + 1
                        local okNode, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID)
                        if okNode and type(nodeInfo) == "table" and type(nodeInfo.entryIDs) == "table" then
                            local committed = {}
                            for _, entryID in ipairs(type(nodeInfo.entryIDsWithCommittedRanks) == "table"
                                    and nodeInfo.entryIDsWithCommittedRanks or {}) do
                                committed[entryID] = true
                            end
                            for _, entryID in ipairs(nodeInfo.entryIDs) do
                                entryCount = entryCount + 1
                                local okEntry, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID)
                                local defInfo
                                if okEntry and type(entryInfo) == "table" then
                                    local okDef, def = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID)
                                    if okDef then defInfo = def end
                                end
                                local sid = type(defInfo) == "table" and defInfo.spellID or nil
                                if committed[entryID] then committedCount = committedCount + 1 end
                                if #detail < 40 then
                                    detail[#detail + 1] = string.format("  node=%s spell=%s committed=%s %s%s",
                                        tostring(nodeID), tostring(sid), tostring(committed[entryID] or false),
                                        sid and spellName(sid) or "?", wanteds[sid] and "  <== 本地列表" or "")
                                end
                            end
                        end
                    end
                end
            end
            print(string.format("system=%d config=%s trees=%d nodes=%d entries=%d committed=%d",
                systemID, tostring(configID), treeCount, nodeCount, entryCount, committedCount))
            if committedCount > 0 and entryCount <= 60 then
                for _, line in ipairs(detail) do print(line) end
            end
        end
    end
    if not found then print("GetConfigIDBySystemID 对所有 1..200 均返回空") end
    print("== 本地推荐列表 ==")
    for id in pairs(wanteds) do
        print("  want spell=" .. tostring(id))
    end
end
end

E:attachTrigger("INSPECT_FRAME_SHOWN",function(_,frame)
    Attach(frame)
    if frame.statsFrame and not R.watchedStats[frame.statsFrame] then
        R.watchedStats[frame.statsFrame]=true
        frame.statsFrame:HookScript("OnShow",function(stats)
            if R.panel and R.panel:IsShown() then R.panel:Hide() end
        end)
    end
    if R.owner==frame then R:RequestRefresh() end
end)

