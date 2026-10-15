
-------------------------------------
-- InspectCore
-------------------------------------

local _, ns = ...
local LibEvent = LibStub:GetLibrary("LibEvent.7000")
local LibSchedule = LibStub:GetLibrary("LibSchedule.7000")
local LibItemInfo = LibStub:GetLibrary("LibItemInfo.7000")
local GetSpecializationAPI = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization
local GetSpecializationInfoAPI = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo
local GetInspectSpecializationAPI = C_SpecializationInfo and C_SpecializationInfo.GetInspectSpecialization or GetInspectSpecialization

local function Readable(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end
function ns.GetReadableInspectSpecID(unit)
    if not Readable(unit) or type(GetInspectSpecializationAPI) ~= "function" then return nil end
    local ok, id = pcall(GetInspectSpecializationAPI, unit)
    if not ok then return nil end
    id = Readable(id)
    if type(id) == "number" and id > 0 then return id end
end

local guids, inspecting = {}, false
local guidOrder, MAX_GUIDS = {}, 100 --缓存有上限，超出按插入顺序移除最旧

-- Global API @trigger UNIT_REINSPECT_READY
function ReInspect(unit)
    local guid = Readable(UnitGUID(unit))
    if (not guid) then return end
    local data = guids[guid]
    if (not data) then return end
    LibSchedule:AddTask({
        identity  = guid,
        timer     = 0.5,
        elasped   = 0.5,
        expired   = GetTime() + 3,
        data      = data,
        unit      = unit,
        onExecute = function(self)
            local count, ilevel, _, weaponLevel, isArtifact, maxLevel = LibItemInfo:GetUnitItemLevel(self.unit)
            if (ilevel <= 0) then return true end
            if (count == 0 and ilevel > 0) then
                self.data.timer = time()
                self.data.ilevel = ilevel
                self.data.maxLevel = maxLevel
                self.data.weaponLevel = weaponLevel
                self.data.isArtifact = isArtifact
                LibEvent:trigger("UNIT_REINSPECT_READY", self.data)
                return true
            end
        end,
    })
end

-- Global API
function GetInspectSpec(unit)
    local specID, specName
    if (unit == "player") then
        specID = GetSpecializationAPI()
        specName = select(2, GetSpecializationInfoAPI(specID))
    else
        specID = ns.GetReadableInspectSpecID(unit)
        if (specID and specID > 0) then
            specName = select(2, GetSpecializationInfoByID(specID))
        end
    end
    return specName or ""
end

-- Clear
hooksecurefunc("ClearInspectPlayer", function()
    inspecting = false
end)

-- @trigger UNIT_INSPECT_STARTED
hooksecurefunc("NotifyInspect", function(unit)
    local guid = Readable(UnitGUID(unit))
    if (not guid) then return end
    local data = guids[guid]
    if (data) then
        data.unit = unit
        data.name, data.realm = UnitName(unit)
        data.name, data.realm = Readable(data.name), Readable(data.realm)
    else
        data = {
            unit   = unit,
            guid   = guid,
            class  = Readable(select(2, UnitClass(unit))),
            level  = Readable(UnitLevel(unit)),
            ilevel = -1,
            spec   = nil,
            hp     = Readable(UnitHealthMax(unit)),
            timer  = time(),
        }
        data.name, data.realm = UnitName(unit)
        data.name, data.realm = Readable(data.name), Readable(data.realm)
        guids[guid] = data
        tinsert(guidOrder, guid)
        if (#guidOrder > MAX_GUIDS) then
            guids[tremove(guidOrder, 1)] = nil
        end
    end
    if (not data.realm) then
        data.realm = GetRealmName()
    end
    data.expired = time() + 3
    inspecting = data
    LibEvent:trigger("UNIT_INSPECT_STARTED", data)
end)

-- @trigger UNIT_INSPECT_READY
LibEvent:attachEvent("INSPECT_READY", function(this, guid)
    guid = Readable(guid)
    if not guid then return end
    if (not guids[guid]) then return end
    LibSchedule:AddTask({
        identity  = guid,
        timer     = 0.3,
        elasped   = 0.3,
        expired   = GetTime() + 5,
        repeats   = 1,  -- 12.x优先首帧完成，缺数据时由任务循环重试
        data      = guids[guid],
        onTimeout = function(self) inspecting = false end,
        onExecute = function(self)
            local count, ilevel, _, weaponLevel, isArtifact, maxLevel = LibItemInfo:GetUnitItemLevel(self.data.unit)
            if (ilevel <= 0) then return true end
            if (count == 0 and ilevel > 0) then
                --if (UnitIsVisible(self.data.unit) or self.data.ilevel == ilevel) then
                    self.repeats = self.repeats - 1
                    if (self.repeats <= 0) then
                        self.data.timer = time()
                        self.data.name = Readable(UnitName(self.data.unit))
                        self.data.class = Readable(select(2, UnitClass(self.data.unit)))
                        self.data.ilevel = ilevel
                        self.data.maxLevel = maxLevel
                        self.data.spec = GetInspectSpec(self.data.unit)
                        self.data.hp = Readable(UnitHealthMax(self.data.unit))
                        self.data.weaponLevel = weaponLevel
                        self.data.isArtifact = isArtifact
                        LibEvent:trigger("UNIT_INSPECT_READY", self.data)
                        inspecting = false
                        return true
                    end
                --else
                --    self.data.ilevel = ilevel
                --    self.data.maxLevel = maxLevel
                --end
            end
        end,
    })
end)
