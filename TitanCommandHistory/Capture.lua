local _, ns = ...
-- Decides what is recorded. A line is recorded only when it looks successful: a slash command must start with a
-- word the client knows, and no error message may follow it within a short moment. This is the shell rule "do not
-- keep what failed". The setting onlySuccess switches it off.
local Capture = {}
Capture.__index = Capture
ns.Capture = Capture

Capture.WAIT = 0.4
-- Commands that end or restart the interface: the waiting time would never run out, so they are recorded at once.
Capture.IMMEDIATE = { reload = true, reloadui = true, rl = true, logout = true, camp = true, quit = true, exit = true }
local LOG_LIMIT = 30

-- The slash words the client knows: SLASH_<NAME><n> globals (commands and chat types) and emote words.
function Capture.Tokens(env)
    local tokens = {}
    for key, value in pairs(env) do
        if type(key) == 'string' and type(value) == 'string' and value:sub(1, 1) == '/' then
            if key:find('^SLASH_') or key:find('^EMOTE%d+_CMD%d+$') then tokens[value:sub(2):lower()] = true end
        end
    end
    return tokens
end

function Capture.New(api)
    return setmetatable({ api = api, pending = {}, tokens = nil }, Capture)
end

function Capture:Log(text, result)
    local log = self.api.Log
    if log then log(text, result) end
end

-- True for text that is not a slash command and for slash words the client knows. A miss rebuilds the set once
-- because other addons register their words later.
function Capture:Known(text)
    local word = text:match('^/(%S+)')
    if not word then return true end
    word = word:lower()
    if word:find('^%d+$') then return true end -- /1 hello (channel number)
    if not self.tokens or not self.tokens[word] then self.tokens = Capture.Tokens(self.api.Env()) end
    return self.tokens[word] == true
end

-- Called with every line the player sent.
function Capture:Sent(text)
    local settings = self.api.Settings()
    text = ns.History.Trim(text)
    if text == '' then return end
    local kind = ns.History.Classify(text)
    if kind == 'chat' and not settings.recordChat then self:Log(text, 'chat-off'); return end
    if not settings.onlySuccess then
        self.api.Add(text); self:Log(text, 'recorded'); return
    end
    if kind == 'command' and not self:Known(text) then self:Log(text, 'unknown-command'); return end
    local word = text:match('^/(%S+)')
    if word and Capture.IMMEDIATE[word:lower()] then
        self.api.Add(text); self:Log(text, 'recorded'); return
    end
    local line = { text = text, failed = false }
    self.pending[#self.pending + 1] = line
    self.api.After(Capture.WAIT, function() self:Resolve(line) end)
end

-- An error message arrived: every line still waiting failed.
function Capture:Failed()
    for _, line in ipairs(self.pending) do line.failed = true end
end

function Capture:Resolve(line)
    local found = false
    for index, other in ipairs(self.pending) do
        if other == line then table.remove(self.pending, index); found = true; break end
    end
    if not found then return end -- already recorded by Flush
    if line.failed then self:Log(line.text, 'failed'); return end
    self.api.Add(line.text)
    self:Log(line.text, 'recorded')
end

-- The game is closing or reloading: lines still waiting have had no error so far, so they count as successful.
function Capture:Flush()
    local waiting = self.pending
    self.pending = {}
    for _, line in ipairs(waiting) do
        if not line.failed then
            self.api.Add(line.text)
            self:Log(line.text, 'recorded')
        end
    end
end
