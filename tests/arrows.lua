local tests = {}
local function test(name, fn) tests[#tests + 1] = { name, fn } end
local function eq(actual, expected) assert(actual == expected, 'expected ' .. tostring(expected) .. ', got ' .. tostring(actual)) end

local function load()
    local ns = {}
    assert(loadfile('TitanCommandHistory/Arrows.lua'))('TitanCommandHistory', ns)
    return ns.Arrows
end

test('up walks back, down walks forward and ends at the typed text', function()
    local Arrows = load()
    local texts = { '/one', '/two', '/three' }
    local nav = Arrows.New(function() return texts end)
    eq(nav:Up('typing'), '/three'); eq(nav:Up('x'), '/two'); eq(nav:Up('x'), '/one')
    eq(nav:Up('x'), '/one')                  -- the oldest line stays
    eq(nav:Down(), '/two'); eq(nav:Down(), '/three')
    eq(nav:Down(), 'typing')                 -- back to the draft
    eq(nav:Down(), nil)                      -- nothing more to change
end)

test('an empty history changes nothing', function()
    local nav = load().New(function() return {} end)
    eq(nav:Up('abc'), nil); eq(nav:Down(), nil)
end)

test('reset starts again from the newest line', function()
    local nav = load().New(function() return { '/a', '/b' } end)
    eq(nav:Up(''), '/b'); eq(nav:Up(''), '/a')
    nav:Reset()
    eq(nav:Up('new'), '/b')
end)

test('attaching enables plain arrows and walks the history in the box', function()
    local Arrows = load()
    local scripts, state = {}, { text = 'draft', mode = nil }
    local box = {
        SetAltArrowKeyMode = function(_, value) state.mode = value end,
        HookScript = function(_, name, fn) scripts[name] = fn end,
        SetText = function(_, value) state.text = value end,
        GetText = function() return state.text end,
        SetCursorPosition = function(_, value) state.cursor = value end,
    }
    Arrows.Attach(box, function() return { '/old', '/new' } end)
    eq(state.mode, false)
    scripts.OnArrowPressed(box, 'UP'); eq(state.text, '/new'); eq(state.cursor, 4)
    scripts.OnArrowPressed(box, 'UP'); eq(state.text, '/old')
    scripts.OnArrowPressed(box, 'LEFT'); eq(state.text, '/old')
    scripts.OnArrowPressed(box, 'DOWN'); scripts.OnArrowPressed(box, 'DOWN'); eq(state.text, 'draft')
    scripts.OnArrowPressed(box, 'UP'); scripts.OnTextChanged(box, true)   -- typing ends the walk
    scripts.OnArrowPressed(box, 'UP'); eq(state.text, '/new')
end)

for _, entry in ipairs(tests) do
    local ok, err = pcall(entry[2])
    if not ok then io.stderr:write('FAIL ' .. entry[1] .. ': ' .. tostring(err) .. '\n'); os.exit(1) end
end
print('PASS arrows ' .. #tests .. ' checks')
