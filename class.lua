-- Author: L00NEY
-- BlastHack: https://www.blast.hk/threads/141275/
-- Github: https://github.com/L00NEY9/class.lua
-- Version: 2.0

local classes = {}
local decoratorsStack = {}
local decorators = {}


--- @param tableToCopy table
--- @return table
local function simpleCopyTable(tableToCopy)
    local newTable = {}
    for key, value in pairs(tableToCopy) do
        newTable[key] = value
    end
    return newTable
end

--- @param initiatorOfChanges function
--- @param onChanges function
--- @return table
local function collectGlobalScopeChanges(initiatorOfChanges, onChanges)
    if not onChanges then onChanges = function() end end
    local changes = {}

    setmetatable(_G, {
        __newindex = function(self, key, value)
            changes[key] = value
            onChanges(key)
        end
    })

    initiatorOfChanges()

    setmetatable(_G, {})

    return changes
end

--- @param method function
--- @param context table
--- @param currentClass table
--- @return function
local function bindMethodWithContext(method, context, currentClass)
    return function(...)
        _G.this = context
        _G.__class = currentClass
        local returned = method(...)
        _G.__class = nil
        _G.this = nil
        return returned
    end
end

--- @param prototype table
--- @return table
local function buildInstanceFromPrototype(prototype, currentClass)
    local instance = simpleCopyTable(prototype)

    for key, value in pairs(instance) do
        if type(value) == "function" then
            instance[key] = bindMethodWithContext(value, instance, currentClass)
        end
    end

    return instance
end

--- @param prototype table
local function applyPrototypeDecorators(prototype)
    for fieldName, _ in pairs(decorators) do
        for _, decorator in ipairs(decorators[fieldName]) do
            decorator(prototype, fieldName, classes[#classes])
        end
    end
end


-- API:

--- @param initiatorFn function
--- @return table
function class(initiatorFn)
    classes[#classes + 1] = {}
    decoratorsStack = {}
    decorators = {}

    local prototype = collectGlobalScopeChanges(initiatorFn, function(key)
        decorators[key] = simpleCopyTable(decoratorsStack)
        decoratorsStack = {}
    end)

    applyPrototypeDecorators(prototype)
    classes[#classes].prototype = prototype

    classes[#classes].new = function(self, ...)
        local instance = buildInstanceFromPrototype(self.prototype, self)

        if instance.new then
            instance.new(...)
        end

        return instance
    end

    setmetatable(classes[#classes], {
        __call = classes[#classes].new
    })

    return classes[#classes]
end

--- @param baseFn function
--- @return function
function createDecorator(baseFn)
    return function(...)
        local args = {...}
        decoratorsStack[#decoratorsStack + 1] = function(context, fieldName, currentClass)
            if table.unpack(args) then
                baseFn(
                    table.unpack(args),
                    context,
                    fieldName,
                    currentClass
                )
            else
                baseFn(
                    context,
                    fieldName,
                    currentClass
                )
            end
        end
    end
end

--- @param parentClass table
function extended(parentClass)
    local parentClassPrototype = simpleCopyTable(parentClass.prototype)


    return function(initiatorFn)
        local newClass = class(initiatorFn)
        newClass.parent = parentClass

        for fieldName, fieldValue in pairs(parentClassPrototype) do
            newClass.prototype[fieldName] = fieldValue
        end

        setmetatable(newClass, {
            __call = newClass.new,
        })

        return newClass
    end
end

function super(...)
    __class.parent:new(...)
end


Static = createDecorator(function(context, fieldName, currentClass)
    local temp = context[fieldName]
    context[fieldName] = nil
    currentClass[fieldName] = temp
end)