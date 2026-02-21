local graph = require "./graph"
type Node<T> = graph.Node<T>
local create_source_node = graph.create_source_node
local push_scope_as_child_of = graph.push_scope_as_child_of
local update_descendants = graph.update_descendants

export type Source<T> = (() -> T) & ((value: T) -> T)
export type Getter<T> = () -> T
export type Setter<T> = (value: T) -> T

local function source<T>(initial_value: T): Source<T>
    local node = create_source_node(initial_value)

    local function update_source(...): T
        if select("#", ...) == 0 then -- no args were given
            push_scope_as_child_of(node)
            return node.cache
        end

        local v = ... :: T
        if node.cache == v and (type(v) ~= "table" or table.isfrozen(v)) then
            return v
        end

        node.cache = v
        update_descendants(node)
        return v
    end

    return update_source
end

local function createSource<T>(initial_value: T): (Getter<T>, Setter<T>)
    local node = create_source_node(initial_value)

    local function getter(): T
        push_scope_as_child_of(node)
        return node.cache
    end

    local function setter(v: T): T
        if node.cache == v and (type(v) ~= "table" or table.isfrozen(v)) then
            return v
        end

        node.cache = v
        update_descendants(node)
        return v
    end

    return getter, setter
end

return {
    source = source :: (<T>(initial_value: T) -> Source<T>) & (<T>() -> Source<T>),
    createSource = createSource :: (<T>(initial_value: T) -> (Getter<T>, Setter<T>)) & (<T>() -> (Getter<T>, Setter<T>)),
}
