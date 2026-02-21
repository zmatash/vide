assert(game, "when using vide outside of Roblox, require lib.luau instead")

local vide = require(script.lib)

export type Source<T> = vide.Source<T>
export type Getter<T> = vide.Getter<T>
export type Setter<T> = vide.Setter<T>
export type Context<T> = vide.Context<T>
export type Readable<T> = T | (() -> T)

return vide
