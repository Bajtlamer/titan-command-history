local _, ns = ...
-- Saved variables, events and the hooks on the chat edit boxes.
local capture
local frame = CreateFrame('Frame')

local function public(value)
    return not (issecretvalue and issecretvalue(value))
end

-- The log keeps the kind and the first word of a line and what became of it, never the text: whispers and
-- conversation lines are private.
local function log(text, result)
    local entries = ns.db and ns.db.log
    if not entries then return end
    local kind = ns.History.Classify(text)
    entries[#entries + 1] = { at = time and time() or 0, kind = kind, word = kind == 'command' and text:match('^/(%S+)') or nil,
        result = result }
    while #entries > 30 do table.remove(entries, 1) end
end

function ns.PrintLog()
    local entries = ns.db and ns.db.log or {}
    if #entries == 0 then print('Titan Command History: nothing recorded yet.'); return end
    for _, entry in ipairs(entries) do
        local stamp = date and date('%H:%M:%S', entry.at) or tostring(entry.at)
        print(stamp .. ' ' .. entry.kind .. (entry.word and (' /' .. entry.word) or '') .. ' ' .. entry.result)
    end
end

-- Error messages that follow a line the client could not use.
local errorPatterns = {}
for _, name in ipairs({ 'ERR_CHAT_PLAYER_NOT_FOUND_S', 'ERR_NOT_IN_GROUP', 'ERR_NOT_IN_RAID', 'ERR_NOT_IN_GUILD',
    'ERR_GUILD_PLAYER_NOT_IN_GUILD', 'ERR_CHAT_WHILE_DEAD' }) do
    local value = _G[name]
    if type(value) == 'string' then
        local escaped = value:gsub('([%^%$%(%)%.%[%]%*%+%-%?%%])', '%%%1'):gsub('%%%%s', '.+')
        errorPatterns[#errorPatterns + 1] = '^' .. escaped .. '$'
    end
end

local function hookBoxes()
    local count = NUM_CHAT_WINDOWS or 10
    for index = 1, count do
        local box = _G['ChatFrame' .. index .. 'EditBox']
        if box then
            local ok = pcall(hooksecurefunc, box, 'AddHistoryLine', function(_, line)
                if type(line) == 'string' and public(line) then capture:Sent(line) end
            end)
            if not ok then log('/hook', 'hook-failed') end
            ns.Arrows.Attach(box, ns.History.Texts)
        end
    end
end

local function setup()
    TitanCommandHistoryDB = TitanCommandHistoryDB or {}
    ns.db = TitanCommandHistoryDB
    ns.db.log = ns.db.log or {}
    local guid = UnitGUID and UnitGUID('player')
    ns.History.LoadChatWords(_G)
    ns.History.Init(ns.db, guid and public(guid) and guid or nil)
    capture = ns.Capture.New({
        Settings = ns.History.Settings,
        Env = function() return _G end,
        After = function(seconds, callback) C_Timer.After(seconds, callback) end,
        Add = function(line)
            ns.History.Add(line, time())
            ns.Titan.Refresh()
        end,
        Log = log,
    })
    ns.capture = capture
end

frame:SetScript('OnEvent', function(_, event, ...)
    if event == 'ADDON_LOADED' then
        if ... == 'TitanCommandHistory' then setup() end
    elseif event == 'PLAYER_LOGIN' then
        hookBoxes()
        ns.Titan.Initialize()
        ns.MinimapButton.Attach()
        -- Titan Panel may read the plugin text after this point, so the count is set again a little later.
        C_Timer.After(2, ns.Titan.Refresh)
    elseif event == 'PLAYER_ENTERING_WORLD' then
        if ns.Titan and ns.db then ns.Titan.Refresh() end
    elseif event == 'PLAYER_LOGOUT' then
        if capture then capture:Flush() end
    elseif event == 'UI_ERROR_MESSAGE' then
        if capture then capture:Failed() end
    elseif event == 'CHAT_MSG_SYSTEM' then
        local message = ...
        if capture and type(message) == 'string' and public(message) then
            for _, pattern in ipairs(errorPatterns) do
                if message:find(pattern) then capture:Failed(); break end
            end
        end
    end
end)
for _, event in ipairs({ 'ADDON_LOADED', 'PLAYER_LOGIN', 'PLAYER_ENTERING_WORLD', 'PLAYER_LOGOUT', 'UI_ERROR_MESSAGE',
    'CHAT_MSG_SYSTEM' }) do
    frame:RegisterEvent(event)
end
