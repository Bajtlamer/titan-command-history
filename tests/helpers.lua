local function eq(actual, expected) assert(actual == expected, 'expected ' .. tostring(expected) .. ', got ' .. tostring(actual)) end
local ns = {}
assert(loadfile('TitanCommandHistory/Window.lua'))('TitanCommandHistory', ns)
assert(loadfile('TitanCommandHistory/MinimapButton.lua'))('TitanCommandHistory', ns)
local W = ns.Window
eq(W.Clamp(-3, 100), 0); eq(W.Clamp(500, 100), 84); eq(W.Clamp(5.6, 100), 6); eq(W.Clamp(3, 5), 0)
eq(W.RangeText(0, 0), 'No lines'); eq(W.RangeText(16, 40), 'Showing 17-32 of 40'); eq(W.RangeText(30, 40), 'Showing 31-40 of 40')
eq(W.Ago(5), 'now'); eq(W.Ago(120), '2 min ago'); eq(W.Ago(7300), '2 h ago'); eq(W.Ago(200000), '2 d ago')
local x, y = ns.MinimapButton.Position(0, 140, 140)
eq(math.floor(x + 0.5), 92); eq(math.floor(y + 0.5), 0)
eq(ns.MinimapButton.AngleFromCursor(0, 10, 0, 0), 90); eq(ns.MinimapButton.AngleFromCursor(-5, 0, 0, 0), 180)
eq(ns.MinimapButton.AngleFromCursor(0, -10, 0, 0), 270)
print('PASS helpers 5 checks')
