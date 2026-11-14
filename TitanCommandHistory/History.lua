local _, ns = ...
-- The store: what was sent, in the order it was sent. Pure Lua so it can be tested without the client.
local History = {}
ns.History = History

History.DEFAULT_QUICK = { '/reload', '/sit', '/stand', '/dance', '/wave', '/cheer', '/laugh', '/thank', '/bow' }
History.DEFAULTS = { max = 500, recordChat = true, onlySuccess = true, scope = 'account', showMinimapButton = true }

local function copy(list)
    local result = {}
    for index, value in ipairs(list) do result[index] = value end
    return result
end

-- db is the saved variables table, characterID identifies the logged in character.
function History.Init(db, characterID)
    db.settings = db.settings or {}
    for key, value in pairs(History.DEFAULTS) do
        if db.settings[key] == nil then db.settings[key] = value end
    end
    if db.settings.quick == nil then db.settings.quick = copy(History.DEFAULT_QUICK) end
    db.account = db.account or { entries = {} }
    db.characters = db.characters or {}
    History.db, History.characterID = db, characterID
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
    local index = 1
    while #entries > max and index <= #entries do
        if entries[index].pinned then index = index + 1 else table.remove(entries, index) end
    end
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

-- Newest first. kind is 'command', 'chat', 'pinned' or 'all'; query is a plain text filter.
function History.Entries(kind, query)
    local entries, result = History.List(), {}
    local needle = query and query ~= '' and query:lower() or nil
    for index = #entries, 1, -1 do
        local entry = entries[index]
        local wanted = kind == 'all' or kind == nil or (kind == 'pinned' and entry.pinned) or entry.kind == kind
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

function History.SetPinned(entry, pinned) entry.pinned = pinned or nil end

function History.Remove(entry)
    local entries = History.List()
    for index, other in ipairs(entries) do
        if other == entry then table.remove(entries, index); return true end
    end
    return false
end

-- Empties the history; pinned lines stay unless keepPinned is false.
function History.Clear(keepPinned)
    local entries, kept = History.List(), {}
    if keepPinned then
        for _, entry in ipairs(entries) do if entry.pinned then kept[#kept + 1] = entry end end
    end
    for index = #entries, 1, -1 do entries[index] = nil end
    for index, entry in ipairs(kept) do entries[index] = entry end
end

function History.Quick() return History.db.settings.quick end

function History.AddQuick(text)
    text = History.Trim(text)
    if text == '' then return false end
    for _, existing in ipairs(History.Quick()) do if existing == text then return false end end
    table.insert(History.Quick(), text)
    return true
end

function History.RemoveQuick(text)
    local quick = History.Quick()
    for index, existing in ipairs(quick) do
        if existing == text then table.remove(quick, index); return true end
    end
    return false
end
