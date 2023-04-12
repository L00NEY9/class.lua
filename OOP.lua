-- Author: L00NEY
-- Pull request: b0ryakha
-- BlastHack: https://www.blast.hk/threads/141275/
-- Github: https://github.com/L00NEY9/class.lua
-- Version: 2.1

--- @region: help functions
local classes, decoratorsStack, decorators = {}, {}, {}

local __copy_table = function(tableToCopy)
    local newTable = {}
    for key, value in pairs(tableToCopy) do
        newTable[key] = value
    end

    return newTable
end

local __collect_global_changes = function(initiatorOfChanges, onChanges)
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

local __bind_method = function(method, context, currentClass)
    return function(...)
        _G.this = context
        _G.__class = currentClass
        local returned = method(...)
        _G.__class = nil
        _G.this = nil

        return returned
    end
end

local __build_instance_from_prototype = function(prototype, currentClass)
    local instance = __copy_table(prototype)

    for key, value in pairs(instance) do
        if type(value) == "function" then
            instance[key] = __bind_method(value, instance, currentClass)
        end
    end

    return instance
end

local __apply_prototype_decorators = function(prototype)
    for fieldName, _ in pairs(decorators) do
        for _, decorator in ipairs(decorators[fieldName]) do
            decorator(prototype, fieldName, classes[#classes])
        end
    end
end
--- @endregion


--- @region: API
-- local objects = private
-- global objects = public
function class(initiatorFn)
    classes[#classes + 1] = {}
    decoratorsStack = {}
    decorators = {}

    local prototype = __collect_global_changes(initiatorFn, function(key)
        decorators[key] = __copy_table(decoratorsStack)
        decoratorsStack = {}
    end)

    __apply_prototype_decorators(prototype)
    classes[#classes].prototype = prototype

    classes[#classes].new = function(self, ...)
        local instance = __build_instance_from_prototype(self.prototype, self)

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

function inherit(parentClass)
    local parentClassPrototype = __copy_table(parentClass.prototype)

    return function(initiatorFn)
        local newClass = class(initiatorFn)
        newClass.parent = parentClass

        for fieldName, fieldValue in pairs(parentClassPrototype) do
            if not newClass.prototype[fieldName] then
                newClass.prototype[fieldName] = fieldValue
            end
        end

        setmetatable(newClass, { __call = newClass.new })
        return newClass
    end
end
--- @endregion