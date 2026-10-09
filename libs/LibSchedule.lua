
---------------------------------
-- 計劃任務庫
---------------------------------

local MAJOR, MINOR = "LibSchedule.7000", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end

local frame = CreateFrame("Frame", nil, UIParent)

frame.schedules, frame.timer = {}, 0
frame.scheduleMap = {} -- identity -> task，O(1)查重/查找
frame.enabled = false

local OnUpdate
local function EnableOnUpdate()
    if (not frame.enabled) then
        frame:SetScript("OnUpdate", OnUpdate)
        frame.enabled = true
    end
end

--OnUpdate：仅在存在任务时启用，任务清空后自动停用
OnUpdate = function(self, elasped)
    local t = GetTime()
    local map = self.scheduleMap
    local item
    for i = #self.schedules, 1, -1 do
        item = self.schedules[i]
        if (item.stopped) then
            tremove(self.schedules, i)
            if (map[item.identity] == item) then
                map[item.identity] = nil
            end
        elseif (t >= item.begined) then
            item.timer = item.timer + elasped
            if (item.timer >= item.elasped) then
                item.timer = 0
                if (t > item.expired) then
                    tremove(self.schedules, i)
                    if (map[item.identity] == item) then
                        map[item.identity] = nil
                    end
                    item.onTimeout(item)
                elseif (item.onExecute(item)) then
                    tremove(self.schedules, i)
                    if (map[item.identity] == item) then
                        map[item.identity] = nil
                    end
                end
            end
        end
    end
    if (#self.schedules == 0) then
        self:SetScript("OnUpdate", nil)
        self.enabled = false
    end
end

--Task的字段
local metatable = {
    identity  = '', --唯一签名(必须)
    timer     = 0,  --初始计时点
    elasped   = 1,  --执行的周期
    begined   = 0,  --开始时间点
    expired   = 0,  --过期时间点
    override  = false, --是否覆蓋
    onStart   = function(self) end, --添加后执行
    onTimeout = function(self) end, --超时后执行
    onExecute = function(self) return true end, --定時執行,直到返回true才停止
    onRemove  = function(self) end, --删除时执行
}
local taskMeta = {__index = metatable} --共享元表，避免每个任务新建

--添加Task
function lib:AddTask(item, override)
    local identity = item.identity or ""
    local map = frame.scheduleMap
    if (override or item.override) then
        local old = map[identity]
        if (old) then
            old.stopped = true
        end
    elseif (map[identity]) then
        return self
    end
    setmetatable(item, taskMeta)
    item.onStart(item)
    tinsert(frame.schedules, item)
    map[identity] = item
    EnableOnUpdate()
    return self
end

--刪除Task
function lib:RemoveTask(identity, useLike)
    local map = frame.scheduleMap
    if (useLike) then
        for i, v in ipairs(frame.schedules) do
            if (string.find(v.identity, identity)) then
                v.stopped = true
                v:onRemove()
            end
        end
    else
        local v = map[identity]
        if (v) then
            v.stopped = true
            v:onRemove()
        end
    end
    return self
end

--執行Task
function lib:AwakeTask(identity, useLike)
    local map = frame.scheduleMap
    if (useLike) then
        for i, v in ipairs(frame.schedules) do
            if (string.find(v.identity, identity) and not v.stopped and v.onExecute(v)) then
                v.stopped = true
            end
        end
    else
        local v = map[identity]
        if (v and not v.stopped and v.onExecute(v)) then
            v.stopped = true
        end
    end
    return self
end

--查找Task
function lib:SearchTask(identity, useLike)
    local identities = {}
    local map = frame.scheduleMap
    if (useLike) then
        for i, v in ipairs(frame.schedules) do
            if (string.find(v.identity, identity) and not v.stopped) then
                tinsert(identities, v.identity)
            end
        end
    else
        local v = map[identity]
        if (v and not v.stopped) then
            tinsert(identities, v.identity)
        end
    end
    return #identities==0 and nil or identities
end
