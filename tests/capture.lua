local tests = {}
local function test(name, fn) tests[#tests + 1] = { name, fn } end
local function eq(actual, expected) assert(actual == expected, 'expected ' .. tostring(expected) .. ', got ' .. tostring(actual)) end

local function fresh(settings, env)
    local ns = {}
    assert(loadfile('TitanCommandHistory/History.lua'))('TitanCommandHistory', ns)
    assert(loadfile('TitanCommandHistory/Capture.lua'))('TitanCommandHistory', ns)
    local db = { settings = settings }
    ns.History.Init(db, 'Player-1')
    local timers, results = {}, {}
    local capture = ns.Capture.New({
        Settings = ns.History.Settings, Env = function() return env or { SLASH_RELOAD1 = '/reload', SLASH_SAY1 = '/s',
            SLASH_SAY2 = '/say', EMOTE1_CMD1 = '/dance' } end,
        After = function(_, fn) timers[#timers + 1] = fn end,
        Add = function(text) ns.History.Add(text, 1) end,
        Log = function(text, result) results[#results + 1] = text .. ':' .. result end })
    return capture, ns.History, timers, results
end
local function flush(timers) for _, fn in ipairs(timers) do fn() end; for index = #timers, 1, -1 do timers[index] = nil end end

test('known slash words are recorded after the waiting time', function()
    local capture, H, timers = fresh()
    capture:Sent('/reload'); capture:Sent('/DANCE'); capture:Sent('/s hello')
    eq(H.Count(), 0)                         -- still waiting for a possible error
    flush(timers)
    eq(H.Count(), 3)
end)

test('unknown slash words are dropped at once', function()
    local capture, H, timers, results = fresh()
    capture:Sent('/relod')
    flush(timers)
    eq(H.Count(), 0); eq(results[1], '/relod:unknown-command')
end)

test('channel numbers count as known words', function()
    local capture, H, timers = fresh()
    capture:Sent('/1 hello'); flush(timers); eq(H.Count(), 1)
end)

test('an error within the waiting time means the line failed', function()
    local capture, H, timers, results = fresh()
    capture:Sent('hello there'); capture:Failed(); flush(timers)
    eq(H.Count(), 0); eq(results[1], 'hello there:failed')
    capture:Sent('hello again'); flush(timers)        -- the error belonged to the first line only
    eq(H.Count(), 1)
end)

test('conversation lines can be switched off', function()
    local capture, H, timers, results = fresh({ recordChat = false })
    capture:Sent('hello'); flush(timers)
    eq(H.Count(), 0); eq(results[1], 'hello:chat-off')
    capture:Sent('/reload'); flush(timers); eq(H.Count(), 1)
end)

test('everything is recorded at once when only successful input is not required', function()
    local capture, H = fresh({ onlySuccess = false })
    capture:Sent('/relod'); capture:Sent('hello')
    eq(H.Count(), 2)
end)

test('a word registered later is found by rebuilding the set once', function()
    local env = { SLASH_SAY1 = '/s' }
    local capture, H, timers = fresh(nil, env)
    capture:Sent('/late'); flush(timers); eq(H.Count(), 0)
    env.SLASH_LATE1 = '/late'
    capture:Sent('/late'); flush(timers); eq(H.Count(), 1)
end)

test('blank lines are ignored', function()
    local capture, H, timers = fresh()
    capture:Sent('   '); flush(timers); eq(H.Count(), 0)
end)

for _, entry in ipairs(tests) do
    local ok, err = pcall(entry[2])
    if not ok then io.stderr:write('FAIL ' .. entry[1] .. ': ' .. tostring(err) .. '\n'); os.exit(1) end
end
print('PASS capture ' .. #tests .. ' checks')
