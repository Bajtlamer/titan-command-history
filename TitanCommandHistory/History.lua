local _, ns = ...
-- The store: what was sent, in the order it was sent. Pure Lua so it can be tested without the client.
local History = {}
ns.History = History

History.DEFAULT_QUICK = { '/reload', '/sit', '/stand', '/dance', '/wave', '/cheer', '/laugh', '/thank', '/bow' }
History.DEFAULTS = { max = 500, recordChat = true, onlySuccess = true, scope = 'account', showMinimapButton = true }

-- db is the saved variables table, characterID identifies the logged in character.
function History.Init(db, characterID)
    db.settings = db.settings or {}
    for key, value in pairs(History.DEFAULTS) do
        if db.settings[key] == nil then db.settings[key] = value end
    end
    db.account = db.account or { entries = {} }
    db.characters = db.characters or {}
    History.db, History.characterID = db, characterID
    -- Favorites replaced the earlier quick commands and pinned lines: both are carried over once.
    if db.favorites == nil then
        db.favorites = {}
        for _, text in ipairs(db.settings.quick or History.DEFAULT_QUICK) do History.AddFavorite(text) end
        db.settings.quick = nil
        local lists = { db.account.entries }
        for _, character in pairs(db.characters) do lists[#lists + 1] = character.entries end
        for _, entries in ipairs(lists) do
            for _, entry in ipairs(entries) do
                if entry.pinned then History.AddFavorite(entry.text) end
                entry.pinned = nil
            end
        end
    end
end

function History.Settings() return History.db.settings end

-- Entries of the active scope, oldest first.
function History.List()
    local db = History.db
    if db.settings.scope == 'character' and History.characterID then
        local character = db.characters[History.characterID]
        if not character then
            character = { entries = {} }
            db.characters[History.characterID] = character
        end
        return character.entries
    end
    return db.account.entries
end

function History.Trim(text)
    return (tostring(text):gsub('^%s+', ''):gsub('%s+$', ''))
end

-- Text starting with a slash is a command, anything else is a conversation line.
function History.Classify(text)
    return text:sub(1, 1) == '/' and 'command' or 'chat'
end

local function limit(entries, max)
    while #entries > max do table.remove(entries, 1) end
end

-- Adds a line. The same line twice in a row only counts as one more use, like a shell with ignoredups.
-- Returns the entry and whether a new one was created.
function History.Add(text, now)
    text = History.Trim(text)
    if text == '' then return nil, false end
    local entries = History.List()
    local last = entries[#entries]
    if last and last.text == text then
        last.at, last.uses = now, (last.uses or 1) + 1
        return last, false
    end
    local entry = { text = text, kind = History.Classify(text), at = now, uses = 1 }
    entries[#entries + 1] = entry
    limit(entries, History.db.settings.max)
    return entry, true
end

-- Newest first. kind is 'command', 'chat' or 'all'; query is a plain text filter.
function History.Entries(kind, query)
    local entries, result = History.List(), {}
    local needle = query and query ~= '' and query:lower() or nil
    for index = #entries, 1, -1 do
        local entry = entries[index]
        local wanted = kind == 'all' or kind == nil or entry.kind == kind
        if wanted and (not needle or entry.text:lower():find(needle, 1, true)) then result[#result + 1] = entry end
    end
    return result
end

-- Oldest first, for the arrow keys in the chat box.
function History.Texts()
    local result = {}
    for index, entry in ipairs(History.List()) do result[index] = entry.text end
    return result
end

function History.Count() return #History.List() end

function History.Remove(entry)
    local entries = History.List()
    for index, other in ipairs(entries) do
        if other == entry then table.remove(entries, index); return true end
    end
    return false
end

-- Empties the history. Favorites are a separate list and stay.
function History.Clear()
    local entries = History.List()
    for index = #entries, 1, -1 do entries[index] = nil end
end

-- Favorites: lines the player keeps on purpose, in the order chosen, for all characters. They are not part of the
-- history, so they do not take part in the arrow keys and are not trimmed.
function History.Favorites() return History.db.favorites end

function History.IsFavorite(text)
    for _, favorite in ipairs(History.db.favorites) do if favorite.text == text then return favorite end end
    return nil
end

function History.AddFavorite(text)
    text = History.Trim(text)
    if text == '' or History.IsFavorite(text) then return false end
    table.insert(History.db.favorites, { text = text, kind = History.Classify(text) })
    return true
end

function History.RemoveFavorite(favorite)
    for index, other in ipairs(History.db.favorites) do
        if other == favorite then table.remove(History.db.favorites, index); return true end
    end
    return false
end

function History.ToggleFavorite(text)
    local existing = History.IsFavorite(text)
    if existing then History.RemoveFavorite(existing); return false end
    History.AddFavorite(text)
    return true
end

-- Moves a favorite up (delta -1) or down (delta 1) in the list.
function History.MoveFavorite(favorite, delta)
    local list = History.db.favorites
    for index, other in ipairs(list) do
        if other == favorite then
            local target = index + delta
            if target < 1 or target > #list then return false end
            list[index], list[target] = list[target], list[index]
            return true
        end
    end
    return false
end

-- The favorites in their order, filtered by a plain text query.
function History.FavoriteEntries(query)
    local needle = query and query ~= '' and query:lower() or nil
    local result = {}
    for _, favorite in ipairs(History.db.favorites) do
        if not needle or favorite.text:lower():find(needle, 1, true) then result[#result + 1] = favorite end
    end
    return result
end
