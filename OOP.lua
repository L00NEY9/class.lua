-- Author: L00NEY
-- Pull request: b0ryakha
-- BlastHack: https://www.blast.hk/threads/141275/
-- Github: https://github.com/L00NEY9/class.lua
-- Version: 2.1

--- @region: table plus
function table:reverse(t)
    for i = 1, #t // 2, 1 do
        t[i], t[#t - i + 1] = t[#t - i + 1], t[i]
    end

    return t
end

function table:copy(t)
    if type(t) ~= "table" then
        return {}
    end

    local result = {}

    for key, value in pairs(t) do
        result[key] = value
    end

    return result
end

function table:remove_duplicate(t)
    if type(t) ~= "table" then
        return {}
    end

    local hash, result = {}, {}

    for _, v in ipairs(t) do
        if not hash[v] then
            result[#result + 1] = v
            hash[v] = true
        end
    end

    return result
end
--- @endregion

--- @region: help functions
local classes, decoratorsStack, decorators = {}, {}, {}

local collect_global_changes = function(init_changes, on_changes)
    if not on_changes then on_changes = function() end end
    local changes = {}

    setmetatable(_G, {
        __newindex = function(self, key, value)
            changes[key] = value
            on_changes(key)
        end
    })

    init_changes()
    setmetatable(_G, {})

    return changes
end

local bind_method = function(method, context, current_class)
    return function(...)
        _G.this = context
        _G.__class = current_class
        local returned = method(...)
        _G.__class = nil
        _G.this = nil

        return returned
    end
end

local build_instance_from_prototype = function(prototype, current_class)
    local instance = table:copy(prototype)

    for key, value in pairs(instance) do
        if type(value) == "function" then
            instance[key] = bind_method(value, instance, current_class)
        end
    end

    return instance
end

local apply_prototype_decorators = function(prototype)
    for field_name, _ in pairs(decorators) do
        for _, decorator in ipairs(decorators[field_name]) do
            decorator(prototype, field_name, classes[#classes])
        end
    end
end
--- @endregion


--- @region: API
-- local objects = private
-- global objects = public
function class(init_function)
    classes[#classes + 1] = {}
    decoratorsStack = {}
    decorators = {}

    local prototype = collect_global_changes(init_function, function(key)
        decorators[key] = table:copy(decoratorsStack)
        decoratorsStack = {}
    end)

    apply_prototype_decorators(prototype)
    classes[#classes].prototype = prototype

    classes[#classes].new = function(self, ...)
        local instance = build_instance_from_prototype(self.prototype, self)

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

function inherit(...)
    local parents = table:reverse(table:remove_duplicate({ ... }))

    return function(init_function)
        local new_class = class(init_function)
        new_class.parents = {}

        for i = 1, #parents do
            local prototype = table:copy(parents[i].prototype)
            new_class.parents[#new_class.parents + 1] = parents[i]

            for field_name, field_val in pairs(prototype) do
                if not new_class.prototype[field_name] then
                    new_class.prototype[field_name] = field_val
                end
            end
        end

        setmetatable(new_class, { __call = new_class.new })
        return new_class
    end
end
--- @endregion
