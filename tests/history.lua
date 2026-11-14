local tests = {}
local function test(name, fn) tests[#tests + 1] = { name, fn } end
local function eq(actual, expected) assert(actual == expected, 'expected ' .. tostring(expected) .. ', got ' .. tostring(actual)) end

local function fresh(settings)
    local ns = {}
    assert(loadfile('TitanCommandHistory/History.lua'))('TitanCommandHistory', ns)
    local db = { settings = settings }
    ns.History.Init(db, 'Player-1')
    return ns.History, db
end

test('defaults are filled in and existing settings are kept', function()
    local H, db = fresh({ max = 10 })
    eq(db.settings.max, 10); eq(db.settings.recordChat, true); eq(db.settings.onlySuccess, true)
    eq(db.settings.scope, 'account'); eq(db.settings.quick[1], '/reload')
end)

test('lines starting with a slash are commands, anything else is a conversation line', function()
    local H = fresh()
    eq(H.Classify('/reload'), 'command'); eq(H.Classify('hello there'), 'chat'); eq(H.Classify('/s hello'), 'command')
end)

test('the same line twice in a row counts as one more use', function()
    local H = fresh()
    H.Add('/sit', 1); H.Add('/sit', 2)
    eq(H.Count(), 1); eq(H.List()[1].uses, 2); eq(H.List()[1].at, 2)
    H.Add('/stand', 3); H.Add('/sit', 4)
    eq(H.Count(), 3)                           -- not in a row: a new entry, like a shell
    eq(select(2, H.Add('   ', 5)), false); eq(H.Count(), 3)
end)

test('the limit removes the oldest lines but never pinned ones', function()
    local H = fresh({ max = 3 })
    local first = H.Add('/one', 1)
    H.SetPinned(first, true)
    for index = 2, 6 do H.Add('/n' .. index, index) end
    eq(H.Count(), 3); eq(H.List()[1].text, '/one'); eq(H.List()[3].text, '/n6')
end)

test('entries come newest first, filtered by tab and search', function()
    local H = fresh()
    H.Add('/reload', 1); H.Add('good morning', 2); H.Add('/dance', 3)
    local commands = H.Entries('command')
    eq(#commands, 2); eq(commands[1].text, '/dance')
    eq(#H.Entries('chat'), 1); eq(#H.Entries('all'), 3)
    eq(#H.Entries('all', 'DAN'), 1)            -- case insensitive plain search
    eq(#H.Entries('pinned'), 0)
    H.SetPinned(H.List()[2], true)
    eq(H.Entries('pinned')[1].text, 'good morning')
    local texts = H.Texts()
    eq(texts[1], '/reload'); eq(texts[3], '/dance')   -- oldest first for the arrow keys
end)

test('remove and clear keep what was asked', function()
    local H = fresh()
    local a = H.Add('/a', 1); H.Add('/b', 2); H.Add('/c', 3)
    H.SetPinned(a, true)
    eq(H.Remove(H.List()[2]), true); eq(H.Count(), 2)
    H.Clear(true); eq(H.Count(), 1); eq(H.List()[1].text, '/a')
    H.Clear(false); eq(H.Count(), 0)
end)

test('the history can be kept per character', function()
    local H, db = fresh({ scope = 'character' })
    H.Add('/mine', 1)
    eq(#db.characters['Player-1'].entries, 1); eq(#db.account.entries, 0)
    db.settings.scope = 'account'
    eq(H.Count(), 0)
end)

test('quick commands can be added once and removed', function()
    local H = fresh()
    local before = #H.Quick()
    eq(H.AddQuick('/played'), true); eq(H.AddQuick('/played'), false); eq(#H.Quick(), before + 1)
    eq(H.RemoveQuick('/played'), true); eq(H.RemoveQuick('/played'), false)
    eq(H.AddQuick('  '), false)
end)

for _, entry in ipairs(tests) do
    local ok, err = pcall(entry[2])
    if not ok then io.stderr:write('FAIL ' .. entry[1] .. ': ' .. tostring(err) .. '\n'); os.exit(1) end
end
print('PASS history ' .. #tests .. ' checks')
