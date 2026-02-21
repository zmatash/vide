local branch = require "./branch"
local createSource = require "./createSource"
local effect = require "./effect"
local timeout = require "./timeout" ()

type Array<T> = { T }
type Map<K, V> = { [K]: V }
type Getter<T> = () -> T
type Setter<T> = (value: T) -> T
type Component<T> = (Getter<boolean>) -> (T, ...number)

local function switch_map<K, Obj>(
    input: Getter<K>,
    map: Map<K, Component<Obj>>
): Getter<nil | Obj | Array<Obj>>
    local scopes = {} :: Map<K, {
        destroy: () -> (),
        object: Obj,
        delay: number,
        set_present: Setter<boolean>,
        timeout: { cancel: boolean }?
    }>

    local output, set_output = createSource(nil :: nil | Obj | Array<Obj>)
    local function update_output()
        local objects = {}

        for _, scope in scopes do
            table.insert(objects, scope.object)
        end

        set_output(
            if objects[2] then objects
            elseif objects[1] then objects[1]
            else nil
        )
    end

    effect(function()
        local key: K? = input()

        -- destroy (or queue destroy) all scopes not associated with the input key
        for k, scope in scopes do
            if k == key then continue end

            scope.set_present(false)

            if scope.delay == 0 then
                scope.destroy()
                scopes[k] = nil
            else
                if scope.timeout == nil then
                    scope.timeout = timeout(scope.delay, function()
                        scope.destroy()
                        scopes[k] = nil
                        update_output()
                    end)
                end
            end
        end

        -- create new scope or abort destruction of existing scope if key exists
        if key ~= nil then
            local scope = scopes[key]

            if scope then
                scope.set_present(true)

                if scope.timeout then
                    scope.timeout.cancel = true
                    scope.timeout = nil
                end
            else
                local component = map[key]

                if component ~= nil then
                    if type(component) ~= "function" then
                        error("map must map a value to a function", 0)
                    end

                    local get_present, set_present = createSource(false)

                    local delay = nil :: number?
                    local destroy, object = branch(function()
                        local object, t = component(get_present)
                        delay = t
                        return object
                    end)

                    set_present(true)

                    scopes[key] = {
                        destroy = destroy,
                        object = object,
                        delay = delay or 0,
                        set_present = set_present,
                        timeout = nil
                    }
                end
            end
        end

        update_output()
    end)

    return output
end

local function switch<K, Obj>(input: Getter<K>): (map: Map<K, Component<Obj>>) -> Getter<nil | Obj | Array<Obj>>
    return function(map)
        return switch_map(input, map)
    end
end

return switch
