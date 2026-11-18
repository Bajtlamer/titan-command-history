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
    eq(db.settings.scope, 'account'); eq(db.favorites[1].text, '/reload'); eq(db.settings.quick, nil)
end)

test('lines starting with a slash are commands, anything else is a conversation line', function()
    local H = fresh()
    eq(H.Classify('/reload'), 'command'); eq(H.Classify('hello there'), 'chat'); eq(H.Classify('/dance'), 'command')
end)

test('the client stores spoken lines with their chat type word: those are conversation lines', function()
    local H = fresh()
    eq(H.Classify('/s hello'), 'chat'); eq(H.Classify('/p hello'), 'chat'); eq(H.Classify('/GUILD hi'), 'chat')
    eq(H.Classify('/w Name hi there'), 'chat'); eq(H.Classify('/r thanks'), 'chat'); eq(H.Classify('/1 anyone?'), 'chat')
    eq(H.Classify('/sit'), 'command'); eq(H.Classify('/run print(1)'), 'command')
end)

test('chat type words of the running client are added from its globals', function()
    local H = fresh()
    eq(H.Classify('/sagen hallo'), 'command')
    H.LoadChatWords({ SLASH_SAY1 = '/sagen', SLASH_SAY2 = '/s', SLASH_RELOAD1 = '/reload', SLASH_PARTY1 = '/gruppe' })
    eq(H.Classify('/sagen hallo'), 'chat'); eq(H.Classify('/gruppe hi'), 'chat'); eq(H.Classify('/reload'), 'command')
end)

test('Add stores the kind by the chat type word, entries are found under the right tab', function()
    local H = fresh()
    H.Add('/p hello', 1); H.Add('/reload', 2)
    eq(#H.Entries('chat'), 1); eq(H.Entries('chat')[1].text, '/p hello'); eq(#H.Entries('command'), 1)
end)

test('entries and favorites saved with the wrong kind are corrected once', function()
    local ns = {}
    assert(loadfile('TitanCommandHistory/History.lua'))('TitanCommandHistory', ns)
    local db = { settings = {}, favorites = { { text = '/s hi', kind = 'command' } },
        account = { entries = { { text = '/p hello', kind = 'command', at = 1 }, { text = '/sit', kind = 'command', at = 2 } } },
        characters = { ['Player-1'] = { entries = { { text = '/w Bob hi', kind = 'command', at = 3 } } } } }
    ns.History.Init(db, 'Player-1')
    eq(db.account.entries[1].kind, 'chat'); eq(db.account.entries[2].kind, 'command')
    eq(db.characters['Player-1'].entries[1].kind, 'chat'); eq(db.favorites[1].kind, 'chat')
end)

test('the same line twice in a row counts as one more use', function()
    local H = fresh()
    H.Add('/sit', 1); H.Add('/sit', 2)
    eq(H.Count(), 1); eq(H.List()[1].uses, 2); eq(H.List()[1].at, 2)
    H.Add('/stand', 3); H.Add('/sit', 4)
    eq(H.Count(), 3)                           -- not in a row: a new entry, like a shell
    eq(select(2, H.Add('   ', 5)), false); eq(H.Count(), 3)
end)

test('the limit removes the oldest lines', function()
    local H = fresh({ max = 3 })
    for index = 1, 6 do H.Add('/n' .. index, index) end
    eq(H.Count(), 3); eq(H.List()[1].text, '/n4'); eq(H.List()[3].text, '/n6')
end)

test('entries come newest first, filtered by tab and search', function()
    local H = fresh()
    H.Add('/reload', 1); H.Add('good morning', 2); H.Add('/dance', 3)
    local commands = H.Entries('command')
    eq(#commands, 2); eq(commands[1].text, '/dance')
    eq(#H.Entries('chat'), 1); eq(#H.Entries('all'), 3)
    eq(#H.Entries('all', 'DAN'), 1)            -- case insensitive plain search
    local texts = H.Texts()
    eq(texts[1], '/reload'); eq(texts[3], '/dance')   -- oldest first for the arrow keys
end)

test('remove and clear', function()
    local H = fresh()
    H.Add('/a', 1); H.Add('/b', 2); H.Add('/c', 3)
    eq(H.Remove(H.List()[2]), true); eq(H.Count(), 2)
    H.AddFavorite('/keep')
    H.Clear(); eq(H.Count(), 0)
    eq(H.IsFavorite('/keep') ~= nil, true)    -- favorites are a separate list
end)

test('the history can be kept per character', function()
    local H, db = fresh({ scope = 'character' })
    H.Add('/mine', 1)
    eq(#db.characters['Player-1'].entries, 1); eq(#db.account.entries, 0)
    db.settings.scope = 'account'
    eq(H.Count(), 0)
end)

test('favorites are added once, in order, and can be moved, toggled and removed', function()
    local H = fresh()
    local before = #H.Favorites()
    eq(H.AddFavorite('/played'), true); eq(H.AddFavorite('  /played '), false); eq(#H.Favorites(), before + 1)
    eq(H.AddFavorite('  '), false)
    eq(H.AddFavorite('good evening everyone'), true)
    eq(H.Favorites()[#H.Favorites()].kind, 'chat')   -- a favorite can be a conversation line
    local played = H.IsFavorite('/played')
    eq(H.MoveFavorite(played, -1), true); eq(H.Favorites()[before].text, '/played')
    eq(H.MoveFavorite(H.Favorites()[1], -1), false)   -- already first
    eq(H.ToggleFavorite('/played'), false); eq(H.IsFavorite('/played'), nil)
    eq(H.ToggleFavorite('/played'), true)
    eq(H.RemoveFavorite(H.IsFavorite('/played')), true); eq(H.RemoveFavorite(played), false)
end)

test('favorites can be searched and keep their order', function()
    local H = fresh()
    local all = #H.Favorites()
    eq(#H.FavoriteEntries(), all)
    eq(#H.FavoriteEntries('RELOAD'), 1); eq(H.FavoriteEntries('reload')[1].text, '/reload')
    eq(#H.FavoriteEntries('nothing like this'), 0)
end)

test('earlier quick commands and pinned lines become favorites once', function()
    local ns = {}
    assert(loadfile('TitanCommandHistory/History.lua'))('TitanCommandHistory', ns)
    local db = { settings = { quick = { '/sit', '/reload' } },
        account = { entries = { { text = '/dance', kind = 'command', at = 1, pinned = true },
            { text = '/wave', kind = 'command', at = 2 } } }, characters = {} }
    ns.History.Init(db, 'P')
    eq(#db.favorites, 3); eq(db.favorites[1].text, '/sit'); eq(db.favorites[3].text, '/dance')
    eq(db.settings.quick, nil); eq(db.account.entries[1].pinned, nil)
    ns.History.Init(db, 'P')                   -- a second start changes nothing
    eq(#db.favorites, 3)
end)

for _, entry in ipairs(tests) do
    local ok, err = pcall(entry[2])
    if not ok then io.stderr:write('FAIL ' .. entry[1] .. ': ' .. tostring(err) .. '\n'); os.exit(1) end
end
print('PASS history ' .. #tests .. ' checks')
