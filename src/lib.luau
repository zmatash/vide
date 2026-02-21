local version = { major = 0, minor = 4, patch = 0 }

local root = require "./root"
local branch = require "./branch"
local mount = require "./mount"
local create = require "./create"
local apply = require "./apply"
local createSource = require "./createSource"
local effect = require "./effect"
local derive = require "./derive"
local cleanup = require "./cleanup"
local untrack = require "./untrack"
local read = require "./read"
local batch = require "./batch"
local context = require "./context"
local switch = require "./switch"
local show = require "./show"
local indexes = require "./indexes"
local values = require "./values"
local action = require "./action"()
local changed = require "./changed"
local timeout, update_timeouts = require "./timeout"()
local flags = require "./flags"

export type Getter<T> = () -> T
export type Setter<T> = (value: T) -> T
export type Context<T> = context.Context<T>

local function step(dt: number)
    if game then debug.profilebegin("VIDE STEP") end

    if game then debug.profilebegin("VIDE SCHEDULER") end
    update_timeouts(dt)
    if game then debug.profileend() end

    if game then debug.profileend() end
end

local stepped = game and game:GetService("RunService").Heartbeat:Connect(function(dt: number)
    task.defer(step, dt)
end)

local vide = {
    version = version,

    -- core
    root = root,
    --branch = branch,
    mount = mount,
    create = create,
    createSource = createSource,
    effect = effect,
    derive = derive,
    switch = switch,
    show = show,
    indexes = indexes,
    values = values,

    -- util
    cleanup = cleanup,
    untrack = untrack,
    read = read,
    batch = batch,
    context = context,

    -- actions
    action = action,
    changed = changed,

    -- flags
    strict = (nil :: any) :: boolean,
    defaults = (nil :: any) :: boolean,
    defer_nested_properties = (nil :: any) :: boolean,

    -- temporary
    apply = function(instance: Instance)
        return function(props: { [any]: any })
            apply(instance, props)
            return instance
        end
    end,

    -- runtime
    step = function(dt: number)
        if stepped then
            stepped:Disconnect()
            stepped = nil
        end
        step(dt)
    end
}

setmetatable(vide :: any, {
    __index = function(_, index: unknown): ()
        if flags[index] == nil then
            error(`{tostring(index)} is not a valid member of vide`, 0)
        else
            return flags[index]
        end
    end,

    __newindex = function(_, index: unknown, value: unknown)
        if flags[index] == nil then
            error(`{tostring(index)} is not a valid member of vide, 0`)
        else
            flags[index] = value
        end
    end
})

return vide
