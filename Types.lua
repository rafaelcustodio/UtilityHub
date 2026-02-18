-------- Generic
---@alias ItemLink string

--------- Database
---@class Character
---@field name string
---@field race number
---@field className number
---@field group number
---@field cooldownGroup table<string, CurrentCooldown[]>

---@class Option
---@field categoryID number

-------- Preset
---@class MailPreset
---@field id? number
---@field name string
---@field to string
---@field color colorRGBA
---@field itemGroups table<string, boolean>
---@field custom ItemLink[]
---@field exclusion ItemLink[]

---@class ItemGroupOption
---@field label string
---@field CheckItemBelongsToGroup fun(itemLink: ItemLink): boolean
---@field IsEnabledInThisExpansion? fun(): boolean

------- Options
---@class OptionsCreateList
---@field GetText? fun(rowData): string
---@field SortComparator fun(a: any, b: any): boolean
---@field CustomizeRow? fun(frame: table, rowData: any, helpers)
---@field showCheckbox? boolean
---@field showRemoveIcon? boolean
---@field OnRemove? fun(rowData, OptionsCreateList): boolean
---@field hasHyperlink? boolean
---@field GetHyperlink? fun(rowData: any): string

------- AutoBuy
---@class AutoBuyItem
---@field itemLink ItemLink
---@field quantity number